import 'package:decimal/decimal.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';

/// An amount the rule reads, and where it sits in the invoice.
typedef _Amount = (Decimal value, String? path);

/// One term whose amount is written with at most two decimals.
///
/// Every rule of the BR-DEC family says this about one term and nothing else,
/// so each is a row rather than a function of its own. The terms the family
/// leaves out are left out on purpose: a unit price (BT-146) or a quantity
/// (BT-129) may carry more decimals, and rounding them would change what is
/// being sold.
final class _DecimalTerm {
  const _DecimalTerm(this.id, this.term, this.read);

  /// The identifier the standard gives the rule.
  final String id;

  /// The business term the rule bears on.
  final String term;

  /// The amounts that term holds in an invoice.
  final List<_Amount> Function(Invoice invoice) read;

  /// Reports the amounts that cannot be written with two decimals.
  Iterable<RuleViolation> check(
    Invoice invoice,
    RuleDescriptor rule,
  ) sync* {
    for (final (value, path) in read(invoice)) {
      if (value.scale <= 2) continue;
      yield at(
        rule,
        'The $term is $value, which needs ${value.scale} decimals. An amount '
        'is written with at most two.',
        path,
      );
    }
  }
}

/// Reads one amount, when the invoice carries it.
List<_Amount> _one(Decimal? value) =>
    value == null ? const [] : [(value, null)];

/// Reads an amount off each document level allowance or charge of [kind].
List<_Amount> Function(Invoice) _documentEntries(
  AllowanceOrCharge kind,
  Decimal? Function(DocumentAllowanceCharge entry) read,
  String noun,
) {
  return (invoice) {
    final amounts = <_Amount>[];
    for (final (index, entry) in invoice.allowancesAndCharges.indexed) {
      if (entry.kind != kind) continue;
      final value = read(entry);
      if (value != null) amounts.add((value, 'document $noun $index'));
    }
    return amounts;
  };
}

/// Reads an amount off each line allowance or charge of [kind].
List<_Amount> Function(Invoice) _lineEntries(
  AllowanceOrCharge kind,
  Decimal? Function(LineAllowanceCharge entry) read,
  String noun,
) {
  return (invoice) {
    final amounts = <_Amount>[];
    for (final line in invoice.lines) {
      for (final (index, entry) in line.allowancesAndCharges.indexed) {
        if (entry.kind != kind) continue;
        final value = read(entry);
        if (value != null) {
          amounts.add((value, '${pathOf(line)}, $noun $index'));
        }
      }
    }
    return amounts;
  };
}

/// Every term the BR-DEC family holds to two decimals.
final List<_DecimalTerm> _terms = [
  _DecimalTerm(
    'BR-DEC-01',
    'document level allowance amount (BT-92)',
    _documentEntries(
      AllowanceOrCharge.allowance,
      (entry) => entry.amount,
      'allowance',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-02',
    'document level allowance base amount (BT-93)',
    _documentEntries(
      AllowanceOrCharge.allowance,
      (entry) => entry.baseAmount,
      'allowance',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-05',
    'document level charge amount (BT-99)',
    _documentEntries(
      AllowanceOrCharge.charge,
      (entry) => entry.amount,
      'charge',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-06',
    'document level charge base amount (BT-100)',
    _documentEntries(
      AllowanceOrCharge.charge,
      (entry) => entry.baseAmount,
      'charge',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-09',
    'sum of line net amounts (BT-106)',
    (invoice) => _one(invoice.totals.sumOfLineNetAmounts),
  ),
  _DecimalTerm(
    'BR-DEC-10',
    'sum of allowances on document level (BT-107)',
    (invoice) => _one(invoice.totals.sumOfAllowances),
  ),
  _DecimalTerm(
    'BR-DEC-11',
    'sum of charges on document level (BT-108)',
    (invoice) => _one(invoice.totals.sumOfCharges),
  ),
  _DecimalTerm(
    'BR-DEC-12',
    'total amount without VAT (BT-109)',
    (invoice) => _one(invoice.totals.totalWithoutVat),
  ),
  _DecimalTerm(
    'BR-DEC-13',
    'total VAT amount (BT-110)',
    (invoice) => _one(invoice.totals.totalVat),
  ),
  _DecimalTerm(
    'BR-DEC-14',
    'total amount with VAT (BT-112)',
    (invoice) => _one(invoice.totals.totalWithVat),
  ),
  _DecimalTerm(
    'BR-DEC-15',
    'total VAT amount in accounting currency (BT-111)',
    (invoice) => _one(invoice.totals.totalVatInAccountingCurrency),
  ),
  _DecimalTerm(
    'BR-DEC-16',
    'paid amount (BT-113)',
    (invoice) => _one(invoice.totals.paidAmount),
  ),
  _DecimalTerm(
    'BR-DEC-17',
    'rounding amount (BT-114)',
    (invoice) => _one(invoice.totals.roundingAmount),
  ),
  _DecimalTerm(
    'BR-DEC-18',
    'amount due for payment (BT-115)',
    (invoice) => _one(invoice.totals.amountDueForPayment),
  ),
  _DecimalTerm(
    'BR-DEC-19',
    'VAT category taxable amount (BT-116)',
    (invoice) => [
      for (final (index, entry) in invoice.vatBreakdown.indexed)
        (entry.taxableAmount, 'VAT breakdown $index'),
    ],
  ),
  _DecimalTerm(
    'BR-DEC-20',
    'VAT category tax amount (BT-117)',
    (invoice) => [
      for (final (index, entry) in invoice.vatBreakdown.indexed)
        (entry.taxAmount, 'VAT breakdown $index'),
    ],
  ),
  _DecimalTerm(
    'BR-DEC-23',
    'line net amount (BT-131)',
    (invoice) => [
      for (final line in invoice.lines) (line.netAmount, pathOf(line)),
    ],
  ),
  _DecimalTerm(
    'BR-DEC-24',
    'line allowance amount (BT-136)',
    _lineEntries(
      AllowanceOrCharge.allowance,
      (entry) => entry.amount,
      'allowance',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-25',
    'line allowance base amount (BT-137)',
    _lineEntries(
      AllowanceOrCharge.allowance,
      (entry) => entry.baseAmount,
      'allowance',
    ),
  ),
  _DecimalTerm(
    'BR-DEC-27',
    'line charge amount (BT-141)',
    _lineEntries(AllowanceOrCharge.charge, (entry) => entry.amount, 'charge'),
  ),
  _DecimalTerm(
    'BR-DEC-28',
    'line charge base amount (BT-142)',
    _lineEntries(
      AllowanceOrCharge.charge,
      (entry) => entry.baseAmount,
      'charge',
    ),
  ),
];

/// The rules of the BR-DEC family, which hold an amount to two decimals.
///
/// The model holds a `Decimal`, not the text an amount was written as, so
/// what is checked is whether the amount can be written with two decimals at
/// all. An amount that could be but was typed as `100.000` is the same amount
/// here, and the syntax package decides how many decimals to write.
final Map<String, RuleCheck> decimalRules = {
  for (final term in _terms) term.id: term.check,
};
