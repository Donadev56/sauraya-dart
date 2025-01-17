import 'package:flutter/material.dart';

import 'package:flutter_highlight/themes/dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:markdown_widget/widget/all.dart';

class MarkdownCustomStyle {
  static MarkdownStyleSheet get customStyle {
    return MarkdownStyleSheet(
      
      h1: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic),
      h2: TextStyle(
          color: const Color.fromARGB(227, 255, 255, 255),
          fontSize: 30,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic),
      h3: TextStyle(
        color: const Color.fromARGB(227, 255, 255, 255),
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      h4: TextStyle(
          color: const Color.fromARGB(227, 255, 255, 255),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic),
      h5: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      h6: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      p: const TextStyle(
        color: Color.fromARGB(237, 255, 255, 255),
        fontSize: 15,
      ),
      strong: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 255, 255, 255),
          letterSpacing: 1.05),
      em: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color.fromARGB(255, 255, 255, 255),
      ),
      listBullet: TextStyle(
        color: Colors.grey[300],
        fontSize: 14,
      ),
      blockquote: TextStyle(
        color: Colors.grey[200],
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 2.0,
            color: Colors.grey,
          ),
        ),
      ),
      a: const TextStyle(
        color: Color.fromARGB(255, 8, 177, 255),
        decoration: TextDecoration.underline,
      ),
      code: TextStyle(
        color: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: 'Courier',
        fontSize: 13,
      ),
      blockSpacing: 10.0,
      blockquoteDecoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 18, 18),
        borderRadius: BorderRadius.circular(4.0),
        border: Border(
          left: BorderSide(
            color: const Color.fromARGB(192, 145, 145, 145),
            width: 4.0,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      codeblockPadding: const EdgeInsets.all(8.0),
      codeblockDecoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4.0),
      ),
      tableHead: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white70,
      ),
      tableBody: const TextStyle(
        color: Colors.white70,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 6.0,
        vertical: 4.0,
      ),
      tableBorder: TableBorder.all(
        color: Colors.white54,
        width: 1.0,
      ),
    );
  }
}

final MarkdownBlockStyle = [
  H1Config(
    style: TextStyle(
      fontSize: 32,
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      height: 1.4,
    ),
  ),
  H2Config(
    style: TextStyle(
      fontSize: 28,
      color: const Color.fromARGB(209, 255, 255, 255),
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
  ),
  H3Config(
    style: TextStyle(
      fontSize: 24,
      color: const Color.fromARGB(221, 255, 255, 255),
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  ),
  H4Config(
    style: TextStyle(
      fontSize: 20,
      color: Colors.white54,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  ),
  H5Config(
    style: TextStyle(
      fontSize: 18,
      color: Colors.white70,
      fontWeight: FontWeight.w400,
      height: 1.2,
    ),
  ),
  H6Config(
    style: TextStyle(
      fontSize: 16,
      color: Colors.white70,
      fontWeight: FontWeight.w400,
      height: 1.2,
    ),
  ),
  PConfig(
    textStyle: TextStyle(
      fontSize: 16,
      color: const Color.fromARGB(213, 255, 255, 255),
      height: 1.6,
    ),
  ),
  BlockquoteConfig(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    textColor: Colors.white60,
  ),
  CodeConfig(
    style: TextStyle(
      fontFamily: 'Courier',
      fontSize: 14,
      color: Colors.greenAccent,
      height: 1.5,
    ),
  ),
  LinkConfig(
    style: TextStyle(
      fontSize: 16,
      color: Colors.lightBlueAccent,
      decoration: TextDecoration.underline,
    ),
  ),
  TableConfig(
    columnWidths: {
      0: FlexColumnWidth(1), // Première colonne prend deux fois plus de place
      1: FlexColumnWidth(1), // Deuxième colonne prend une unité d'espace
      2: FlexColumnWidth(1), // Troisième colonne prend une unité d'espace
      3: FlexColumnWidth(1)
    },
    defaultColumnWidth: IntrinsicColumnWidth(),
    textDirection: TextDirection.ltr,
    border: TableBorder.all(color: Colors.white30, width: 1.0),
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    headerRowDecoration: BoxDecoration(
      color: Colors.transparent,
    ),
    bodyRowDecoration: BoxDecoration(
      color: Colors.transparent,
    ),
    headPadding: EdgeInsets.fromLTRB(8, 4, 8, 4),
    bodyPadding: EdgeInsets.fromLTRB(8, 4, 8, 4),
    headerStyle: TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    bodyStyle: TextStyle(
      fontSize: 13.5,
      color: Colors.white70,
    ),
  ),
  HrConfig(
    color: Colors.white30,
  ),
  CheckBoxConfig(
    builder: (isChecked) {
      return Icon(
        isChecked ? Icons.check_box : Icons.check_box_outline_blank,
        color: isChecked ? Colors.grey : Colors.white,
      );
    },
  ),
  ListConfig(
    marginLeft: 32.0,
    marginBottom: 4.0,
    marker: (isOrdered, index, level) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Text(
          isOrdered ? "$index." : "•",
          style: TextStyle(
            fontSize: 16,
            color: const Color.fromARGB(199, 255, 255, 255),
          ),
        ),
      );
    },
  ),
  PreConfig(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xff1e1e1e), // Couleur personnalisée pour un fond sombre
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      language: 'dart',
      theme: darkTheme),
];
