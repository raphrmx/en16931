import 'package:decimal/decimal.dart';

/// Reads [value] as an exact amount.
///
/// A `num` written in the source is read back as it was written, because
/// `toString` gives the shortest decimal that round trips. A `num` that came
/// out of a calculation carries whatever binary floating point made of it,
/// which is why the model holds `Decimal` and only the builders take a `num`.
///
/// {@category values}
Decimal exact(num value) => Decimal.parse(value.toString());

/// [value] rounded to the two decimals an amount is written with.
Decimal round2(Decimal value) => value.round(scale: 2);
