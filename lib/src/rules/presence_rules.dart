import 'package:decimal/decimal.dart';
import 'package:en16931/src/codes/payment_means_code.dart';
import 'package:en16931/src/codes/vat_category.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';

/// The rules of the BR family, which say what an invoice has to carry.
///
/// Each entry is the rule the standard publishes under that identifier. The
/// meaning is implemented here against the semantic model, and the identifier
/// is the only thing the catalogue and this map share.
///
/// {@category validation}
const Map<String, RuleCheck> presenceRules = {
  'BR-01': _br01,
  'BR-02': _br02,
  'BR-04': _br04,
  'BR-05': _br05,
  'BR-06': _br06,
  'BR-07': _br07,
  'BR-09': _br09,
  'BR-11': _br11,
  'BR-16': _br16,
  'BR-17': _br17,
  'BR-18': _br18,
  'BR-20': _br20,
  'BR-21': _br21,
  'BR-23': _br23,
  'BR-25': _br25,
  'BR-27': _br27,
  'BR-28': _br28,
  'BR-29': _br29,
  'BR-30': _br30,
  'BR-33': _br33,
  'BR-38': _br38,
  'BR-42': _br42,
  'BR-44': _br44,
  'BR-48': _br48,
  'BR-49': _br49,
  'BR-50': _br50,
  'BR-51': _br51,
  'BR-52': _br52,
  'BR-53': _br53,
  'BR-54': _br54,
  'BR-55': _br55,
  'BR-56': _br56,
  'BR-57': _br57,
  'BR-61': _br61,
  'BR-62': _br62,
  'BR-63': _br63,
  'BR-64': _br64,
  'BR-65': _br65,
};

/// The rules of the BR family an invoice built with this library cannot
/// break, and what stops it.
///
/// These are not skipped: they are met before the invoice exists, because the
/// model asks for the term in its constructor and the type carries no empty
/// value. A syntax package parsing an invoice from XML has to check them
/// itself, since what it reads was not built here.
///
/// {@category validation}
const Map<String, String> presenceSatisfiedByConstruction = {
  'BR-03': 'Invoice.issueDate is required, and a CalendarDate is a date.',
  'BR-08': 'Seller.address is required.',
  'BR-10': 'Buyer.address is required.',
  'BR-12': 'InvoiceTotals.sumOfLineNetAmounts is required.',
  'BR-13': 'InvoiceTotals.totalWithoutVat is required.',
  'BR-14': 'InvoiceTotals.totalWithVat is required.',
  'BR-15': 'InvoiceTotals.amountDueForPayment is required.',
  'BR-19': 'TaxRepresentative.address is required.',
  'BR-22': 'InvoiceLine.quantity is required.',
  'BR-24': 'InvoiceLine.netAmount is required.',
  'BR-26': 'Price.netPrice is required.',
  'BR-31': 'DocumentAllowanceCharge.amount is required.',
  'BR-32': 'DocumentAllowanceCharge.vatCategory is required.',
  'BR-36': 'DocumentAllowanceCharge.amount is required.',
  'BR-37': 'DocumentAllowanceCharge.vatCategory is required.',
  'BR-41': 'LineAllowanceCharge.amount is required.',
  'BR-43': 'LineAllowanceCharge.amount is required.',
  'BR-45': 'VatBreakdown.taxableAmount is required.',
  'BR-46': 'VatBreakdown.taxAmount is required.',
  'BR-47': 'VatBreakdown.category is required.',
};

// --- The rules -------------------------------------------------------------

Iterable<RuleViolation> _br01(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.specificationIdentifier)) {
    yield at(
      rule,
      'The specification identifier (BT-24) is missing. A profile package '
      'sets it; an invoice claiming no specification cannot be validated by '
      'a receiver.',
    );
  }
}

Iterable<RuleViolation> _br02(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.number)) {
    yield at(rule, 'The invoice number (BT-1) is empty.');
  }
}

Iterable<RuleViolation> _br04(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.typeCode.value)) {
    yield at(rule, 'The invoice type code (BT-3) is empty.');
  }
}

Iterable<RuleViolation> _br05(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.currency)) {
    yield at(rule, 'The invoice currency code (BT-5) is empty.');
  }
}

Iterable<RuleViolation> _br06(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.seller.name)) {
    yield at(rule, 'The seller name (BT-27) is empty.');
  }
}

Iterable<RuleViolation> _br07(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.buyer.name)) {
    yield at(rule, 'The buyer name (BT-44) is empty.');
  }
}

Iterable<RuleViolation> _br09(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.seller.address.country)) {
    yield at(rule, 'The seller country code (BT-40) is empty.');
  }
}

Iterable<RuleViolation> _br11(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.buyer.address.country)) {
    yield at(rule, 'The buyer country code (BT-55) is empty.');
  }
}

