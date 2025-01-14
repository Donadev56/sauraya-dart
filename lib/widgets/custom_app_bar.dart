import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../logger/logger.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const TopBar({
    Key? key,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: primaryColor,
      backgroundColor: primaryColor,
      title: Row(
        children: [
          IconButton(
            onPressed: () {
              log("Element clicked");
            },
            icon: Icon(FeatherIcons.alignLeft),
            color: secondaryColor,
          ),
          TextButton(
            onPressed: () {
              log("Text button clicked");
            },
            child: Text(
              "Sauraya Ai",
              style: TextStyle(
                color: secondaryColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            log("Action clicked");
          },
          icon: Icon(FeatherIcons.edit),
          color: secondaryColor,
        ),
        PopupMenuButton(
          icon: Icon(FeatherIcons.moreVertical),
          iconColor: secondaryColor,
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem(
              child: Text('Option 1'),
              value: 'option 1',
            ),
            PopupMenuItem(
              child: Text('Option 2'),
              value: 'option 2',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
