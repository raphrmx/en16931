import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Decimal _d(String value) => Decimal.parse(value);

void main() {
  group('coverage', () {
    test('every BR-DEC rule of the catalogue is accounted for', () {
      final catalogue = ruleCatalogue
          .where((rule) => rule.family == RuleFamily.decimals)
          .map((rule) => rule.id)
          .toSet();
      expect(catalogue, hasLength(21));
      expect(catalogue.difference(accountedRules), isEmpty);
      expect(decimalRules.keys.toSet().difference(catalogue), isEmpty);
    });
  });

  group('two decimals', () {
    test('BR-DEC-18 catches an amount due that needs three', () {
      final invoice = validInvoice(
        totals: standardTotals(amountDueForPayment: _d('121.005')),
      );
      expect(broken(invoice), contains('BR-DEC-18'));
    });

    test('BR-DEC-23 catches a line net amount that needs three', () {
      final line = invoiceLine(netAmount: _d('100.001'));
      expect(broken(validInvoice(lines: [line])), contains('BR-DEC-23'));
    });

    test('BR-DEC-19 and BR-DEC-20 read the VAT breakdown', () {
      final invoice = validInvoice(
        vatBreakdown: [
          standardBreakdown(
            taxableAmount: _d('100.001'),
            taxAmount: _d('21.002'),
          ),
        ],
      );
      expect(broken(invoice), containsAll(['BR-DEC-19', 'BR-DEC-20']));
    });

    test('an amount written with trailing zeros is the same amount', () {
      // The model holds a Decimal, so 100.00 and 100.000 are one value. What
      // the rule catches is an amount that cannot be written with two
      // decimals at all.
      final invoice = validInvoice(
        totals: standardTotals(amountDueForPayment: _d('121.000')),
      );
      expect(broken(invoice), isNot(contains('BR-DEC-18')));
    });

    test('the plain invoice breaks none of them', () {
      final ids = broken(validInvoice());
      expect(ids.where((id) => id.startsWith('BR-DEC')), isEmpty);
    });
  });

  group('the terms the family leaves out', () {
    test('a unit price may carry four decimals', () {
      // BT-146 has no BR-DEC rule: rounding a unit price would change what is
      // being sold, which is why the standard holds the line amount to two
      // decimals rather than the price.
      final line = invoiceLine(price: Price(netPrice: _d('0.0125')));
      final ids = broken(validInvoice(lines: [line]));
      expect(ids.where((id) => id.startsWith('BR-DEC')), isEmpty);
    });

    test('a quantity may carry more than two decimals', () {
      final invoice = validInvoice(
        lines: [
          InvoiceLine(
            id: '1',
            quantity: _d('1.5555'),
            unit: UnitCode.kilogram,
            netAmount: net,
            item: const Item(name: 'A thing'),
            price: Price(netPrice: net),
            vatCategory: VatCategory.standardRate,
            vatRate: rate,
          ),
        ],
      );
      final ids = broken(invoice);
      expect(ids.where((id) => id.startsWith('BR-DEC')), isEmpty);
    });
  });

  group('allowances and charges', () {
    test('BR-DEC-01 reads the document level allowance amount', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.005'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      final violations = validate(
        validInvoice(allowancesAndCharges: [allowance]),
      );
      final violation = violations.firstWhere(
        (v) => v.rule.id == 'BR-DEC-01',
      );
      expect(violation.path, 'document allowance 0');
      expect(violation.message, contains('BT-92'));
    });

    test('BR-DEC-05 reads the charge side, not the allowance side', () {
      final charge = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.charge,
        amount: _d('10.005'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: 'ZZZ',
      );
      final ids = broken(validInvoice(allowancesAndCharges: [charge]));
      expect(ids, contains('BR-DEC-05'));
      expect(ids, isNot(contains('BR-DEC-01')));
    });

    test('BR-DEC-25 reads a line allowance base amount', () {
      final line = invoiceLine(
        allowancesAndCharges: [
          LineAllowanceCharge(
            kind: AllowanceOrCharge.allowance,
            amount: _d('5.00'),
            baseAmount: _d('100.001'),
            reasonCode: '95',
          ),
        ],
      );
      final violations = validate(validInvoice(lines: [line]));
      final violation = violations.firstWhere(
        (v) => v.rule.id == 'BR-DEC-25',
      );
      expect(violation.path, 'line 1, allowance 0');
    });

    test('an absent base amount is not a breach', () {
      final allowance = DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: _d('10.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: rate,
        reasonCode: '95',
      );
      final ids = broken(validInvoice(allowancesAndCharges: [allowance]));
      expect(ids, isNot(contains('BR-DEC-02')));
    });
  });
}
