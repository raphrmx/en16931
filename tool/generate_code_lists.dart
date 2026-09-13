// Reads the code lists the BR-CL rules check against, and writes them out.
//
// The lists themselves are not the standard's work: the country codes come
// from ISO 3166-1, the currencies from ISO 4217, the units from UN/ECE
// Recommendations 20 and 21, the rest from UNTDID and from the code lists the
// European Commission publishes. The validation artefacts copy them into
// their tests, and this reads the codes back out. Codes are facts, and no
// text or expression of the artefacts is written into the generated file.
//
// Usage:
//   dart run tool/generate_code_lists.dart
import 'dart:io';

import 'package:xml/xml.dart';

const String _artefacts = 'artefacts/ubl.sch';
const String _output = 'lib/src/codes/lists.g.dart';

/// What each rule checks against, and what this package calls that list.
///
/// Several rules share a list, and the names are what a reader of the
/// standard would call them rather than the rule that happens to come first.
/// This is the part no artefact can tell us: the rules name a list in prose,
/// so the mapping is stated here by hand.
const Map<String, String> _lists = {
  'BR-CL-01': 'untdid1001DocumentTypes',
  'BR-CL-03': 'iso4217Currencies',
  'BR-CL-04': 'iso4217Currencies',
  'BR-CL-05': 'iso4217Currencies',
  'BR-CL-06': 'untdid2005VatPointDateCodes',
  'BR-CL-07': 'untdid1153ReferenceQualifiers',
  'BR-CL-08': 'untdid4451NoteSubjects',
  'BR-CL-10': 'iso6523Icd',
  'BR-CL-11': 'iso6523Icd',
  'BR-CL-13': 'untdid7143ClassificationSchemes',
  'BR-CL-14': 'iso3166Countries',
  'BR-CL-15': 'iso3166Countries',
  'BR-CL-16': 'untdid4461PaymentMeans',
  'BR-CL-17': 'uncl5305VatCategories',
  'BR-CL-18': 'uncl5305VatCategories',
  'BR-CL-19': 'uncl5189AllowanceReasons',
  'BR-CL-20': 'untdid7161ChargeReasons',
  'BR-CL-21': 'iso6523Icd',
  'BR-CL-22': 'vatexExemptionReasons',
  'BR-CL-23': 'unece20UnitCodes',
  'BR-CL-24': 'attachmentMimeTypes',
  'BR-CL-25': 'cefEasSchemes',
  'BR-CL-26': 'iso6523Icd',
};

/// What each list is, for the reader of the generated file.
const Map<String, String> _descriptions = {
  'untdid1001DocumentTypes':
      'UNTDID 1001, narrowed to the invoice and credit note codes.',
  'iso4217Currencies': 'ISO 4217 alpha-3 currency codes.',
  'untdid2005VatPointDateCodes':
      'UNTDID 2005, narrowed to the three codes that say when VAT falls due.',
  'untdid1153ReferenceQualifiers': 'UNTDID 1153 reference qualifiers.',
  'untdid4451NoteSubjects': 'UNTDID 4451 note subject codes.',
  'iso6523Icd': 'ISO 6523 ICD, the schemes an organisation identifier is '
      'issued under.',
  'untdid7143ClassificationSchemes': 'UNTDID 7143 item classification '
      'schemes.',
  'iso3166Countries': 'ISO 3166-1 alpha-2 country codes.',
  'untdid4461PaymentMeans': 'UNTDID 4461 payment means codes.',
  'uncl5305VatCategories': 'UNCL 5305 VAT category codes.',
  'uncl5189AllowanceReasons': 'UNCL 5189 allowance reason codes.',
  'untdid7161ChargeReasons': 'UNTDID 7161 charge reason codes.',
  'vatexExemptionReasons':
      'The VATEX list of VAT exemption reasons, published by the European '
          'Commission.',
  'unece20UnitCodes':
      'UN/ECE Recommendation 20 units of measure, with the Recommendation 21 '
          'extension.',
  'attachmentMimeTypes':
      'The media types an attachment may carry, which the standard narrows to '
          'six.',
  'cefEasSchemes':
      'The EAS list of electronic address schemes, published by the European '
          'Commission.',
};

