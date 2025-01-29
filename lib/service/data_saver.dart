import 'dart:convert';

import 'package:sauraya/logger/logger.dart';
import 'package:sauraya/service/crypto.dart';
import 'package:sauraya/service/directory.dart';
import 'package:sauraya/service/web.dart';
import 'package:sauraya/types/types.dart';
import 'package:flutter/foundation.dart';

const databaseKey = "database";
const fileName = "sauraya.crypt";

class ConversationManager {
  Future<void> saveConversations(
      String key, Conversations conversations, String userId) async {
    try {
      final storageService = LocalStorageService();
      final encryptedConversations =
          await encryptJson(jsonEncode(conversations.toJson()), key);

      if (encryptedConversations != null) {
        dynamic result;
        if (kIsWeb) {
          // Web Storage API is used in Flutter Web
          result = saveToWebStorage("userData/$userId", encryptedConversations);
          if (result == true) {
            log("Data stored successfully in $result");
          } else {
            logError("Failed to store data");
          }
        } else {
          // External storage is used in Flutter mobile or desktop
          result = await storageService.saveStringData(
            databaseKey,
            encryptedConversations,
            "$userId-$fileName",
          );
          if (result != null) {
            log("Data stored successfully in $result");
          } else {
            logError("Failed to store data");
          }
        }
      } else {
        logError("Failed to encrypt conversations.");
      }
    } catch (e) {
      logError('Error while saving conversations: $e');
    }
  }

  Future<Conversations?> getSavedConversations(
      String userId, String savedKey) async {
    try {
      final storageService = LocalStorageService();
      dynamic savedData;
      if (kIsWeb) {
        // Web Storage API is used in Flutter Web
        savedData = getWebStorageData("userData/$userId");
      } else {
        // External storage is used in Flutter mobile or desktop

        savedData = await storageService.getStringData(
            databaseKey, "$userId-$fileName");
      }

      log("Saved data: $savedData");

      if (savedData == null) {
        log("No saved conversations found.");
        return null;
      }

      final decryptedData = await decryptJson(savedData, savedKey);

      if (decryptedData == null) {
        logError("Failed to decrypt conversation data.");
        return null;
      }

      final conversations = Conversations.fromJson(
          jsonDecode(decryptedData) as Map<String, dynamic>);

      log("Decrypted conversations: ${conversations.toString()}");
      return conversations;
    } catch (e) {
      logError("Error while fetching conversations: $e");
      return null;
    }
  }
}
