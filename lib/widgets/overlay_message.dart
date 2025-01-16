import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_feather_icons/flutter_feather_icons.dart";
import "package:sauraya/utils/snackbar_manager.dart";

void showOutPut(BuildContext context, String text, bool isExec) {
  OverlayState overlayState = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(builder: (BuildContext context) {
    return Positioned(
        top: MediaQuery.of(context).size.height / 3,
        left: MediaQuery.of(context).size.width / 10,
        right: MediaQuery.of(context).size.width / 10,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5.0,
            sigmaY: 5.0,
          ),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0XFF252525),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        color: Color(0XFF171717)),
                    child: Row(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommandCircle(circleColor: Colors.red),
                            CommandCircle(circleColor: Colors.orange),
                            CommandCircle(circleColor: Colors.green)
                          ],
                        ),
                        Spacer(),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                overlayEntry.remove();
                              },
                              icon: Icon(Icons.close),
                            ),
                            IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: text))
                                      .then((_) {
                                    showCustomSnackBar(
                                        context: context,
                                        message: "Copied",
                                        backgroundColor: Color(0XFF0D0D0D),
                                        icon: Icons.check_circle,
                                        iconColor: Colors.greenAccent);
                                  });
                                },
                                icon: isExec
                                    ? Icon(FeatherIcons.loader)
                                    : Icon(FeatherIcons.copy))
                          ],
                        )
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            text,
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  });
  overlayState.insert(overlayEntry);
}

class CommandCircle extends StatelessWidget {
  final Color circleColor;

  const CommandCircle({Key? key, required this.circleColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: circleColor,
          ),
        ),
      ),
    );
  }
}
