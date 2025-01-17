import 'package:flutter/material.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/screens/auth.dart';
import 'package:sauraya/screens/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const Sauraya());
}

class Routes {
  static const String chatRoom = '/dashboard/chat';
  static const String loader = '/loader';
  static const String registration = '/auth';
}

Future<bool> isLogin() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? lastAccount = prefs.getString('lastAccount');
    if (lastAccount != null) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    logError(e.toString());
    return false;
  }
}

class Sauraya extends StatelessWidget {
  const Sauraya({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: isLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            logError(snapshot.error!.toString());
            return const Center(
                child: Text('An error ocured during the app initialization.'));
          } else {
            final bool isLoginBool = snapshot.data ?? false;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Sauraya AI',
              theme: ThemeData(
                textSelectionTheme: TextSelectionThemeData(
                    selectionHandleColor: Colors.blue,
                    selectionColor: Colors.blue),
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
              home: isLoginBool ? const ChatScreen() : const AuthScreen(),
              routes: {Routes.chatRoom: (context) => ChatScreen()},
            );
          }
        });
  }
}
