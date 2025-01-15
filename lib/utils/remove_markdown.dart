import 'dart:core';

String removeMarkdown(String markdown) {
  // Remove headers (e.g., # Header, ## Subheader)
  String result = markdown.replaceAll(RegExp(r'(^|\n)#+\s+'), '\n');

  // Remove links [text](url) and [text](url "title")
  result = result.replaceAll(RegExp(r'\[.*?\]\(.*?(\s+".*?")?\)'), '');

  // Remove images ![alt text](url)
  result = result.replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '');

  // Remove inline code `code`
  result = result.replaceAll(RegExp(r'`.*?`'), '');

  // Remove code blocks ```code``` and indented code blocks
  result = result.replaceAll(RegExp(r'```[\s\S]*?```'), '');
  result = result.replaceAll(RegExp(r'(\n|^) {4}.*'), '');

  // Remove bold, italic, and strikethrough (**text**, *text*, ~~text~~)
  result = result.replaceAll(RegExp(r'(\*\*|\*|~~)(.*?)\1'), '');

  // Remove blockquotes > text
  result = result.replaceAll(RegExp(r'(^|\n)>\s+.*'), '');

  // Remove lists (e.g., - Item, * Item, 1. Item)
  result = result.replaceAll(RegExp(r'(^|\n)([-*]|\d+\.)\s+'), '\n');

  // Remove horizontal rules (---, ***, etc.)
  result = result.replaceAll(RegExp(r'(^|\n)(---|\*\*\*|___)(\n|$)'), '\n');

  // Remove tables | Header | and rows
  result = result.replaceAll(RegExp(r'(^|\n)\|.*?\|'), '\n');

  // Remove any leftover special characters
  result = result.replaceAll(RegExp(r'[\*_`>\[\](){}#+\-|~]'), '');

  // Trim extra whitespace
  result = result.trim();

  return result;
}

String removeEmojis(String textWithEmojis) {
  // Remove emojis using regex
  String result = textWithEmojis.replaceAll(
      RegExp(r'(?:\p{Emoji}(?:\p{Emoji_Modifier}|\uFE0F)?(?:\u200D\p{Emoji})*)',
          unicode: true),
      '');
  return result;
}
