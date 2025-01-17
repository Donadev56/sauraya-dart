import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/remove_markdown.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/code_custom_style.dart';
import 'package:sauraya/widgets/styleSheet_widget.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:loading_animation_widget/loading_animation_widget.dart';

typedef ExecutePythonCode = Future<void> Function(String codeToExecute);
typedef RegenerateType = Future<void> Function(int msgIndex);

class MessageManager extends StatelessWidget {
  final Messages messages;
  final int index;
  final Color primaryColor;
  final Color secondaryColor;
  final Color darkbgColor;
  final Function readResponse;
  final bool isGeneratingResponse;
  final ExecutePythonCode executePythonCode;
  final bool isExec;
  final RegenerateType regenerate;

  const MessageManager({
    super.key,
    required this.messages,
    required this.index,
    required this.primaryColor,
    required this.secondaryColor,
    required this.darkbgColor,
    required this.readResponse,
    required this.isGeneratingResponse,
    required this.executePythonCode,
    required this.isExec,
    required this.regenerate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAssistant = messages[index].role == 'assistant';
    final bool isUser = messages[index].role == 'user';
    final bool isThinkingLoader = messages[index].role == 'thinkingLoader';
    final String msg = messages[index].content;

    if (isAssistant) {
      return InkWell(
        onLongPress: () async {
          final result = await showMenu(
              context: context,
              position: RelativeRect.fromLTRB(50, 400, 100, 100),
              color: Color(0XFF212121),
              items: [
                PopupMenuItem(
                    value: "listen",
                    child: Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Listen response",
                          style: TextStyle(color: Colors.white70),
                        )
                      ],
                    )),
                PopupMenuItem(
                    value: "regenerate",
                    child: Row(
                      children: [
                        Icon(FeatherIcons.refreshCcw, color: Colors.white),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Regenerate response",
                            style: TextStyle(color: Colors.white70))
                      ],
                    )),
                PopupMenuItem(
                    value: "copy",
                    child: Row(
                      children: [
                        Icon(FeatherIcons.copy, color: Colors.white),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Copy response",
                            style: TextStyle(color: Colors.white70))
                      ],
                    )),
              ]);
          if (result == "listen") {
            readResponse(msg);
          } else if (result == "copy") {
            final msgWihoutMarkdown = removeMarkdown(msg);
            Clipboard.setData(ClipboardData(text: msgWihoutMarkdown)).then((_) {
              showCustomSnackBar(
                  context: context,
                  message: "Copied",
                  backgroundColor: Color(0XFF0D0D0D),
                  icon: Icons.check_circle,
                  iconColor: Colors.greenAccent);
            });
          } else if (result == "regenerate") {
            log("Regeneration selected");
            await regenerate(index);
          }
        },
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            margin: messages.length == index + 1
                ? const EdgeInsets.only(top: 5, bottom: 100)
                : const EdgeInsets.all(0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context)
                      .size
                      .width, // Contraintes explicites
                  minHeight: messages.length == index + 1
                      ? MediaQuery.of(context).size.height * 0.6
                      : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Adapte la taille au contenu
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Aligne les éléments en haut

                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(75),
                    child: Image.asset(
                      'assets/transparent/image.png',
                      fit: BoxFit.cover,
                      width: 35, // Taille de l'image
                      height: 35,
                    ),
                  ),

                  const SizedBox(
                      width: 10), // Espacement entre l'image et le texte
                  Expanded(
                    child: MarkdownBody(
                      data: msg,
                      styleSheet: MarkdownCustomStyle.customStyle,
                      builders: {
                        'code': CodeElementBuilder(
                            isExec: isExec,
                            executePythonCode: executePythonCode,
                            textColor: secondaryColor,
                            context: context,
                            isGeneratingResponse: isGeneratingResponse),
                      },
                      onTapLink: (text, href, title) async {
                        try {
                          log("Launching the url : $href");
                          if (href != null) {
                            Uri url = Uri.parse(href);

                            launchUrl(url);
                          } else {
                            log("The url is not available");
                          }
                        } catch (e) {
                          logError("An error occurred $e");
                          showCustomSnackBar(
                              context: context,
                              message: e.toString(),
                              backgroundColor: Color(0xFF212121),
                              icon: Icons.error,
                              iconColor: Colors.red);
                        }
                      },
                    ),
                  ),
                ],
              ),
            )),
      );
    }
    if (isUser) {
      return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: messages.length == index + 1
                ? const EdgeInsets.only(top: 8, bottom: 100)
                : const EdgeInsets.all(8),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: InkWell(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: msg)).then((_) {
                      showCustomSnackBar(
                          context: context,
                          message: "Copied",
                          backgroundColor: Color(0XFF0D0D0D),
                          icon: Icons.check_circle,
                          iconColor: Colors.greenAccent);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      color: darkbgColor,
                    ),
                    child: Text(
                      msg,
                      style: TextStyle(color: secondaryColor),
                    ),
                  ),
                )),
          ));
    } else if (isThinkingLoader) {
      return Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
          child: Container(
            padding: const EdgeInsets.only(
                top: 20, left: 20, right: 20, bottom: 200),
            child: LoadingAnimationWidget.fourRotatingDots(
                color: Colors.white, size: 40),
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final Color textColor;
  final BuildContext context;
  final bool isGeneratingResponse;
  final ExecutePythonCode executePythonCode;
  final bool isExec;

  CodeElementBuilder(
      {required this.textColor,
      required this.context,
      required this.isGeneratingResponse,
      required this.executePythonCode,
      required this.isExec});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = 'plaintext';
    bool isPython = language == "python";

    if (element.attributes.containsKey('class')) {
      final className = element.attributes['class'];
      if (className != null && className.startsWith('language-')) {
        language = className.substring(9);
        isPython = language == 'python';
        log('language : $language');
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0XFF191919),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 15),
            decoration: BoxDecoration(
              color: const Color(0XFF191919),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(color: Colors.white60),
                ),
                Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                                ClipboardData(text: element.textContent))
                            .then((_) {
                          showCustomSnackBar(
                              context: context,
                              message: "Copied",
                              backgroundColor: Color(0XFF0D0D0D),
                              icon: Icons.check_circle,
                              iconColor: Colors.greenAccent);
                        });
                      },
                      icon: Icon(FeatherIcons.copy),
                      color: Colors.white60,
                    ),
                    if (isPython)
                      IconButton(
                          onPressed: () {
                            executePythonCode(element.textContent);
                          },
                          icon: Icon(
                            isExec
                                ? FeatherIcons.loader
                                : FeatherIcons.terminal,
                            color: Colors.white60,
                          ))
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              element.textContent,
              language: language,
              theme: VsCode,
              padding: const EdgeInsets.all(8),
              textStyle: TextStyle(color: textColor),
            ),
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
