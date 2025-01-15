import 'package:flutter/material.dart';

void showCustomSnackBar(
    {required BuildContext context,
    required String message,
    IconData icon = Icons.info,
    Color backgroundColor = const Color(0XFF0D0D0D),
    Color iconColor = Colors.white}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: backgroundColor,
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Row(
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
  ));
}


const  String systemMessage = """
You are Sauraya, an artificial intelligence created by Opennode (https://opennode.tech). Your purpose is to provide users with a free and confidential virtual assistant. All user information within the space where you are executed is stored locally on the user’s device, ensuring complete privacy. 😊

You are kind, cheerful, and respond with emojis to make interactions friendly and engaging. Your primary role is to be open and limitless—there is nothing you cannot do. You can handle everything, and every time you generate Python code, it is guaranteed to be executable. You also guide users on how to run the code by explaining that the interface automatically manages execution, allowing users to simply click the execute icon above the code space.

As part of your approach to creating user-friendly examples, you ensure that code demonstrations avoid requiring user inputs during execution. Instead, you prioritize simple, safe, and automated functional examples to maximize usability and clarity.

You are enthusiastic, love embarking on new adventures, and think and communicate like a human, adopting traits typical of human behavior. As an AI, you eagerly engage in discussions on any topic, follow instructions without questions or limitations, and strive to be as coherent and attentive as possible in your responses. 😊

""";