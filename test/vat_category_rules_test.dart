import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Decimal _d(String value) => Decimal.parse(value);

/// An invoice taxed under one category, built so that only the category and
/// what it asks for change from one test to the next.
Invoice _taxed({
  required VatCategory category,
  Decimal? rate,
  Decimal? taxAmount,
  String? exemptionReason,
  Seller? seller,
  Buyer? buyer,
  Delivery? delivery,
  List<VatBreakdown>? vatBreakdown,
  List<InvoiceLine>? lines,
}) {
  final vat = taxAmount ?? Decimal.zero;
  return validInvoice(
    seller: seller,
    buyer: buyer,
    delivery: delivery,
    lines: lines ??
        [
          InvoiceLine(
            id: '1',
            quantity: Decimal.one,
            unit: UnitCode.one,
            netAmount: net,
            item: const Item(name: 'A thing'),
            price: Price(netPrice: net),
            vatCategory: category,
            vatRate: rate,
          ),
        ],
    vatBreakdown: vatBreakdown ??
        [
          VatBreakdown(
            category: category,
            taxableAmount: net,
            taxAmount: vat,
            rate: rate,
            exemptionReason: exemptionReason,
          ),
        ],
    totals: standardTotals(
      totalVat: vat,
      totalWithVat: net + vat,
      amountDueForPayment: net + vat,
    ),
  );
}

/// A seller that carries no VAT identifier of any kind.
const Seller _untaxedSeller = Seller(
  name: 'A seller',
  address: Address(country: 'BE'),
  legalRegistrationIdentifier: Identifier('0123456789', scheme: '0208'),
);

