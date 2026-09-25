import 'package:decimal/decimal.dart';

import 'package:en16931/src/codes/vat_category.dart';

/// BG-23. One line of the VAT breakdown.
///
/// There is exactly one of these per pair of category and rate found on the
/// invoice, lines and document level allowances and charges together. This is
/// the part the tax authority reads, and the part most invoices get wrong.
///
/// {@category invoice}
final class VatBreakdown {
  /// The [taxableAmount] taxed under [category] at [rate], coming to
  /// [taxAmount].
  const VatBreakdown({
    required this.category,
    required this.taxableAmount,
    required this.taxAmount,
    this.rate,
    this.exemptionReason,
    this.exemptionReasonCode,
  });

  /// BT-118. The VAT category this line of the breakdown covers.
  final VatCategory category;

  /// BT-116. The sum of every amount taxed under this category and rate,
  /// before VAT.
  final Decimal taxableAmount;

  /// BT-117. The VAT due on [taxableAmount].
  final Decimal taxAmount;

  /// BT-119. The rate, as a percentage. Left out only for a category that
  /// carries no rate.
  final Decimal? rate;

  /// BT-120. Why no VAT is due, in words. Required for every category other
  /// than standard rate and zero rated.
  final String? exemptionReason;

  /// BT-121. Why no VAT is due, as a code from the VATEX list.
  final String? exemptionReasonCode;
}
