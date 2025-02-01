import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
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
import 'package:youtube_player_embed/controller/video_controller.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
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
  bool isBottom = false;
  bool isWebSearch = false;
  bool _isKeyboardOpen = false;
  String pdfText = "";
  bool canPdfCardClose = true;
  bool isPdfLoading = false;

  String currentModel = availableModels[2];

  Conversations conversations = Conversations(conversations: {});

  late AudioPlayer audioPlayer;

  bool isGeneratingResponse = false;

  Map<String, VideoController> controllers = {};

  bool isVideoPlaying = false;

  final FocusNode _focusNode = FocusNode();
  bool isInputFocus = false;

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
        isBottom = true;
      });
    } else {
      setState(() {
        isBottom = false;
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
          Messages newMessages = [];

          for (int i = 0; i < conv.messages.length; i++) {
            final msg = conv.messages[i];
            String? id = msg.msgId;

            if (msg.msgId == null) {
              id = generateUUID();
            } else {
              id = msg.msgId;
            }
            Message newMessage = Message(
                pdfContent: msg.pdfContent,
                role: msg.role,
                content: msg.content,
                msgId: id,
                videos: msg.videos);
            newMessages.add(newMessage);
          }
          messages = newMessages;
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

  void initController(VideoController controller, String id) {
    setState(() {
      controllers[id] = controller;
    });
  }

  Future<void> sendInitialMessage() async {
    try {
      if (!canPdfCardClose) {
       setState(() {
        canPdfCardClose = true ;
      });
      }
     
      Message sysMessage = Message(
          role: "system",
          content:
              "$systemMessage + . the current name of the user you are talking with is ${user.name}, So know what you can do is reply to messages , You can call him by his name .  ");

      Messages lastMessages = [...messages];
      Message newMessage =
          Message(role: "user", content:  prompt , msgId: generateUUID(), pdfContent: pdfText.isNotEmpty ? pdfText : null);

      if (lastMessages.isEmpty) {
        lastMessages.add(sysMessage);
        findTitle(newMessage.content);
      }

      lastMessages.add(newMessage);

      updateState(
          updatedMessages: lastMessages, newPrompt: "", controllerText: "");

      await chat(lastMessages);
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
      Message updatedMessage ;
      
       
      setState(() {
        Message thinkingLoader =
            Message(role: "thinkingLoader", content: "Thinking");
        messages = [...lastMessages, thinkingLoader];
        prompt = "";

        
        isGeneratingResponse = true;

        _textController.clear();

        scrollToBottom(_messagesScrollController);
      });
      // check the existance of the pdf and add it 
     final userMessage = lastMessages[lastMessages.length - 1];
     log("User message : $userMessage");
    
     if (pdfText.isNotEmpty) {
       updatedMessage = Message(
           role: "user",
           content: pdfText + userMessage.content,
           msgId: userMessage.msgId ) ;
           log("Updated message ${updatedMessage.toJson().toString()}");
       
       } else {
        logError("PDF is empty");
       updatedMessage = userMessage;
     } 

     lastMessages[lastMessages.length - 1] = updatedMessage;

      OllamaChatRequest newChatRequest = OllamaChatRequest(
          messages: lastMessages,
          model: currentModel,
          isWebSearch: isWebSearch,
          stream: true,
          token: user.token);

      HttpClientRequest request;
      log("Current model : $currentModel");
      String url;
      if (currentModel.contains("deepseek-chat")) {
        url = "https://chat.sauraya.com/chat/message/dSeek";
      } else if (currentModel.contains("qw")) {
        url = "https://chat.sauraya.com/chat/message/qwen";
      } else {
        url = "https://chat.sauraya.com/chat/message";
      }
      request = await client.postUrl(Uri.parse(url));

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
                log("Data $data");
                final isFirst = data["isFirst"];
                final response = data["response"];
                final message = response["message"];
                final done = response["done"];
                final textResponse = message["content"];
                final msgId = message["msgId"];

                if (isFirst == true) {
                  hasGenerateAtLastOne = true;

                  setState(() {
                    Message newMessage = Message(
                        pdfContent: pdfText.isEmpty ? null : pdfText,
                        role: "assistant",
                        content: textResponse,
                        msgId: msgId);
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
                int index =
                    lastMessages.indexWhere((msg) => msg.msgId == msgId);

                if (index != -1) {
                  String newText = lastMessages[index].content + textResponse;

                  Message newMessage = Message(
                      msgId: lastMessages[index].msgId,
                      content: newText,
                      role: "assistant");
                  setState(() {
                    lastMessages[index] = newMessage;
                    messages = lastMessages;
                    currentNumberOfResponse++;
                  });

                  if (done) {
                    updateState(isGenerating: false, numberOfResponse: 0);
                    final regex = RegExp(
                      r"(https?:\/\/(www\.)?(youtube\.com|youtu\.be)\/[^\s\)]+)",
                      caseSensitive: false,
                    );
                    final matches = regex.allMatches(newText);
                    final videos =
                        matches.map((match) => match.group(0) ?? "").toList();

                    Message newMessageWithVideos = Message(
                        pdfContent: pdfText.isEmpty ? null : pdfText,
                        role: 'assistant',
                        content: newText,
                        videos: videos,
                        msgId: generateUUID());


                    lastMessages[index] = newMessageWithVideos;
                    setState(() {
                      messages = lastMessages;
                      if (pdfText.isNotEmpty) {
                        pdfText = "";
                      }
                    });

                    scrollToBottom(_messagesScrollController);
                    updateMessages();
                  }
                } else {
                  throw ErrorDescription("The Index is not a valid index");
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

  void stopPlayingVideo(String id) {
    final controller = controllers[id];
    if (controller != null) {
      controller.pauseVideo();
      setState(() {
        isVideoPlaying = false;
      });
    }
  }

  void playVideo(String id) {
    log("Playin video of id :$id");
    final controller = controllers[id];
    if (controller != null) {
      controller.playVideo();
      setState(() {
        isVideoPlaying = true;
      });
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

  void changeIsplayingState(bool isplaying) {
    setState(() {
      isVideoPlaying = isplaying;
    });
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

  void takeAction() {
    if (!isGeneratingResponse) {
      if (prompt.isEmpty && pdfText.isEmpty) return;
      FocusScope.of(context).unfocus();
      log("Sending message $prompt");
      sendInitialMessage();
    } else {
      if (!hasGenerateAtLastOne) {
        showCustomSnackBar(
            context: context,
            message: "Please wait for the first response",
            iconColor: Colors.yellow);
        return;
      }
      stopGenerationWithoutSocket();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _messagesScrollController.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
    _focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = View.of(context).viewInsets.bottom;
    final isOpen = bottomInset > 0;

    if (_isKeyboardOpen != isOpen) {
      setState(() {
        _isKeyboardOpen = isOpen;
      });
    }
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
    WidgetsBinding.instance.addObserver(this);
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
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          isInputFocus = true;
        });
      } else {
        setState(() {
          isInputFocus = false;
        });
      }
    });
    audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  Future<void> getDocuments() async {
    try {
      setState(() {
        isPdfLoading = true;
      });
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["pdf"],
        allowMultiple: false,
      );
      if (result != null) {
        final path = result.files.single.path;
        if (path != null) {
          setState(() {
            canPdfCardClose = false;
          });
          String text = await ReadPdfText.getPDFtext(path);
          setState(() {
            pdfText =
                "This is the content of a pdf, analyze it and tell me what you understand about this content : \n $text";
            isPdfLoading = false;
          });
          log(pdfText);
        } else {
          throw Exception("The path was not found");
        }
      } else {
        throw Exception("The file is not deifined");
      }
    } catch (e) {
      logError(e.toString());
      if (!mounted) return;
      setState(() {
        canPdfCardClose = false;
        pdfText = "";
        isPdfLoading = false;
      });
      showCustomSnackBar(
          context: context,
          message: "Error reading PDF",
          icon: Icons.error,
          iconColor: Colors.pinkAccent);
    }
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
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: TopBar(
          spaceName: "Sauraya Ai",
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
        // TOP //
        children: [
          messages.isEmpty
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              // Centrer les cartes
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              // Centrer les cartes
                              children: [
                                CustomButton(
                                    icon: FeatherIcons.globe,
                                    text: "Search...",
                                    color: Colors.greenAccent,
                                    onTap: () {
                                      setState(() {
                                        prompt = startingConversions[4];
                                        _textController.text = prompt;
                                      });
                                    }),
                                CustomButton(
                                  color: Colors.white,
                                  icon: FontAwesomeIcons.newspaper,
                                  text: "News...",
                                  onTap: () {
                                    setState(() {
                                      prompt = startingConversions[5];
                                      _textController.text = prompt;
                                    });
                                  },
                                ),
                                CustomButton(
                                  color: Colors.orangeAccent,
                                  icon: FontAwesomeIcons.image,
                                  text: "Images..",
                                  onTap: () {
                                    setState(() {
                                      prompt = startingConversions[6];
                                      _textController.text = prompt;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              // MESSAGES CENTER //
              : Center(
                  child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 728),
                  child: Center(
                    child: ListView.builder(
                        controller: _messagesScrollController,
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int i) {
                          return MessageManager(
                            isPlayingVideo: isVideoPlaying,
                            stopPlayingVideo: stopPlayingVideo,
                            playVideo: playVideo,
                            videoPlayingState: changeIsplayingState,
                            initController: initController,
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

          // INPUT SPACE //
          Positioned(
              bottom: 0,
              child: AnimatedContainer(
                  duration: Duration(microseconds: 3000),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: AnimatedContainer(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color.fromARGB(104, 13, 13, 13),
                              ),
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          30, 158, 158, 158),
                                      width: 2.5),
                                  borderRadius: BorderRadius.circular(30),
                                  color: Color(0XFF171717),
                                ),
                                padding: EdgeInsets.only(
                                    top: 2,
                                    bottom: !_isKeyboardOpen ? 2 : 4,
                                    left: 12,
                                    right: 12),
                                child: AnimatedContainer(
                                  duration: Duration(microseconds: 1000),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (!canPdfCardClose)
                                        SizedBox(
                                          height: 10,
                                        ),
                                      if (!canPdfCardClose)
                                        SizedBox(
                                          width: 60,
                                          height: 60,
                                          child: Container(
                                              decoration: BoxDecoration(
                                                  color: Color(0XFF212121),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      pdfText = "";
                                                      canPdfCardClose = true;
                                                    });
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  child: Center(
                                                    child: !isPdfLoading
                                                        ? Text(
                                                            "PDF",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          )
                                                        : CircularProgressIndicator(
                                                            color: Colors.white,
                                                          ),
                                                  ),
                                                ),
                                              )),
                                        ),
                                      // INPUT ELEMENT SPACE //
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                            maxWidth: width *
                                                0.85, // Max 60% de largeur
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
                                          focusNode: _focusNode,
                                          decoration: InputDecoration(
                                            suffixIcon: !isInputFocus
                                                ? IconButton(
                                                    onPressed: takeAction,
                                                    icon: Icon(
                                                      isGeneratingResponse
                                                          ? Icons.square_rounded
                                                          : Icons.arrow_upward,
                                                      color: Colors.white,
                                                    ))
                                                : null,
                                            hintText: "Ask anything",
                                            hintStyle: TextStyle(
                                              color: Colors.white70,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(30)),
                                                borderSide: BorderSide(
                                                  color: Colors.transparent,
                                                  width: 0,
                                                )),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(30)),
                                                borderSide: BorderSide(
                                                  color: Colors.transparent,
                                                  width: 0,
                                                )),
                                            filled: false,
                                            fillColor: Color(0XFF252525),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(30)),
                                                borderSide: BorderSide(
                                                  color: Colors.transparent,
                                                  width: 0,
                                                )),
                                            contentPadding:
                                                const EdgeInsets.all(12),
                                          ),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),

                                      // BOTTOM INPUT SPACE //
                                      _isKeyboardOpen || prompt.isNotEmpty
                                          ? ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  minWidth: width * 0.85),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween, // Espacement uniforme
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,

                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                          decoration:
                                                              BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              50),
                                                                  border: Border
                                                                      .all(
                                                                    color: isWebSearch
                                                                        ? Colors
                                                                            .blue
                                                                        : Colors
                                                                            .transparent,
                                                                    width: 0.5,
                                                                  )),
                                                          child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(Radius
                                                                          .circular(
                                                                              50)),
                                                              child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child:
                                                                      InkWell(
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        isWebSearch =
                                                                            !isWebSearch;
                                                                      });
                                                                    },
                                                                    child:
                                                                        AnimatedContainer(
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              500),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: Colors
                                                                            .blue,
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          AnimatedContainer(
                                                                              padding: const EdgeInsets.all(5),
                                                                              duration: const Duration(milliseconds: 200),
                                                                              width: 90,
                                                                              decoration: BoxDecoration(color: isWebSearch ? const Color.fromARGB(255, 8, 32, 52) : Color(0XFF212121)),
                                                                              child: Row(
                                                                                children: [
                                                                                  Icon(
                                                                                    FeatherIcons.globe,
                                                                                    color: isWebSearch ? Colors.blue : Colors.white,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 2,
                                                                                  ),
                                                                                  Text(
                                                                                    "Search",
                                                                                    style: GoogleFonts.exo2(color: !isWebSearch ? Colors.white : Colors.blue),
                                                                                  )
                                                                                ],
                                                                              )),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  )))),
                                                      PopupMenuButton(
                                                        color:
                                                            Color(0XFF212121),
                                                        icon: Icon(Icons
                                                            .folder_copy_outlined),
                                                        iconColor:
                                                            secondaryColor,
                                                        onSelected:
                                                            (value) async {
                                                          log(value);

                                                          if (value != 'pdf') {
                                                            showCustomSnackBar(
                                                                context:
                                                                    context,
                                                                message:
                                                                    "Not available yet",
                                                                iconColor: Colors
                                                                    .pinkAccent);
                                                          }
                                                        },
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context) =>
                                                                [
                                                          PopupMenuItem(
                                                            onTap: () {
                                                              log("onTap");
                                                              getDocuments();
                                                            },
                                                            value: 'pdf',
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .picture_as_pdf,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Text(
                                                                  'Pdf file',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'image',
                                                            onTap: () {
                                                              showCustomSnackBar(
                                                                  context:
                                                                      context,
                                                                  message:
                                                                      "Not available yet",
                                                                  iconColor: Colors
                                                                      .pinkAccent);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.image,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          127,
                                                                          255,
                                                                          255,
                                                                          255),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Text(
                                                                  'Image',
                                                                  style: TextStyle(
                                                                      color: Color.fromARGB(
                                                                          127,
                                                                          255,
                                                                          255,
                                                                          255)),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'video',
                                                            onTap: () {
                                                              showCustomSnackBar(
                                                                  context:
                                                                      context,
                                                                  message:
                                                                      "Not available yet",
                                                                  iconColor: Colors
                                                                      .pinkAccent);
                                                            },
                                                            child: Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .video_file,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          127,
                                                                          255,
                                                                          255,
                                                                          255),
                                                                ),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Text(
                                                                  'Video',
                                                                  style: TextStyle(
                                                                      color: Color.fromARGB(
                                                                          127,
                                                                          255,
                                                                          255,
                                                                          255)),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 5,
                                                  ),

                                                  // RIGHT INPUT ICONS SPACE //
                                                  Row(
                                                    children: [
                                                      ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                          child: Container(
                                                            width: 38,
                                                            height: 38,
                                                            decoration: BoxDecoration(
                                                                color: isListening
                                                                    ? Colors
                                                                        .blue
                                                                    : Colors
                                                                        .transparent),
                                                            child: IconButton(
                                                              onPressed: () {
                                                                if (isListening) {
                                                                  stopListening();
                                                                } else {
                                                                  startListening();
                                                                }
                                                              },
                                                              icon: Icon(
                                                                  Icons.mic),
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )),
                                                      SizedBox(
                                                        width: 5,
                                                      ),
                                                      ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          50)),
                                                          child:
                                                              AnimatedContainer(
                                                            duration: Duration(
                                                                milliseconds:
                                                                    200),
                                                            width: 38,
                                                            height: 38,
                                                            decoration: BoxDecoration(
                                                                color: !isGeneratingResponse
                                                                    ? prompt.isNotEmpty || pdfText.isNotEmpty 
                                                                    
                                                                        ? Colors.white
                                                                        : Colors.grey
                                                                    : Colors.white),
                                                            child: IconButton(
                                                              onPressed:
                                                                  takeAction,
                                                              icon:
                                                                  !isGeneratingResponse
                                                                      ? Icon(
                                                                          Icons
                                                                              .arrow_upward,
                                                                          size:
                                                                              20,
                                                                        )
                                                                      : Icon(Icons
                                                                          .square_rounded),
                                                              color:
                                                                  !isGeneratingResponse
                                                                      ? prompt
                                                                              .isEmpty
                                                                          ? const Color
                                                                              .fromARGB(
                                                                              246,
                                                                              47,
                                                                              47,
                                                                              47)
                                                                          : const Color
                                                                              .fromARGB(
                                                                              239,
                                                                              0,
                                                                              0,
                                                                              0)
                                                                      : const Color
                                                                          .fromARGB(
                                                                          213,
                                                                          0,
                                                                          0,
                                                                          0),
                                                            ),
                                                          ))
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ),
                              )))))),

          // Audio Speaker space //
          if (_isPlaying || isAudioLoading)
            Positioned(
                bottom: MediaQuery.of(context).size.height * 0.14,
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

          if (!isBottom && _messagesScrollController.hasClients)
            Positioned(
                top: MediaQuery.of(context).size.height * 0.65,
                left: MediaQuery.of(context).size.width * 0.45,
                child: InkWell(
                  onTap: () {
                    scrollToBottom(_messagesScrollController);
                    setState(() {
                      isBottom = true;
                    });
                  },
                  child: ClipPath(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Color(0XFF212121)),
                      child: Center(
                        child: Icon(
                          FeatherIcons.chevronDown,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ))
        ],
      ),
    );
  }
}
