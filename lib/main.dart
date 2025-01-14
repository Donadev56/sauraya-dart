import 'package:flutter/material.dart';
import 'package:sauraya/screens/chat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sauraya AI',
      theme: ThemeData(
        textSelectionTheme: TextSelectionThemeData(
            selectionHandleColor: Colors.orange, selectionColor: Colors.orange),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
