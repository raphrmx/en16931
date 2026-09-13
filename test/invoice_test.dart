import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

/// The smallest invoice the standard accepts: one line, one VAT rate, one
/// seller, one buyer.
Invoice _minimal() {
  final net = Decimal.parse('100.00');
  final vat = Decimal.parse('21.00');
  return Invoice(
    number: '2026-0001',
    issueDate: CalendarDate(2026, 9, 13),
    typeCode: InvoiceTypeCode.commercialInvoice,
    currency: 'EUR',
    seller: const Seller(
      name: 'COMAPPS',
      address: Address(country: 'BE'),
      vatIdentifier: 'BE0123456789',
    ),
    buyer: const Buyer(name: 'A buyer', address: Address(country: 'BE')),
    lines: [
      InvoiceLine(
        id: '1',
        quantity: Decimal.one,
        unit: UnitCode.one,
        netAmount: net,
        item: const Item(name: 'A thing'),
        price: Price(netPrice: net),
        vatCategory: VatCategory.standardRate,
        vatRate: Decimal.parse('21'),
      ),
    ],
    vatBreakdown: [
      VatBreakdown(
        category: VatCategory.standardRate,
        taxableAmount: net,
        taxAmount: vat,
        rate: Decimal.parse('21'),
      ),
    ],
    totals: InvoiceTotals(
      sumOfLineNetAmounts: net,
      totalWithoutVat: net,
      totalVat: vat,
      totalWithVat: net + vat,
      amountDueForPayment: net + vat,
    ),
  );
}

void main() {
  group('Invoice', () {
    test('holds the figures it was built with', () {
      final invoice = _minimal();
      expect(invoice.number, '2026-0001');
      expect(invoice.issueDate.toString(), '2026-09-13');
      expect(invoice.typeCode, InvoiceTypeCode.commercialInvoice);
      expect(invoice.totals.totalWithVat, Decimal.parse('121.00'));
      expect(invoice.lines.single.item.name, 'A thing');
    });

    test('keeps amounts exact, which a double would not', () {
      final tenth = Decimal.parse('0.1');
      expect(tenth + tenth + tenth, Decimal.parse('0.3'));
      expect(0.1 + 0.1 + 0.1 == 0.3, isFalse);
    });

    test('carries a credit note as a type, not as a negative invoice', () {
      final invoice = _minimal();
      expect(invoice.typeCode.value, '380');
      expect(InvoiceTypeCode.creditNote.value, '381');
    });
  });
}
