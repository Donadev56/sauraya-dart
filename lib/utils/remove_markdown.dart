import 'dart:core';
import 'package:remove_markdown/remove_markdown.dart';

String removeMarkdown(String markdown) {
  return markdown.removeMarkdown();
}

String removeEmojis(String textWithEmojis) {
  // Remove emojis using regex
  String result = textWithEmojis.replaceAll(
      RegExp(r'(?:\p{Emoji}(?:\p{Emoji_Modifier}|\uFE0F)?(?:\u200D\p{Emoji})*)',
          unicode: true),
      '');
  return result;
}
