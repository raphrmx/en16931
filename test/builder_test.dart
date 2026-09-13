import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

const _seller = Seller(
  name: 'COMAPPS SRL',
  vatIdentifier: 'BE0123456789',
  address: Address(city: 'Bruxelles', postalCode: '1000', country: 'BE'),
);

const _buyer = Buyer(
  name: 'Client SA',
  address: Address(city: 'Namur', postalCode: '5000', country: 'BE'),
);

Decimal _d(String value) => Decimal.parse(value);

void main() {
  group('InvoiceLine.of', () {
    test('works out the net amount', () {
      final line = InvoiceLine.of(
        id: '1',
        item: const Item(name: 'Consulting'),
        quantity: 8,
        unitPrice: 150.00,
        vatRate: 21,
        unit: UnitCode.hour,
      );
      expect(line.netAmount, _d('1200.00'));
      expect(line.price.netPrice, _d('150'));
      expect(line.quantity, _d('8'));
      expect(line.vatRate, _d('21'));
    });

    test('rounds the net amount to two decimals', () {
      final line = InvoiceLine.of(
        id: '1',
        item: const Item(name: 'Screws'),
        quantity: 3,
        unitPrice: 0.335,
        vatRate: 21,
      );
      // Three at 0.335 is 1.005, which no invoice can carry.
      expect(line.netAmount, _d('1.01'));
      expect(line.netAmount.scale, lessThanOrEqualTo(2));
    });

    test('takes its own allowance off the net amount', () {
      final line = InvoiceLine.of(
        id: '1',
        item: const Item(name: 'Consulting'),
        quantity: 10,
        unitPrice: 100,
        vatRate: 21,
        allowancesAndCharges: [
          LineAllowanceCharge(
            kind: AllowanceOrCharge.allowance,
            amount: _d('50.00'),
            reasonCode: '95',
          ),
        ],
      );
      expect(line.netAmount, _d('950.00'));
    });
  });

  group('Invoice.fromLines', () {
    test('builds an invoice that breaks no rule', () {
      final invoice = Invoice.fromLines(
        number: '2026-0042',
        issueDate: DateTime(2026, 9, 13),
        dueDate: DateTime(2026, 10, 13),
        seller: _seller,
        buyer: _buyer,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'Consulting'),
            quantity: 8,
            unitPrice: 150.00,
            vatRate: 21,
            unit: UnitCode.hour,
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.totals.totalWithoutVat, _d('1200.00'));
      expect(invoice.totals.totalVat, _d('252.00'));
      expect(invoice.totals.totalWithVat, _d('1452.00'));
      expect(invoice.totals.amountDueForPayment, _d('1452.00'));
    });

    test('reads the day off a DateTime without moving it', () {
      final invoice = Invoice.fromLines(
        number: '1',
        issueDate: DateTime(2026),
        seller: _seller,
        buyer: _buyer,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'A thing'),
            quantity: 1,
            unitPrice: 10,
            vatRate: 21,
          ),
        ],
      );
      expect(invoice.issueDate.toString(), '2026-01-01');
    });

    test('makes one breakdown entry per rate', () {
      final invoice = Invoice.fromLines(
        number: '2026-0043',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'Consulting'),
            quantity: 8,
            unitPrice: 150.00,
            vatRate: 21,
            unit: UnitCode.hour,
          ),
          InvoiceLine.of(
            id: '2',
            item: const Item(name: 'Printed manual'),
            quantity: 4,
            unitPrice: 15.00,
            vatRate: 6,
            unit: UnitCode.piece,
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.vatBreakdown, hasLength(2));
      final rates = invoice.vatBreakdown.map((e) => e.rate).toList();
      expect(rates, containsAll([_d('21'), _d('6')]));
      expect(invoice.totals.totalVat, _d('255.60'));
    });

    test('takes a document level allowance off the right bracket', () {
      final invoice = Invoice.fromLines(
        number: '2026-0044',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'Consulting'),
            quantity: 8,
            unitPrice: 150.00,
            vatRate: 21,
            unit: UnitCode.hour,
          ),
        ],
        allowancesAndCharges: [
          DocumentAllowanceCharge(
            kind: AllowanceOrCharge.allowance,
            amount: _d('50.00'),
            vatCategory: VatCategory.standardRate,
            vatRate: _d('21'),
            reasonCode: '95',
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.totals.sumOfAllowances, _d('50.00'));
      expect(invoice.totals.totalWithoutVat, _d('1150.00'));
      expect(invoice.vatBreakdown.single.taxableAmount, _d('1150.00'));
      expect(invoice.vatBreakdown.single.taxAmount, _d('241.50'));
    });

    test('subtracts what has already been paid', () {
      final invoice = Invoice.fromLines(
        number: '2026-0045',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        paidAmount: 452.00,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'Consulting'),
            quantity: 8,
            unitPrice: 150.00,
            vatRate: 21,
            unit: UnitCode.hour,
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.totals.amountDueForPayment, _d('1000.00'));
    });

    test('carries no VAT and a reason for an exempt invoice', () {
      final invoice = Invoice.fromLines(
        number: '2026-0046',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        exemptionReasons: const {
          VatCategory.exempt: 'Article 44 of the VAT directive',
        },
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'Training'),
            quantity: 1,
            unitPrice: 500,
            vatRate: 0,
            vatCategory: VatCategory.exempt,
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.totals.totalVat, Decimal.zero);
      expect(invoice.totals.totalWithVat, _d('500.00'));
      expect(
        invoice.vatBreakdown.single.exemptionReason,
        'Article 44 of the VAT directive',
      );
    });

    test('leaves the rate out of an invoice outside the scope of VAT', () {
      const seller = Seller(
        name: 'A small seller',
        address: Address(country: 'BE'),
        legalRegistrationIdentifier: Identifier('0123456789', scheme: '0208'),
      );
      final invoice = Invoice.fromLines(
        number: '2026-0047',
        issueDate: DateTime(2026, 9, 13),
        seller: seller,
        buyer: _buyer,
        exemptionReasons: const {
          VatCategory.outsideScope: 'Not registered for VAT',
        },
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'A thing'),
            quantity: 1,
            unitPrice: 100,
            vatCategory: VatCategory.outsideScope,
          ),
        ],
      );
      expect(validate(invoice), isEmpty);
      expect(invoice.vatBreakdown.single.rate, isNull);
    });

    test('sets the specification identifier by default', () {
      final invoice = Invoice.fromLines(
        number: '1',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'A thing'),
            quantity: 1,
            unitPrice: 10,
            vatRate: 21,
          ),
        ],
      );
      expect(invoice.specificationIdentifier, en16931Specification);
    });

    test('carries the references a buyer books the invoice against', () {
      final invoice = Invoice.fromLines(
        number: '1',
        issueDate: DateTime(2026, 9, 13),
        seller: _seller,
        buyer: _buyer,
        buyerReference: 'REF-1',
        purchaseOrderReference: 'PO-77812',
        contractReference: 'V-2026-11',
        tenderReference: 'LOT-3',
        lines: [
          InvoiceLine.of(
            id: '1',
            item: const Item(name: 'A thing'),
            quantity: 1,
            unitPrice: 10,
            vatRate: 21,
          ),
        ],
      );
      expect(invoice.buyerReference, 'REF-1');
      expect(invoice.purchaseOrderReference, 'PO-77812');
      expect(invoice.contractReference, 'V-2026-11');
      expect(invoice.tenderReference, 'LOT-3');
    });
  });

  group('exact', () {
    test('reads a number back as it was written', () {
      expect(exact(150.00), _d('150'));
      expect(exact(0.335), _d('0.335'));
      expect(exact(8), _d('8'));
    });
  });
}