Iterable<RuleViolation> _br16(Invoice invoice, RuleDescriptor rule) sync* {
  if (invoice.lines.isEmpty) {
    yield at(rule, 'The invoice has no line (BG-25).');
  }
}

Iterable<RuleViolation> _br17(Invoice invoice, RuleDescriptor rule) sync* {
  final payee = invoice.payee;
  if (payee != null && blank(payee.name)) {
    yield at(rule, 'The payee name (BT-59) is empty.');
  }
}

Iterable<RuleViolation> _br18(Invoice invoice, RuleDescriptor rule) sync* {
  final representative = invoice.taxRepresentative;
  if (representative != null && blank(representative.name)) {
    yield at(rule, 'The seller tax representative name (BT-62) is empty.');
  }
}

Iterable<RuleViolation> _br20(Invoice invoice, RuleDescriptor rule) sync* {
  final representative = invoice.taxRepresentative;
  if (representative != null && blank(representative.address.country)) {
    yield at(rule, 'The tax representative country code (BT-69) is empty.');
  }
}

Iterable<RuleViolation> _br21(Invoice invoice, RuleDescriptor rule) sync* {
  for (final (index, line) in invoice.lines.indexed) {
    if (blank(line.id)) {
      yield at(rule, 'The line identifier (BT-126) is empty.', 'line $index');
    }
  }
}

Iterable<RuleViolation> _br23(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    if (blank(line.unit.value)) {
      yield at(
        rule,
        'The unit of measure code (BT-130) is empty.',
        pathOf(line),
      );
    }
  }
}

Iterable<RuleViolation> _br25(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    if (blank(line.item.name)) {
      yield at(rule, 'The item name (BT-153) is empty.', pathOf(line));
    }
  }
}

Iterable<RuleViolation> _br27(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    if (line.price.netPrice < Decimal.zero) {
      yield at(
        rule,
        'The item net price (BT-146) is negative. A line that takes something '
        'back carries a negative quantity, not a negative price.',
        pathOf(line),
      );
    }
  }
}

Iterable<RuleViolation> _br28(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    final gross = line.price.grossPrice;
    if (gross != null && gross < Decimal.zero) {
      yield at(
        rule,
        'The item gross price (BT-148) is negative.',
        pathOf(line),
      );
    }
  }
}

Iterable<RuleViolation> _br29(Invoice invoice, RuleDescriptor rule) sync* {
  final period = invoice.invoicingPeriod;
  final start = period?.start;
  final end = period?.end;
  if (start != null && end != null && end < start) {
    yield at(
      rule,
      'The invoicing period ends on $end, before it starts on $start.',
    );
  }
}

Iterable<RuleViolation> _br30(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    final start = line.period?.start;
    final end = line.period?.end;
    if (start != null && end != null && end < start) {
      yield at(
        rule,
        'The line period ends on $end, before it starts on $start.',
        pathOf(line),
      );
    }
  }
}

Iterable<RuleViolation> _br33(Invoice invoice, RuleDescriptor rule) sync* {
  yield* documentReason(invoice, rule, AllowanceOrCharge.allowance, 'BT-97',
      'BT-98', 'allowance');
}

Iterable<RuleViolation> _br38(Invoice invoice, RuleDescriptor rule) sync* {
  yield* documentReason(
      invoice, rule, AllowanceOrCharge.charge, 'BT-104', 'BT-105', 'charge');
}

Iterable<RuleViolation> _br42(Invoice invoice, RuleDescriptor rule) sync* {
  yield* lineReason(invoice, rule, AllowanceOrCharge.allowance, 'BT-139',
      'BT-140', 'allowance');
}

Iterable<RuleViolation> _br44(Invoice invoice, RuleDescriptor rule) sync* {
  yield* lineReason(
      invoice, rule, AllowanceOrCharge.charge, 'BT-144', 'BT-145', 'charge');
}

Iterable<RuleViolation> _br48(Invoice invoice, RuleDescriptor rule) sync* {
  for (final (index, breakdown) in invoice.vatBreakdown.indexed) {
    // An invoice outside the scope of VAT is the one case the standard lets
    // through without a rate.
    if (breakdown.category == VatCategory.outsideScope) continue;
    if (breakdown.rate == null) {
      yield at(
        rule,
        'The VAT category rate (BT-119) is missing for category '
            '${breakdown.category}.',
        'VAT breakdown $index',
      );
    }
  }
}

Iterable<RuleViolation> _br49(Invoice invoice, RuleDescriptor rule) sync* {
  final instructions = invoice.paymentInstructions;
  if (instructions != null && blank(instructions.means.value)) {
    yield at(rule, 'The payment means type code (BT-81) is empty.');
  }
}

Iterable<RuleViolation> _br50(Invoice invoice, RuleDescriptor rule) sync* {
  final transfers = invoice.paymentInstructions?.creditTransfers ?? const [];
  for (final (index, account) in transfers.indexed) {
    if (blank(account.identifier)) {
      yield at(
        rule,
        'The payment account identifier (BT-84) is empty.',
        'credit transfer $index',
      );
    }
  }
}

