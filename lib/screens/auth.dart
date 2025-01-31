import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/screens/chat.dart';
import 'package:sauraya/service/secure_storage.dart';
import 'package:sauraya/types/types.dart';
import 'package:sauraya/utils/auth_service.dart';
import 'package:sauraya/utils/snackbar_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

String email = "";
String name = "";
String otp = "";
bool isLoading = false;
bool isSendingOtp = false;
int step = 1;
String url = "https://chat.sauraya.com";

class _AuthScreenState extends State<AuthScreen> {
  FocusNode focusNode = FocusNode();
  FocusNode focusNode2 = FocusNode();
  bool isFocus = false;
  bool isFocus2 = false;

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      setState(() {
        isFocus = focusNode.hasFocus;
      });
    });
    focusNode2.addListener(() {
      setState(() {
        isFocus2 = focusNode2.hasFocus;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> sendEmail() async {
      setState(() {
        isLoading = false;
        isSendingOtp = true;
      });

      try {
        if (email.isEmpty || name.isEmpty) {
          showCustomSnackBar(
              context: context,
              message: "Please enter a valid email or nickname",
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
          return;
        }
        final response = await http.post(
          Uri.parse("$url/auth/sendEmail/$email"),
        );
        if (response.statusCode == 200) {
          showCustomSnackBar(
              context: context,
              message: "Otp sent to $email",
              icon: Icons.check_circle,
              iconColor: Colors.greenAccent);
          setState(() {
            step = 2;
            isLoading = false;
            isSendingOtp = false;
          });
        } else {
          final reason = json.decode(response.body);

          showCustomSnackBar(
              context: context,
              message: "${reason["response"]}",
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
          setState(() {
            step = 1;
            isLoading = false;
            isSendingOtp = false;
          });
        }
      } catch (e) {
        logError("An error occurred while sending the email");
        showCustomSnackBar(
            context: context,
            message: "An error occurred while sending the Otp",
            icon: Icons.check_circle,
            iconColor: Colors.pinkAccent);
        setState(() {
          step = 1;
          isLoading = false;
          isSendingOtp = false;
        });
      }
    }

    Future<void> VerifyOtt() async {
      SecureStorageService secureStorage = SecureStorageService();
      final prefs = await SharedPreferences.getInstance();

      try {
        setState(() {
          isLoading = true;
        });
        final req = {'email': email, 'name': name, 'otp': otp};
        final response = await http.post(
          Uri.parse(
            "$url/auth/verifyOtp/",
          ),
          body: json.encode(req),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final res = json.decode(response.body)["response"];
          final data = res["userData"];
          UserData userData = UserData(
              name: data["name"],
              userId: data["userId"],
              joiningDate: data["joiningDate"],
              address: data["address"],
              token: res["token"]);
          await secureStorage.saveDataInFSS(
              json.encode(userData.toJson()), 'userData/${userData.userId}');
          await prefs.setString("lastAccount", userData.userId);
          log('Data saved successfully');

          if (!mounted) return;
          showCustomSnackBar(
              context: context,
              message: "Login successful",
              icon: Icons.check_circle,
              iconColor: Colors.greenAccent);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ChatScreen()));
        } else {
          final reason = json.decode(response.body);
          showCustomSnackBar(
              context: context,
              message: "${reason["response"]}",
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        logError(e.toString());
        setState(() {
          isLoading = false;
        });
        showCustomSnackBar(
            context: context,
            message: "An error occurred while verifying the Otp",
            icon: Icons.error,
            iconColor: Colors.pinkAccent);
      }
    }

    Future<void> sendGoogleData(GoogleSignInAccount user) async {
      SecureStorageService secureStorage = SecureStorageService();
      final prefs = await SharedPreferences.getInstance();

      try {
        setState(() {
          isLoading = true;
        });
        final req = {
          'email': user.email,
          'name': user.displayName,
          'id': user.id,
          "photoUrl": user.photoUrl,
          "serverAuthCode": user.serverAuthCode
        };
        final response = await http.post(
          Uri.parse(
            "$url/auth/googleAuth",
          ),
          body: json.encode(req),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final res = json.decode(response.body)["response"];
          final data = res["userData"];
          UserData userData = UserData(
              name: data["name"],
              userId: data["userId"],
              joiningDate: data["joiningDate"],
              address: data["address"],
              token: res["token"]);
          await secureStorage.saveDataInFSS(
              json.encode(userData.toJson()), 'userData/${userData.userId}');
          await prefs.setString("lastAccount", userData.userId);
          log('Data saved successfully');

          if (!mounted) return;
          showCustomSnackBar(
              context: context,
              message: "Login successful",
              icon: Icons.check_circle,
              iconColor: Colors.greenAccent);

          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ChatScreen()));
        } else {
          final reason = json.decode(response.body);
          showCustomSnackBar(
              context: context,
              message: "${reason["response"]}",
              icon: Icons.error,
              iconColor: Colors.pinkAccent);
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        logError(e.toString());
        setState(() {
          isLoading = false;
        });
        showCustomSnackBar(
            context: context,
            message: "An error occurred while verifying the Otp",
            icon: Icons.error,
            iconColor: Colors.pinkAccent);
      }
    }

    return Scaffold(
        body: SingleChildScrollView(
            child: ConstrainedBox(
      constraints:
          BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      child: Center(
        child: AnimatedContainer(
          duration: Duration(microseconds: 300),
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
              color: Color(0XFF0D0D0D),
              image: DecorationImage(
                image: AssetImage('assets/bg/blur1.png'),
                fit: BoxFit.cover,
              )),
          child: SafeArea(
              child: Center(
                  child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 0, left: 20),
                        child: RichText(
                            text: TextSpan(
                                text: "Welcome to the world's first\n",
                                style: GoogleFonts.exo2(
                                  color: Colors.white,
                                  fontSize: 36,
                                  letterSpacing: 1.2,
                                ),
                                children: [
                              TextSpan(
                                  text: "Private Ai",
                                  style: GoogleFonts.audiowide(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40)),
                              TextSpan(
                                text: " assistant",
                              )
                            ])),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 40, left: 20, right: 20),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              if (step == 1)
                                InputWidget(
                                    focusNode: focusNode,
                                    isFocus: isFocus,
                                    onChanged: (value) {
                                      setState(() {
                                        name = value;
                                        log(name);
                                      });
                                    },
                                    hintText: "Nickname"),
                              SizedBox(
                                height: 15,
                              ),
                              if (step == 1)
                                InputWidget(
                                    focusNode: focusNode2,
                                    isFocus: isFocus2,
                                    onChanged: (value) {
                                      setState(() {
                                        email = value;
                                      });
                                    },
                                    hintText: "Email"),
                              SizedBox(
                                height: 10,
                              ),
                              if (step == 2)
                                InputWidgetOtp(
                                  isFocused: isFocus,
                                  focusnode: focusNode,
                                  hintText: "Enter Otp",
                                  onChanged: (value) {
                                    setState(() {
                                      otp = value;
                                    });
                                  },
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (step == 2)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: ConstrainedBox(
                                        constraints:
                                            BoxConstraints(minHeight: 40),
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white),
                                            onPressed: () {
                                              if (step == 2) {
                                                setState(() {
                                                  step = 1;
                                                  isLoading = false;
                                                });
                                              }
                                            },
                                            child: Text(
                                              "back",
                                              style: GoogleFonts.audiowide(
                                                  color: Color(0XFF212121),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            )),
                                      ),
                                    ),
                                  if (step == 2)
                                    SizedBox(
                                      width: 30,
                                    ),
                                  isLoading
                                      ? Container(
                                          padding: const EdgeInsets.all(15),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        )
                                      : Padding(
                                          padding:
                                              const EdgeInsets.only(top: 10),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                                minWidth: step == 2 ? 0 : 280,
                                                minHeight: 40),
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  if (isSendingOtp) return;
                                                  if (step == 1) {
                                                    sendEmail();
                                                  } else {
                                                    VerifyOtt();
                                                  }
                                                },
                                                child: Text(
                                                  "Submit",
                                                  style: GoogleFonts.audiowide(
                                                      color: Color(0XFF212121),
                                                      fontSize: 15),
                                                )),
                                          ),
                                        ),
                                ],
                              ),
                              if (step == 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: 280, minHeight: 40),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                        ),
                                        onPressed: () async {
                                          log("Google auth");
                                          final auth = AuthService();
                                          final user =
                                              await auth.signInWithGoogle();
                                          log(user.toString());
                                          final userToAuth = user;
                                          if (userToAuth != null) {
                                            await sendGoogleData(userToAuth);
                                          } else {
                                            showCustomSnackBar(
                                                context: context,
                                                message: "An error occurred",
                                                iconColor: Colors.pinkAccent);
                                          }
                                        },
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: Image.asset(
                                                      "assets/logo/google1.png"),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                "Sign in with Google",
                                                style: TextStyle(
                                                    color: const Color.fromARGB(
                                                        206, 0, 0, 0)),
                                              )
                                            ],
                                          ),
                                        ),
                                      )),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ))),
        ),
      ),
    )));
  }
}

