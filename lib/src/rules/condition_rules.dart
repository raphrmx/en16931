import 'package:decimal/decimal.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';

/// The rules of the BR-CO family, which say what has to follow from what.
///
/// These are the rules that catch an invoice that does not add up, and they
/// are the ones a receiver rejects most often. What each compares is stated
/// here against the semantic model.
const Map<String, RuleCheck> conditionRules = {
  'BR-CO-03': _brCo03,
  'BR-CO-09': _brCo09,
  'BR-CO-10': _brCo10,
  'BR-CO-11': _brCo11,
  'BR-CO-12': _brCo12,
  'BR-CO-13': _brCo13,
  'BR-CO-14': _brCo14,
  'BR-CO-15': _brCo15,
  'BR-CO-16': _brCo16,
  'BR-CO-17': _brCo17,
  'BR-CO-18': _brCo18,
  'BR-CO-19': _brCo19,
  'BR-CO-20': _brCo20,
  'BR-CO-21': _brCo21,
  'BR-CO-22': _brCo22,
  'BR-CO-23': _brCo23,
  'BR-CO-24': _brCo24,
  'BR-CO-26': _brCo26,
};

/// The rules of the BR-CO family met before the invoice exists.
const Map<String, String> conditionSatisfiedByConstruction = {
  'BR-CO-04': 'InvoiceLine.vatCategory is required.',
};

/// The rules of the BR-CO family no program can decide.
///
/// Each of these asks whether a code and the words next to it say the same
/// thing, which takes a reader. The published artefacts do not decide them
/// either: their test is `true()`, so they pass whatever the invoice says.
/// Reporting them as checked would be a claim this library cannot back.
const Map<String, String> conditionNotMachineCheckable = {
  'BR-CO-05':
      'Whether the document level allowance reason (BT-97) and its code '
          '(BT-98) mean the same thing.',
  'BR-CO-06': 'Whether the document level charge reason (BT-104) and its code '
      '(BT-105) mean the same thing.',
  'BR-CO-07':
      'Whether the line allowance reason (BT-139) and its code (BT-140) mean '
          'the same thing.',
  'BR-CO-08':
      'Whether the line charge reason (BT-144) and its code (BT-145) mean the '
          'same thing.',
};

// --- Dates and identifiers -------------------------------------------------

Iterable<RuleViolation> _brCo03(Invoice invoice, RuleDescriptor rule) sync* {
  if (invoice.vatPointDate != null && !blank(invoice.vatPointDateCode)) {
    yield at(
      rule,
      'The VAT point date (BT-7) and the VAT point date code (BT-8) are both '
      'set. The day VAT becomes due is either a date or a rule, not both.',
    );
  }
}

Iterable<RuleViolation> _brCo09(Invoice invoice, RuleDescriptor rule) sync* {
  final identifiers = {
    'BT-31': invoice.seller.vatIdentifier,
    'BT-48': invoice.buyer.vatIdentifier,
    'BT-63': invoice.taxRepresentative?.vatIdentifier,
  };
  for (final entry in identifiers.entries) {
    final value = entry.value;
    if (blank(value)) continue;
    if (_countryPrefix.hasMatch(value!.trim())) continue;
    yield at(
      rule,
      'The VAT identifier (${entry.key}) does not start with a country '
      'prefix. It carries "$value".',
    );
  }
}

/// Two letters, which is what a country prefix looks like.
///
/// Whether those two letters name a country is BR-CL-14's business. Greece
/// issues VAT identifiers under EL rather than its ISO code GR, and both pass
/// here for the same reason.
final RegExp _countryPrefix = RegExp('^[A-Za-z]{2}');

