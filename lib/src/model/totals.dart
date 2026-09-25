import 'package:decimal/decimal.dart';

/// BG-22. The totals of the invoice.
///
/// Every one of these is arrived at by a rule the standard states, and the
/// rules are checked rather than assumed: an invoice whose totals do not
/// follow from its lines is rejected by the receiver, not corrected.
///
/// {@category invoice}
final class InvoiceTotals {
  /// The totals, of which four are always required.
  const InvoiceTotals({
    required this.sumOfLineNetAmounts,
    required this.totalWithoutVat,
    required this.totalWithVat,
    required this.amountDueForPayment,
    this.sumOfAllowances,
    this.sumOfCharges,
    this.totalVat,
    this.totalVatInAccountingCurrency,
    this.paidAmount,
    this.roundingAmount,
  });

  /// BT-106. The sum of BT-131 over every line.
  final Decimal sumOfLineNetAmounts;

  /// BT-109. BT-106 less BT-107 plus BT-108.
  final Decimal totalWithoutVat;

  /// BT-112. BT-109 plus BT-110.
  final Decimal totalWithVat;

  /// BT-115. BT-112 less BT-113 plus BT-114.
  final Decimal amountDueForPayment;

  /// BT-107. The sum of the document level allowances.
  final Decimal? sumOfAllowances;

  /// BT-108. The sum of the document level charges.
  final Decimal? sumOfCharges;

  /// BT-110. The sum of BT-117 over the VAT breakdown.
  final Decimal? totalVat;

  /// BT-111. BT-110 converted into the VAT accounting currency. Required as
  /// soon as BT-6 is given.
  final Decimal? totalVatInAccountingCurrency;

  /// BT-113. What has already been paid.
  final Decimal? paidAmount;

  /// BT-114. What was added or taken off to round the amount due.
  final Decimal? roundingAmount;
}
