import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('coverage', () {
    test('every BR rule of the catalogue is accounted for', () {
      final catalogue = ruleCatalogue
          .where((rule) => rule.family == RuleFamily.presence)
          .map((rule) => rule.id)
          .toSet();
      final implemented = {
        ...presenceRules.keys,
        ...presenceSatisfiedByConstruction.keys,
      };
      expect(
        catalogue.difference(implemented),
        isEmpty,
        reason: 'Rules the standard defines and this library does not check',
      );
      expect(
        implemented.difference(catalogue),
        isEmpty,
        reason: 'Rules checked under an identifier the standard does not use',
      );
    });

    test('a rule is either evaluated or met by construction, never both', () {
      expect(
        presenceRules.keys.toSet().intersection(
              presenceSatisfiedByConstruction.keys.toSet(),
            ),
        isEmpty,
      );
    });

    test('every implemented rule is in the catalogue', () {
      for (final id in presenceRules.keys) {
        expect(() => ruleFor(id), returnsNormally, reason: id);
      }
      expect(() => ruleFor('BR-999'), throwsArgumentError);
    });
  });

  group('an invoice that breaks nothing', () {
    test('passes', () {
      expect(validate(validInvoice()), isEmpty);
      expect(isAcceptable(validInvoice()), isTrue);
    });
  });

  group('presence', () {
    test('BR-01 wants a specification identifier', () {
      expect(
        broken(validInvoice(specificationIdentifier: null)),
        contains('BR-01'),
      );
      expect(broken(validInvoice(specificationIdentifier: '  ')),
          contains('BR-01'));
    });

    test('BR-02 reads an empty number as a missing one', () {
      expect(broken(validInvoice(number: '')), contains('BR-02'));
      expect(broken(validInvoice(number: '   ')), contains('BR-02'));
    });

    test('BR-16 wants at least one line', () {
      expect(broken(validInvoice(lines: [])), contains('BR-16'));
    });

    test('BR-21 wants an identifier on each line', () {
      expect(
        broken(validInvoice(lines: [invoiceLine(id: '')])),
        contains('BR-21'),
      );
    });

    test('BR-25 wants a name on each item', () {
      expect(
        broken(validInvoice(lines: [invoiceLine(item: const Item(name: ''))])),
        contains('BR-25'),
      );
    });
  });

  group('amounts and dates', () {
    test('BR-27 refuses a negative net price', () {
      final line = invoiceLine(price: Price(netPrice: Decimal.parse('-1.00')));
      expect(broken(validInvoice(lines: [line])), contains('BR-27'));
    });

    test('BR-28 refuses a negative gross price', () {
      final line = invoiceLine(
        price: Price(netPrice: net, grossPrice: Decimal.parse('-1.00')),
      );
      expect(broken(validInvoice(lines: [line])), contains('BR-28'));
    });

    test('BR-29 refuses a period that ends before it starts', () {
      final period = DatePeriod(
        start: CalendarDate(2026, 9, 30),
        end: CalendarDate(2026, 9, 1),
      );
      expect(broken(validInvoice(invoicingPeriod: period)), contains('BR-29'));
      expect(
        broken(
          validInvoice(
            invoicingPeriod: DatePeriod(
              start: CalendarDate(2026, 9, 1),
              end: CalendarDate(2026, 9, 1),
            ),
          ),
        ),
        isNot(contains('BR-29')),
      );
    });

    test('BR-30 refuses a line period that ends before it starts', () {
      final line = invoiceLine(
        period: DatePeriod(
          start: CalendarDate(2026, 9, 30),
          end: CalendarDate(2026, 9, 1),
        ),
      );
      expect(broken(validInvoice(lines: [line])), contains('BR-30'));
    });
  });

  group('allowances and charges', () {
    test('BR-33 wants a reason or a reason code on a document allowance', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: Decimal.parse('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
      );
      final ids = broken(validInvoice(allowancesAndCharges: [allowance]));
      expect(ids, contains('BR-33'));
      expect(ids, isNot(contains('BR-38')));
    });

    test('BR-38 wants the same on a document charge', () {
      final charge = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.charge,
        amount: Decimal.parse('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
      );
      final ids = broken(validInvoice(allowancesAndCharges: [charge]));
      expect(ids, contains('BR-38'));
      expect(ids, isNot(contains('BR-33')));
    });

    test('a reason code alone is enough', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: Decimal.parse('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      expect(
        broken(validInvoice(allowancesAndCharges: [allowance])),
        isNot(contains('BR-33')),
      );
    });

    test('BR-42 wants a reason on a line allowance', () {
      final line = invoiceLine(
        allowancesAndCharges: [
          LineAllowanceCharge(
            kind: AllowanceOrCharge.allowance,
            amount: Decimal.parse('5.00'),
          ),
        ],
      );
      expect(broken(validInvoice(lines: [line])), contains('BR-42'));
    });
  });

  group('VAT', () {
    test('BR-48 wants a rate on every breakdown', () {
      final breakdown = [
        VatBreakdown(
          category: VatCategory.standardRate,
          taxableAmount: net,
          taxAmount: vat,
        ),
      ];
      expect(broken(validInvoice(vatBreakdown: breakdown)), contains('BR-48'));
    });

    test('BR-48 lets an invoice outside the scope of VAT through', () {
      final breakdown = [
        VatBreakdown(
          category: VatCategory.outsideScope,
          taxableAmount: net,
          taxAmount: Decimal.zero,
          exemptionReason: 'Not registered for VAT',
        ),
      ];
      expect(
        broken(validInvoice(vatBreakdown: breakdown)),
        isNot(contains('BR-48')),
      );
    });

    test('BR-53 wants the VAT total in the accounting currency', () {
      expect(
        broken(validInvoice(vatAccountingCurrency: 'SEK')),
        contains('BR-53'),
      );
    });
  });

  group('payment', () {
    test('BR-61 wants an account for a credit transfer', () {
      const instructions = PaymentInstructions(
        means: PaymentMeansCode.sepaCreditTransfer,
      );
      expect(
        broken(validInvoice(paymentInstructions: instructions)),
        contains('BR-61'),
      );
    });

    test('BR-61 leaves other payment means alone', () {
      const instructions = PaymentInstructions(
        means: PaymentMeansCode.inCash,
      );
      expect(
        broken(validInvoice(paymentInstructions: instructions)),
        isNot(contains('BR-61')),
      );
    });

    test('BR-51 refuses a full card number', () {
      const instructions = PaymentInstructions(
        means: PaymentMeansCode.bankCard,
        card: PaymentCard('4111111111111111'),
      );
      expect(
        broken(validInvoice(paymentInstructions: instructions)),
        contains('BR-51'),
      );
    });

    test('BR-51 takes the six and four digits the card standards allow', () {
      const instructions = PaymentInstructions(
        means: PaymentMeansCode.bankCard,
        card: PaymentCard('411111******1111'),
      );
      expect(
        broken(validInvoice(paymentInstructions: instructions)),
        isNot(contains('BR-51')),
      );
    });
  });

  group('electronic addresses', () {
    test('BR-62 and BR-63 want a scheme', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        electronicAddress: Identifier('0123456789'),
      );
      const buyer = Buyer(
        name: 'A buyer',
        address: Address(country: 'BE'),
        electronicAddress: Identifier('0987654321'),
      );
      final ids = broken(validInvoice(seller: seller, buyer: buyer));
      expect(ids, containsAll(['BR-62', 'BR-63']));
    });

    test('a scheme satisfies them', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        electronicAddress: Identifier('0123456789', scheme: '0208'),
      );
      expect(broken(validInvoice(seller: seller)), isNot(contains('BR-62')));
    });

    test('BR-64 wants a scheme on the item standard identifier', () {
      final line = invoiceLine(
        item: const Item(
          name: 'A thing',
          standardIdentifier: Identifier('5412345678901'),
        ),
      );
      expect(broken(validInvoice(lines: [line])), contains('BR-64'));
    });
  });

  group('violations', () {
    test('say which line they are about', () {
      final violations = validate(
        validInvoice(lines: [invoiceLine(id: '7', item: const Item(name: ''))]),
      );
      final violation = violations.firstWhere((v) => v.rule.id == 'BR-25');
      expect(violation.path, 'line 7');
      expect(violation.toString(), startsWith('[BR-25] line 7:'));
    });

    test('carry the rule they come from', () {
      final violation = validate(
        validInvoice(lines: [], totals: emptyTotals()),
      ).firstWhere((v) => v.rule.id == 'BR-16');
      expect(violation.rule.id, 'BR-16');
      expect(violation.rule.severity, RuleSeverity.fatal);
      expect(violation.rule.terms, contains('BG-25'));
    });
  });
}
