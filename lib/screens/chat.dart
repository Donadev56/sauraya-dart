import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/types/enums.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/remove_markdown.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/audio_player.dart';
import 'package:sauraya/widgets/custom_app_bar.dart';
import 'package:sauraya/widgets/message_manager.dart';
import 'package:sauraya/widgets/options_button.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

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

      final lastMessages = [...messages];
      Message newMessage = Message(role: "user", content: prompt);
      lastMessages.add(newMessage);
      log("New message added");
      setState(() {
        messages = lastMessages;
        prompt = "";
        isGeneratingResponse = true;

        _textController.clear();

        if (messages.length > 1) {
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
      final server = "http://185.97.144.209:7000";
      IO.Socket io = IO.io(
          server, IO.OptionBuilder().setTransports(["websocket"]).build());
      setState(() {
        socket = io;
      });
      io.onConnect((_) {
        log("Connected to the server $server");
      });
      io.on(SocketEvents.partialResponse, (data) {
        log("New data received $data");
        
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
               currentNumberOfResponse ++;

             _messagesScrollController.animateTo(
            _messagesScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          });
          
          return;
        }
        if (currentNumberOfResponse == 2){
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
          currentNumberOfResponse ++;
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
                                onTap: () {
                                  log("Teach element clicked");
                                }),
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
                  child: ListView.builder(
                    
                      controller: _messagesScrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int i) {
                        return MessageManager(
                          readResponse: readResponse,
                          messages: messages,
                          index: i,
                          primaryColor: primaryColor,
                          secondaryColor: secondaryColor,
                          darkbgColor: darkbgColor,
                        );
                      }),
                ),
          Positioned(
              bottom: 0,
              child: AnimatedContainer(
                decoration: BoxDecoration(
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
