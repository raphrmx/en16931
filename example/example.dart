// ignore_for_file: avoid_print

import 'package:decimal/decimal.dart';
import 'package:en16931/en16931.dart';

/// Builds one invoice: two lines at two different VAT rates and a discount on
/// the whole invoice. The breakdown and the totals are worked out from the
/// lines, and the result is checked against the 223 rules of the standard.
void main() {
  final invoice = Invoice.fromLines(
    number: '2026-0042',
    issueDate: DateTime(2026, 9, 13),
    dueDate: DateTime(2026, 10, 13),
    buyerReference: 'PO-77812',
    seller: const Seller(
      name: 'COMAPPS SRL',
      tradingName: 'ComApps',
      vatIdentifier: 'BE0123456789',
      electronicAddress: Identifier('0123456789', scheme: '0208'),
      address: Address(
        line1: 'Rue Example 1',
        city: 'Bruxelles',
        postalCode: '1000',
        country: 'BE',
      ),
      contact: Contact(name: 'Billing', email: 'billing@example.be'),
    ),
    buyer: const Buyer(
      name: 'Client SA',
      vatIdentifier: 'BE0987654321',
      electronicAddress: Identifier('0987654321', scheme: '0208'),
      address: Address(
        line1: 'Avenue Example 2',
        city: 'Namur',
        postalCode: '5000',
        country: 'BE',
      ),
    ),
    lines: [
      InvoiceLine.of(
        id: '1',
        item: const Item(
          name: 'Consulting',
          description: 'Integration work, September 2026',
          sellerIdentifier: 'SRV-CONS',
        ),
        quantity: 8,
        unitPrice: 150.00,
        vatRate: 21,
        unit: UnitCode.hour,
        period: DatePeriod(
          start: CalendarDate(2026, 9, 1),
          end: CalendarDate(2026, 9, 30),
        ),
      ),
      InvoiceLine.of(
        id: '2',
        item: const Item(
          name: 'Printed manual',
          standardIdentifier: Identifier('5412345678901', scheme: '0160'),
        ),
        quantity: 4,
        unitPrice: 15.00,
        vatRate: 6,
        unit: UnitCode.piece,
      ),
    ],
    allowancesAndCharges: [
      DocumentAllowanceCharge(
        kind: AllowanceOrCharge.allowance,
        amount: Decimal.parse('50.00'),
        vatCategory: VatCategory.standardRate,
        vatRate: Decimal.parse('21'),
        reason: 'Loyalty discount',
        reasonCode: '95',
      ),
    ],
    paymentTerms: 'Payable within 30 days.',
    paymentInstructions: const PaymentInstructions(
      means: PaymentMeansCode.sepaCreditTransfer,
      remittanceInformation: '+++090/9337/55493+++',
      creditTransfers: [
        CreditTransferAccount(
          'BE68539007547034',
          name: 'COMAPPS SRL',
          providerBic: 'GEBABEBB',
        ),
      ],
    ),
  );

  print('Invoice ${invoice.number} of ${invoice.issueDate}');
  print('  ${invoice.seller.name} to ${invoice.buyer.name}');
  for (final line in invoice.lines) {
    print(
      '  line ${line.id}: ${line.item.name}, '
      '${line.quantity} ${line.unit} at ${line.price.netPrice} '
      '= ${line.netAmount} (VAT ${line.vatRate}%)',
    );
  }
  for (final vat in invoice.vatBreakdown) {
    print(
      '  VAT ${vat.rate}% on ${vat.taxableAmount} '
      '= ${vat.taxAmount} (${vat.category})',
    );
  }
  print(
    '  due ${invoice.totals.amountDueForPayment} ${invoice.currency} '
    'by ${invoice.dueDate}',
  );

  final violations = validate(invoice);
  print(violations.isEmpty ? '  checks out' : '  ${violations.length} to fix');
  for (final violation in violations) {
    print('  $violation');
  }
}
