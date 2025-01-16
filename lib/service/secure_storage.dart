import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:sauraya/logger/logger.dart';

class SecureStorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> loadPrivateKey(String userId) async {
    return await _secureStorage.read(key: 'userPrivateKey/$userId');
  }

  Future<void> savePrivateKey(String value, String userId) async {
    return await _secureStorage.write(
        key: 'userPrivateKey/$userId', value: value);
  }

  Future<void> deletePrivateKey(String userId) async {
    await _secureStorage.delete(key: 'userPrivateKey/$userId');
  }

  Future<void> saveDataInFSS(String value, String name) async {
    try {
      log("saving $name with value $value to FSS...");
      await _secureStorage.write(key: name, value: value);
      log("Data saved to FSS: $name");
    } catch (e) {
      logError("Error saving $name to FSS: $e");
    }
  }

  Future<String?> loadDataFromFSS(String name) async {
    log("Loading $name from FSS...");
    try {
      final data = await _secureStorage.read(key: name);
      if (data == null) {
        log("No data found for key: $name");
        return null;
      }
      return data;
    } catch (e) {
      logError("Error loading $name from FSS: $e");
      return null;
    }
  }
}
