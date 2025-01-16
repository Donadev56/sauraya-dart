import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/types/types.dart';

typedef LoadConvType = Future Function(String convId);
typedef rmConvType = Future<void> Function(String);

class SideBard extends StatelessWidget {
  final rmConvType onTap;
  final LoadConvType onOpen;
  final Conversations conversations;
  final VoidCallback startConv;
  final String currentConvId;

  const SideBard({
    Key? key,
    required this.onTap,
    required this.onOpen,
    required this.conversations,
    required this.startConv,
    required this.currentConvId,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Color(0XFF121212),
      width: 280,
      child: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          Container(
              padding: const EdgeInsets.only(top: 30),
              margin: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                border: Border.all(width: 0, color: Colors.transparent),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                            child: TextField(
                          style: TextStyle(color: Colors.white),
                          cursorColor: Colors.grey,
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white60,
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 0)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 0)),
                              filled: true,
                              fillColor: const Color.fromARGB(151, 77, 77, 77),
                              hintText: "Search",
                              hintStyle: TextStyle(color: Colors.white60),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(40),
                                  borderSide: BorderSide(
                                      color: Colors.transparent, width: 0))),
                        )),
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              startConv();
                            },
                            icon: Icon(
                              FeatherIcons.edit,
                              size: 27,
                              color: Colors.white60,
                            ))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width),
                    child: Ink(
                      color: Color(0XFF212121), // Définir la couleur ici
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          startConv();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(75),
                                child: Image.asset(
                                  'lib/assets/transparent/image.png',
                                  fit: BoxFit.cover,
                                  width: 35,
                                  height: 35,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Start a new Chat",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )),
          if (conversations.conversations.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: ListView.builder(
                  itemCount: conversations.conversations.values.length,
                  itemBuilder: (BuildContext context, int i) {
                    final conversation = conversations.conversations.values
                        .toList()
                        .reversed
                        .toList()[i]; // Récupère chaque conversation

                    return ConversationWidget(
                        currentConvId: currentConvId,
                        key: ValueKey(conversation.id),
                        conversation: conversation,
                        onTap: () => {onTap(conversation.id)},
                        onOpen: () {
                          onOpen(conversation.id);
                        });
                  }),
            )
        ],
      ),
    );
  }
}

class ConversationWidget extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final String currentConvId;

  const ConversationWidget({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onOpen,
    required this.currentConvId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: Container(
          color: currentConvId == conversation.id
              ? Colors.white
              : Colors.transparent,
          child: ListTile(
            key: key,
            onLongPress: onTap,
            onTap: onOpen,
            title: Text(
              conversation.title,
              overflow: TextOverflow.clip,
              maxLines: 1,
              style: TextStyle(
                  color: currentConvId == conversation.id
                      ? Colors.black
                      : const Color.fromARGB(238, 255, 255, 255),
                  fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }
}
