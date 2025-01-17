import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/types/types.dart';

typedef LoadConvType = Future Function(String convId);
typedef RmConvType = Future<void> Function(String);
typedef UpdateInputType = void Function(String value);

class SideBard extends StatelessWidget {
  final RmConvType onTap;
  final LoadConvType onOpen;
  final Conversations conversations;
  final VoidCallback startConv;
  final String currentConvId;
  final String searchInput;
  final UpdateInputType updateInput;
  final String name;

  const SideBard(
      {super.key,
      required this.onTap,
      required this.onOpen,
      required this.conversations,
      required this.startConv,
      required this.currentConvId,
      required this.searchInput,
      required this.updateInput,
      required this.name});

  @override
  Widget build(BuildContext context) {
    final filteredConversations = conversations.conversations.values
        .toList()
        .reversed
        .toList()
        .where((conv) =>
            conv.title.toLowerCase().contains(searchInput.toLowerCase()))
        .toList();

    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Color(0XFF121212),
      width: 250,
      child: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          SafeArea(
            child: Container(
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
                            onChanged: (value) {
                              updateInput(value);
                            },
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
                                fillColor:
                                    const Color.fromARGB(151, 77, 77, 77),
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
                                    'assets/transparent/image.png',
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
                    ),
                  ],
                )),
          ),
          if (conversations.conversations.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: ListView.builder(
                  itemCount: filteredConversations.length,
                  itemBuilder: (BuildContext context, int i) {
                    final conversation = filteredConversations[i];

                    return ConversationWidget(
                        currentConvId: currentConvId,
                        key: ValueKey(conversation.id),
                        conversation: conversation,
                        onTap: () => {onTap(conversation.id)},
                        onOpen: () {
                          onOpen(conversation.id);
                        });
                  }),
            ),
          Center(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  color: Colors.white,
                  width: 35,
                  height: 35,
                  child: Center(
                    child: Text(
                      name.substring(0, 2).toUpperCase(),
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              title: Text(
                name.toUpperCase(),
                overflow: TextOverflow.clip,
                maxLines: 35,
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
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