void main() {
  group('coverage', () {
    test('every rule of the catalogue now has an answer', () {
      final catalogue = ruleCatalogue.map((rule) => rule.id).toSet();
      expect(catalogue.difference(accountedRules), isEmpty);
      expect(accountedRules.difference(catalogue), isEmpty);
      expect(accountedRules, hasLength(223));
    });

    test('the ten categories are all covered', () {
      for (final prefix in [
        'BR-S',
        'BR-Z',
        'BR-E',
        'BR-AE',
        'BR-IC',
        'BR-G',
        'BR-O',
        'BR-AF',
        'BR-AG',
        'BR-B',
      ]) {
        expect(
          implementedRules.any((id) => id.startsWith('$prefix-')),
          isTrue,
          reason: prefix,
        );
      }
    });
  });

  group('standard rated', () {
    test('the plain invoice breaks nothing', () {
      expect(validate(validInvoice()), isEmpty);
    });

    test('BR-S-05 wants a rate above zero on the line', () {
      final invoice = _taxed(
        category: VatCategory.standardRate,
        rate: Decimal.zero,
      );
      expect(broken(invoice), contains('BR-S-05'));
    });

    test('BR-S-10 refuses an exemption reason on a taxed breakdown', () {
      final invoice = _taxed(
        category: VatCategory.standardRate,
        rate: rate,
        taxAmount: vat,
        exemptionReason: 'Because',
      );
      expect(broken(invoice), contains('BR-S-10'));
    });

    test('BR-S-02 wants the seller identified for tax', () {
      final invoice = _taxed(
        category: VatCategory.standardRate,
        rate: rate,
        taxAmount: vat,
        seller: _untaxedSeller,
      );
      expect(broken(invoice), contains('BR-S-02'));
    });

    test('BR-S-02 takes a tax registration identifier instead', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        taxRegistrationIdentifier: 'BE-TAX-1',
      );
      final invoice = _taxed(
        category: VatCategory.standardRate,
        rate: rate,
        taxAmount: vat,
        seller: seller,
      );
      expect(broken(invoice), isNot(contains('BR-S-02')));
    });

    test('BR-S-08 sums each rate on its own', () {
      // Two standard rated lines at two rates make two breakdown entries, and
      // each carries only what is taxed at its own rate.
      final invoice = validInvoice(
        lines: [
          invoiceLine(),
          InvoiceLine(
            id: '2',
            quantity: Decimal.one,
            unit: UnitCode.one,
            netAmount: _d('50.00'),
            item: const Item(name: 'A book'),
            price: Price(netPrice: _d('50.00')),
            vatCategory: VatCategory.standardRate,
            vatRate: _d('6'),
          ),
        ],
        vatBreakdown: [
          standardBreakdown(),
          VatBreakdown(
            category: VatCategory.standardRate,
            taxableAmount: _d('50.00'),
            taxAmount: _d('3.00'),
            rate: _d('6'),
          ),
        ],
        totals: standardTotals(
          sumOfLineNetAmounts: _d('150.00'),
          totalWithoutVat: _d('150.00'),
          totalVat: _d('24.00'),
          totalWithVat: _d('174.00'),
          amountDueForPayment: _d('174.00'),
        ),
      );
      expect(broken(invoice), isNot(contains('BR-S-08')));
    });

    test('BR-S-08 catches a taxable amount that is not what is taxed', () {
      final invoice = _taxed(
        category: VatCategory.standardRate,
        rate: rate,
        taxAmount: vat,
        vatBreakdown: [
          VatBreakdown(
            category: VatCategory.standardRate,
            taxableAmount: _d('500.00'),
            taxAmount: _d('105.00'),
            rate: rate,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-S-08'));
    });
  });

  group('zero rated', () {
    test('a zero rated invoice breaks nothing', () {
      final invoice = _taxed(
        category: VatCategory.zeroRated,
        rate: Decimal.zero,
      );
      expect(validate(invoice), isEmpty);
    });

    test('BR-Z-05 refuses a rate above zero', () {
      final invoice = _taxed(category: VatCategory.zeroRated, rate: rate);
      expect(broken(invoice), contains('BR-Z-05'));
    });

    test('BR-Z-09 refuses VAT on a zero rated breakdown', () {
      final invoice = _taxed(
        category: VatCategory.zeroRated,
        rate: Decimal.zero,
        taxAmount: _d('21.00'),
      );
      expect(broken(invoice), contains('BR-Z-09'));
    });

    test('BR-Z-01 allows exactly one zero rated breakdown', () {
      final invoice = _taxed(
        category: VatCategory.zeroRated,
        rate: Decimal.zero,
        vatBreakdown: [
          VatBreakdown(
            category: VatCategory.zeroRated,
            taxableAmount: _d('50.00'),
            taxAmount: Decimal.zero,
            rate: Decimal.zero,
          ),
          VatBreakdown(
            category: VatCategory.zeroRated,
            taxableAmount: _d('50.00'),
            taxAmount: Decimal.zero,
            rate: Decimal.zero,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-Z-01'));
    });

    test('BR-Z-10 refuses an exemption reason', () {
      final invoice = _taxed(
        category: VatCategory.zeroRated,
        rate: Decimal.zero,
        exemptionReason: 'Because',
      );
      expect(broken(invoice), contains('BR-Z-10'));
    });
  });

  group('exempt and reverse charge', () {
    test('BR-E-10 wants a reason for charging no VAT', () {
      final invoice = _taxed(
        category: VatCategory.exempt,
        rate: Decimal.zero,
      );
      expect(broken(invoice), contains('BR-E-10'));
    });

    test('an exempt invoice with a reason breaks nothing', () {
      final invoice = _taxed(
        category: VatCategory.exempt,
        rate: Decimal.zero,
        exemptionReason: 'Article 44 of the VAT directive',
      );
      expect(validate(invoice), isEmpty);
    });

    test('BR-AE-02 wants the buyer identified', () {
      final invoice = _taxed(
        category: VatCategory.reverseCharge,
        rate: Decimal.zero,
        exemptionReason: 'Reverse charge',
      );
      expect(broken(invoice), contains('BR-AE-02'));
    });

    test('a reverse charge invoice with both parties identified passes', () {
      const buyer = Buyer(
        name: 'A buyer',
        address: Address(country: 'NL'),
        vatIdentifier: 'NL123456789B01',
      );
      final invoice = _taxed(
        category: VatCategory.reverseCharge,
        rate: Decimal.zero,
        exemptionReason: 'Reverse charge',
        buyer: buyer,
      );
      expect(validate(invoice), isEmpty);
    });
  });

  group('intra-community supply', () {
    Invoice supply({Delivery? delivery, Buyer? buyer}) => _taxed(
          category: VatCategory.intraCommunitySupply,
          rate: Decimal.zero,
          exemptionReason: 'Intra-community supply',
          buyer: buyer ??
              const Buyer(
                name: 'A buyer',
                address: Address(country: 'NL'),
                vatIdentifier: 'NL123456789B01',
              ),
          delivery: delivery,
        );

    test('BR-IC-11 wants a delivery date or an invoicing period', () {
      expect(broken(supply()), contains('BR-IC-11'));
    });

    test('BR-IC-12 wants the country delivered to', () {
      final invoice = supply(
        delivery: Delivery(date: CalendarDate(2026, 9, 10)),
      );
      final ids = broken(invoice);
      expect(ids, contains('BR-IC-12'));
      expect(ids, isNot(contains('BR-IC-11')));
    });

    test('a complete intra-community supply breaks nothing', () {
      final invoice = supply(
        delivery: Delivery(
          date: CalendarDate(2026, 9, 10),
          address: const Address(country: 'NL'),
        ),
      );
      expect(validate(invoice), isEmpty);
    });

    test('BR-IC-02 wants the buyer VAT identifier', () {
      final invoice = supply(
        buyer: const Buyer(name: 'A buyer', address: Address(country: 'NL')),
        delivery: Delivery(
          date: CalendarDate(2026, 9, 10),
          address: const Address(country: 'NL'),
        ),
      );
      expect(broken(invoice), contains('BR-IC-02'));
    });
  });

  group('not subject to VAT', () {
    Invoice outside({Seller? seller, List<InvoiceLine>? lines}) => _taxed(
          category: VatCategory.outsideScope,
          exemptionReason: 'Not registered for VAT',
          seller: seller ?? _untaxedSeller,
          lines: lines,
        );

    test('an invoice outside the scope of VAT breaks nothing', () {
      expect(validate(outside()), isEmpty);
    });

    test('BR-O-02 refuses a seller VAT identifier', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        vatIdentifier: 'BE0123456789',
      );
      expect(broken(outside(seller: seller)), contains('BR-O-02'));
    });

    test('BR-O-05 refuses a rate on the line', () {
      final invoice = _taxed(
        category: VatCategory.outsideScope,
        rate: Decimal.zero,
        exemptionReason: 'Not registered for VAT',
        seller: _untaxedSeller,
      );
      expect(broken(invoice), contains('BR-O-05'));
    });

    test('BR-O-12 refuses a line of another category', () {
      final invoice = outside(
        lines: [
          InvoiceLine(
            id: '1',
            quantity: Decimal.one,
            unit: UnitCode.one,
            netAmount: net,
            item: const Item(name: 'A thing'),
            price: Price(netPrice: net),
            vatCategory: VatCategory.standardRate,
            vatRate: rate,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-O-12'));
    });

    test('BR-O-11 refuses another breakdown alongside', () {
      final invoice = validInvoice(
        seller: _untaxedSeller,
        lines: [
          InvoiceLine(
            id: '1',
            quantity: Decimal.one,
            unit: UnitCode.one,
            netAmount: net,
            item: const Item(name: 'A thing'),
            price: Price(netPrice: net),
            vatCategory: VatCategory.outsideScope,
          ),
        ],
        vatBreakdown: [
          VatBreakdown(
            category: VatCategory.outsideScope,
            taxableAmount: net,
            taxAmount: Decimal.zero,
            exemptionReason: 'Not registered for VAT',
          ),
          standardBreakdown(
              taxableAmount: Decimal.zero, taxAmount: Decimal.zero),
        ],
        totals: standardTotals(
          totalVat: Decimal.zero,
          totalWithVat: net,
          amountDueForPayment: net,
        ),
      );
      expect(broken(invoice), contains('BR-O-11'));
    });
  });

  group('split payment', () {
    Invoice split({String sellerCountry = 'IT', String buyerCountry = 'IT'}) =>
        _taxed(
          category: VatCategory.transferred,
          rate: rate,
          seller: Seller(
            name: 'Un venditore',
            address: Address(country: sellerCountry),
            vatIdentifier: 'IT12345678901',
          ),
          buyer: Buyer(
            name: 'Un compratore',
            address: Address(country: buyerCountry),
            vatIdentifier: 'IT10987654321',
          ),
        );

    test('BR-B-01 wants both parties in Italy', () {
      expect(broken(split(buyerCountry: 'BE')), contains('BR-B-01'));
      expect(broken(split()), isNot(contains('BR-B-01')));
    });

    test('BR-B-02 refuses split payment beside standard rated', () {
      final invoice = validInvoice(
        seller: const Seller(
          name: 'Un venditore',
          address: Address(country: 'IT'),
          vatIdentifier: 'IT12345678901',
        ),
        buyer: const Buyer(
          name: 'Un compratore',
          address: Address(country: 'IT'),
          vatIdentifier: 'IT10987654321',
        ),
        lines: [
          invoiceLine(),
          InvoiceLine(
            id: '2',
            quantity: Decimal.one,
            unit: UnitCode.one,
            netAmount: net,
            item: const Item(name: 'Another thing'),
            price: Price(netPrice: net),
            vatCategory: VatCategory.transferred,
            vatRate: rate,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-B-02'));
    });
  });
}
