import 'package:decimal/decimal.dart';

import 'package:en16931/src/codes/vat_category.dart';

/// Whether an amount is taken off the invoice or added to it.
enum AllowanceOrCharge {
  /// Taken off. BG-20 at document level, BG-27 on a line.
  allowance,

  /// Added on. BG-21 at document level, BG-28 on a line.
  charge,
}

/// BG-20 and BG-21. An allowance or a charge that applies to the whole
/// invoice.
///
/// A document level allowance or charge carries its own VAT treatment,
/// because it lands in the VAT breakdown on its own.
final class DocumentAllowanceCharge {
  /// An allowance or a charge of [amount], taxed under [vatCategory].
  const DocumentAllowanceCharge({
    required this.kind,
    required this.amount,
    required this.vatCategory,
    this.vatRate,
    this.baseAmount,
    this.percentage,
    this.reason,
    this.reasonCode,
  });

  /// Whether the amount is taken off or added on.
  final AllowanceOrCharge kind;

  /// BT-92 or BT-99. The amount, written positive whichever way it goes.
  final Decimal amount;

  /// BT-95 or BT-102. The VAT category the amount falls under.
  final VatCategory vatCategory;

  /// BT-96 or BT-103. The VAT rate, as a percentage. Required unless the
  /// category is one that carries no rate.
  final Decimal? vatRate;

  /// BT-93 or BT-100. The amount [percentage] is taken of.
  final Decimal? baseAmount;

  /// BT-94 or BT-101. The percentage of [baseAmount] the amount comes to.
  final Decimal? percentage;

  /// BT-97 or BT-104. Why the allowance or charge applies, in words.
  final String? reason;

  /// BT-98 or BT-105. Why it applies, as a code from UNTDID 5189 for an
  /// allowance and UNTDID 7161 for a charge.
  final String? reasonCode;
}

/// BG-27 and BG-28. An allowance or a charge that applies to one line.
///
/// A line level allowance or charge has no VAT treatment of its own: it
/// follows the VAT of the line it sits on.
final class LineAllowanceCharge {
  /// An allowance or a charge of [amount] on the line.
  const LineAllowanceCharge({
    required this.kind,
    required this.amount,
    this.baseAmount,
    this.percentage,
    this.reason,
    this.reasonCode,
  });

  /// Whether the amount is taken off or added on.
  final AllowanceOrCharge kind;

  /// BT-136 or BT-141. The amount, written positive whichever way it goes.
  final Decimal amount;

  /// BT-137 or BT-142. The amount [percentage] is taken of.
  final Decimal? baseAmount;

  /// BT-138 or BT-143. The percentage of [baseAmount] the amount comes to.
  final Decimal? percentage;

  /// BT-139 or BT-144. Why the allowance or charge applies, in words.
  final String? reason;

  /// BT-140 or BT-145. Why it applies, as a code from UNTDID 5189 for an
  /// allowance and UNTDID 7161 for a charge.
  final String? reasonCode;
}
