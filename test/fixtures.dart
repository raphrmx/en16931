import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';

/// One hundred, the net amount of the single line of a plain invoice.
final Decimal net = Decimal.parse('100.00');

/// The VAT on [net] at [rate].
final Decimal vat = Decimal.parse('21.00');

/// The Belgian standard rate, as a percentage.
final Decimal rate = Decimal.parse('21');

/// An invoice that breaks nothing, so a test can break one thing at a time.
Invoice validInvoice({
  List<InvoiceLine>? lines,
  List<VatBreakdown>? vatBreakdown,
  List<DocumentAllowanceCharge> allowancesAndCharges = const [],
  String? specificationIdentifier = 'urn:test:any',
  String number = '2026-0001',
  String? vatAccountingCurrency,
  InvoiceTotals? totals,
  DatePeriod? invoicingPeriod,
  PaymentInstructions? paymentInstructions,
  CalendarDate? vatPointDate,
  String? vatPointDateCode,
  Seller? seller,
  Buyer? buyer,
  TaxRepresentative? taxRepresentative,
  Delivery? delivery,
}) {
  return Invoice(
    number: number,
    issueDate: CalendarDate(2026, 9, 13),
    typeCode: InvoiceTypeCode.commercialInvoice,
    currency: 'EUR',
    specificationIdentifier: specificationIdentifier,
    vatAccountingCurrency: vatAccountingCurrency,
    vatPointDate: vatPointDate,
    vatPointDateCode: vatPointDateCode,
    invoicingPeriod: invoicingPeriod,
    paymentInstructions: paymentInstructions,
    allowancesAndCharges: allowancesAndCharges,
    taxRepresentative: taxRepresentative,
    delivery: delivery,
    seller: seller ??
        const Seller(
          name: 'A seller',
          address: Address(country: 'BE'),
          vatIdentifier: 'BE0123456789',
        ),
    buyer:
        buyer ?? const Buyer(name: 'A buyer', address: Address(country: 'BE')),
    lines: lines ?? [invoiceLine()],
    vatBreakdown: vatBreakdown ?? [standardBreakdown()],
    totals: totals ?? standardTotals(),
  );
}

/// The line the plain invoice carries.
InvoiceLine invoiceLine({
  String id = '1',
  Item item = const Item(name: 'A thing'),
  Price? price,
  Decimal? netAmount,
  DatePeriod? period,
  List<LineAllowanceCharge> allowancesAndCharges = const [],
}) {
  return InvoiceLine(
    id: id,
    quantity: Decimal.one,
    unit: UnitCode.one,
    netAmount: netAmount ?? net,
    item: item,
    price: price ?? Price(netPrice: net),
    vatCategory: VatCategory.standardRate,
    vatRate: rate,
    period: period,
    allowancesAndCharges: allowancesAndCharges,
  );
}

/// The VAT breakdown the plain invoice carries.
VatBreakdown standardBreakdown({Decimal? taxableAmount, Decimal? taxAmount}) =>
    VatBreakdown(
      category: VatCategory.standardRate,
      taxableAmount: taxableAmount ?? net,
      taxAmount: taxAmount ?? vat,
      rate: rate,
    );

/// The totals the plain invoice carries, which follow from its one line.
InvoiceTotals standardTotals({
  Decimal? sumOfLineNetAmounts,
  Decimal? sumOfAllowances,
  Decimal? sumOfCharges,
  Decimal? totalWithoutVat,
  Decimal? totalVat,
  Decimal? totalWithVat,
  Decimal? paidAmount,
  Decimal? roundingAmount,
  Decimal? amountDueForPayment,
}) =>
    InvoiceTotals(
      sumOfLineNetAmounts: sumOfLineNetAmounts ?? net,
      sumOfAllowances: sumOfAllowances,
      sumOfCharges: sumOfCharges,
      totalWithoutVat: totalWithoutVat ?? net,
      totalVat: totalVat ?? vat,
      totalWithVat: totalWithVat ?? net + vat,
      paidAmount: paidAmount,
      roundingAmount: roundingAmount,
      amountDueForPayment: amountDueForPayment ?? net + vat,
    );

/// Totals that add up to nothing, for an invoice with no line to sum.
InvoiceTotals emptyTotals() => InvoiceTotals(
      sumOfLineNetAmounts: Decimal.zero,
      totalWithoutVat: Decimal.zero,
      totalVat: Decimal.zero,
      totalWithVat: Decimal.zero,
      amountDueForPayment: Decimal.zero,
    );

/// The identifiers of the rules [invoice] breaks.
Set<String> broken(Invoice invoice) =>
    validate(invoice).map((violation) => violation.rule.id).toSet();
