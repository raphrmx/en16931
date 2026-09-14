// Reads the EN 16931 validation artefacts and writes the rule catalogue.
//
// The artefacts are published by CEN/TC 434 through the European Commission
// at https://github.com/ConnectingEurope/eInvoicing-EN16931 under the EUPL
// 1.2, which this package does not redistribute and cannot inherit from. Only
// facts are taken out of them: which rules exist, what each is called, how
// severe it is, and which business terms it bears on. No text and no
// expression of the artefacts is written into the generated file, and the
// meaning of every rule is implemented by hand against the semantic model.
//
// Usage:
//   dart run tool/generate_catalogue.dart --fetch
//   dart run tool/generate_catalogue.dart
import 'dart:io';

import 'package:xml/xml.dart';

/// The release the artefacts are read from.
///
/// A tag rather than a branch, so that generating the catalogue twice gives
/// the same catalogue twice. The CEN revises the artefacts several times a
/// year, and reading from a moving branch leaves the package saying which
/// rules it covers without being able to say against what.
///
/// Raising this is a deliberate act: bump it, regenerate, and read what the
/// diff says before committing it.
const String artefactRelease = 'validation-1.3.16';

const String _base =
    'https://raw.githubusercontent.com/ConnectingEurope/eInvoicing-EN16931';

const String _ublUrl = '$_base/$artefactRelease/ubl/schematron/preprocessed/'
    'EN16931-UBL-validation-preprocessed.sch';
const String _ciiUrl = '$_base/$artefactRelease/cii/schematron/preprocessed/'
    'EN16931-CII-validation-preprocessed.sch';

const String _artefactsDirectory = 'artefacts';
const String _output = 'lib/src/rules/catalogue.g.dart';

/// A rule as the artefacts describe it, before anything is written out.
class _Rule {
  _Rule(this.id, this.severity, this.terms);

  final String id;
  final String severity;
  final List<String> terms;
  final Set<String> syntaxes = {};
}

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--fetch')) {
    await _fetch(_ublUrl, '$_artefactsDirectory/ubl.sch');
    await _fetch(_ciiUrl, '$_artefactsDirectory/cii.sch');
  }

  final ubl = File('$_artefactsDirectory/ubl.sch');
  final cii = File('$_artefactsDirectory/cii.sch');
  for (final file in [ubl, cii]) {
    if (file.existsSync()) continue;
    stderr.writeln(
      'Missing ${file.path}. Run with --fetch to download the artefacts.',
    );
    exitCode = 1;
    return;
  }

  final rules = <String, _Rule>{};
  final versions = <String>{};
  for (final entry in {'UBL': ubl, 'CII': cii}.entries) {
    final source = entry.value.readAsStringSync();
    final version = _version(source);
    if (version != null) versions.add(version);
    for (final rule in _read(source)) {
      final known = rules.putIfAbsent(rule.id, () => rule);
      known.syntaxes.add(entry.key);
      if (known.terms.isEmpty && rule.terms.isNotEmpty) {
        known.terms.addAll(rule.terms);
      }
    }
  }

  final catalogue = rules.values.toList()
    ..sort((a, b) => _compareIdentifiers(a.id, b.id));

  File(_output).writeAsStringSync(_emit(catalogue, versions));

  // The emitted lists run past the column the formatter wraps at, so what is
  // written and what is committed would differ by a reflow. Formatting here
  // keeps them the same file, which is what lets the build compare them.
  final formatted = Process.runSync('dart', ['format', _output]);
  if (formatted.exitCode != 0) {
    stderr.writeln('dart format failed: ${formatted.stderr}');
    exitCode = 1;
    return;
  }

  stdout.writeln('${catalogue.length} rules written to $_output');
  stdout.writeln('  artefacts ${versions.join(', ')}');
  final counts = <String, int>{};
  for (final rule in catalogue) {
    final family = _family(rule.id);
    counts[family] = (counts[family] ?? 0) + 1;
  }
  final families = counts.keys.toList()..sort();
  for (final family in families) {
    stdout.writeln('  $family: ${counts[family]}');
  }
  final oneSided = catalogue.where((r) => r.syntaxes.length == 1).toList();
  if (oneSided.isNotEmpty) {
    stdout.writeln(
      '  ${oneSided.length} bound to one syntax: '
      '${oneSided.map((r) => '${r.id} (${r.syntaxes.single})').join(', ')}',
    );
  }
}

Future<void> _fetch(String url, String target) async {
  Directory(_artefactsDirectory).createSync(recursive: true);
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('${response.statusCode} for $url');
    }
    final sink = File(target).openWrite();
    await response.pipe(sink);
    stdout.writeln('Fetched $target');
  } finally {
    client.close();
  }
}

