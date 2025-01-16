import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:sauraya/logger/logger.dart';

class LocalStorageService {
  Future<String?> getBasePath() async {
    try {
      if (Platform.isAndroid) {
        bool permissionStatus = await checkPermission();

        if (!permissionStatus) {
          logError("Permission denied for accessing external storage");
          return null;
        }
      }

      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        final mediaDir = Directory(
            '${externalDir!.path.split("Android")[0]}Android/media/com.sauraya');

        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
          log('Media directory created for Android: ${mediaDir.path}');
        }

        return mediaDir.path;
      } else if (Platform.isIOS) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final mediaDir = Directory('${documentsDir.path}/media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
          log('Media directory created for iOS: ${mediaDir.path}');
        }
        return mediaDir.path;
      } else if (Platform.isLinux || Platform.isMacOS) {
        final homeDir = Directory(Platform.environment['HOME']!);
        final mediaDir = Directory('${homeDir.path}/.Sauraya/media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
          log('Media directory created for ${Platform.operatingSystem}: ${mediaDir.path}');
        }
        return mediaDir.path;
      } else if (Platform.isWindows) {
        final appDataDir = Directory(Platform.environment['APPDATA']!);
        final mediaDir = Directory('${appDataDir.path}\\Sauraya\\Media');
        if (!await mediaDir.exists()) {
          await mediaDir.create(recursive: true);
          log('Media directory created for Windows: ${mediaDir.path}');
        }
        return mediaDir.path;
      } else {
        throw UnsupportedError('Platform not supported');
      }
    } catch (e) {
      logError('Error getting base path: $e');
      rethrow;
    }
  }

  Future<bool> createSubdirectory(String subDirectoryName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError('Permission denied for accessing external storage');
        return false;
      }
      log("current base path is $basePath");
      final newDirectory = Directory('$basePath/$subDirectoryName');
      if (!await newDirectory.exists()) {
        await newDirectory.create(recursive: true);
        log('Subdirectory created successfully: ${newDirectory.path}');
        return true;
      } else {
        log('Directory already exists: ${newDirectory.path}');
        return false;
      }
    } catch (e) {
      logError('Error creating subdirectory: $e');
      return false;
    }
  }

  Future<bool> isDirectoryExists(Directory directory) async {
    return await directory.exists();
  }

  Future<String?> saveStringData(
      String customDir, String dataToStored, String fileName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return null;
      }
      final newDir = Directory('$basePath/$customDir');
      if (!await isDirectoryExists(newDir)) {
        log("Creating directory $customDir");
        await createSubdirectory(customDir);
      }
      final file = File('${newDir.path}/$fileName');
      await file.writeAsString(dataToStored);
      log('Data saved successfully: ${file.path}');
      return file.path;
    } catch (e) {
      logError('Error saving string data: $e');
      return null;
    }
  }

  Future<String?> saveBytesData(
      String customDir, List<int> dataToStored, String fileName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return null;
      }
      final newDir = Directory('$basePath/$customDir');
      if (!await isDirectoryExists(newDir)) {
        log("Creating directory $customDir");
        await createSubdirectory(customDir);
      }
      final file = File('${newDir.path}/$fileName');
      await file.writeAsBytes(dataToStored);
      log('Data saved successfully: ${file.path}');
      return file.path;
    } catch (e) {
      logError('Error saving bytes data: $e');
      return null;
    }
  }

  Future<String?> getStringData(String customDir, String fileName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return null;
      }
      final filePath = '$basePath/$customDir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        final data = await file.readAsString();
        log('Data retrieved successfully: $filePath');
        return data;
      } else {
        log('File does not exist: $filePath');
        return null;
      }
    } catch (e) {
      logError('Error retrieving string data: $e');
      return null;
    }
  }

  Future<List<int>> getBytesData(String customDir, String fileName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return [];
      }
      final filePath = '$basePath/$customDir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        final data = await file.readAsBytes();
        log('Data retrieved successfully: $filePath');
        return data;
      } else {
        log('File does not exist: $filePath');
        return [];
      }
    } catch (e) {
      logError('Error retrieving bytes data: $e');
      return [];
    }
  }

  Future<bool> deleteFile(String customDir, String fileName) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return false;
      }
      final filePath = '$basePath/$customDir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        log('File deleted successfully: $filePath');
        return true;
      } else {
        log('File does not exist: $filePath');
        return false;
      }
    } catch (e) {
      logError('Error deleting file: $e');
      return false;
    }
  }

  /// Supprime un répertoire
  Future<bool> deleteDirectory(String customDir) async {
    try {
      final basePath = await getBasePath();
      if (basePath == null) {
        logError("Permission denied for accessing external storage");
        return false;
      }
      final directory = Directory('$basePath/$customDir');
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        log("Directory deleted successfully: $customDir");
        return true;
      } else {
        log("Directory does not exist: $customDir");
        return false;
      }
    } catch (e) {
      logError("Error deleting directory: $e");
      return false;
    }
  }

  Future<bool> checkPermission() async {
    try {
      if (!Platform.isAndroid) {
        return true;
      }
      final status = await Permission.manageExternalStorage.status;
      log("Initial storage permission status: $status");

      if (status == PermissionStatus.denied) {
        log("Requesting storage permission...");
        try {
          final result = await Permission.manageExternalStorage.request();
          log("Storage permission status after request: $result");

          if (!result.isGranted) {
            log("Permission denied after request. Redirecting to app settings...");
            await openAppSettings();
          }
          return result.isGranted;
        } catch (e) {
          logError("Error requesting permission: $e");
          return false;
        }
      } else if (status == PermissionStatus.permanentlyDenied) {
        log("Storage permission permanently denied. Redirecting to settings...");

        // try to ask for permission
        final result = await Permission.manageExternalStorage.request();
        if (result.isGranted) {
          log("Storage permission granted after permanently denied request.");
          return true;
        }
        log("Permission denied after permanently denied request. Redirecting to app settings...");
        await openAppSettings();
        return false;
      } else if (status == PermissionStatus.granted) {
        log("Permission already granted.");
        return true;
      } else {
        log("Unexpected permission status: $status");
        return false;
      }
    } catch (e) {
      logError("Error checking permission: $e");
      return false;
    }
  }
}