void main() {
  final file = File(_artefacts);
  if (!file.existsSync()) {
    stderr.writeln('Missing ${file.path}. Run generate_catalogue --fetch.');
    exitCode = 1;
    return;
  }

  final document = XmlDocument.parse(file.readAsStringSync());
  final byName = <String, Set<String>>{};
  final sources = <String, String>{};
  final found = <String>{};

  for (final assertion in document.findAllElements('assert')) {
    final id = assertion.getAttribute('id');
    if (id == null) continue;
    final name = _lists[id];
    if (name == null) continue;
    found.add(id);

    final codes = _codes(assertion.getAttribute('test') ?? '');
    if (codes.isEmpty) {
      stderr.writeln('$id carries no code list.');
      exitCode = 1;
      return;
    }

    final known = byName[name];
    if (known == null) {
      byName[name] = codes;
      sources[name] = id;
      continue;
    }
    // Two rules said to share a list have to hold the same codes. When they
    // do not, the mapping above is wrong and the file would be a guess.
    if (!_same(known, codes)) {
      stderr.writeln(
        '$id and ${sources[name]} are both mapped to $name but hold '
        'different codes: ${known.length} against ${codes.length}.',
      );
      exitCode = 1;
      return;
    }
  }

  final missing = _lists.keys.toSet().difference(found);
  if (missing.isNotEmpty) {
    stderr.writeln('No assertion found for ${missing.join(', ')}.');
    exitCode = 1;
    return;
  }

  File(_output).writeAsStringSync(_emit(byName));
  stdout.writeln('${byName.length} lists written to $_output');
  final names = byName.keys.toList()..sort();
  for (final name in names) {
    stdout.writeln('  $name: ${byName[name]!.length}');
  }
}

/// The codes a Schematron test checks membership of.
///
/// A test either carries the list as one string of space separated codes, or
/// compares the value to each code in turn. Both forms appear.
Set<String> _codes(String test) {
  final literals = RegExp("'([^']*)'")
      .allMatches(test)
      .map((match) => match.group(1)!)
      .toList();

  // The list form: every literal that is a run of space separated codes,
  // wrapped in the spaces the test needs to match whole words.
  //
  // A test can carry more than one, because one rule can cover more than one
  // document: BR-CL-01 holds the invoice codes in one branch and the credit
  // note codes in another, and an invoice type code is valid if either branch
  // accepts it. Taking only the longer of the two loses 381.
  final codes = <String>{};
  for (final literal in literals) {
    if (!literal.startsWith(' ') || !literal.endsWith(' ')) continue;
    final tokens = literal.trim().split(RegExp(r'\s+'));
    if (tokens.length < 2) continue;
    codes.addAll(tokens);
  }
  if (codes.isNotEmpty) return codes;

  // The comparison form: everything the value is allowed to equal.
  return RegExp("=\\s*'([^']+)'")
      .allMatches(test)
      .map((match) => match.group(1)!)
      .toSet();
}

bool _same(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

String _emit(Map<String, Set<String>> lists) {
  final buffer = StringBuffer()
    ..writeln('// GENERATED by tool/generate_code_lists.dart. Do not edit.')
    ..writeln('//')
    ..writeln('// The codes come from the lists the standard points at, which')
    ..writeln('// ISO, the UNECE and the European Commission publish. They')
    ..writeln('// were read out of the EN 16931 validation artefacts, none of')
    ..writeln('// whose text or expression is reproduced here.')
    ..writeln();

  final names = lists.keys.toList()..sort();
  for (final name in names) {
    final codes = lists[name]!.toList()..sort();
    final description = _descriptions[name] ?? 'A code list.';
    buffer
      ..writeln('/// $description')
      ..writeln('///')
      ..writeln('/// ${codes.length} codes.')
      ..writeln('const Set<String> $name = {');
    for (final code in codes) {
      buffer.writeln("  '$code',");
    }
    buffer
      ..writeln('};')
      ..writeln();
  }

  buffer
    ..writeln('/// The list each code list rule checks against.')
    ..writeln('const Map<String, Set<String>> codeListByRule = {');
  final rules = _lists.keys.toList()..sort();
  for (final rule in rules) {
    buffer.writeln("  '$rule': ${_lists[rule]},");
  }
  buffer.writeln('};');
  return buffer.toString();
}
