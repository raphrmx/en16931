import 'package:en16931/src/codes/code_value.dart';

/// BT-130 and BT-150. The unit a quantity is counted in, from UN/ECE
/// Recommendation 20 and its Recommendation 21 extension.
///
/// The list runs to several thousand entries. The ones named here are the
/// handful that carry most invoice lines.
final class UnitCode extends CodeValue {
  /// Holds [value] as it appears in UN/ECE Recommendation 20.
  const UnitCode(super.value);

  /// C62. A count of items, when no other unit applies.
  static const UnitCode one = UnitCode('C62');

  /// H87. A count of pieces.
  static const UnitCode piece = UnitCode('H87');

  /// DAY. Days.
  static const UnitCode day = UnitCode('DAY');

  /// HUR. Hours.
  static const UnitCode hour = UnitCode('HUR');

  /// KGM. Kilograms.
  static const UnitCode kilogram = UnitCode('KGM');

  /// LTR. Litres.
  static const UnitCode litre = UnitCode('LTR');

  /// MTR. Metres.
  static const UnitCode metre = UnitCode('MTR');

  /// MTK. Square metres.
  static const UnitCode squareMetre = UnitCode('MTK');

  /// MTQ. Cubic metres.
  static const UnitCode cubicMetre = UnitCode('MTQ');

  /// KWH. Kilowatt hours.
  static const UnitCode kilowattHour = UnitCode('KWH');
}
