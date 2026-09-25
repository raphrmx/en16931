import 'package:en16931/src/codes/lists.g.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';

/// A code the rule reads, and where it sits in the invoice.
typedef _Code = (String value, String? path);

/// One term whose value has to be drawn from a published code list.
final class _CodeTerm {
  const _CodeTerm(this.id, this.term, this.read);

  /// The identifier the standard gives the rule.
  final String id;

  /// What the term is, for the message.
  final String term;

  /// The codes that term holds in an invoice.
  final List<_Code> Function(Invoice invoice) read;

  /// Reports the codes the list does not hold.
  Iterable<RuleViolation> check(Invoice invoice, RuleDescriptor rule) sync* {
    final allowed = codeListByRule[id];
    if (allowed == null) return;
    for (final (value, path) in read(invoice)) {
      if (blank(value) || allowed.contains(value.trim())) continue;
      yield at(
        rule,
        'The $term is "$value", which the list does not hold.',
        path,
      );
    }
  }
}

/// Reads one code, when the invoice carries it.
List<_Code> _one(String? value) => value == null ? const [] : [(value, null)];

/// Every term the BR-CL family draws from a list.
final List<_CodeTerm> _terms = [
  _CodeTerm(
    'BR-CL-01',
    'invoice type code (BT-3)',
    (invoice) => _one(invoice.typeCode.value),
  ),
  // BR-CL-03 checks the currency an amount is written in. The model carries
  // the currency once for the invoice and once for VAT accounting rather than
  // on each amount, so it reads the same two terms as BR-CL-04 and BR-CL-05.
  _CodeTerm('BR-CL-03', 'currency (BT-5, BT-6)', (invoice) {
    return [..._one(invoice.currency), ..._one(invoice.vatAccountingCurrency)];
  }),
  _CodeTerm(
    'BR-CL-04',
    'invoice currency code (BT-5)',
    (invoice) => _one(invoice.currency),
  ),
  _CodeTerm(
    'BR-CL-05',
    'VAT accounting currency code (BT-6)',
    (invoice) => _one(invoice.vatAccountingCurrency),
  ),
  _CodeTerm(
    'BR-CL-06',
    'VAT point date code (BT-8)',
    (invoice) => _one(invoice.vatPointDateCode),
  ),
  _CodeTerm(
    'BR-CL-07',
    'object identifier scheme (BT-18-1)',
    (invoice) => _one(invoice.objectIdentifier?.scheme),
  ),
  _CodeTerm('BR-CL-08', 'note subject code (BT-21)', (invoice) {
    return [
      for (final (index, note) in invoice.notes.indexed)
        if (note.subjectCode != null) (note.subjectCode!, 'note $index'),
    ];
  }),
  _CodeTerm('BR-CL-10', 'party identifier scheme', (invoice) {
    return [
      for (final (index, identifier) in invoice.seller.identifiers.indexed)
        if (identifier.scheme != null)
          (identifier.scheme!, 'seller identifier $index'),
      if (invoice.buyer.identifier?.scheme != null)
        (invoice.buyer.identifier!.scheme!, 'buyer identifier'),
      if (invoice.payee?.identifier?.scheme != null)
        (invoice.payee!.identifier!.scheme!, 'payee identifier'),
    ];
  }),
  _CodeTerm('BR-CL-11', 'legal registration identifier scheme', (invoice) {
    return [
      if (invoice.seller.legalRegistrationIdentifier?.scheme != null)
        (
          invoice.seller.legalRegistrationIdentifier!.scheme!,
          'seller registration',
        ),
      if (invoice.buyer.legalRegistrationIdentifier?.scheme != null)
        (
          invoice.buyer.legalRegistrationIdentifier!.scheme!,
          'buyer registration',
        ),
      if (invoice.payee?.legalRegistrationIdentifier?.scheme != null)
        (
          invoice.payee!.legalRegistrationIdentifier!.scheme!,
          'payee registration',
        ),
    ];
  }),
  _CodeTerm('BR-CL-13', 'item classification scheme (BT-158-1)', (invoice) {
    return [
      for (final line in invoice.lines)
        for (final identifier in line.item.classificationIdentifiers)
          if (identifier.scheme != null) (identifier.scheme!, pathOf(line)),
    ];
  }),
  _CodeTerm('BR-CL-14', 'country code', (invoice) {
    return [
      (invoice.seller.address.country, 'seller address'),
      (invoice.buyer.address.country, 'buyer address'),
      if (invoice.taxRepresentative != null)
        (
          invoice.taxRepresentative!.address.country,
          'tax representative address',
        ),
      if (invoice.delivery?.address != null)
        (invoice.delivery!.address!.country, 'delivery address'),
    ];
  }),
  _CodeTerm('BR-CL-15', 'item origin country (BT-159)', (invoice) {
    return [
      for (final line in invoice.lines)
        if (line.item.originCountry != null)
          (line.item.originCountry!, pathOf(line)),
    ];
  }),
  _CodeTerm(
    'BR-CL-16',
    'payment means code (BT-81)',
    (invoice) => _one(invoice.paymentInstructions?.means.value),
  ),
  _CodeTerm('BR-CL-19', 'allowance reason code (BT-98, BT-140)', (invoice) {
    return [
      ..._documentReasonCodes(invoice, AllowanceOrCharge.allowance),
      ..._lineReasonCodes(invoice, AllowanceOrCharge.allowance),
    ];
  }),
  _CodeTerm('BR-CL-20', 'charge reason code (BT-105, BT-145)', (invoice) {
    return [
      ..._documentReasonCodes(invoice, AllowanceOrCharge.charge),
      ..._lineReasonCodes(invoice, AllowanceOrCharge.charge),
    ];
  }),
  _CodeTerm('BR-CL-21', 'item standard identifier scheme (BT-157-1)', (
    invoice,
  ) {
    return [
      for (final line in invoice.lines)
        if (line.item.standardIdentifier?.scheme != null)
          (line.item.standardIdentifier!.scheme!, pathOf(line)),
    ];
  }),
  _CodeTerm('BR-CL-22', 'VAT exemption reason code (BT-121)', (invoice) {
    return [
      for (final (index, entry) in invoice.vatBreakdown.indexed)
        if (entry.exemptionReasonCode != null)
          (entry.exemptionReasonCode!, 'VAT breakdown $index'),
    ];
  }),
  _CodeTerm('BR-CL-23', 'unit of measure code (BT-130, BT-150)', (invoice) {
    return [
      for (final line in invoice.lines) ...[
        (line.unit.value, pathOf(line)),
        if (line.price.baseQuantityUnit != null)
          (line.price.baseQuantityUnit!.value, '${pathOf(line)}, base unit'),
      ],
    ];
  }),
  _CodeTerm('BR-CL-24', 'attachment media type (BT-125-1)', (invoice) {
    return [
      for (final (index, document) in invoice.supportingDocuments.indexed)
        if (document.attachment != null)
          (document.attachment!.mimeCode, 'supporting document $index'),
    ];
  }),
  _CodeTerm('BR-CL-25', 'electronic address scheme (BT-34-1, BT-49-1)', (
    invoice,
  ) {
    return [
      if (invoice.seller.electronicAddress?.scheme != null)
        (invoice.seller.electronicAddress!.scheme!, 'seller'),
      if (invoice.buyer.electronicAddress?.scheme != null)
        (invoice.buyer.electronicAddress!.scheme!, 'buyer'),
    ];
  }),
  _CodeTerm(
    'BR-CL-26',
    'delivery location identifier scheme (BT-71-1)',
    (invoice) => _one(invoice.delivery?.locationIdentifier?.scheme),
  ),
];

