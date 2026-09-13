import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('coverage', () {
    test('every BR-CL rule of the catalogue is accounted for', () {
      final catalogue = ruleCatalogue
          .where((rule) => rule.family == RuleFamily.codeList)
          .map((rule) => rule.id)
          .toSet();
      expect(catalogue, hasLength(23));
      expect(catalogue.difference(accountedRules), isEmpty);
      expect(codeListRules.keys.toSet().difference(catalogue), isEmpty);
    });

    test('every rule that reads a list has one to read', () {
      for (final id in codeListRules.keys) {
        expect(codeListByRule[id], isNotNull, reason: id);
        expect(codeListByRule[id], isNotEmpty, reason: id);
      }
    });
  });

  group('the lists', () {
    test('hold what the standard points at', () {
      expect(iso3166Countries, contains('BE'));
      expect(iso4217Currencies, contains('EUR'));
      expect(unece20UnitCodes, containsAll(['C62', 'H87', 'KGM', 'HUR']));
      expect(attachmentMimeTypes, contains('application/pdf'));
      expect(cefEasSchemes, contains('0208'));
    });

    test('the VAT category enum and UNCL 5305 are the same list', () {
      // Neither may drift: a code in the list with no enum member cannot be
      // expressed, and an enum member the list does not hold would be written
      // into an invoice no receiver accepts. This is what caught B, which the
      // enum was missing.
      final fromEnum = VatCategory.values.map((c) => c.code).toSet();
      expect(fromEnum.difference(uncl5305VatCategories), isEmpty);
      expect(uncl5305VatCategories.difference(fromEnum), isEmpty);
    });

    test('the named code constants are all in their list', () {
      expect(
          untdid1001DocumentTypes, contains(InvoiceTypeCode.creditNote.value));
      expect(
        untdid4461PaymentMeans,
        contains(PaymentMeansCode.sepaCreditTransfer.value),
      );
      expect(unece20UnitCodes, contains(UnitCode.kilowattHour.value));
    });
  });

  group('codes an invoice may carry', () {
    test('the plain invoice breaks none of them', () {
      expect(broken(validInvoice()).where((id) => id.startsWith('BR-CL')),
          isEmpty);
    });

    test('BR-CL-14 catches a country that is not a country', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'XX'),
        vatIdentifier: 'BE0123456789',
      );
      expect(broken(validInvoice(seller: seller)), contains('BR-CL-14'));
    });

    test('BR-CL-14 reads every address, not only the seller', () {
      const representative = TaxRepresentative(
        name: 'A representative',
        vatIdentifier: 'FR12345678901',
        address: Address(country: 'ZZ'),
      );
      final violations = validate(
        validInvoice(taxRepresentative: representative),
      );
      final violation = violations.firstWhere((v) => v.rule.id == 'BR-CL-14');
      expect(violation.path, 'tax representative address');
    });

    test('BR-CL-04 catches a currency that is not a currency', () {
      final invoice = validInvoice();
      final wrong = Invoice(
        number: invoice.number,
        issueDate: invoice.issueDate,
        typeCode: invoice.typeCode,
        currency: 'EURO',
        specificationIdentifier: invoice.specificationIdentifier,
        seller: invoice.seller,
        buyer: invoice.buyer,
        lines: invoice.lines,
        vatBreakdown: invoice.vatBreakdown,
        totals: invoice.totals,
      );
      final ids = broken(wrong);
      expect(ids, containsAll(['BR-CL-04', 'BR-CL-03']));
    });

    test('BR-CL-05 reads the VAT accounting currency', () {
      final invoice = validInvoice(
        vatAccountingCurrency: 'ZZZZ',
        totals: standardTotals(),
      );
      expect(broken(invoice), contains('BR-CL-05'));
    });

    test('BR-CL-23 catches a unit that is not in Recommendation 20', () {
      final invoice = validInvoice(
        lines: [
          InvoiceLine(
            id: '1',
            quantity: Decimal.one,
            unit: const UnitCode('PIECES'),
            netAmount: net,
            item: const Item(name: 'A thing'),
            price: Price(netPrice: net),
            vatCategory: VatCategory.standardRate,
            vatRate: rate,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-CL-23'));
    });

    test('BR-CL-16 catches a payment means that is not one', () {
      const instructions = PaymentInstructions(
        means: PaymentMeansCode('99999'),
      );
      expect(
        broken(validInvoice(paymentInstructions: instructions)),
        contains('BR-CL-16'),
      );
    });

    test('BR-CL-25 catches an electronic address scheme that is not one', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        vatIdentifier: 'BE0123456789',
        electronicAddress: Identifier('0123456789', scheme: 'KBO'),
      );
      expect(broken(validInvoice(seller: seller)), contains('BR-CL-25'));
    });

    test('BR-CL-19 catches an allowance reason code that is not one', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: Decimal.parse('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: 'DISCOUNT',
      );
      expect(
        broken(validInvoice(allowancesAndCharges: [allowance])),
        contains('BR-CL-19'),
      );
    });

    test('BR-CL-19 takes the code the list does hold', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: Decimal.parse('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      expect(
        broken(validInvoice(allowancesAndCharges: [allowance])),
        isNot(contains('BR-CL-19')),
      );
    });

    test('BR-CL-15 reads the item origin country', () {
      final line = invoiceLine(
        item: const Item(name: 'A thing', originCountry: 'XX'),
      );
      expect(broken(validInvoice(lines: [line])), contains('BR-CL-15'));
    });

    test('BR-CL-21 reads the item standard identifier scheme', () {
      final line = invoiceLine(
        item: const Item(
          name: 'A thing',
          standardIdentifier: Identifier('5412345678901', scheme: 'GTIN'),
        ),
      );
      final ids = broken(validInvoice(lines: [line]));
      expect(ids, contains('BR-CL-21'));
      // The scheme is there, so the rule that wants one is quiet.
      expect(ids, isNot(contains('BR-64')));
    });

    test('an absent code is not a breach', () {
      expect(
        broken(validInvoice()),
        isNot(anyOf(contains('BR-CL-06'), contains('BR-CL-22'))),
      );
    });
  });
}
