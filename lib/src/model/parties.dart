import 'package:en16931/src/model/address.dart';
import 'package:en16931/src/model/contact.dart';
import 'package:en16931/src/types/identifier.dart';

/// BG-4. The party selling the goods or services.
///
/// The seller is the party whose VAT is accounted for, which is not always
/// the party the money goes to: see [Payee].
///
/// {@category invoice}
final class Seller {
  /// A seller called [name], at [address].
  const Seller({
    required this.name,
    required this.address,
    this.tradingName,
    this.identifiers = const [],
    this.legalRegistrationIdentifier,
    this.vatIdentifier,
    this.taxRegistrationIdentifier,
    this.additionalLegalInformation,
    this.electronicAddress,
    this.contact,
  });

  /// BT-27. The full name the seller is registered under.
  final String name;

  /// BG-5. The seller's postal address.
  final Address address;

  /// BT-28. The name the seller trades under, when it differs from BT-27.
  final String? tradingName;

  /// BT-29. Identifiers of the seller, each optionally under a scheme.
  final List<Identifier> identifiers;

  /// BT-30. The identifier issued by the official registrar of companies.
  final Identifier? legalRegistrationIdentifier;

  /// BT-31. The seller's VAT identifier, country prefix included.
  final String? vatIdentifier;

  /// BT-32. An identifier issued by the tax authority that is not a VAT
  /// identifier.
  final String? taxRegistrationIdentifier;

  /// BT-33. The legal form, the share capital or whatever else the law of the
  /// seller's country requires on an invoice.
  final String? additionalLegalInformation;

  /// BT-34. The address the invoice itself is delivered to, with the scheme
  /// saying which network it belongs to.
  final Identifier? electronicAddress;

  /// BG-6. Who to contact at the seller.
  final Contact? contact;
}

/// BG-7. The party buying the goods or services.
///
/// {@category invoice}
final class Buyer {
  /// A buyer called [name], at [address].
  const Buyer({
    required this.name,
    required this.address,
    this.identifier,
    this.legalRegistrationIdentifier,
    this.vatIdentifier,
    this.electronicAddress,
    this.contact,
  });

  /// BT-44. The full name the buyer is registered under.
  final String name;

  /// BG-8. The buyer's postal address.
  final Address address;

  /// BT-46. An identifier of the buyer, optionally under a scheme.
  final Identifier? identifier;

  /// BT-47. The identifier issued by the official registrar of companies.
  final Identifier? legalRegistrationIdentifier;

  /// BT-48. The buyer's VAT identifier, country prefix included. Required
  /// whenever the buyer accounts for the VAT.
  final String? vatIdentifier;

  /// BT-49. The address the invoice itself is delivered to, with the scheme
  /// saying which network it belongs to.
  final Identifier? electronicAddress;

  /// BG-9. Who to contact at the buyer.
  final Contact? contact;
}

/// BG-10. The party the money goes to, when it is not the seller.
///
/// Naming a payee does not move the VAT: the seller stays the seller.
final class Payee {
  /// A payee called [name].
  const Payee({
    required this.name,
    this.identifier,
    this.legalRegistrationIdentifier,
  });

  /// BT-59. The name of the payee.
  final String name;

  /// BT-60. An identifier of the payee, optionally under a scheme.
  final Identifier? identifier;

  /// BT-61. The identifier issued by the official registrar of companies.
  final Identifier? legalRegistrationIdentifier;
}

/// BG-11. The party that accounts for the seller's VAT in another country.
///
/// {@category invoice}
final class TaxRepresentative {
  /// A tax representative called [name], registered under [vatIdentifier].
  const TaxRepresentative({
    required this.name,
    required this.vatIdentifier,
    required this.address,
  });

  /// BT-62. The name of the representative.
  final String name;

  /// BT-63. The representative's VAT identifier, country prefix included.
  final String vatIdentifier;

  /// BG-12. The representative's postal address.
  final Address address;
}
