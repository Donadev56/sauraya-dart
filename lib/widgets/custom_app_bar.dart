import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:sauraya/screens/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ChangeModelType = void Function(String model);

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback startConv;
  final String currentModel;
  final List<String> availableModels;
  final ChangeModelType changeModel;
  final String userId;
  final String spaceName;

  const TopBar({
    super.key,
    required this.primaryColor,
    required this.secondaryColor,
    required this.startConv,
    required this.currentModel,
    required this.availableModels,
    required this.changeModel,
    required this.userId,
    required this.spaceName,
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
        icon: Icon(FeatherIcons.sidebar),
        color: secondaryColor,
      ),
      title: Row(
        children: [
          TextButton(
              onPressed: () async {
                String? selected = await showMenu(
                  color: Color(0XFF212121),
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
                            Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            model,
                            style: TextStyle(color: Colors.white),
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
              child: Row(
                children: [
                  Text(
                    spaceName,
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )),
        ],
      ),
      actions: [
        IconButton(
          onPressed: startConv,
          icon: Icon(FeatherIcons.edit),
          color: secondaryColor,
        ),
        PopupMenuButton(
          color: Colors.pinkAccent,
          icon: Icon(FeatherIcons.moreVertical),
          iconColor: secondaryColor,
          onSelected: (value) async {
            final prefs = await SharedPreferences.getInstance();
            prefs.remove("lastAccount");

            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => AuthScreen()));
          },
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem(
              
              child: Row(
                
                children: [
                  Icon(Icons.logout, color: Colors.white,),
                  SizedBox(width: 10,) ,
                  Text('Logout', style: TextStyle(color: Colors.white),),
                ],
              ),
              value: 'logout',
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
