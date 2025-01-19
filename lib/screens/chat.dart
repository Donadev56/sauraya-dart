import 'dart:convert';
import 'dart:io';
import 'package:sauraya/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/service/secure_storage.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/id_generator.dart';
import 'package:sauraya/utils/remove_markdown.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/audio_player.dart';
import 'package:sauraya/widgets/custom_app_bar.dart';
import 'package:sauraya/widgets/diaolog.dart';
import 'package:sauraya/widgets/message_manager.dart';
import 'package:sauraya/widgets/options_button.dart';
import 'package:sauraya/widgets/overlay_message.dart';
import 'package:sauraya/widgets/sidebar_custom.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:sauraya/service/data_saver.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String prompt = "";
  Messages messages = [];
  late TextEditingController _textController;
  late ScrollController _messagesScrollController;
  late stt.SpeechToText speech;
  bool _speechEnabled = false;
  bool isListening = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  int currentNumberOfResponse = 0;
  bool isAudioLoading = false;
  bool isExec = false;
  UserData user =
      UserData(address: "", userId: "", token: "", joiningDate: 0, name: "");

  String userId = "";
  String conversationId = "";
  String conversationTitle = "";
  String searchInput = "";
  bool hasGenerateAtLastOne = true;
  bool isBottom = false ;

  String currentModel = availableModels[0];

  Conversations conversations = Conversations(conversations: {});

  late AudioPlayer audioPlayer;

  bool isGeneratingResponse = false;

  void stopGenerationWithoutSocket() async {
    try {
      if (!hasGenerateAtLastOne) {
        logError(
            "Can't send a new message when the last message is not generated");
        return;
      }
      log("Generation stopped");
      setState(() {
        isGeneratingResponse = false;
        final lastMessages = [...messages];
        lastMessages.removeWhere((msg) => msg.role == "thinkingLoader");

        messages = [...lastMessages];

        updateMessages();
      });
    } catch (e) {
      log("error during stop socket generation $e");
      showCustomSnackBar(
          context: context, message: "error during stop socket generation $e");
    }
  }

  void updateInput(String value) {
    setState(() {
      searchInput = value;
    });
  }

  void changeModel(String model) {
    setState(() {
      currentModel = model;
    });
  }

  Future<void> regenerateWithoutSocket(int msgIndex) async {
    try {
      if (!hasGenerateAtLastOne) {
        logError(
            "Can't send a new message when the last message is not generated");
        return;
      }

      if (messages.isEmpty) {
        return;
      }

      log("Regenerating response $msgIndex");
      Messages lastMessages = [...messages];
      lastMessages.removeRange(msgIndex, lastMessages.length);
      stopGenerationWithoutSocket();

      await chat(lastMessages);
    } catch (e) {
      logError("An error occurred $e");
    }
  }

  Future<void> changeTitle(String convId, String newTitle) async {
    try {
      ConversationManager manager = ConversationManager();

      final conv = conversations.conversations[convId];
      if (conv != null) {
        final newConversation =
            Conversation(id: conv.id, title: newTitle, messages: conv.messages);
        final key = await getKey(user.userId);

        setState(() {
          conversations.conversations[convId] = newConversation;
          if (convId == conversationId) {
            conversationTitle = newTitle;
          }
        });
        Conversations convsToSave =
            Conversations(conversations: conversations.conversations);

        await manager.saveConversations(key, convsToSave, userId);
      }
    } catch (e) {
      log("An error occurred $e");
    }
  }

  Future<String> getOutput(String codeToExecute) async {
    try {
      setState(() {
        isExec = true;
      });
      log("Executing code...");
      String code = codeToExecute.trim();
      final url = "https://python.sauraya.com/execute";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"code": code}),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        setState(() {
          isExec = false;
        });

        if (responseBody["error"] != null) {
          return responseBody["details"] ?? "Unknown error occurred.";
        } else {
          return responseBody["result"] ?? "No output found.";
        }
      } else {
        final error =
            "An error occurred: ${response.statusCode} - ${response.body}";
        setState(() {
          isExec = false;
        });
        return error;
      }
    } catch (e) {
      setState(() {
        isExec = false;
      });
      return "An exception occurred: $e";
    }
  }

  Future<void> updateMessages() async {
    try {
      ConversationManager manager = ConversationManager();

      String keyToUse = await getKey(user.userId);

      final messageToUpdate = [...messages];
      String convId;
      String firstMessageText = messageToUpdate[1].content;
      String currentTitle =
          conversationTitle.isEmpty ? firstMessageText : conversationTitle;

      if (messageToUpdate.isEmpty) {
        log("No messages to update");
        return;
      }
      if (conversationId.isEmpty) {
        convId = generateUUID();
      } else {
        convId = conversationId;
      }
      Conversation conversationToSave = Conversation(
          messages: messageToUpdate, id: convId, title: currentTitle);

      Conversations newConversations = conversations;
      newConversations.conversations[convId] = conversationToSave;
      manager.saveConversations(keyToUse, newConversations, userId);

      setState(() {
        if (conversationId.isEmpty) {
          conversationId = convId;
        }
        if (conversationTitle.isEmpty) {
          conversationTitle = currentTitle;
        }
        conversations = newConversations;
      });

      log("Conversations saved and updated");
    } catch (e) {
      log("an error occured $e");
    }
  }

  void _onScroll() {
  final currentPosition = _messagesScrollController.position.pixels;
  final maxPosition = _messagesScrollController.position.maxScrollExtent;

  if (currentPosition >= maxPosition) {
    setState(() {
      isBottom = true ;
    });
  } else {
    setState(() {
      isBottom = false ;
    });
  }
}


  Future<void> getConversations() async {
    try {
      ConversationManager manager = ConversationManager();

      String keyToUse = await getKey(user.userId);

      final savedConversations =
          await manager.getSavedConversations(user.userId, keyToUse);

      if (savedConversations != null) {
        setState(() {
          conversations.conversations.addAll(savedConversations.conversations);

          log("Conversations initialized");
        });
        log("Conversations found : ${conversations.conversations.values.length}");
      } else {
        log("No conversation found");
      }
    } catch (e) {
      log("Error during get conversations $e");
    }
  }

  Future<void> loadConversation(String convId) async {
    try {
      setState(() {
        final conv = conversations.conversations[convId];
        if (conv != null) {
          messages = conv.messages;
          conversationId = convId;
          conversationTitle = conv.title;
          isGeneratingResponse = false;
          isExec = false;
          isListening = false;
          currentNumberOfResponse = 0;
          _isPlaying = false;
          prompt = "";
          _textController.text = "";
          audioPlayer.stop();
        }
      });
    } catch (e) {
      log("Error during get conversations $e");
      showCustomSnackBar(
          context: context, message: "Error during get conversations ");
    }
  }

  void startNewConversation() {
    try {
      stopGenerationWithoutSocket();
      setState(() {
        conversationId = "";
        conversationTitle = "";
        messages = [];
        isGeneratingResponse = false;
        isExec = false;
        hasGenerateAtLastOne = true;

        isListening = false;
        currentNumberOfResponse = 0;
        _isPlaying = false;
        prompt = "";
        _textController.text = "";
        audioPlayer.stop();
      });
    } catch (e) {
      log("Error while starting new conversation $e");
      showCustomSnackBar(
          context: context, message: "Error while starting new conversation");
    }
  }

  Future<void> sendInitialMessage() async {
    try {
      Message sysMessage = Message(
          role: "system",
          content:
              "$systemMessage + . the current name of the user you are talking with is ${user.name}, So know what you can do is reply to messages , You can call him by his name .  ");

      Messages lastMessages = [...messages];
      Message newMessage = Message(role: "user", content: prompt);

      if (lastMessages.isEmpty) {
        lastMessages.add(sysMessage);
        findTitle(newMessage.content);
      }

      lastMessages.add(newMessage);

      updateState(
          updatedMessages: lastMessages, newPrompt: "", controllerText: "");

      chat(lastMessages);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> chat(Messages lastMessages) async {
    try {
      if (!hasGenerateAtLastOne) {
        logError(
            "Can't send a new message when the last message is not generated");
        return;
      }
      hasGenerateAtLastOne = false;

      final client = HttpClient();

      setState(() {
        Message thinkingLoader =
            Message(role: "thinkingLoader", content: "Thinking");
        messages = [...lastMessages, thinkingLoader];
        prompt = "";
        isGeneratingResponse = true;

        _textController.clear();

        scrollToBottom(_messagesScrollController);
      });
      OllamaChatRequest newChatRequest = OllamaChatRequest(
          messages: lastMessages,
          model: currentModel,
          stream: true,
          token: user.token);

      final request = await client
          .postUrl(Uri.parse("https://chat.sauraya.com/chat/message"));

      request.headers.contentType = ContentType.json;

      request.write(json.encode(newChatRequest.toJson()));

      final response = await request.close();

      response.transform(utf8.decoder).listen((chunk) {
        for (final line in chunk.split("\n")) {
          if (!isGeneratingResponse) {
            break;
          }

          if (line.startsWith("data: ")) {
            final jsonStr = line.replaceFirst("data: ", "").trim();

            if (jsonStr.isNotEmpty) {
              try {
                final dynamic data = jsonDecode(jsonStr);
                final isFirst = data["isFirst"];
                final response = data["response"];
                final message = response["message"];
                final done = response["done"];
                final textResponse = message["content"];

                if (isFirst == true) {
                  log("First Message received ");
                  hasGenerateAtLastOne = true;

                  setState(() {
                    Message newMessage =
                        Message(role: "assistant", content: textResponse);
                    final lastMessages = [...messages];
                    lastMessages
                        .removeWhere((msg) => msg.role == "thinkingLoader");

                    messages = [...lastMessages, newMessage];
                    currentNumberOfResponse++;

                    scrollToBottom(_messagesScrollController);
                  });

                  return;
                }

                if (currentNumberOfResponse == 2) {
                  scrollToBottom(_messagesScrollController);
                }

                Messages lastMessages = [...messages];
                Message lastMessage = lastMessages[lastMessages.length - 1];
                String newText = lastMessage.content + textResponse;
                setState(() {
                  Message newMessage =
                      Message(content: newText, role: "assistant");
                  lastMessages[messages.length - 1] = newMessage;
                  currentNumberOfResponse++;
                  setState(() {
                    messages = lastMessages;
                  });
                });

                if (done) {
                  updateState(isGenerating: false, numberOfResponse: 0);

                  scrollToBottom(_messagesScrollController);
                  updateMessages();
                }
              } catch (e) {
                hasGenerateAtLastOne = true;

                logError("Error parsing json : $e");
              }
            }
          } else if (line.startsWith("event: done")) {
            log("Received done event.");
            hasGenerateAtLastOne = true;
          }
        }
      });
    } catch (e) {
      logError(e.toString());
      if (!mounted) return;
      showCustomSnackBar(
          context: context, message: "Error while sending message");

      scrollToBottom(_messagesScrollController);

      updateState(
        generatedAtLastOne: true,
        isGenerating: false,
        numberOfResponse: 0,
      );
      stopGenerationWithoutSocket();
    }
  }

  Future<void> findTitle(String text) async {
    try {
      log("Finding title for $text");
      final newReq = {"token": user.token, "text": text};
      final response = await http.post(
          Uri.parse("https://chat.sauraya.com/chat/title"),
          body: json.encode(newReq),
          headers: {
            'Content-Type': 'application/json',
          });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        log("Title found $data");
        setState(() {
          conversationTitle = data;
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> removeConversation(String convId) async {
    final keyToUse = await getKey(user.userId);

    try {
      setState(() {
        final lastConvs = conversations;
        final removedConv = lastConvs.conversations.remove(convId);
        if (convId == conversationId) {
          startNewConversation();
        }
        if (removedConv != null) {
          conversations = lastConvs;
          ConversationManager manager = ConversationManager();

          Conversations newConversations =
              Conversations(conversations: lastConvs.conversations);
          manager.saveConversations(keyToUse, newConversations, userId);
          log("Conversation removed");
          if (!mounted) return;
          showCustomSnackBar(
              context: context,
              message: "Conversation removed",
              icon: Icons.check_circle,
              iconColor: Colors.green);
        }
      });
    } catch (e) {
      log("Error while removing conversation $e");
    }
  }

  Future<void> executePythonCode(String codeToExecute) async {
    try {
      final result = await getOutput(codeToExecute);
      if (!mounted) return;
      showOutPut(context, result, isExec);
    } catch (e) {
      log("An error occured $e");
    }
  }

  void readResponse(String markdown) async {
    try {
      updateState(audioLoading: true);

      final textWithEmojis = removeMarkdown(markdown);
      final text = removeEmojis(textWithEmojis);
      log("reading $text");

      final request = {"text": text};
      final mainUrl = "converter.sauraya.com";
      final url = "https://$mainUrl/convert/";
      log("Sending a request to $url");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(request),
      );
      if (response.statusCode == 200) {
        log("Converted successfully");
        final audioBytes = response.bodyBytes;
        playAudio(audioBytes);
      } else {
        log("Error converting text");
        updateState(audioLoading: false);
        if (!mounted) return;

        return;
      }
    } catch (e) {
      log(e as String);
      updateState(audioLoading: false);
    }
  }

  void playAudio(Uint8List audioBytes) async {
    try {
      await audioPlayer.play(BytesSource(audioBytes));
      setState(() {
        _isPlaying = true;
        isAudioLoading = false;
      });
    } catch (e) {
      log("Error playing audio $e");
      updateState(audioLoading: false);
      if (!mounted) return;
    }
  }

  void stopPlaying() async {
    try {
      audioPlayer.stop();
      updateState(playing: false);
    } catch (e) {
      log("Error stopping audio $e");
      showCustomSnackBar(
          context: context,
          message: "Error stopping audio: $e",
          iconColor: Colors.pinkAccent);
    }
  }

  Future<void> startListening() async {
    try {
      if (!_speechEnabled) {
        logError("Speech recognition is not enabled");
        showCustomSnackBar(
            context: context,
            message: "Speech recognition is not enabled ",
            iconColor: Colors.pinkAccent);
        return;
      }
      setState(() {
        isListening = true;
      });
      await speech.listen(
        onResult: (result) => {
          setState(
            () {
              prompt = result.recognizedWords;
              _textController.text = prompt;
            },
          )
        },
      );
    } catch (e) {
      logError("error during listen $e");
      if (!mounted) return;
      showCustomSnackBar(context: context, message: "error during listen $e");
    }
  }

  void stopListening() async {
    await speech.stop();
    updateState(listening: false);
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await speech.initialize(
        onError: ((error) {
          logError("Error initializing speech recognition");
          showCustomSnackBar(
            context: context,
            message: "Error initializing speech recognition",
            icon: Icons.error,
            iconColor: Colors.pinkAccent,
          );
        }),
        onStatus: (status) => {
          if (status == 'done' || status == 'notListening')
            {updateState(listening: false)}
        },
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
          context: context,
          message: "An error occured $e",
          icon: Icons.error,
          iconColor: Colors.pinkAccent);
    }
  }

  Future<void> getSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      SecureStorageService secureStorage = SecureStorageService();

      final userId = prefs.getString('lastAccount');
      if (userId == null) {
        logError("No user found");
        return;
      }
      final savedStringData =
          await secureStorage.loadDataFromFSS("userData/$userId");
      if (savedStringData == null) {
        logError("No data found");
        return;
      }
      final savedUserDataJson = json.decode(savedStringData);
      UserData userDataParesed = UserData.fromJson(savedUserDataJson);

      updateState(userData: userDataParesed);
      getConversations();
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _messagesScrollController.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getSavedData();
    _textController = TextEditingController();
    _messagesScrollController = ScrollController();
    _messagesScrollController.addListener(_onScroll);
    speech = stt.SpeechToText();
    audioPlayer = AudioPlayer();
    _initSpeech();
    audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  void updateState(
      {bool? isGenerating,
      List<Message>? updatedMessages,
      String? newPrompt,
      UserData? userData,
      bool? listening,
      bool? playing,
      bool? audioLoading,
      int? numberOfResponse,
      bool? generatedAtLastOne,
      String? controllerText}) {
    setState(() {
      if (isGenerating != null) isGeneratingResponse = isGenerating;
      if (updatedMessages != null) messages = updatedMessages;
      if (newPrompt != null) prompt = newPrompt;
      if (userData != null) {
        user = userData;
        userId = user.userId;
      }
      if (listening != null) isListening = listening;
      if (playing != null) _isPlaying = playing;
      if (audioLoading != null) isAudioLoading = audioLoading;
      if (numberOfResponse != null) currentNumberOfResponse = numberOfResponse;
      if (generatedAtLastOne != null) hasGenerateAtLastOne = generatedAtLastOne;
      if (controllerText != null) _textController.text = controllerText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: TopBar(
          userId: user.userId,
          changeModel: changeModel,
          availableModels: availableModels,
          currentModel: currentModel,
          startConv: startNewConversation,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor),
      drawer: SideBard(
        name: user.name,
        updateInput: updateInput,
        searchInput: searchInput,
        currentConvId: conversationId,
        startConv: startNewConversation,
        conversations: conversations,
        onTap: (String convId) async {
          final result = await showMenu(
              context: context,
              position: RelativeRect.fromLTRB(50, 400, 100, 100),
              color: Color(0XFF212121),
              items: [
                PopupMenuItem(
                    value: "remove",
                    child: Row(
                      children: [
                        Icon(
                          FeatherIcons.trash,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Remove",
                          style: TextStyle(color: Colors.white70),
                        )
                      ],
                    )),
                PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(FeatherIcons.edit2, color: Colors.white),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Edit title",
                            style: TextStyle(color: Colors.white70))
                      ],
                    )),
              ]);
          if (result == "remove") {
            await removeConversation(convId);
            getConversations();
          } else if (result == "edit") {
            if (!mounted) return;
            showInputDialog(context, changeTitle, convId);
          }
        },
        onOpen: loadConversation,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          messages.isEmpty
              ? Center(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomButton(
                                icon: Icons.code,
                                text: "Create a code",
                                color: Colors.blue,
                                onTap: () {
                                  setState(() {
                                    prompt = startingConversions[0];
                                    _textController.text = prompt;
                                  });
                                }),
                            CustomButton(
                                icon: FeatherIcons.edit2,
                                text: "Make a summary",
                                color: Colors.orange,
                                onTap: () {
                                  setState(() {
                                    prompt = startingConversions[1];
                                    _textController.text = prompt;
                                  });
                                })
                          ],
                        ),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // Centrer les cartes
                          children: [
                            CustomButton(
                                icon: FeatherIcons.bookOpen,
                                text: "Teach me",
                                color: Colors.green,
                                onTap: () {
                                  setState(() {
                                    prompt = startingConversions[2];
                                    _textController.text = prompt;
                                  });
                                }),
                            CustomButton(
                              color: Colors.pink,
                              icon: FontAwesomeIcons.brain,
                              text: "Think deeply about",
                              onTap: () {
                                setState(() {
                                  prompt = startingConversions[3];
                                  _textController.text = prompt;
                                });
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 728),
                  child: Center(
                    child: ListView.builder(
                        controller: _messagesScrollController,
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int i) {
                          return MessageManager(
                            titleFound: conversationTitle,
                            regenerate: regenerateWithoutSocket,
                            key: ValueKey(messages[i]),
                            isExec: isExec,
                            executePythonCode: executePythonCode,
                            isGeneratingResponse: isGeneratingResponse,
                            readResponse: readResponse,
                            messages: messages,
                            index: i,
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                            darkbgColor: darkbgColor,
                          );
                        }),
                  ),
                )),
          Positioned(
              bottom: 0,
              child: AnimatedContainer(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0XFF0D0D0D),
                ),
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Espacement uniforme
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: Colors.grey),
                          child: IconButton(
                            onPressed: () {
                              showCustomSnackBar(
                                  context: context,
                                  message: "Coming soon!",
                                  iconColor: Colors.yellow);
                            },
                            icon: Icon(Icons.image),
                            color: Colors.white,
                          ),
                        )),
                    SizedBox(
                      width: 5,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width *
                              0.6, // Max 60% de largeur
                          maxHeight: 200),
                      child: TextField(
                        cursorColor: Colors.white60,
                        controller: _textController,
                        maxLines: null,
                        onChanged: (value) {
                          setState(() {
                            prompt = value;
                          });
                        },
                        decoration: InputDecoration(
                            hintText: "Message Sauraya",
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                )),
                            enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                )),
                            filled: true,
                            fillColor: Color(0XFF252525),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30)),
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                  width: 0,
                                )),
                            contentPadding: const EdgeInsets.all(12),
                            suffixIcon: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: isListening
                                          ? Colors.blue
                                          : Colors.transparent),
                                  child: IconButton(
                                    onPressed: () {
                                      if (isListening) {
                                        stopListening();
                                      } else {
                                        startListening();
                                      }
                                    },
                                    icon: Icon(Icons.mic),
                                    color: Colors.white,
                                  ),
                                ))),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(50)),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: !isGeneratingResponse
                                  ? prompt.isEmpty
                                      ? Colors.grey
                                      : Colors.white
                                  : Colors.white),
                          child: IconButton(
                            onPressed: () {
                              if (!isGeneratingResponse) {
                                if (prompt.isEmpty) return;
                                FocusScope.of(context).unfocus();
                                log("Sending message $prompt");
                                sendInitialMessage();
                              } else {
                                if (!hasGenerateAtLastOne) {
                                  showCustomSnackBar(
                                      context: context,
                                      message:
                                          "Please wait for the first response",
                                      iconColor: Colors.yellow);
                                  return;
                                }
                                stopGenerationWithoutSocket();
                              }
                            },
                            icon: !isGeneratingResponse
                                ? Icon(Icons.arrow_upward)
                                : Icon(Icons.square_rounded),
                            color: !isGeneratingResponse
                                ? prompt.isEmpty
                                    ? const Color.fromARGB(246, 47, 47, 47)
                                    : const Color.fromARGB(239, 0, 0, 0)
                                : const Color.fromARGB(213, 0, 0, 0),
                          ),
                        )),
                  ],
                ),
              )),
          if (_isPlaying || isAudioLoading)
            Positioned(
                bottom: MediaQuery.of(context).size.height * 0.12,
                right: MediaQuery.of(context).size.width * 0.08,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {
                    log("Audio player clicked");
                    setState(() {
                      if (_isPlaying) {
                        stopPlaying();
                      } else {
                        if (messages.isNotEmpty) {
                          readResponse(messages[messages.length - 1].content);
                        }
                      }
                    });
                  },
                  child: AudioPlayerWidget(
                    isAudioLoading: isAudioLoading,
                    isPlaying: _isPlaying,
                    totalDuration: _duration,
                    currentPosition: _position,
                  ),
                )),

      if (!isBottom && _messagesScrollController.hasClients)    Positioned(
            top:MediaQuery.of(context).size.height * 0.70 ,
            left: MediaQuery.of(context).size.width * 0.45,
          child:
          InkWell(
            onTap: (){
              scrollToBottom(_messagesScrollController);
              setState(() {
                isBottom = true ;
              });
            },
          child: ClipPath(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(50),
                color: Color(0XFF212121)
              ),
              child: Center(
                child: Icon(FeatherIcons.chevronDown, color: Colors.white,),
              ),
            ),
          ),
          ))
        ],
      ),
    );
  }
}
