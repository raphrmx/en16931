import 'package:decimal/decimal.dart';
import 'package:en16931/src/codes/vat_category.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/line.dart';
import 'package:en16931/src/model/totals.dart';
import 'package:en16931/src/model/vat_breakdown.dart';
import 'package:en16931/src/types/amount.dart';

/// A pair of category and rate, which is what the VAT breakdown is made of.
typedef _Bracket = (VatCategory category, Decimal? rate);

/// The VAT breakdown [lines] and [entries] add up to.
///
/// One entry comes out per pair of category and rate, which is what the
/// standard asks for. The VAT of a category that charges none is zero, and
/// [exemptionReasons] gives the reason those categories have to state.
///
/// {@category invoice}
List<VatBreakdown> deriveBreakdown({
  required List<InvoiceLine> lines,
  required List<DocumentAllowanceCharge> entries,
  Map<VatCategory, String> exemptionReasons = const {},
}) {
  final taxable = <_Bracket, Decimal>{};

  void add(_Bracket bracket, Decimal amount) {
    taxable[bracket] = (taxable[bracket] ?? Decimal.zero) + amount;
  }

  for (final line in lines) {
    add((line.vatCategory, line.vatRate), line.netAmount);
  }
  for (final entry in entries) {
    final bracket = (entry.vatCategory, entry.vatRate);
    add(
      bracket,
      entry.kind == AllowanceOrCharge.charge ? entry.amount : -entry.amount,
    );
  }

  final breakdown = <VatBreakdown>[];
  for (final bracket in taxable.keys) {
    final (category, rate) = bracket;
    final amount = round2(taxable[bracket]!);
    final charges = _chargesVat(category);
    final tax = charges && rate != null
        ? round2(
            amount *
                (rate / Decimal.fromInt(100)).toDecimal(
                  scaleOnInfinitePrecision: 20,
                ),
          )
        : Decimal.zero;
    breakdown.add(
      VatBreakdown(
        category: category,
        rate: rate,
        taxableAmount: amount,
        taxAmount: tax,
        exemptionReason: charges ? null : exemptionReasons[category],
      ),
    );
  }
  return breakdown;
}

/// Whether a category actually charges VAT, or only reports a base.
bool _chargesVat(VatCategory category) => switch (category) {
      VatCategory.standardRate ||
      VatCategory.canaryIslands ||
      VatCategory.ceutaAndMelilla ||
      VatCategory.transferred =>
        true,
      VatCategory.zeroRated ||
      VatCategory.exempt ||
      VatCategory.reverseCharge ||
      VatCategory.intraCommunitySupply ||
      VatCategory.exportOutsideEu ||
      VatCategory.outsideScope =>
        false,
    };

/// The totals [lines], [entries] and [breakdown] add up to.
///
/// {@category invoice}
InvoiceTotals deriveTotals({
  required List<InvoiceLine> lines,
  required List<DocumentAllowanceCharge> entries,
  required List<VatBreakdown> breakdown,
  Decimal? paidAmount,
  Decimal? roundingAmount,
}) {
  Decimal sum(Iterable<Decimal> amounts) =>
      amounts.fold(Decimal.zero, (total, amount) => total + amount);

  final lineTotal = round2(sum(lines.map((line) => line.netAmount)));
  final allowances = entries.where(
    (entry) => entry.kind == AllowanceOrCharge.allowance,
  );
  final charges = entries.where(
    (entry) => entry.kind == AllowanceOrCharge.charge,
  );
  final allowanceTotal = allowances.isEmpty
      ? null
      : round2(sum(allowances.map((entry) => entry.amount)));
  final chargeTotal = charges.isEmpty
      ? null
      : round2(sum(charges.map((entry) => entry.amount)));

  final withoutVat = round2(
    lineTotal -
        (allowanceTotal ?? Decimal.zero) +
        (chargeTotal ?? Decimal.zero),
  );
  final vat = round2(sum(breakdown.map((entry) => entry.taxAmount)));
  final withVat = round2(withoutVat + vat);
  final due = round2(
    withVat - (paidAmount ?? Decimal.zero) + (roundingAmount ?? Decimal.zero),
  );

  return InvoiceTotals(
    sumOfLineNetAmounts: lineTotal,
    sumOfAllowances: allowanceTotal,
    sumOfCharges: chargeTotal,
    totalWithoutVat: withoutVat,
    totalVat: vat,
    totalWithVat: withVat,
    paidAmount: paidAmount,
    roundingAmount: roundingAmount,
    amountDueForPayment: due,
  );
}
