/// A value drawn from a published code list.
///
/// The lists the standard points at are long and they are revised without the
/// standard being revised, so a code is held as the string it is rather than
/// as a closed set. The subclasses name the codes that come up, and any other
/// code from the same list can be written out by hand.
abstract base class CodeValue {
  /// Holds [value] as it appears in the list.
  const CodeValue(this.value);

  /// The code itself.
  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is CodeValue &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}
