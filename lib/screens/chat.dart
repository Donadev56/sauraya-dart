import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
import 'package:sauraya/widgets/message_manager.dart';
import 'package:sauraya/widgets/options_button.dart';
import 'package:sauraya/widgets/overlay_message.dart';
import 'package:sauraya/widgets/sidebar_custom.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
final TextEditingController _textController = TextEditingController();
final ScrollController _messagesScrollController = ScrollController();
stt.SpeechToText speech = stt.SpeechToText();
bool _speechEnabled = false;
bool isListening = false;
Duration _duration = Duration.zero;
Duration _position = Duration.zero;
bool _isPlaying = false;
int currentNumberOfResponse = 0;
bool isAudioLoading = false;
bool isExec = false;

String userId = "DonaDev";
String conversationId = "";
String conversationTitle = "";

Conversations conversations = Conversations(conversations: {});

AudioPlayer audioPlayer = AudioPlayer();

late IO.Socket socket;
bool isGeneratingResponse = false;

class _ChatScreenState extends State<ChatScreen> {
  void stopSocketGeneration() async {
    try {
      socket.emit(SocketEvents.stopGeneration);
      log("Generation stopped");
      setState(() {
        isGeneratingResponse = false;
      });
    } catch (e) {
      log("error during stop socket generation $e");
      showCustomSnackBar(
          context: context, message: "error during stop socket generation $e");
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
      SecureStorageService service = SecureStorageService();

      String keyToUse = "";
      final savedkey = await service.loadPrivateKey(userId);

      if (savedkey != null) {
        keyToUse = savedkey;
      } else {
        keyToUse = await generateSecureKey(32);
        await service.savePrivateKey(keyToUse, userId);
      }

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
      SecureStorageService service = SecureStorageService();

      String keyToUse = "";
      final savedkey = await service.loadPrivateKey(userId);

      if (savedkey != null) {
        keyToUse = savedkey;
      } else {
        keyToUse = await generateSecureKey(32);
        await service.savePrivateKey(keyToUse, userId);
      }

      final savedConversations =
          await manager.getSavedConversations(userId, keyToUse);
      if (savedConversations != null) {
        setState(() {
          conversations.conversations.addAll(savedConversations.conversations);

          log("Conversations initialized");
        });
        log("Conversations ${conversations.toJson().toString()}");
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
          conversationId = convId;
          conversationTitle = conv.title;
          messages = conv.messages;
        }
      });
    } catch (e) {
      log("Error during get conversations $e");
      showCustomSnackBar(
          context: context, message: "Error during get conversations ");
    }
  }

  Future<void> executePythonCode(String codeToExecute) async {
    try {
      final result = await getOutput(codeToExecute);

      showOutPut(context, result, isExec);
    } catch (e) {
      log("An error occured $e");
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

  void startListening() async {
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
        return;
      }
      Message sysMessage = Message(role: "system", content: systemMessage);

      Messages lastMessages = [...messages];

      if (lastMessages.isEmpty) {
        lastMessages.add(sysMessage);
      }
      Message newMessage = Message(role: "user", content: prompt);
      lastMessages.add(newMessage);
      log("New message added");

      setState(() {
        messages = lastMessages;
        prompt = "";
        isGeneratingResponse = true;

        _textController.clear();

        if (messages.length > 2) {
          _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      OllamaChatRequest newChatRequest = OllamaChatRequest(
          messages: lastMessages, model: "llama3.2:1b", stream: true);
      socket.emit(SocketEvents.chat, newChatRequest);
      log("Prmpts sent to the server");
    } catch (e) {
      logError(e.toString());
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
      showCustomSnackBar(
          context: context,
          message: "An error occured $e",
          icon: Icons.error,
          iconColor: Colors.pinkAccent);
    }
  }

  void connectToSocket() {
    try {
      log("Connecting to the server...");
      final server = "http://46.202.175.219:7000";
      IO.Socket io = IO.io(
          server, IO.OptionBuilder().setTransports(["websocket"]).build());
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

        log("is First : $isFirst , Text : $textResponse , Done : $done , message : $message");

        if (isFirst) {
          log("First Message received ");

          setState(() {
            Message newMessage =
                Message(role: "assistant", content: textResponse);
            messages = [...messages, newMessage];
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
          log("New message: $newText , last message : ${lastMessage.content}");
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
    _textController.dispose();
    _messagesScrollController.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    connectToSocket();

    _initSpeech();
    getConversations();
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
      appBar:
          TopBar(primaryColor: primaryColor, secondaryColor: secondaryColor),
      drawer: SideBard(
        conversations: conversations,
        onTap: () async {
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
        },
        onOpen: () {
          log("opening conversation");
        },
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
                                    _textController.text =
                                        "Generate a python code to show me your programming skills, choose the type of code you want.";
                                    prompt =
                                        "Generate a python code to show me your programming skills, choose the type of code you want.";
                                  });
                                }),
                            CustomButton(
                                icon: FeatherIcons.edit2,
                                text: "Make a summary",
                                color: Colors.orange,
                                onTap: () {
                                  log("Summary element clicked");
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
                                onTap: () {}),
                            CustomButton(
                              color: Colors.pink,
                              icon: FontAwesomeIcons.brain,
                              text: "Think deeply about",
                              onTap: () {
                                log("Think element cliked");
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
                        padding: const EdgeInsets.all(10),
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int i) {
                          return MessageManager(
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
                              log("adding ");
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