/// The version the artefacts announce in their leading comment.
String? _version(String source) {
  final match = RegExp(
    r'Schematron version ([0-9.]+) - Last update: (\d{4}-\d{2}-\d{2})',
  ).firstMatch(source);
  if (match == null) return null;
  return '${match.group(1)} of ${match.group(2)}';
}

/// Every business rule one artefact file asserts.
///
/// The syntax bound rules, UBL-CR and the like, are left out: they say how one
/// serialisation has to be written, which is the business of a syntax package.
/// What stays is the rules the standard itself defines.
Iterable<_Rule> _read(String source) sync* {
  final document = XmlDocument.parse(source);
  for (final assertion in document.findAllElements('assert')) {
    final id = assertion.getAttribute('id');
    if (id == null || !id.startsWith('BR-')) continue;
    final severity =
        assertion.getAttribute('flag') == 'warning' ? 'warning' : 'fatal';
    yield _Rule(id, severity, _terms(assertion.innerText));
  }
}

/// The business terms and groups a rule bears on, in the order they appear.
///
/// The identifiers are read out of the message and the message is dropped.
List<String> _terms(String message) {
  final found = <String>[];
  final pattern = RegExp(r'\b(?:BT|BG)-\d+(?:-\d+)?\b');
  for (final match in pattern.allMatches(message)) {
    final term = match.group(0)!;
    if (!found.contains(term)) found.add(term);
  }
  return found;
}

String _family(String id) {
  final match = RegExp(r'^(BR(?:-[A-Z]+)?)-\d+$').firstMatch(id);
  return match?.group(1) ?? id;
}

/// Orders identifiers the way a reader does, so BR-2 comes before BR-10.
int _compareIdentifiers(String a, String b) {
  final familyOrder = _family(a).compareTo(_family(b));
  if (familyOrder != 0) return familyOrder;
  return _number(a).compareTo(_number(b));
}

int _number(String id) {
  final match = RegExp(r'(\d+)$').firstMatch(id);
  return match == null ? 0 : int.parse(match.group(1)!);
}

String _emit(List<_Rule> rules, Set<String> versions) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED by tool/generate_catalogue.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// Read from the EN 16931 validation artefacts, version')
    ..writeln(
      '// ${versions.join(' and ')}. The artefacts are EUPL 1.2 and',
    )
    ..writeln(
      '// none of their content is reproduced here: what is taken is',
    )
    ..writeln(
      '// which rules exist, how severe each is, and which business',
    )
    ..writeln('// terms it bears on.')
    ..writeln()
    ..writeln("import 'package:en16931/src/rules/rule.dart';")
    ..writeln()
    ..writeln('/// The release of the artefacts the catalogue was read from.')
    ..writeln('///')
    ..writeln('/// A receiver rejecting an invoice names the rule it rejected')
    ..writeln('/// on. This says which revision of the rules that identifier')
    ..writeln('/// was read from, so the two can be lined up.')
    ..writeln("const String en16931ArtefactRelease = '$artefactRelease';")
    ..writeln()
    ..writeln('/// Every business rule EN 16931 defines.')
    ..writeln('///')
    ..writeln(
      '/// The list is read from the published validation artefacts,',
    )
    ..writeln(
      '/// so it is complete by construction rather than by memory.',
    )
    ..writeln('const List<RuleDescriptor> ruleCatalogue = [');
  for (final rule in rules) {
    final family = _dartFamily(_family(rule.id));
    final terms = rule.terms.map((term) => "'$term'").join(', ');
    buffer
      ..writeln('  RuleDescriptor(')
      ..writeln("    id: '${rule.id}',")
      ..writeln('    family: RuleFamily.$family,')
      ..writeln('    severity: RuleSeverity.${rule.severity},')
      ..writeln('    terms: [$terms],')
      ..writeln('  ),');
  }
  buffer.writeln('];');
  return buffer.toString();
}

const Map<String, String> _families = {
  'BR': 'presence',
  'BR-CO': 'condition',
  'BR-CL': 'codeList',
  'BR-DEC': 'decimals',
  'BR-S': 'vatStandardRate',
  'BR-Z': 'vatZeroRated',
  'BR-E': 'vatExempt',
  'BR-AE': 'vatReverseCharge',
  'BR-IC': 'vatIntraCommunity',
  'BR-G': 'vatExport',
  'BR-O': 'vatOutsideScope',
  'BR-AF': 'vatCanaryIslands',
  'BR-AG': 'vatCeutaAndMelilla',
  'BR-B': 'vatCategoryMix',
};

String _dartFamily(String prefix) {
  final name = _families[prefix];
  if (name == null) {
    throw StateError('No family for $prefix. Add it to RuleFamily first.');
  }
  return name;
}
