import 'package:en16931/src/codes/code_value.dart';

/// BT-81. How payment is expected, from UNTDID 4461.
final class PaymentMeansCode extends CodeValue {
  /// Holds [value] as it appears in UNTDID 4461.
  const PaymentMeansCode(super.value);

  /// 1. The means are not known at the time the invoice is written.
  static const PaymentMeansCode instrumentNotDefined = PaymentMeansCode('1');

  /// 10. Cash.
  static const PaymentMeansCode inCash = PaymentMeansCode('10');

  /// 20. Cheque.
  static const PaymentMeansCode cheque = PaymentMeansCode('20');

  /// 30. Credit transfer, the account being named on the invoice.
  static const PaymentMeansCode creditTransfer = PaymentMeansCode('30');

  /// 48. Payment card.
  static const PaymentMeansCode bankCard = PaymentMeansCode('48');

  /// 49. Direct debit, the seller pulling from the buyer's account.
  static const PaymentMeansCode directDebit = PaymentMeansCode('49');

  /// 58. SEPA credit transfer.
  static const PaymentMeansCode sepaCreditTransfer = PaymentMeansCode('58');

  /// 59. SEPA direct debit.
  static const PaymentMeansCode sepaDirectDebit = PaymentMeansCode('59');

  /// 97. Settled between the parties without a transfer, by offset.
  static const PaymentMeansCode clearingBetweenPartners = PaymentMeansCode(
    '97',
  );
}
