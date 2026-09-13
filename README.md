<a alt="ComApps Logo" href="https://comapps.be" target="_blank" rel="noreferrer"><img src="https://www.comapps.be/wp-content/uploads/2026/09/CompleteLogoHorizontalMini.png" style="margin: 15px"></a>

# EN 16931

[![Build](https://img.shields.io/github/actions/workflow/status/raphrmx/en16931/ci.yml?branch=main&label=build)](https://github.com/raphrmx/en16931/actions/workflows/ci.yml)
[![Pub Version](https://img.shields.io/pub/v/en16931?color=blue)](https://pub.dev/packages/en16931)
[![Maintainer](https://img.shields.io/badge/Maintainer-Raphael_Vrient-purple)](https://pub.dev/publishers/comapps.be/packages)
[![License](https://img.shields.io/badge/Licence-MIT-blue)](/LICENSE)
![Maintenance](https://img.shields.io/badge/Maintained-yes-success)

The European electronic invoice as Dart objects, with the 223 business rules
that decide whether a receiver accepts it.

Pure Dart. No XML, no HTTP, no Flutter, one dependency.

## Install

```yaml
dependencies:
  en16931: ^0.1.0
```

## Build an invoice

Give it the lines and it works out the VAT breakdown and every total. Nothing
to add up by hand.

```dart
import 'package:en16931/en16931.dart';

final invoice = Invoice.fromLines(
  number: '2026-0042',
  issueDate: DateTime(2026, 9, 13),
  dueDate: DateTime(2026, 10, 13),
  seller: const Seller(
    name: 'COMAPPS SRL',
    vatIdentifier: 'BE0123456789',
    address: Address(city: 'Bruxelles', postalCode: '1000', country: 'BE'),
  ),
  buyer: const Buyer(
    name: 'Client SA',
    address: Address(city: 'Namur', postalCode: '5000', country: 'BE'),
  ),
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

invoice.totals.amountDueForPayment; // 1452.00
```

Lines at different rates land in their own breakdown entry, document level
allowances come off the bracket they belong to, and amounts are rounded to two
decimals as they are worked out.

## Check it

```dart
for (final violation in validate(invoice)) {
  print(violation); // [BR-25] line 7: The item name (BT-153) is empty.
}
```

An empty result means the invoice satisfies EN 16931. Violations carry the
identifier the standard uses, so a receiver rejecting on `BR-CO-13` points at
the rule you can look up.

## Worth knowing up front

Pass quantities, prices and rates as plain numbers. The builders read them
exactly as written and hold them as `Decimal` from there on, because binary
floating point does not survive a VAT breakdown. Dates go in as `DateTime`
and come back as `CalendarDate`, a day with no time and no zone, so nothing
shifts the invoice date by a day across a time zone.

An invoice that was issued elsewhere goes through the unnamed constructor
instead, with its own breakdown and totals. It keeps the figures it went out
with, down to the rounding, and `validate` says whether they follow from the
lines.

Fields carry the business term they stand for, BT-1 to BT-165, so the
documentation of a field is what the standard says about it.

Code lists ship with the package, from the ISO 3166 countries to the 2162
units of UN/ECE Recommendation 20. Nothing to download or configure. The named
constants cover the codes that come up, and any other code from the same list
is accepted.

```dart
InvoiceTypeCode.creditNote;    // 381
const InvoiceTypeCode('875');  // partial construction invoice
```

An identifier says which register it came from, because the number alone is
not findable. `Scheme` names the ones that come up.

```dart
Identifier('0123456749', scheme: Scheme.belgianEnterprise);
Identifier('5412345678901', scheme: Scheme.gtin);
```

They are constants and not an enum: the codes are drawn from different lists
depending on the term that carries them, those lists are revised on their own
schedule, and a profile narrows some of them. Any other code from the same
list is written as it is.

## What it does not do

Writing the invoice out as UBL or CII belongs to a syntax package, and the
extra rules of Peppol, XRechnung or Factur-X to a profile package. Sending it
is a different problem again. This is the document, checked.

## License

MIT.
