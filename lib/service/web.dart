import 'package:flutter/foundation.dart';
import 'package:sauraya/logger/logger.dart';
//import 'dart:html';

bool saveToWebStorage(String key, String encryptedData) {
  try {
    if (kIsWeb) {
      // window.localStorage[key] = encryptedData;
      return true;
    }
    logError("The platfrom is not the web");
    return false;
  } catch (e) {
    logError("An error occurred while saving data in the web $e");
    return false;
  }
}

String getWebStorageData(String key) {
  try {
    if (kIsWeb) {
      //    return window.localStorage[key] ?? "";
    }
    logError("The platfrom is not the web");
    return "";
  } catch (e) {
    logError("An error occurred while getting data from the web $e");
    return "";
  }
}
