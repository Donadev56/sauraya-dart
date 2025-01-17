import 'package:flutter/material.dart';

typedef ChangeConvtype = Future<void> Function(String convId, String newTitle);

void showInputDialog(
    BuildContext context, ChangeConvtype changeTitle, String convId) {
  final TextEditingController inputController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color(0XFF212121),
        content: TextField(
          style: TextStyle(color: Colors.white),
          cursorColor: Colors.orange,
          controller: inputController,
          decoration: InputDecoration(
              labelText: "New title",
              labelStyle: TextStyle(color: Colors.white),
              focusColor: Colors.white,
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 3)),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 3)),
              hintText: 'New title here ...',
              hintStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Close',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              String userInput = inputController.text;
              changeTitle(convId, userInput);
              Navigator.of(context).pop();
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      );
    },
  );
}
