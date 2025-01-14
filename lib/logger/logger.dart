import 'package:logger/logger.dart';

final logger = Logger(); // Initialize the logger

// normal log : logger.i(message);
void log(String message) {
  logger.i(message);
}

// error log : logger.e(message);
void logError(String message) {
  logger.e(message);
}