List<_Code> _documentReasonCodes(Invoice invoice, AllowanceOrCharge kind) {
  final noun = kind == AllowanceOrCharge.allowance ? 'allowance' : 'charge';
  return [
    for (final (index, entry) in invoice.allowancesAndCharges.indexed)
      if (entry.kind == kind && entry.reasonCode != null)
        (entry.reasonCode!, 'document $noun $index'),
  ];
}

List<_Code> _lineReasonCodes(Invoice invoice, AllowanceOrCharge kind) {
  final noun = kind == AllowanceOrCharge.allowance ? 'allowance' : 'charge';
  return [
    for (final line in invoice.lines)
      for (final (index, entry) in line.allowancesAndCharges.indexed)
        if (entry.kind == kind && entry.reasonCode != null)
          (entry.reasonCode!, '${pathOf(line)}, $noun $index'),
  ];
}

/// The rules of the BR-CL family, which draw a code from a published list.
///
/// {@category validation}
final Map<String, RuleCheck> codeListRules = {
  for (final term in _terms) term.id: term.check,
};

/// The rules of the BR-CL family met before the invoice exists.
///
/// A VAT category is an enum here, and every one of its codes is in the list,
/// so an invoice cannot carry a category the list does not hold. A test holds
/// the enum and the list to each other.
const Map<String, String> codeListSatisfiedByConstruction = {
  'BR-CL-17': 'VatBreakdown.category is a VatCategory, which is UNCL 5305.',
  'BR-CL-18': 'Every VAT category in the model is a VatCategory.',
};
