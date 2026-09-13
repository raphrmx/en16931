import 'package:en16931/src/codes/payment_means_code.dart';

/// BG-16. How the invoice is to be paid.
final class PaymentInstructions {
  /// Payment expected by [means], with the details that go with it.
  const PaymentInstructions({
    required this.means,
    this.meansText,
    this.remittanceInformation,
    this.creditTransfers = const [],
    this.card,
    this.directDebit,
  });

  /// BT-81. How payment is expected.
  final PaymentMeansCode means;

  /// BT-82. How payment is expected, in words, when the code is not enough.
  final String? meansText;

  /// BT-83. The reference the buyer puts on the transfer so the seller can
  /// match it. A structured communication belongs here.
  final String? remittanceInformation;

  /// BG-17. The accounts a credit transfer can be sent to.
  final List<CreditTransferAccount> creditTransfers;

  /// BG-18. The card the payment was taken from.
  final PaymentCard? card;

  /// BG-19. The mandate the direct debit is taken under.
  final DirectDebit? directDebit;
}

/// BG-17. An account a credit transfer can be sent to.
final class CreditTransferAccount {
  /// The account identified by [identifier], which is an IBAN wherever there
  /// is one.
  const CreditTransferAccount(this.identifier, {this.name, this.providerBic});

  /// BT-84. The account identifier.
  final String identifier;

  /// BT-85. The name the account is held under.
  final String? name;

  /// BT-86. The BIC of the institution holding the account.
  final String? providerBic;
}

/// BG-18. The card a payment was taken from.
final class PaymentCard {
  /// The card whose number ends in [primaryAccountNumber].
  const PaymentCard(this.primaryAccountNumber, {this.holderName});

  /// BT-87. The card number. The standard asks for the last four digits and
  /// no more, so nothing that falls under PCI DSS travels on the invoice.
  final String primaryAccountNumber;

  /// BT-88. The name on the card.
  final String? holderName;
}

/// BG-19. The mandate a direct debit is taken under.
final class DirectDebit {
  /// The debit taken under [mandateReference] by [creditorIdentifier].
  const DirectDebit({
    this.mandateReference,
    this.creditorIdentifier,
    this.debitedAccountIdentifier,
  });

  /// BT-89. The reference of the mandate the buyer signed.
  final String? mandateReference;

  /// BT-90. The creditor identifier the seller collects under.
  final String? creditorIdentifier;

  /// BT-91. The account the money is taken from.
  final String? debitedAccountIdentifier;
}
