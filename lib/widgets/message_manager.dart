import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_player_embed/controller/video_controller.dart';
import 'package:youtube_player_embed/enum/video_state.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:youtube_player_embed/youtube_player_embed.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/remove_markdown.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/code_custom_style.dart';
import 'package:sauraya/widgets/styleSheet_widget.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as yP;
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';

typedef ExecutePythonCode = Future<void> Function(String codeToExecute);
typedef RegenerateType = Future<void> Function(int msgIndex);
typedef ChangeUrl = void Function(String url);
typedef InitController = void Function(VideoController controller, String id);
typedef VideoPlayingStateType = void Function(bool isplaying);
typedef ControllerManagerType = void Function(String id);

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
  final String titleFound;
  final InitController initController;
  final ControllerManagerType stopPlayingVideo;
  final ControllerManagerType playVideo;
  final VideoPlayingStateType videoPlayingState;
  final bool isPlayingVideo;

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
    required this.titleFound,
    required this.initController,
    required this.stopPlayingVideo,
    required this.playVideo,
    required this.videoPlayingState,
    required this.isPlayingVideo,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAssistant = messages[index].role == 'assistant';
    final bool isUser = messages[index].role == 'user';
    final bool isThinkingLoader = messages[index].role == 'thinkingLoader';
    final List<String>? videos = messages[index].videos;
    final String msg = messages[index].content;
    final message = messages[index];
    var random = Random();

    String convertUrl(String url) {
      final videoId = yP.YoutubePlayer.convertUrlToId(url);
      return videoId ?? "";
    }

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
                      ? MediaQuery.of(context).size.height * 0.64
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
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: msg,
                        styleSheet: MarkdownCustomStyle.customStyle,
                        builders: {
                          'code': CodeElementBuilder(
                              isExec: isExec,
                              executePythonCode: executePythonCode,
                              textColor: secondaryColor,
                              context: context,
                              isGeneratingResponse: isGeneratingResponse),
                          'img': CustomImageBuilder(context: context)
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
                      if (videos != null && videos.isNotEmpty)
                        InkWell(
                          onTap: () {
                            log("current state $isPlayingVideo");
                            if (isPlayingVideo) {
                              stopPlayingVideo(message.msgId ?? "");
                            } else {
                              playVideo(message.msgId ?? "");
                            }
                          },
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(15),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: YoutubePlayerEmbed(
                                    autoPlay: false,
                                    videoId: convertUrl(videos[
                                        random.nextInt(videos.length - 1)]),
                                    callBackVideoController: (controller) {
                                      initController(
                                          controller, message.msgId ?? "");
                                    },
                                    onVideoStateChange: (state) {
                                      log("Current state $state");
                                      if (state == VideoState.playing) {
                                        videoPlayingState(true);
                                      } else if (state == VideoState.paused) {
                                        videoPlayingState(false);
                                      }
                                    },
                                    onVideoEnd: () {
                                      videoPlayingState(false);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  )),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonParagraph(
                      style: SkeletonParagraphStyle(
                          lines: 3,
                          spacing: 6,
                          lineStyle: SkeletonLineStyle(
                            randomLength: true,
                            height: 10,
                            borderRadius: BorderRadius.circular(8),
                            minLength: MediaQuery.of(context).size.width / 6,
                            maxLength: MediaQuery.of(context).size.width / 3,
                          ))),
                  SizedBox(
                    height: 10,
                  ),
                  if (messages.length < 4)
                    Text(
                      titleFound,
                      overflow: TextOverflow.fade,
                      maxLines: 2,
                      style: TextStyle(
                          color: const Color.fromARGB(141, 255, 255, 255)),
                    )
                ],
              )),
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
      margin: language == "plaintext"
          ? const EdgeInsets.all(10)
          : const EdgeInsets.all(0),
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

class CustomImageBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CustomImageBuilder({required this.context});

  Future<void> downloadImage(String url, String fileName) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        log("Can not find application or  documents directory");
        return;
      }

      String filePath = "${directory.path}/$fileName";

      Dio dio = Dio();
      await dio.download(url, filePath);
      log("file saved to:   $filePath");
      showCustomSnackBar(
          context: context,
          message: "File saved ",
          iconColor: Colors.greenAccent,
          icon: Icons.check_circle);
    } catch (e) {
      log("An error occured while downloading the file : $e");
      showCustomSnackBar(
          context: context,
          message: "Error while downloading the file",
          iconColor: Colors.pinkAccent,
          icon: Icons.error);
    }
  }

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String? imageUrl = element.attributes['src'];
    return GestureDetector(
      onTap: () {
        Uri url = Uri.parse(imageUrl ?? "");

        launchUrl(url);
      },
      child: Container(
        margin: EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(imageUrl ?? ''),
        ),
      ),
    );
  }
}
