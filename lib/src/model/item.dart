import 'package:en16931/src/types/identifier.dart';

/// BG-31. What is being sold on a line.
///
/// {@category invoice}
final class Item {
  /// An item called [name].
  const Item({
    required this.name,
    this.description,
    this.sellerIdentifier,
    this.buyerIdentifier,
    this.standardIdentifier,
    this.classificationIdentifiers = const [],
    this.originCountry,
    this.attributes = const [],
  });

  /// BT-153. What the item is called. This is what a person reads.
  final String name;

  /// BT-154. What the item is, at length.
  final String? description;

  /// BT-155. The identifier the seller knows the item by.
  final String? sellerIdentifier;

  /// BT-156. The identifier the buyer knows the item by.
  final String? buyerIdentifier;

  /// BT-157. The identifier the item carries under a registered scheme, a
  /// GTIN for instance.
  final Identifier? standardIdentifier;

  /// BT-158. Where the item sits in a classification, each under the scheme
  /// that defines it.
  final List<Identifier> classificationIdentifiers;

  /// BT-159. Where the item comes from, as an ISO 3166-1 alpha-2 code.
  final String? originCountry;

  /// BG-32. Anything else about the item, as name and value.
  final List<ItemAttribute> attributes;
}

/// BG-32. One property of an item, as a name and a value.
///
/// {@category invoice}
final class ItemAttribute {
  /// The attribute called [name], whose value is [value].
  const ItemAttribute(this.name, this.value);

  /// BT-160. What the property is called.
  final String name;

  /// BT-161. What the property is, as text. There is no unit and no type:
  /// put them in the value.
  final String value;
}