Iterable<RuleViolation> _br51(Invoice invoice, RuleDescriptor rule) sync* {
  final card = invoice.paymentInstructions?.card;
  if (card == null) return;
  final digits = card.primaryAccountNumber.replaceAll(RegExp(r'\D'), '');
  // The card security standards allow the first six and the last four, so
  // anything longer than ten digits is carrying more of the number than it
  // may.
  if (digits.length > 10) {
    yield at(
      rule,
      'The card primary account number (BT-87) carries ${digits.length} '
      'digits. At most the first six and the last four may appear on an '
      'invoice.',
    );
  }
}

Iterable<RuleViolation> _br52(Invoice invoice, RuleDescriptor rule) sync* {
  for (final (index, document) in invoice.supportingDocuments.indexed) {
    if (blank(document.reference)) {
      yield at(
        rule,
        'The supporting document reference (BT-122) is empty.',
        'supporting document $index',
      );
    }
  }
}

Iterable<RuleViolation> _br53(Invoice invoice, RuleDescriptor rule) sync* {
  if (blank(invoice.vatAccountingCurrency)) return;
  if (invoice.totals.totalVatInAccountingCurrency == null) {
    yield at(
      rule,
      'The VAT accounting currency (BT-6) is set, so the invoice total VAT '
      'amount in that currency (BT-111) is required.',
    );
  }
}

Iterable<RuleViolation> _br54(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    for (final (index, attribute) in line.item.attributes.indexed) {
      if (blank(attribute.name) || blank(attribute.value)) {
        yield at(
          rule,
          'The item attribute (BG-32) needs both a name (BT-160) and a value '
              '(BT-161).',
          '${pathOf(line)}, attribute $index',
        );
      }
    }
  }
}

Iterable<RuleViolation> _br55(Invoice invoice, RuleDescriptor rule) sync* {
  for (final (index, preceding) in invoice.precedingInvoices.indexed) {
    if (blank(preceding.reference)) {
      yield at(
        rule,
        'The preceding invoice reference (BT-25) is empty.',
        'preceding invoice $index',
      );
    }
  }
}

Iterable<RuleViolation> _br56(Invoice invoice, RuleDescriptor rule) sync* {
  final representative = invoice.taxRepresentative;
  if (representative != null && blank(representative.vatIdentifier)) {
    yield at(
      rule,
      'The seller tax representative VAT identifier (BT-63) is empty.',
    );
  }
}

Iterable<RuleViolation> _br57(Invoice invoice, RuleDescriptor rule) sync* {
  final address = invoice.delivery?.address;
  if (address != null && blank(address.country)) {
    yield at(rule, 'The deliver to country code (BT-80) is empty.');
  }
}

Iterable<RuleViolation> _br61(Invoice invoice, RuleDescriptor rule) sync* {
  final instructions = invoice.paymentInstructions;
  if (instructions == null) return;
  if (!_creditTransferMeans.contains(instructions.means)) return;
  if (instructions.creditTransfers.isEmpty) {
    yield at(
      rule,
      'Payment is expected by credit transfer, so a payment account '
      'identifier (BT-84) is required.',
    );
  }
}

/// The payment means the standard reads as a credit transfer, and for which
/// an account has to be named.
final Set<PaymentMeansCode> _creditTransferMeans = {
  PaymentMeansCode.creditTransfer,
  PaymentMeansCode.sepaCreditTransfer,
};

Iterable<RuleViolation> _br62(Invoice invoice, RuleDescriptor rule) sync* {
  final address = invoice.seller.electronicAddress;
  if (address != null && blank(address.scheme)) {
    yield at(
      rule,
      'The seller electronic address (BT-34) has no scheme identifier, so a '
      'receiver cannot tell which network it belongs to.',
    );
  }
}

Iterable<RuleViolation> _br63(Invoice invoice, RuleDescriptor rule) sync* {
  final address = invoice.buyer.electronicAddress;
  if (address != null && blank(address.scheme)) {
    yield at(
      rule,
      'The buyer electronic address (BT-49) has no scheme identifier, so a '
      'receiver cannot tell which network it belongs to.',
    );
  }
}

Iterable<RuleViolation> _br64(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    final identifier = line.item.standardIdentifier;
    if (identifier != null && blank(identifier.scheme)) {
      yield at(
        rule,
        'The item standard identifier (BT-157) has no scheme identifier.',
        pathOf(line),
      );
    }
  }
}

Iterable<RuleViolation> _br65(Invoice invoice, RuleDescriptor rule) sync* {
  for (final line in invoice.lines) {
    for (final identifier in line.item.classificationIdentifiers) {
      if (blank(identifier.scheme)) {
        yield at(
          rule,
          'The item classification identifier (BT-158) has no scheme '
          'identifier.',
          pathOf(line),
        );
      }
    }
  }
}
