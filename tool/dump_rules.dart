// Prints what the artefacts say about one family of rules, to read while
// implementing it.
//
// This is a development aid: it reads the EUPL licensed artefacts from the
// working copy and prints them to the terminal. Nothing it prints is copied
// into the package, which states each rule in its own words.
//
// Usage:
//   dart run tool/dump_rules.dart BR-CO
import 'dart:io';

import 'package:xml/xml.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln('Usage: dart run tool/dump_rules.dart <family>');
    exitCode = 1;
    return;
  }
  final family = arguments.first;
  final file = File('artefacts/ubl.sch');
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}. Run generate_catalogue --fetch.');
    exitCode = 1;
    return;
  }

  final document = XmlDocument.parse(file.readAsStringSync());
  final seen = <String>{};
  for (final assertion in document.findAllElements('assert')) {
    final id = assertion.getAttribute('id');
    if (id == null || !id.startsWith('$family-')) continue;
    if (!seen.add(id)) continue;
    final flag = assertion.getAttribute('flag');
    stdout.writeln('$id [$flag] ${assertion.innerText.trim()}');
    if (arguments.contains('--test')) {
      stdout.writeln('    test: ${assertion.getAttribute('test')}');
    }
  }
  stdout.writeln('${seen.length} rules in $family');
}
