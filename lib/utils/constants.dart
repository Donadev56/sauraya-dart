import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/service/crypto.dart';
import 'package:sauraya/service/secure_storage.dart';

List<String> availableModels = [
  "llama3.2:1b",
  "llama3.2",
  "dolphin3",
  "sauraya"
];

List<String> startingConversions = [
   "Generate a python code to show me your programming skills, choose the type of code you want.",
   "Summarize the lifestyle a person should adopt to be successful in life.",
    "Teach me how to do data analysis as a data analyst and the tools needed to use it",
      "think of something I probably don't know that you're teaching me today",
   
];

Color primaryColor = Color(0xFF0D0D0D);
Color secondaryColor = Colors.white;
Color darkbgColor = Color(0XFF212121);

void scrollToBottom(ScrollController messagesScrollController) {
    if (messagesScrollController.hasClients) {
      messagesScrollController.animateTo(
        messagesScrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> getKey(String userId) async {
    try {
      SecureStorageService service = SecureStorageService();

      String keyToUse = "";
      final savedkey = await service.loadPrivateKey(userId);

      if (savedkey != null) {
        keyToUse = savedkey;
      } else {
        keyToUse = await generateSecureKey(32);
        await service.savePrivateKey(keyToUse, userId);
      }
      return keyToUse;
    } catch (e) {
      log("An error occured $e");
      return "";
    }
  }