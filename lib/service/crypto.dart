import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:sauraya/logger/logger.dart';
import 'package:cryptography/cryptography.dart';

Future<String?> encryptJson(String jsonData, String password) async {
  try {
    final key = Key.fromUtf8(password.padRight(32, "*"));
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonData, iv: iv);
    final encryptedData = {
      "iv": base64Encode(iv.bytes),
      "ecr": encrypted.base64
    };

    log("Data encrypted and saved successfully");

    return jsonEncode(encryptedData);
  } catch (e) {
    logError(e.toString());
    return null;
  }
}

Future<String?> decryptJson(String encryptedJson, String password) async {
  try {
    final Map<String, dynamic> encryptedData = jsonDecode(encryptedJson);

    final iv = IV.fromBase64(encryptedData['iv']);
    final encryptedText = encryptedData['ecr'];

    final key = Key.fromUtf8(password.padRight(32, "*"));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    final decrypted = encrypter.decrypt64(encryptedText, iv: iv);

    log("Data decrypted successfully");
    return decrypted;
  } catch (e) {
    logError("Erreur : ${e.toString()}");
    return null;
  }
}

Future<String> generateSecureKey(int lenght) async {
  final algorithm = AesGcm.with256bits();
  final key = await algorithm.newSecretKey();
  final finalKey =
      base64UrlEncode((await key.extractBytes())).substring(0, lenght);
  return finalKey;
}
