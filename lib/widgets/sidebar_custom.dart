import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/types/types.dart';

class SideBard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final Conversations conversations;

  const SideBard({
    Key? key,
    required this.onTap,
    required this.onOpen,
    required this.conversations,
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
                            onPressed: () {},
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
                          log("InkWell");
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
                        key: ValueKey(conversation.id),
                        conversation: conversation,
                        onTap: onTap,
                        onOpen: onOpen);
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

  const ConversationWidget({
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: ListTile(
        key: key,
        onLongPress: onTap,
        onTap: onOpen,
        title: Text(
          conversation.title,
          overflow: TextOverflow.clip,
          maxLines: 1,
          style: TextStyle(
              color: const Color.fromARGB(238, 255, 255, 255),
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