Iterable<RuleViolation> _brCo26(Invoice invoice, RuleDescriptor rule) sync* {
  final seller = invoice.seller;
  final identified = seller.identifiers.isNotEmpty ||
      seller.legalRegistrationIdentifier != null ||
      !blank(seller.vatIdentifier);
  if (!identified) {
    yield at(
      rule,
      'The seller carries no identifier (BT-29), legal registration '
      'identifier (BT-30) or VAT identifier (BT-31), so the buyer cannot '
      'match the invoice to a supplier on its own.',
    );
  }
}

// --- The totals ------------------------------------------------------------

Iterable<RuleViolation> _brCo10(Invoice invoice, RuleDescriptor rule) sync* {
  yield* expectTotal(
    rule: rule,
    actual: invoice.totals.sumOfLineNetAmounts,
    expected: sum(invoice.lines.map((line) => line.netAmount)),
    term: 'sum of line net amounts (BT-106)',
    formula: 'the sum of the lines (BT-131)',
  );
}

Iterable<RuleViolation> _brCo11(Invoice invoice, RuleDescriptor rule) sync* {
  yield* _documentTotal(
    invoice,
    rule,
    AllowanceOrCharge.allowance,
    invoice.totals.sumOfAllowances,
    'sum of allowances (BT-107)',
    'the document level allowances (BT-92)',
  );
}

Iterable<RuleViolation> _brCo12(Invoice invoice, RuleDescriptor rule) sync* {
  yield* _documentTotal(
    invoice,
    rule,
    AllowanceOrCharge.charge,
    invoice.totals.sumOfCharges,
    'sum of charges (BT-108)',
    'the document level charges (BT-99)',
  );
}

/// BT-107 and BT-108 read the same way: the total is the sum, and leaving the
/// total out is only allowed when there is nothing to sum.
Iterable<RuleViolation> _documentTotal(
  Invoice invoice,
  RuleDescriptor rule,
  AllowanceOrCharge kind,
  Decimal? total,
  String term,
  String formula,
) sync* {
  final entries = invoice.allowancesAndCharges.where(
    (entry) => entry.kind == kind,
  );
  if (total == null) {
    if (entries.isEmpty) return;
    yield at(
      rule,
      'The $term is missing while the invoice carries '
      '${entries.length} of them.',
    );
    return;
  }
  yield* expectTotal(
    rule: rule,
    actual: total,
    expected: sum(entries.map((entry) => entry.amount)),
    term: term,
    formula: formula,
  );
}

Iterable<RuleViolation> _brCo13(Invoice invoice, RuleDescriptor rule) sync* {
  final totals = invoice.totals;
  yield* expectTotal(
    rule: rule,
    actual: totals.totalWithoutVat,
    expected: totals.sumOfLineNetAmounts -
        (totals.sumOfAllowances ?? zero) +
        (totals.sumOfCharges ?? zero),
    term: 'total without VAT (BT-109)',
    formula: 'BT-106 less BT-107 plus BT-108',
  );
}

Iterable<RuleViolation> _brCo14(Invoice invoice, RuleDescriptor rule) sync* {
  final total = invoice.totals.totalVat;
  if (total == null) return;
  yield* expectTotal(
    rule: rule,
    actual: total,
    expected: sum(invoice.vatBreakdown.map((entry) => entry.taxAmount)),
    term: 'total VAT amount (BT-110)',
    formula: 'the VAT breakdown (BT-117)',
  );
}

Iterable<RuleViolation> _brCo15(Invoice invoice, RuleDescriptor rule) sync* {
  final totals = invoice.totals;
  yield* expectTotal(
    rule: rule,
    actual: totals.totalWithVat,
    expected: totals.totalWithoutVat + (totals.totalVat ?? zero),
    term: 'total with VAT (BT-112)',
    formula: 'BT-109 plus BT-110',
  );
}

Iterable<RuleViolation> _brCo16(Invoice invoice, RuleDescriptor rule) sync* {
  final totals = invoice.totals;
  yield* expectTotal(
    rule: rule,
    actual: totals.amountDueForPayment,
    expected: totals.totalWithVat -
        (totals.paidAmount ?? zero) +
        (totals.roundingAmount ?? zero),
    term: 'amount due for payment (BT-115)',
    formula: 'BT-112 less BT-113 plus BT-114',
  );
}

