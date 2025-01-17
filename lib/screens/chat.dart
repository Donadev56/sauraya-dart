import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/service/crypto.dart';
import 'package:sauraya/service/secure_storage.dart';
import 'package:sauraya/types/enums.dart';
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
import 'package:socket_io_client/socket_io_client.dart' as client_socket;
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

Color primaryColor = Color(0xFF0D0D0D);
Color secondaryColor = Colors.white;
Color darkbgColor = Color(0XFF212121);
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

String userId = user.userId;
String conversationId = "";
String conversationTitle = "";
String searchInput = "";

List<String> availableModels = [
  "llama3.2:1b",
  "llama3.2",
];
String currentModel = availableModels[1];

Conversations conversations = Conversations(conversations: {});

late AudioPlayer audioPlayer;

late client_socket.Socket socket;
bool isGeneratingResponse = false;

class _ChatScreenState extends State<ChatScreen> {
  void stopSocketGeneration() async {
    try {
      socket.emit(SocketEvents.stopGeneration);

      log("Socket disconnected");
      log("Generation stopped");
      setState(() {
        isGeneratingResponse = false;
        final lastMessages = [...messages];
        lastMessages.removeWhere((msg) => msg.role == "thinkingLoader");

        messages = [...lastMessages];
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

  Future<void> regenerate(int msgIndex) async {
    try {
      if (messages.isEmpty) {
        return;
      }

      log("Regenerating response $msgIndex");
      Messages lastMessages = [...messages];
      lastMessages.removeRange(msgIndex, lastMessages.length);
      await transferMessage(lastMessages);
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
        setState(() async {
          conversations.conversations[convId] = newConversation;
          if (convId == conversationId) {
            conversationTitle = newTitle;
          }
          final key = await getKey();
          Conversations convsToSave =
              Conversations(conversations: conversations.conversations);

          await manager.saveConversations(key, convsToSave, userId);
        });
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

      String keyToUse = await getKey();

      final messageToUpdate = [...messages];
      String convId;
      String firstMessageText = messageToUpdate[0].content;
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

  Future<void> getConversations() async {
    try {
      ConversationManager manager = ConversationManager();

      String keyToUse = await getKey();

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
      setState(() {
        conversationId = "";
        conversationTitle = "";
        messages = [];
        isGeneratingResponse = false;
        isExec = false;

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

  Future<void> removeConversation(String convId) async {
    try {
      setState(() async {
        final lastConvs = conversations;
        final removedConv = lastConvs.conversations.remove(convId);
        if (convId == conversationId) {
          startNewConversation();
        }
        if (removedConv != null) {
          conversations = lastConvs;
          ConversationManager manager = ConversationManager();

          final keyToUse = await getKey();

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

  Future<String> getKey() async {
    try {
      SecureStorageService service = SecureStorageService();

      String keyToUse = "";
      final savedkey = await service.loadPrivateKey(user.userId);

      if (savedkey != null) {
        keyToUse = savedkey;
      } else {
        keyToUse = await generateSecureKey(32);
        await service.savePrivateKey(keyToUse, user.userId);
      }
      return keyToUse;
    } catch (e) {
      log("An error occured $e");
      return "";
    }
  }

  void readResponse(String markdown) async {
    try {
      setState(() {
        isAudioLoading = true;
      });

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
        setState(() {
          isAudioLoading = false;
        });
        if (!mounted) return;
        showCustomSnackBar(
            context: context,
            message: "Error converting text",
            iconColor: Colors.pinkAccent);
        return;
      }
    } catch (e) {
      log(e as String);
      setState(() {
        isAudioLoading = false;
      });
      if (!mounted) return;
      showCustomSnackBar(
          context: context, message: "error during read response");
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
      setState(() {
        isAudioLoading = false;
      });
      if (!mounted) return;
      showCustomSnackBar(
          context: context,
          message: "Error playing audio: $e",
          iconColor: Colors.pinkAccent);
    }
  }

  void stopPlaying() async {
    try {
      audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
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
    setState(() {
      isListening = false;
    });
  }

  void sendMessage() async {
    try {
      if (prompt.isEmpty) return;
      if (!socket.connected) {
        logError("The server is not connected");

        showCustomSnackBar(
            context: context,
            message: "Not connected to the server",
            iconColor: Colors.pinkAccent);
        return;
      }
      Message sysMessage = Message(
          role: "system",
          content:
              "$systemMessage + . the current name of the user you are talking with is ${user.name}, his email ${user.address} , So know what you can do is reply to messages , you can call him by his name only use or remind him his email address in emergency case cause it is private .  ");

      Messages lastMessages = [...messages];

      if (lastMessages.isEmpty) {
        lastMessages.add(sysMessage);
      }
      Message newMessage = Message(role: "user", content: prompt);

      lastMessages.add(newMessage);

      log("New message added");

      await transferMessage(lastMessages);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> transferMessage(Messages lastMessages) async {
    try {
      setState(() {
        Message thinkingLoader =
            Message(role: "thinkingLoader", content: "Thinking");
        messages = [...lastMessages, thinkingLoader];
        prompt = "";
        isGeneratingResponse = true;

        _textController.clear();

        if (messages.length > 3) {
          _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      OllamaChatRequest newChatRequest = OllamaChatRequest(
          messages: lastMessages, model: currentModel, stream: true);
      socket.emit(SocketEvents.chat, newChatRequest);
      log("message sent to the server");
    } catch (e) {
      logError("An error occurred while sending the message $e");
    }
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
            {
              setState(() {
                isListening = false;
              })
            }
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
      UserData UserDataParesed = UserData.fromJson(savedUserDataJson);
      setState(() {
        user = UserDataParesed;
      });
      getConversations();

      connectToSocket();
    } catch (e) {
      logError(e.toString());
    }
  }

  void connectToSocket() {
    try {
      log("Connecting to the server...");
      final server = "https://chat.sauraya.com";
      client_socket.Socket io = client_socket.io(
        server,
        client_socket.OptionBuilder().setAuth(
            {'token': user.token}).setTransports(["websocket"]).build(),
      );

      setState(() {
        socket = io;
      });

      io.onConnect((_) {
        log("Connected to the server $server");
      });
      io.on(SocketEvents.titleFound, (newTitle) {
        log("New title: $newTitle");
        String foundTitle = newTitle["title"];
        if (foundTitle.isNotEmpty) {
          setState(() {
            conversationTitle = foundTitle;
          });
        }
      });
      io.on(SocketEvents.partialResponse, (data) {
        io.on(SocketEvents.error, (error) {
          logError("Error received $error");
          showCustomSnackBar(
              context: context,
              message: "An error occured in server Side $error",
              backgroundColor: Colors.pinkAccent,
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
        });

        final isFirst = data["isFirst"] as bool? ?? false;
        final response = data["response"] as Map<String, dynamic>?;

        if (response == null) {
          logError("No response in the data received");
          return;
        }

        final message = response["message"] as Map<String, dynamic>?;

        if (message == null) {
          logError("No message in the response data");
          return;
        }

        final done = response["done"] as bool? ?? false;
        final textResponse = message["content"] as String? ?? "";

        if (isFirst) {
          log("First Message received ");

          setState(() {
            Message newMessage =
                Message(role: "assistant", content: textResponse);
            final lastMessages = [...messages];
            lastMessages.removeWhere((msg) => msg.role == "thinkingLoader");

            messages = [...lastMessages, newMessage];
            currentNumberOfResponse++;

            _messagesScrollController.animateTo(
              _messagesScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });

          return;
        }
        if (currentNumberOfResponse == 2) {
          _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        Messages lastMessages = [...messages];
        Message lastMessage = lastMessages[lastMessages.length - 1];
        String newText = lastMessage.content + textResponse;
        setState(() {
          Message newMessage = Message(content: newText, role: "assistant");
          lastMessages[messages.length - 1] = newMessage;
          currentNumberOfResponse++;
          setState(() {
            messages = lastMessages;
          });
        });

        if (done) {
          setState(() {
            isGeneratingResponse = false;
            _messagesScrollController.animateTo(
              _messagesScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            currentNumberOfResponse = 0;
          });
          readResponse(newText);
          updateMessages();
        }
      });
      io.onDisconnect((_) {
        logError("Disconnect from the server $server");
      });
    } catch (e) {
      setState(() {
        isGeneratingResponse = false;
        currentNumberOfResponse = 0;
      });
      logError(e.toString());
      showCustomSnackBar(
          context: context,
          message: "An error occured in server Side $e",
          backgroundColor: Colors.pinkAccent,
          icon: Icons.error,
          iconColor: Colors.pinkAccent);
    }
  }

  @override
  void dispose() {
    socket.dispose();
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
                                    prompt =
                                        "Generate a python code to show me your programming skills, choose the type of code you want.";
                                    _textController.text = prompt;
                                  });
                                }),
                            CustomButton(
                                icon: FeatherIcons.edit2,
                                text: "Make a summary",
                                color: Colors.orange,
                                onTap: () {
                                  setState(() {
                                    prompt =
                                        "Summarize the lifestyle a person should adopt to be successful in life.";
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
                                    prompt =
                                        "Teach me how to do data analysis as a data analyst and the tools needed to use it";
                                    _textController.text = prompt;
                                  });
                                }),
                            CustomButton(
                              color: Colors.pink,
                              icon: FontAwesomeIcons.brain,
                              text: "Think deeply about",
                              onTap: () {
                                setState(() {
                                  prompt =
                                      "think of something I probably don't know that you're teaching me today";
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
                            regenerate: regenerate,
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
                                sendMessage();
                              } else {
                                stopSocketGeneration();
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
                ))
        ],
      ),
    );
  }
}
