import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/service/data_saver.dart';
import 'package:sauraya/service/secure_storage.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/html.dart';
import 'package:sauraya/utils/id_generator.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/custom_app_bar.dart';
import 'package:sauraya/utils/constants.dart';
import 'package:sauraya/widgets/diaolog.dart';
import 'package:sauraya/widgets/sidebar_custom_wb.dart';
import 'package:sauraya/widgets/web_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebisteCreator extends StatefulWidget {
  const WebisteCreator({super.key});

  @override
  State<WebisteCreator> createState() => _WebisteCreatorState();
}

class _WebisteCreatorState extends State<WebisteCreator> {
  String prompt = "";
  Messages messages = [];
  late TextEditingController _textController;
  late ScrollController _messagesScrollController;

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
  String currentHtml = html;
  String titleOfTop = "Website Builder";

  String currentModel = availableModels[2];

  Conversations conversations = Conversations(conversations: {});

  late AudioPlayer audioPlayer;

  bool isGeneratingResponse = false;

  bool isVideoPlaying = false;

  final FocusNode _focusNode = FocusNode();
  bool isInputFocus = false;
  String suffix = "-web-builder";

  Future<void> sendInitialMessage() async {
    try {
      Message sysMessage = Message(role: "system", content: codeSystemPrompt);

      Messages lastMessages = [...messages];
      Message newMessage =
          Message(role: "user", content: prompt, msgId: generateUUID());

      if (lastMessages.isEmpty) {
        lastMessages.add(sysMessage);
        findTitle(newMessage.content);
      }

      lastMessages.add(newMessage);

      setState(() {
        messages = lastMessages;
        prompt = "";
        _textController.text = "";
      });

      await generate(lastMessages);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> generate(Messages lastMessages) async {
    try {
      final dio = Dio();

      if (!hasGenerateAtLastOne) {
        logError(
            "Can't send a new message when the last message is not generated");
        return;
      }

      setState(() {
        Message thinkingLoader =
            Message(role: "thinkingLoader", content: "Thinking");
        messages = [...lastMessages, thinkingLoader];
        prompt = "";
        isGeneratingResponse = true;
        hasGenerateAtLastOne = false;
        webController.loadHtmlString(loaderHtml);

        _textController.clear();

        scrollToBottom(_messagesScrollController);
      });
      Messages newMessages = [];
      for (int i = 0; i < lastMessages.length; i++) {
        final msg = lastMessages[i];

        Message newMessage = Message(
          role: msg.role,
          content: msg.content,
        );
        newMessages.add(newMessage);
      }
      if (newMessages.length > 6) {
        newMessages = newMessages.sublist(newMessages.length - 6);
      Message sysMessage = Message(role: "system", content: codeSystemPrompt);

        newMessages.insert(0,sysMessage );
      } else {
        lastMessages = newMessages;
      }
      OllamaChatRequest newChatRequest = OllamaChatRequest(
          messages: lastMessages,
          model: currentModel,
          isWebSearch: isWebSearch,
          stream: true,
          token: user.token);

      final response = await dio.post(
          "https://chat.sauraya.com/chat/generate_code",
          data: newChatRequest.toJson());

      if (response.statusCode == 200) {
        final data = response.data;
        final result = data["response"];
        final code = result["code_html"];
        final desc = result["description"];

        setState(() {
          isGeneratingResponse = false;
          hasGenerateAtLastOne = true;
          Message newMessage = Message(
              code: code,
              role: "assistant",
              content: desc,
              msgId: generateUUID());
          final msgs = [...messages];
          msgs.removeWhere((msg) => msg.role == "thinkingLoader");

          messages = [...msgs, newMessage];
          updateMessages();
        });
        webController.loadHtmlString(code);
        final pageTitle = conversationTitle;
        setState(() {
          titleOfTop = pageTitle.substring(0, 15);
          webController.loadHtmlString(code);
        });
        scrollToBottom(_messagesScrollController);
      }
    } catch (e) {
      logError(e.toString());
      webController.loadHtmlString(codeError);
      setState(() {
        isGeneratingResponse = false;
        hasGenerateAtLastOne = true;

        final lastMessages = [...messages];
        lastMessages.removeWhere((msg) => msg.role == "thinkingLoader");

        messages = [...lastMessages];
      });
      showCustomSnackBar(
          context: context,
          message: "Error while generating response",
          iconColor: Colors.red);
    }
  }

  void changePrompt (String text) {
    setState(() {
      prompt = text;
      _textController.text = prompt;
    });
  }

  void takeAction() {
    if (!isGeneratingResponse) {
      if (prompt.isEmpty) return;
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

  Future<void> findTitle(String text) async {
    try {
      final dio = Dio();
      log("Finding title for $text");
      final newReq = {"token": user.token, "text": text};
      final response = await dio.post(
        "https://chat.sauraya.com/chat/title",
        data: newReq,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.data.toString());

        log("Title found $data");
        setState(() {
          conversationTitle = data;
        });
      }
    } catch (e) {
      logError(e.toString());
    }
  }

  WebViewController webController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(html);

  get http => null;

  @override
  void dispose() {
    _textController.dispose();
    _messagesScrollController.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
    _focusNode.dispose();

    super.dispose();
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

  void changePage(String code) {}
  @override
  void initState() {
    super.initState();
    getSavedData();
    _textController = TextEditingController();
    _messagesScrollController = ScrollController();
    _messagesScrollController.addListener(_onScroll);
    audioPlayer = AudioPlayer();

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

      setState(() {
        user = UserData.fromJson(savedUserDataJson);
      });
      getConversations();
    } catch (e) {
      logError(e.toString());
    }
  }

  void changeModel(String model) {
    setState(() {
      currentModel = model;
    });
  }

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

  void startNewConversation() {
    try {
      stopGenerationWithoutSocket();
      setState(() {
        conversationId = "";
        conversationTitle = "";
        messages = [];
        isGeneratingResponse = false;
        hasGenerateAtLastOne = true;
        webController.loadFile(html);
        prompt = "";
        _textController.text = "";
        audioPlayer.stop();
        webController.loadHtmlString(html);
      });
    } catch (e) {
      log("Error while starting new conversation $e");
      showCustomSnackBar(
          context: context, message: "Error while starting new conversation");
    }
  }

  void updateInput(String value) {
    setState(() {
      searchInput = value;
    });
  }

  Future<void> removeConversation(String convId) async {
    final keyToUse = await getKey(user.userId);

    try {
      setState(() {
        final lastConvs = conversations;
        final removedConv = lastConvs.conversations.remove(convId);

        if (removedConv != null) {
          conversations = lastConvs;
          ConversationManager manager = ConversationManager();

          Conversations newConversations =
              Conversations(conversations: lastConvs.conversations);
          manager.saveConversations(
              keyToUse, newConversations, "${user.userId}$suffix");
          log("Conversation removed");
          if (!mounted) return;
          showCustomSnackBar(
              context: context,
              message: "Conversation removed",
              icon: Icons.check_circle,
              iconColor: Colors.green);
        }

        if (convId == conversationId) {
          startNewConversation();
        }
      });
    } catch (e) {
      log("Error while removing conversation $e");
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
      manager.saveConversations(
          keyToUse, newConversations, "${user.userId}$suffix");

      setState(() {
        if (conversationId.isEmpty) {
          conversationId = convId;
        }
        if (conversationTitle.isEmpty) {
          conversationTitle = currentTitle;
        }
        conversations = newConversations;
        webController
            .loadHtmlString(messages[messages.length - 1].code ?? html);
      });

      log("Conversations saved and updated");
    } catch (e) {
      log("an error occured $e");
    }
  }

  Future<void> getConversations() async {
    try {
      ConversationManager manager = ConversationManager();

      String keyToUse = await getKey(user.userId);

      final savedConversations = await manager.getSavedConversations(
          "${user.userId}$suffix", keyToUse);

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
          currentNumberOfResponse = 0;
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
                role: msg.role,
                content: msg.content,
                msgId: id,
                videos: msg.videos,
                code: msg.code);
            newMessages.add(newMessage);
          }
          messages = newMessages;
          webController
              .loadHtmlString(messages[messages.length - 1].code ?? html);
          titleOfTop = messages[messages.length - 1].content.substring(0, 15);
        }
      });
    } catch (e) {
      log("Error during get conversations $e");
      showCustomSnackBar(
          context: context, message: "Error during get conversations ");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0XFF0D0D0D),
      appBar: TopBar(
          spaceName: titleOfTop,
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          startConv: startNewConversation,
          currentModel: currentModel,
          availableModels: availableModels,
          changeModel: changeModel,
          userId: user.userId),
      drawer: SideBarWB(
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
          conversations: conversations,
          startConv: startNewConversation,
          currentConvId: conversationId,
          searchInput: searchInput,
          updateInput: updateInput,
          name: user.name),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Container(
                decoration: BoxDecoration(color: Color(0XFF0D0D0D)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.9,
                      minWidth: MediaQuery.of(context).size.width),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: WebViewWidget(controller: webController),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.25,
                          child: MessageManagerWB(
                            changePrompt: changePrompt,
                            webViewController: webController,
                            messages: messages,
                          ),
                        )
                      ],
                    ),
                  ),
                )),
          ),
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
                              padding: const EdgeInsets.all(7),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          30, 158, 158, 158),
                                      width: 2.5),
                                  borderRadius: BorderRadius.circular(30),
                                  color: Color(0XFF171717),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    // INPUT ELEMENT SPACE //
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
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
                                          suffixIcon: IconButton(
                                              onPressed: takeAction,
                                              icon: Icon(
                                                isGeneratingResponse
                                                    ? Icons.square_rounded
                                                    : Icons.arrow_upward,
                                                color: Colors.white,
                                              )),
                                          hintText: "what do you want to create?",
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
                                  ],
                                ),
                              ))))))
        ],
      ),
    );
  }
}
