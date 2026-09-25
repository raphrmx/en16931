import 'package:decimal/decimal.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/model/line.dart';
import 'package:en16931/src/rules/rule.dart';

/// Checks one rule against an invoice and reports what it finds.
///
/// {@category validation}
typedef RuleCheck = Iterable<RuleViolation> Function(
    Invoice invoice, RuleDescriptor rule);

/// Whether a term is absent, which includes a value that is only spaces.
///
/// The standard reads an empty element as an absent term, so the model does
/// the same rather than counting an empty string as a value.
bool blank(String? value) => value == null || value.trim().isEmpty;

/// Where a violation was found, when it was found on a line.
String pathOf(InvoiceLine line) => 'line ${line.id}';

/// A violation of [rule].
RuleViolation at(RuleDescriptor rule, String message, [String? path]) =>
    RuleViolation(rule: rule, message: message, path: path);

/// Zero, for a term the standard reads as zero when it is absent.
final Decimal zero = Decimal.zero;

/// The sum of [amounts], or zero when there are none.
Decimal sum(Iterable<Decimal> amounts) =>
    amounts.fold(zero, (total, amount) => total + amount);

/// [value] rounded to the two decimals an amount is written with.
///
/// The artefacts round with XPath, which rounds a half away from zero for a
/// positive number and towards zero for a negative one. Dart rounds a half
/// away from zero either way, so a credit note whose half cent falls exactly
/// on the boundary can differ. It takes an amount ending in exactly half a
/// cent to see it.
Decimal round2(Decimal value) => value.round(scale: 2);

/// Whether [left] and [right] are the same amount once both are rounded.
bool sameAmount(Decimal left, Decimal right) => round2(left) == round2(right);

/// Reports the sum a total is supposed to be when it is not.
Iterable<RuleViolation> expectTotal({
  required RuleDescriptor rule,
  required Decimal actual,
  required Decimal expected,
  required String term,
  required String formula,
}) sync* {
  if (sameAmount(actual, expected)) return;
  yield at(
    rule,
    'The $term is ${round2(actual)} where $formula comes to '
    '${round2(expected)}.',
  );
}

/// Reports a document level allowance or charge that gives no reason.
///
/// The standard states this twice, once in the BR family and once in BR-CO,
/// so both call this and report under their own identifier.
///
/// {@category validation}
Iterable<RuleViolation> documentReason(
  Invoice invoice,
  RuleDescriptor rule,
  AllowanceOrCharge kind,
  String reasonTerm,
  String codeTerm,
  String noun,
) sync* {
  for (final (index, entry) in invoice.allowancesAndCharges.indexed) {
    if (entry.kind != kind) continue;
    if (blank(entry.reason) && blank(entry.reasonCode)) {
      yield at(
        rule,
        'The document level $noun needs a reason ($reasonTerm) or a reason '
            'code ($codeTerm).',
        'document $noun $index',
      );
    }
  }
}

/// Reports a line allowance or charge that gives no reason.
Iterable<RuleViolation> lineReason(
  Invoice invoice,
  RuleDescriptor rule,
  AllowanceOrCharge kind,
  String reasonTerm,
  String codeTerm,
  String noun,
) sync* {
  for (final line in invoice.lines) {
    for (final (index, entry) in line.allowancesAndCharges.indexed) {
      if (entry.kind != kind) continue;
      if (blank(entry.reason) && blank(entry.reasonCode)) {
        yield at(
          rule,
          'The line $noun needs a reason ($reasonTerm) or a reason code '
              '($codeTerm).',
          '${pathOf(line)}, $noun $index',
        );
      }
    }
  }
}

/// Whether [declared] is close enough to [expected] for the standard.
///
/// The artefacts allow anything within one unit of currency wherever an
/// amount is arrived at by applying a rate or by summing lines. It is not a
/// cent: an invoice that rounds line by line lands a few cents away from one
/// that rounds once, and both are accepted.
///
/// {@category validation}
bool withinOneUnit(Decimal declared, Decimal expected) =>
    declared - Decimal.one < expected && declared + Decimal.one > expected;
