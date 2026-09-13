/// An identifier, and the scheme that says who issues it.
///
/// The standard puts the scheme in an attribute next to the value rather than
/// in the value, and a profile usually decides which schemes it accepts. A
/// VAT number is not one of these: it is a plain string on its own term.
final class Identifier {
  /// The identifier [value], optionally issued under [scheme].
  const Identifier(this.value, {this.scheme});

  /// The identifier itself.
  final String value;

  /// The identifier of the scheme the value belongs to.
  ///
  /// Which list the scheme is drawn from depends on the term: an ISO 6523 ICD
  /// for a party identifier, an EAS code for an electronic address, a UNTDID
  /// code for an item classification.
  final String? scheme;

  @override
  String toString() => scheme == null ? value : '$scheme:$value';

  @override
  bool operator ==(Object other) =>
      other is Identifier && other.value == value && other.scheme == scheme;

  @override
  int get hashCode => Object.hash(value, scheme);
}
