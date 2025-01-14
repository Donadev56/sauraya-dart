import 'package:flutter/material.dart';

final CodeCustomTheme = {
  'root': TextStyle(
      backgroundColor: Color(0XFF212121), color: Colors.white, fontSize: 10),
  'title': TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
  'section': TextStyle(color: Colors.amber),

  'keyword': TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
  'selector-tag': TextStyle(color: Colors.lightBlueAccent),
  'attribute': TextStyle(color: Colors.orangeAccent),
  'literal': TextStyle(color: Colors.purpleAccent),
  'built_in': TextStyle(color: const Color.fromARGB(255, 70, 224, 255)),
  'type': TextStyle(color: Colors.yellowAccent),
  'variable': TextStyle(color: Colors.tealAccent),
  'template-variable': TextStyle(color: Colors.indigoAccent),
  'addition': TextStyle(color: Colors.lightGreen),
  'deletion': TextStyle(color: Colors.redAccent),

  'string': TextStyle(color: const Color.fromARGB(255, 0, 189, 91)),
  'comment': TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Colors.lightGreenAccent),
  'regexp': TextStyle(color: Colors.greenAccent),
  'symbol': TextStyle(color: Colors.cyan),

  'function': TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
  'class': TextStyle(color: Colors.limeAccent, fontStyle: FontStyle.italic),
  'meta': TextStyle(color: Colors.blueGrey),
  'tag': TextStyle(color: Colors.deepPurpleAccent),
  'name': TextStyle(color: Colors.deepOrangeAccent),
  'title.function':
      TextStyle(color: Colors.yellow, fontWeight: FontWeight.w600),

  'number': TextStyle(color: Colors.purple),
  'constant': TextStyle(color: Colors.redAccent),
  'unit': TextStyle(color: Colors.lightBlue),

  'operator': TextStyle(color: Colors.amberAccent),
  'punctuation': TextStyle(color: Colors.white),

  'selector-attr': TextStyle(color: Colors.blueGrey),
  'selector-id': TextStyle(color: Colors.lightBlueAccent),
  'selector-class': TextStyle(color: Colors.cyan),

  'error': TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  'warning': TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),

  'markup': TextStyle(color: Colors.orange),
  'attribute-value': TextStyle(color: Colors.lightGreen),
  'entity': TextStyle(color: Colors.deepOrangeAccent),

  'strong': TextStyle(fontWeight: FontWeight.bold),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'bold': TextStyle(fontWeight: FontWeight.bold),
  'italic': TextStyle(fontStyle: FontStyle.italic),
  'title.class':
      TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),

  'link': TextStyle(
      color: Colors.blue, decoration: TextDecoration.underline), // Hyperliens
  'header':
      TextStyle(color: Colors.green, fontWeight: FontWeight.bold), // En-têtes
  'parameter': TextStyle(color: Colors.orange), // Paramètres
  'whitespace':
      TextStyle(backgroundColor: Colors.grey), // Espaces blancs visibles
  'boolean': TextStyle(
      color: Colors.pinkAccent,
      fontWeight: FontWeight.bold), // Valeurs booléennes
  'property': TextStyle(color: Colors.lightBlueAccent), // Propriétés
  'namespace': TextStyle(color: Colors.deepPurpleAccent), // Espaces de noms

  'json-key':
      TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
  'json-string': TextStyle(color: Colors.greenAccent),

  'markdown-header': TextStyle(color: Colors.lime, fontWeight: FontWeight.bold),
  'markdown-link':
      TextStyle(color: Colors.cyan, decoration: TextDecoration.underline),
};

const VsCode = {
  'root': TextStyle(
      backgroundColor: Colors.transparent,
      color: Color.fromARGB(233, 220, 220, 220),
      fontSize: 10),
  'keyword': TextStyle(
    color: Color(0xff569CD6),
  ),
  'literal': TextStyle(color: Color(0xff569CD6)),
  'symbol': TextStyle(color: Color(0xff569CD6)),
  'name': TextStyle(color: Color(0xff569CD6)),
  'link': TextStyle(color: Color(0xff569CD6)),
  'built_in': TextStyle(color: Color(0xff4EC9B0)),
  'type': TextStyle(color: Color(0xff4EC9B0)),
  'number': TextStyle(color: Color(0xffB8D7A3)),
  'class': TextStyle(color: Color(0xffB8D7A3)),
  'string': TextStyle(color: Color.fromARGB(255, 255, 157, 115)),
  'meta-string': TextStyle(color: Color(0xffD69D85)),
  'regexp': TextStyle(color: Color.fromARGB(255, 0, 255, 132)),
  'template-tag': TextStyle(color: Color(0xff9A5334)),
  'subst': TextStyle(color: Color.fromARGB(255, 255, 151, 103)),
  'function': TextStyle(color: Color(0XFFdcdcaa)),
  'title': TextStyle(color: Color(0XFFdcdcaa)),
  'params': TextStyle(color: Color(0XFF94D1F0)),
  'formula': TextStyle(color: Color(0xffDCDCDC)),
  'comment': TextStyle(
      color: Color.fromARGB(55, 255, 255, 255), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xff57A64A), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xff608B4E)),
  'meta': TextStyle(color: Color(0xff569CD6)),
  'meta-keyword': TextStyle(color: Color(0xff569CD6)),
  'tag': TextStyle(color: Color(0xff9B9B9B)),
  'variable': TextStyle(color: Color(0xffBD63C5)),
  'template-variable': TextStyle(color: Color(0xffBD63C5)),
  'attr': TextStyle(color: Color(0xff9CDCFE)),
  'attribute': TextStyle(color: Color(0xff9CDCFE)),
  'builtin-name': TextStyle(color: Color(0xff9CDCFE)),
  'section': TextStyle(color: Color(0xffffd700)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'bullet': TextStyle(color: Color(0xffD7BA7D)),
  'selector-tag': TextStyle(color: Color(0xffD7BA7D)),
  'selector-id': TextStyle(color: Color(0xffD7BA7D)),
  'selector-class': TextStyle(color: Color(0xffD7BA7D)),
  'selector-attr': TextStyle(color: Color(0xffD7BA7D)),
  'selector-pseudo': TextStyle(color: Color(0xffD7BA7D)),
  'addition': TextStyle(backgroundColor: Color(0xff144212)),
  'deletion': TextStyle(backgroundColor: Color(0xff660000)),
};
