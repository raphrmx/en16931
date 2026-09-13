import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Decimal _d(String value) => Decimal.parse(value);

void main() {
  group('coverage', () {
    test('every BR-CO rule of the catalogue is accounted for', () {
      final catalogue = ruleCatalogue
          .where((rule) => rule.family == RuleFamily.condition)
          .map((rule) => rule.id)
          .toSet();
      expect(
        catalogue.difference(accountedRules),
        isEmpty,
        reason: 'Rules the standard defines and this library does not answer',
      );
    });

    test('the three answers never overlap', () {
      expect(
        implementedRules.intersection(rulesMetByConstruction.keys.toSet()),
        isEmpty,
      );
      expect(
        implementedRules.intersection(rulesNotMachineCheckable.keys.toSet()),
        isEmpty,
      );
    });

    test('says which rules no program can decide, and why', () {
      expect(rulesNotMachineCheckable.keys, contains('BR-CO-05'));
      expect(rulesNotMachineCheckable['BR-CO-05'], contains('BT-98'));
    });
  });

  group('the totals', () {
    test('BR-CO-10 catches a sum that is not the sum of the lines', () {
      final invoice = validInvoice(
        lines: [invoiceLine(), invoiceLine(id: '2')],
        totals: standardTotals(sumOfLineNetAmounts: net),
      );
      expect(broken(invoice), contains('BR-CO-10'));
    });

    test('BR-CO-10 passes when the lines add up', () {
      final invoice = validInvoice(
        lines: [invoiceLine(), invoiceLine(id: '2')],
        totals: standardTotals(
          sumOfLineNetAmounts: _d('200.00'),
          totalWithoutVat: _d('200.00'),
          totalVat: _d('42.00'),
          totalWithVat: _d('242.00'),
          amountDueForPayment: _d('242.00'),
        ),
        vatBreakdown: [
          standardBreakdown(
            taxableAmount: _d('200.00'),
            taxAmount: _d('42.00'),
          ),
        ],
      );
      expect(broken(invoice), isNot(contains('BR-CO-10')));
    });

    test('BR-CO-11 wants the allowance total when there are allowances', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      expect(
        broken(validInvoice(allowancesAndCharges: [allowance])),
        contains('BR-CO-11'),
      );
    });

    test('BR-CO-11 stays quiet when there is nothing to sum', () {
      expect(broken(validInvoice()), isNot(contains('BR-CO-11')));
    });

    test('BR-CO-13 catches a total that ignores an allowance', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      final invoice = validInvoice(
        allowancesAndCharges: [allowance],
        totals: standardTotals(sumOfAllowances: _d('10.00')),
      );
      expect(broken(invoice), contains('BR-CO-13'));
    });

    test('BR-CO-13 accepts the total once the allowance is taken off', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      final invoice = validInvoice(
        allowancesAndCharges: [allowance],
        totals: standardTotals(
          sumOfAllowances: _d('10.00'),
          totalWithoutVat: _d('90.00'),
          totalVat: _d('18.90'),
          totalWithVat: _d('108.90'),
          amountDueForPayment: _d('108.90'),
        ),
        vatBreakdown: [
          standardBreakdown(taxableAmount: _d('90.00'), taxAmount: _d('18.90')),
        ],
      );
      expect(broken(invoice), isNot(contains('BR-CO-13')));
    });

    test('BR-CO-14 catches a VAT total that is not the breakdown', () {
      final invoice = validInvoice(
        vatBreakdown: [standardBreakdown(taxAmount: _d('10.00'))],
      );
      expect(broken(invoice), contains('BR-CO-14'));
    });

    test('BR-CO-15 catches a total with VAT that does not follow', () {
      final invoice = validInvoice(
        totals: standardTotals(totalWithVat: _d('999.00')),
      );
      expect(broken(invoice), contains('BR-CO-15'));
    });

    test('BR-CO-16 takes the paid amount and the rounding into account', () {
      final invoice = validInvoice(
        totals: standardTotals(
          paidAmount: _d('21.00'),
          roundingAmount: _d('0.05'),
          amountDueForPayment: _d('100.05'),
        ),
      );
      expect(broken(invoice), isNot(contains('BR-CO-16')));
    });

    test('BR-CO-16 catches an amount due that ignores what was paid', () {
      final invoice = validInvoice(
        totals: standardTotals(paidAmount: _d('21.00')),
      );
      expect(broken(invoice), contains('BR-CO-16'));
    });
  });

  group('BR-CO-17', () {
    test('accepts a VAT amount within a unit of what the rate gives', () {
      // 100.00 at 21% is 21.00, and the artefacts accept anything closer than
      // one unit of currency, which is what an invoice rounding line by line
      // lands on.
      final invoice = validInvoice(
        vatBreakdown: [standardBreakdown(taxAmount: _d('21.99'))],
      );
      expect(broken(invoice), isNot(contains('BR-CO-17')));
    });

    test('refuses an amount a whole unit away', () {
      final invoice = validInvoice(
        vatBreakdown: [standardBreakdown(taxAmount: _d('22.00'))],
      );
      expect(broken(invoice), contains('BR-CO-17'));
    });

    test('wants nothing when the rate rounds to zero', () {
      final invoice = validInvoice(
        vatBreakdown: [
          VatBreakdown(
            category: VatCategory.zeroRated,
            taxableAmount: net,
            taxAmount: Decimal.zero,
            rate: Decimal.zero,
          ),
        ],
        totals: standardTotals(
          totalVat: Decimal.zero,
          totalWithVat: net,
          amountDueForPayment: net,
        ),
      );
      expect(broken(invoice), isNot(contains('BR-CO-17')));
    });

    test('refuses VAT charged at a rate of zero', () {
      final invoice = validInvoice(
        vatBreakdown: [
          VatBreakdown(
            category: VatCategory.zeroRated,
            taxableAmount: net,
            taxAmount: _d('21.00'),
            rate: Decimal.zero,
          ),
        ],
      );
      expect(broken(invoice), contains('BR-CO-17'));
    });
  });

  group('groups that have to carry something', () {
    test('BR-CO-18 wants a VAT breakdown', () {
      expect(broken(validInvoice(vatBreakdown: [])), contains('BR-CO-18'));
    });

    test('BR-CO-19 wants a date in an invoicing period', () {
      expect(
        broken(validInvoice(invoicingPeriod: const DatePeriod())),
        contains('BR-CO-19'),
      );
      expect(
        broken(
          validInvoice(
            invoicingPeriod: DatePeriod(start: CalendarDate(2026, 9, 1)),
          ),
        ),
        isNot(contains('BR-CO-19')),
      );
    });

    test('BR-CO-20 wants a date in a line period', () {
      final line = invoiceLine(period: const DatePeriod());
      expect(broken(validInvoice(lines: [line])), contains('BR-CO-20'));
    });
  });

  group('dates and identifiers', () {
    test('BR-CO-03 refuses both a VAT point date and its code', () {
      final invoice = validInvoice(
        vatPointDate: CalendarDate(2026, 9, 30),
        vatPointDateCode: '3',
      );
      expect(broken(invoice), contains('BR-CO-03'));
    });

    test('BR-CO-03 takes either one alone', () {
      expect(
        broken(validInvoice(vatPointDate: CalendarDate(2026, 9, 30))),
        isNot(contains('BR-CO-03')),
      );
      expect(
        broken(validInvoice(vatPointDateCode: '3')),
        isNot(contains('BR-CO-03')),
      );
    });

    test('BR-CO-09 wants a country prefix on a VAT identifier', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        vatIdentifier: '0123456789',
      );
      expect(broken(validInvoice(seller: seller)), contains('BR-CO-09'));
    });

    test('BR-CO-09 lets the Greek EL prefix through', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'GR'),
        vatIdentifier: 'EL123456789',
      );
      expect(
        broken(validInvoice(seller: seller)),
        isNot(contains('BR-CO-09')),
      );
    });

    test('BR-CO-09 reads the tax representative too', () {
      const representative = TaxRepresentative(
        name: 'A representative',
        vatIdentifier: '999999999',
        address: Address(country: 'FR'),
      );
      expect(
        broken(validInvoice(taxRepresentative: representative)),
        contains('BR-CO-09'),
      );
    });

    test('BR-CO-26 wants the seller identifiable', () {
      const seller = Seller(name: 'A seller', address: Address(country: 'BE'));
      expect(broken(validInvoice(seller: seller)), contains('BR-CO-26'));
    });

    test('BR-CO-26 takes a legal registration identifier alone', () {
      const seller = Seller(
        name: 'A seller',
        address: Address(country: 'BE'),
        legalRegistrationIdentifier: Identifier('0123456789', scheme: '0208'),
      );
      expect(
        broken(validInvoice(seller: seller)),
        isNot(contains('BR-CO-26')),
      );
    });
  });

  group('the rules the standard states twice', () {
    test('an allowance with no reason breaks BR-33 and BR-CO-21 both', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
      );
      final ids = broken(validInvoice(allowancesAndCharges: [allowance]));
      expect(ids, containsAll(['BR-33', 'BR-CO-21']));
    });

    test('a line charge with no reason breaks BR-44 and BR-CO-24 both', () {
      final line = invoiceLine(
        allowancesAndCharges: [
          LineAllowanceCharge(
            kind: AllowanceOrCharge.charge,
            amount: _d('5.00'),
          ),
        ],
      );
      final ids = broken(validInvoice(lines: [line]));
      expect(ids, containsAll(['BR-44', 'BR-CO-24']));
    });
  });
}
