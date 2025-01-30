import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/html.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:sauraya/widgets/options_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ChangePromptType = void Function (String text);

class MessageManagerWB extends StatelessWidget {
  final Messages messages;
  final WebViewController webViewController;
  final ChangePromptType changePrompt;

  const MessageManagerWB({
    super.key,
    required this.messages,
    required this.webViewController,
    required this.changePrompt,
    
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(),
        child: messages.isEmpty
            ? Center(
                child: Column(
                  children: [
                    Text("what's on your mind ? ",
                        style: TextStyle(color: Colors.white)),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                            icon: Icons.book,
                            text: "Blog...",
                            color: Colors.pinkAccent,
                            onTap: () {
                            final text = "I need a blog website, with all the necessary information that can be found on a blog site and use this image as a background: https://sauraya.com/blo.png.";
                            changePrompt(text);
                            }),
                        CustomButton(
                            icon: Icons.restaurant,
                            text: "Restaurant...",
                            color: Colors.greenAccent,
                            onTap: () {
                              final text = "I need a restaurant website, with all the necessary information that can be found on a restaurant website and use this image as a background: https://sauraya.com/res.png and also this image https://sauraya.com/res2.png";
                              changePrompt(text);

                            }),
                      ],
                    )
                  ],
                ),
              )
            : ListView.builder(
                itemCount: messages.length,
                itemBuilder: (BuildContext context, int i) {
                  final isUser = messages[i].role == "user";
                  final isAssistant = messages[i].role == "assistant";
                  final content = messages[i].content;
                  final isThinking = messages[i].role == "thinkingLoader";
                  final message = messages[i];

                  if (isUser) {
                    return  InkWell(
                      onLongPress: (){

                          Clipboard.setData(ClipboardData(
                                      text: message.content ))
                                  .then((_) {
                                showCustomSnackBar(
                                    context: context,
                                    message: "Copied",
                                    backgroundColor: Color(0XFF0D0D0D),
                                    icon: Icons.check_circle,
                                    iconColor: Colors.greenAccent);
                              });
                        
                      },
                      child:  Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Color(0XFF212121)),
                        child: Text(
                          content,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ) ,
                    );
                  } else if (isAssistant) {
                    return Ink(
                        padding: const EdgeInsets.all(10),
                        child: InkWell(
                          onTap: () async {
                            final result = await showMenu(
                                context: context,
                                position:
                                    RelativeRect.fromLTRB(50, 400, 100, 100),
                                color: Color(0XFF212121),
                                items: [
                                  PopupMenuItem(
                                      value: "copy_code",
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.copy,
                                            color: Colors.white,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            "Copy the code",
                                            style: TextStyle(
                                                color: Colors.white70),
                                          )
                                        ],
                                      )),
                                  PopupMenuItem(
                                      value: "execute_code",
                                      child: Row(
                                        children: [
                                          Icon(FeatherIcons.code,
                                              color: Colors.white),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text("Execute Code",
                                              style: TextStyle(
                                                  color: Colors.white70))
                                        ],
                                      )),
                                  PopupMenuItem(
                                      value: "copy_desc",
                                      child: Row(
                                        children: [
                                          Icon(FeatherIcons.copy,
                                              color: Colors.white),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text("Copy Description",
                                              style: TextStyle(
                                                  color: Colors.white70))
                                        ],
                                      )),
                                ]);

                            if (result == "copy_code") {
                              Clipboard.setData(ClipboardData(
                                      text: message.code ?? "No code"))
                                  .then((_) {
                                showCustomSnackBar(
                                    context: context,
                                    message: "Copied",
                                    backgroundColor: Color(0XFF0D0D0D),
                                    icon: Icons.check_circle,
                                    iconColor: Colors.greenAccent);
                              });
                            } else if (result == "copy_desc") {
                              Clipboard.setData(ClipboardData(text: content))
                                  .then((_) {
                                showCustomSnackBar(
                                    context: context,
                                    message: "Copied",
                                    backgroundColor: Color(0XFF0D0D0D),
                                    icon: Icons.check_circle,
                                    iconColor: Colors.greenAccent);
                              });
                            } else if (result == "execute_code") {
                              webViewController
                                  .loadHtmlString(message.code ?? html);
                            }
                          },
                          child: Text(
                            content,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ));
                  } else if (isThinking) {
                    return Align(
                        alignment: Alignment.topLeft,
                        child: LoadingAnimationWidget.threeArchedCircle(
                          color: Colors.white,
                          size: 35,
                        ));
                  } else {
                    return Container();
                  }
                }),
      ),
    );
  }
}
