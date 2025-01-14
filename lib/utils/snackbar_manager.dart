import 'package:flutter/material.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    Color backgroundColor = const Color(0XFF0D0D0D),
    Color iconColor = Colors.white}) {

      
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor),
          Text(
            message,
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
