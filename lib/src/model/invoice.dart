import 'package:en16931/src/codes/invoice_type_code.dart';
import 'package:en16931/src/codes/vat_category.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/derive.dart';
import 'package:en16931/src/model/line.dart';
import 'package:en16931/src/model/parties.dart';
import 'package:en16931/src/model/payment.dart';
import 'package:en16931/src/model/references.dart';
import 'package:en16931/src/model/totals.dart';
import 'package:en16931/src/model/vat_breakdown.dart';
import 'package:en16931/src/types/amount.dart';
import 'package:en16931/src/types/calendar_date.dart';
import 'package:en16931/src/types/identifier.dart';

/// An invoice, as EN 16931 defines it.
///
/// This is the semantic model, which is what the standard actually specifies:
/// the same invoice can be written out as UBL or as CII and stays the same
/// invoice. Nothing here knows about XML, and nothing here knows about a
/// network.
///
/// The totals and the VAT breakdown are held rather than worked out, because
/// an invoice that has already been issued has to keep the figures it was
/// issued with, down to the rounding. Building them from the lines is a
/// separate step, and checking that they follow is what the business rules
/// are for.
final class Invoice {
  /// An invoice numbered [number], issued on [issueDate].
  const Invoice({
    required this.number,
    required this.issueDate,
    required this.typeCode,
    required this.currency,
    required this.seller,
    required this.buyer,
    required this.lines,
    required this.vatBreakdown,
    required this.totals,
    this.specificationIdentifier,
    this.businessProcess,
    this.vatAccountingCurrency,
    this.vatPointDate,
    this.vatPointDateCode,
    this.dueDate,
    this.buyerReference,
    this.projectReference,
    this.contractReference,
    this.purchaseOrderReference,
    this.salesOrderReference,
    this.receivingAdviceReference,
    this.despatchAdviceReference,
    this.tenderReference,
    this.objectIdentifier,
    this.buyerAccountingReference,
    this.paymentTerms,
    this.notes = const [],
    this.precedingInvoices = const [],
    this.supportingDocuments = const [],
    this.payee,
    this.taxRepresentative,
    this.delivery,
    this.invoicingPeriod,
    this.paymentInstructions,
    this.allowancesAndCharges = const [],
  });

  /// An invoice whose VAT breakdown and totals are worked out from [lines].
  ///
  /// Build the lines with `InvoiceLine.of` and nothing has to be added up by
  /// hand: one breakdown entry comes out per pair of category and rate, the
  /// VAT is applied, and every total follows. Amounts are rounded to two
  /// decimals as they are worked out, so the result passes the rules that
  /// check them.
  ///
  /// A category that charges no VAT has to say why, and [exemptionReasons]
  /// carries that reason. Use the unnamed constructor for an invoice that was
  /// issued elsewhere and has to keep the figures it went out with.
  factory Invoice.fromLines({
    required String number,
    required DateTime issueDate,
    required Seller seller,
    required Buyer buyer,
    required List<InvoiceLine> lines,
    String currency = 'EUR',
    InvoiceTypeCode typeCode = InvoiceTypeCode.commercialInvoice,
    String? specificationIdentifier = en16931Specification,
    DateTime? dueDate,
    List<DocumentAllowanceCharge> allowancesAndCharges = const [],
    Map<VatCategory, String> exemptionReasons = const {},
    num? paidAmount,
    String? buyerReference,
    String? paymentTerms,
    PaymentInstructions? paymentInstructions,
    Delivery? delivery,
    DatePeriod? invoicingPeriod,
    Payee? payee,
    TaxRepresentative? taxRepresentative,
    List<InvoiceNote> notes = const [],
    List<PrecedingInvoiceReference> precedingInvoices = const [],
    List<SupportingDocument> supportingDocuments = const [],
  }) {
    final breakdown = deriveBreakdown(
      lines: lines,
      entries: allowancesAndCharges,
      exemptionReasons: exemptionReasons,
    );
    return Invoice(
      number: number,
      issueDate: CalendarDate.from(issueDate),
      dueDate: dueDate == null ? null : CalendarDate.from(dueDate),
      typeCode: typeCode,
      currency: currency,
      specificationIdentifier: specificationIdentifier,
      seller: seller,
      buyer: buyer,
      lines: lines,
      vatBreakdown: breakdown,
      totals: deriveTotals(
        lines: lines,
        entries: allowancesAndCharges,
        breakdown: breakdown,
        paidAmount: paidAmount == null ? null : exact(paidAmount),
      ),
      allowancesAndCharges: allowancesAndCharges,
      buyerReference: buyerReference,
      paymentTerms: paymentTerms,
      paymentInstructions: paymentInstructions,
      delivery: delivery,
      invoicingPeriod: invoicingPeriod,
      payee: payee,
      taxRepresentative: taxRepresentative,
      notes: notes,
      precedingInvoices: precedingInvoices,
      supportingDocuments: supportingDocuments,
    );
  }

