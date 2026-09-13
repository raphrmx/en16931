import 'package:decimal/decimal.dart';
import 'package:en16931/src/codes/unit_code.dart';
import 'package:en16931/src/codes/vat_category.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/item.dart';
import 'package:en16931/src/model/references.dart';
import 'package:en16931/src/types/amount.dart';
import 'package:en16931/src/types/identifier.dart';

/// BG-25. One line of the invoice.
final class InvoiceLine {
  /// A line numbered [id], selling [quantity] of [item] for [netAmount].
  const InvoiceLine({
    required this.id,
    required this.quantity,
    required this.unit,
    required this.netAmount,
    required this.item,
    required this.price,
    required this.vatCategory,
    this.vatRate,
    this.note,
    this.objectIdentifier,
    this.buyerOrderLineReference,
    this.buyerAccountingReference,
    this.period,
    this.allowancesAndCharges = const [],
  });

  /// A line selling [quantity] of [item] at [unitPrice].
  ///
  /// The net amount is worked out here and rounded to two decimals, its own
  /// allowances and charges included, so no amount has to be added up by
  /// hand. Pass the numbers as they are written on the order: a `num` in the
  /// source is read back exactly as it was typed.
  factory InvoiceLine.of({
    required String id,
    required Item item,
    required num quantity,
    required num unitPrice,
    num? vatRate,
    UnitCode unit = UnitCode.one,
    VatCategory vatCategory = VatCategory.standardRate,
    String? note,
    Identifier? objectIdentifier,
    String? buyerOrderLineReference,
    String? buyerAccountingReference,
    DatePeriod? period,
    List<LineAllowanceCharge> allowancesAndCharges = const [],
  }) {
    final gross = round2(exact(quantity) * exact(unitPrice));
    final net = allowancesAndCharges.fold(gross, (total, entry) {
      return entry.kind == AllowanceOrCharge.charge
          ? total + entry.amount
          : total - entry.amount;
    });
    return InvoiceLine(
      id: id,
      quantity: exact(quantity),
      unit: unit,
      netAmount: round2(net),
      item: item,
      price: Price(netPrice: exact(unitPrice)),
      vatCategory: vatCategory,
      vatRate: vatRate == null ? null : exact(vatRate),
      note: note,
      objectIdentifier: objectIdentifier,
      buyerOrderLineReference: buyerOrderLineReference,
      buyerAccountingReference: buyerAccountingReference,
      period: period,
      allowancesAndCharges: allowancesAndCharges,
    );
  }

  /// BT-126. The identifier of the line, unique inside the invoice.
  final String id;

  /// BT-129. How much is being sold. Negative on a line that takes something
  /// back.
  final Decimal quantity;

  /// BT-130. The unit [quantity] is counted in.
  final UnitCode unit;

  /// BT-131. What the line comes to, before VAT and after its own allowances
  /// and charges.
  final Decimal netAmount;

  /// BG-31. What is being sold.
  final Item item;

  /// BG-29. What it costs.
  final Price price;

  /// BT-151. The VAT category the line falls under.
  final VatCategory vatCategory;

  /// BT-152. The VAT rate, as a percentage. Left out only for a category that
  /// carries no rate.
  final Decimal? vatRate;

  /// BT-127. A free text note about the line.
  final String? note;

  /// BT-128. An identifier of the object the line is about, under the scheme
  /// that issues it.
  final Identifier? objectIdentifier;

  /// BT-132. Which line of the buyer's order this answers.
  final String? buyerOrderLineReference;

  /// BT-133. Where the buyer books the line.
  final String? buyerAccountingReference;

  /// BG-26. When the supply on this line happened.
  final DatePeriod? period;

  /// BG-27 and BG-28. What is taken off or added on to this line.
  final List<LineAllowanceCharge> allowancesAndCharges;
}

/// BG-29. What one item costs.
///
/// The net price is the price after any discount, and it is the one the line
/// amount is worked out from. The gross price and the discount are there to
/// show how the net price was arrived at.
final class Price {
  /// A net price of [netPrice], for [baseQuantity] of the item.
  const Price({
    required this.netPrice,
    this.discount,
    this.grossPrice,
    this.baseQuantity,
    this.baseQuantityUnit,
  });

  /// BT-146. What one unit costs, after any discount and without VAT.
  final Decimal netPrice;

  /// BT-147. What was taken off the gross price to get the net price.
  final Decimal? discount;

  /// BT-148. What one unit costs before the discount.
  final Decimal? grossPrice;

  /// BT-149. How many units [netPrice] is the price of. One when left out.
  final Decimal? baseQuantity;

  /// BT-150. The unit [baseQuantity] is counted in.
  final UnitCode? baseQuantityUnit;
}
