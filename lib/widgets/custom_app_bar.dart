import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../logger/logger.dart';

typedef ChangeModelType = void Function(String model);

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback startConv;
  final String currentModel;
  final List<String> availableModels;
  final ChangeModelType changeModel;

  const TopBar({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.startConv,
    required this.currentModel,
    required this.availableModels,
    required this.changeModel,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: primaryColor,
      backgroundColor: primaryColor,
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: Icon(FeatherIcons.alignLeft),
        color: secondaryColor,
      ),
      title: Row(
        children: [
          TextButton(
            onPressed: () async {
              String? selected = await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(60, 100, 100, 100),
                items: availableModels.map((model) {
                  return PopupMenuItem(
                    value: model,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (model == currentModel)
                          Icon(Icons.check_circle, color: Colors.black),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          model,
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );

              if (selected != null) {
                changeModel(selected);
              }
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
          onPressed: startConv,
          icon: Icon(FeatherIcons.edit),
          color: secondaryColor,
        ),
        PopupMenuButton(
          icon: Icon(FeatherIcons.moreVertical),
          iconColor: secondaryColor,
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.logout),
                  Text('Logout'),
                ],
              ),
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
