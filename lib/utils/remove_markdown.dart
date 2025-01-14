String removeMarkdown(String markdown) {
  // Replace bold text with plain text
  markdown = markdown.replaceAll(RegExp(r'\*\*(.+?)\*\*'), '');
  markdown = markdown.replaceAll(RegExp('__(.+?)__'), '');

  // Replace italicized text with plain text
  markdown = markdown.replaceAll(RegExp('_(.+?)_'), '');
  markdown = markdown.replaceAll(RegExp(r'\*(.+?)\*'), '');

  // Replace strikethrough text with plain text
  markdown = markdown.replaceAll(RegExp('~~(.+?)~~'), '');

  // Replace inline code blocks with plain text
  markdown = markdown.replaceAll(RegExp('`(.+?)`'), '');

  // Replace code blocks with plain text
  markdown =
      markdown.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');
  markdown =
      markdown.replaceAll(RegExp(r'```[\s\S]*?```', multiLine: true), '');

  // Remove links
  markdown = markdown.replaceAll(RegExp(r'\[(.+?)\]\((.+?)\)'), '');

  // Remove images
  markdown = markdown.replaceAll(RegExp(r'!\[(.+?)\]\((.+?)\)'), '');

  // Remove headings
  markdown =
      markdown.replaceAll(RegExp(r'^#+\s+(.+?)\s*$', multiLine: true), '');
  markdown = markdown.replaceAll(RegExp(r'^\s*=+\s*$', multiLine: true), '');
  markdown = markdown.replaceAll(RegExp(r'^\s*-+\s*$', multiLine: true), '');

  // Remove blockquotes
  markdown =
      markdown.replaceAll(RegExp(r'^\s*>\s+(.+?)\s*$', multiLine: true), '');

  // Remove lists
  markdown = markdown.replaceAll(
    RegExp(r'^\s*[\*\+-]\s+(.+?)\s*$', multiLine: true),
    '',
  );
  markdown = markdown.replaceAll(
    RegExp(r'^\s*\d+\.\s+(.+?)\s*$', multiLine: true),
    '',
  );

  // Remove horizontal lines
  markdown =
      markdown.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');

  return markdown;
}
