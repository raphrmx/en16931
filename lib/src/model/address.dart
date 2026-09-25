/// A postal address. BG-5, BG-8, BG-12 and BG-15 all carry this shape.
///
/// Only the country is always required. The rest is what the parties need to
/// find each other, and a profile may ask for more.
///
/// {@category invoice}
final class Address {
  /// An address in [country], the rest being what is known of it.
  const Address({
    required this.country,
    this.line1,
    this.line2,
    this.line3,
    this.city,
    this.postalCode,
    this.countrySubdivision,
  });

  /// BT-40, BT-55, BT-69 or BT-80. The country, as an ISO 3166-1 alpha-2
  /// code.
  final String country;

  /// BT-35, BT-50, BT-64 or BT-75. The main address line, usually the street
  /// and number.
  final String? line1;

  /// BT-36, BT-51, BT-65 or BT-76. A second address line.
  final String? line2;

  /// BT-162, BT-163, BT-164 or BT-165. A third address line.
  final String? line3;

  /// BT-37, BT-52, BT-66 or BT-77. The city or town.
  final String? city;

  /// BT-38, BT-53, BT-67 or BT-78. The postal code, written as the postal
  /// service of the country writes it.
  final String? postalCode;

  /// BT-39, BT-54, BT-68 or BT-79. The region, province or state, in words
  /// rather than as a code.
  final String? countrySubdivision;
}