  /// BT-1. The number of the invoice, unique in the seller's own sequence.
  final String number;

  /// BT-2. The day the invoice was issued.
  final CalendarDate issueDate;

  /// BT-3. What kind of document this is.
  final InvoiceTypeCode typeCode;

  /// BT-5. The currency every amount is in, as an ISO 4217 code, except the
  /// one amount that is in BT-6.
  final String currency;

  /// BG-4. Who is selling.
  final Seller seller;

  /// BG-7. Who is buying.
  final Buyer buyer;

  /// BG-25. The lines. An invoice carries at least one.
  final List<InvoiceLine> lines;

  /// BG-23. The VAT breakdown, one entry per pair of category and rate.
  final List<VatBreakdown> vatBreakdown;

  /// BG-22. The totals.
  final InvoiceTotals totals;

  /// BT-24. Which specification the invoice follows.
  ///
  /// A profile package fills this in with its own identifier. Left alone, the
  /// invoice claims nothing beyond the standard itself.
  final String? specificationIdentifier;

  /// BT-23. Which business process the invoice belongs to.
  final String? businessProcess;

  /// BT-6. The currency VAT is accounted for in, when the tax authority asks
  /// for one other than BT-5.
  final String? vatAccountingCurrency;

  /// BT-7. The day the VAT becomes due.
  final CalendarDate? vatPointDate;

  /// BT-8. What decides the day the VAT becomes due, when it is not a date
  /// but a rule.
  final String? vatPointDateCode;

  /// BT-9. The day payment is due.
  final CalendarDate? dueDate;

  /// BT-10. The reference the buyer asked to see on the invoice. Public
  /// buyers usually require it.
  final String? buyerReference;

  /// BT-11. The project the invoice belongs to.
  final String? projectReference;

  /// BT-12. The contract the invoice is issued under.
  final String? contractReference;

  /// BT-13. The buyer's purchase order.
  final String? purchaseOrderReference;

  /// BT-14. The seller's own order.
  final String? salesOrderReference;

  /// BT-15. The receiving advice the delivery was acknowledged by.
  final String? receivingAdviceReference;

  /// BT-16. The despatch advice the goods were sent under.
  final String? despatchAdviceReference;

  /// BT-17. The tender or lot the invoice answers.
  final String? tenderReference;

  /// BT-18. An identifier of the object the invoice is about, a meter or a
  /// subscription for instance, under the scheme that issues it.
  final Identifier? objectIdentifier;

  /// BT-19. Where the buyer books the invoice.
  final String? buyerAccountingReference;

  /// BT-20. The terms of payment, in words.
  final String? paymentTerms;

  /// BG-1. Free text notes about the invoice.
  final List<InvoiceNote> notes;

  /// BG-3. The invoices this one corrects or reverses.
  final List<PrecedingInvoiceReference> precedingInvoices;

  /// BG-24. Documents that support the invoice.
  final List<SupportingDocument> supportingDocuments;

  /// BG-10. Who the money goes to, when it is not the seller.
  final Payee? payee;

  /// BG-11. Who accounts for the seller's VAT, when it is not the seller.
  final TaxRepresentative? taxRepresentative;

  /// BG-13. Where and when the goods or services were delivered.
  final Delivery? delivery;

  /// BG-14. The period the invoice covers, when the lines do not each say so.
  final DatePeriod? invoicingPeriod;

  /// BG-16. How the invoice is to be paid.
  final PaymentInstructions? paymentInstructions;

  /// BG-20 and BG-21. What is taken off or added on to the whole invoice.
  final List<DocumentAllowanceCharge> allowancesAndCharges;
}

/// BG-1. A free text note about the invoice.
final class InvoiceNote {
  /// The note [text], optionally about [subjectCode].
  const InvoiceNote(this.text, {this.subjectCode});

  /// BT-22. The note itself.
  final String text;

  /// BT-21. What the note is about, as a code from UNTDID 4451.
  final String? subjectCode;
}

/// BT-24 for an invoice that follows the standard and nothing more.
///
/// A profile has its own identifier and sets it instead: Peppol, XRechnung and
/// Factur-X each publish one, and it says which extra rules the receiver is
/// expected to apply.
const String en16931Specification = 'urn:cen.eu:en16931:2017';