Iterable<RuleViolation> _brCo17(Invoice invoice, RuleDescriptor rule) sync* {
  for (final (index, entry) in invoice.vatBreakdown.indexed) {
    final rate = entry.rate;
    final path = 'VAT breakdown $index';

    // A rate that rounds to zero asks for a tax amount that rounds to zero,
    // and so does a breakdown with no rate at all.
    if (rate == null || rate.round() == zero) {
      if (entry.taxAmount.round() != zero) {
        yield at(
          rule,
          'The VAT category rate (BT-119) is ${rate ?? 'absent'}, so the VAT '
          'category tax amount (BT-117) should round to zero. It is '
          '${entry.taxAmount}.',
          path,
        );
      }
      continue;
    }

    // The artefacts allow anything within one unit of currency here, not one
    // cent: an invoice rounding line by line lands a few cents away from an
    // invoice rounding once, and both are accepted.
    final expected = round2(
      entry.taxableAmount.abs() *
          (rate / Decimal.fromInt(100)).toDecimal(
            scaleOnInfinitePrecision: 20,
          ),
    );
    final declared = entry.taxAmount.abs();
    if (declared - Decimal.one < expected &&
        declared + Decimal.one > expected) {
      continue;
    }
    yield at(
      rule,
      'The VAT category tax amount (BT-117) is ${entry.taxAmount} where '
      '${entry.taxableAmount} at $rate% comes to $expected.',
      path,
    );
  }
}

Iterable<RuleViolation> _brCo18(Invoice invoice, RuleDescriptor rule) sync* {
  if (invoice.vatBreakdown.isEmpty) {
    yield at(
      rule,
      'The invoice carries no VAT breakdown (BG-23). Every invoice states how '
      'its VAT is made up, including one that owes none.',
    );
  }
}

// --- Groups that have to carry something -----------------------------------

Iterable<RuleViolation> _brCo19(Invoice invoice, RuleDescriptor rule) sync* {
  final period = invoice.invoicingPeriod;
  if (period == null) return;
  if (period.start == null && period.end == null) {
    yield at(
      rule,
      'The invoicing period (BG-14) carries neither a start date (BT-73) nor '
      'an end date (BT-74).',
    );
  }
}

Iterable<RuleViolation> _brCo20(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    final period = line.period;
    if (period == null) continue;
    if (period.start == null && period.end == null) {
      yield at(
        rule,
        'The line period (BG-26) carries neither a start date (BT-134) nor an '
        'end date (BT-135).',
        pathOf(line),
      );
    }
  }
}

// BR-CO-21 to BR-CO-24 say what BR-33, BR-38, BR-42 and BR-44 say. Both
// identifiers are published, so both are reported: a receiver quoting one of
// them should find it in the result.

Iterable<RuleViolation> _brCo21(Invoice invoice, RuleDescriptor rule) sync* {
  yield* documentReason(invoice, rule, AllowanceOrCharge.allowance, 'BT-97',
      'BT-98', 'allowance');
}

Iterable<RuleViolation> _brCo22(Invoice invoice, RuleDescriptor rule) sync* {
  yield* documentReason(
      invoice, rule, AllowanceOrCharge.charge, 'BT-104', 'BT-105', 'charge');
}

Iterable<RuleViolation> _brCo23(Invoice invoice, RuleDescriptor rule) sync* {
  yield* lineReason(invoice, rule, AllowanceOrCharge.allowance, 'BT-139',
      'BT-140', 'allowance');
}

Iterable<RuleViolation> _brCo24(Invoice invoice, RuleDescriptor rule) sync* {
  yield* lineReason(
      invoice, rule, AllowanceOrCharge.charge, 'BT-144', 'BT-145', 'charge');
}