class InputWidget extends StatelessWidget {
  final String hintText;
  final Function(String value) onChanged;
  final FocusNode focusNode;
  final bool isFocus;

  const InputWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.focusNode,
    required this.isFocus,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      onChanged: (value) {
        onChanged(value);
      },
      keyboardType:
          hintText == "Email" ? TextInputType.emailAddress : TextInputType.name,
      cursorColor: Colors.greenAccent,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
          filled: isFocus ? false : true,
          fillColor: const Color.fromARGB(15, 255, 255, 255),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          labelText: hintText,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white60),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 3)),
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white))),
    );
  }
}

class InputWidgetOtp extends StatelessWidget {
  final String hintText;
  final Function(String value) onChanged;
  final FocusNode focusnode;
  final bool isFocused;

  const InputWidgetOtp({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.focusnode,
    required this.isFocused,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (value) {
        onChanged(value);
      },
      maxLength: 5,
      cursorColor: Colors.greenAccent,
      style: TextStyle(
          color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
      keyboardType: TextInputType.numberWithOptions(),
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide(color: Colors.white, width: 3),
          ),
          labelText: hintText,
          hintText: hintText,
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(
              color: Colors.white60, fontSize: 20, fontWeight: FontWeight.bold),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 3)),
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white))),
    );
  }
}

class Circle extends StatelessWidget {
  final IconData icon;
  const Circle({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showCustomSnackBar(
            context: context,
            icon: Icons.error,
            iconColor: Colors.pinkAccent,
            message: "Not available yet");
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: Colors.white),
          child: Center(
            child: Icon(
              icon,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
