## 0.1.0

First release.

- Holds the EN 16931 semantic model as Dart objects: the invoice and its
  lines, the seller, the buyer, the payee and the tax representative, the
  addresses and contacts, the delivery, the payment instructions, the document
  and line level allowances and charges, the VAT breakdown and the totals.
- Every field carries the business term it stands for, BT-1 through BT-165,
  and every class the group it stands for, BG-1 through BG-32. The names are
  the ones a reader of the standard already knows, so no mapping table is
  needed to find a field.
- Amounts, quantities, prices and rates are `Decimal`. A monetary amount is
  never a `double`, because an invoice that does not add up is rejected by the
  receiver rather than corrected.
- Dates are `CalendarDate`, a day on the calendar with no time and no zone.
  BT-2 is the day written on the invoice, and holding it in a `DateTime` moves
  it by a day as soon as it crosses a zone.
- The code lists are open, because they are revised without the standard being
  revised: `InvoiceTypeCode`, `PaymentMeansCode` and `UnitCode` name the codes
  that come up and accept any other from the same list. `VatCategory` is the
  one closed list, since the business rules name its codes one by one.
- `Invoice.fromLines` works the VAT breakdown and the totals out of the lines,
  and `InvoiceLine.of` works the line amount out of a quantity and a unit
  price. Both take plain numbers, take dates as `DateTime`, and round what
  they produce to two decimals, so an invoice built this way passes the rules
  that check its arithmetic. Nothing has to be added up by hand.
- The unnamed constructor takes the breakdown and the totals as given, for an
  invoice that was issued elsewhere and has to keep the figures it went out
  with, down to the rounding.
- `en16931Specification` carries BT-24 for an invoice that follows the
  standard and nothing more. A profile sets its own identifier instead.
- Carries the catalogue of the 223 business rules the standard defines, read
  from the validation artefacts it is published with rather than written from
  memory. Each rule comes with its severity and the terms it bears on.
- `validate` states all 223 rules the standard defines: what an invoice has to
  carry, what has to follow from what, how many decimals an amount may be
  written with, which codes it may use, and what each of the ten VAT
  categories asks of it. A violation names the rule, the term and the line it
  was found on.
- The totals are checked against the lines, the allowances and the charges,
  and the VAT of each breakdown against its rate. The tolerance is the one the
  artefacts use: a VAT amount passes while it stays within one unit of
  currency of the rate applied to the taxable amount, because an invoice
  rounding line by line lands a few cents from one rounding once.
- Rules that cannot be broken are listed rather than skipped, with what meets
  them: twenty one of them are met by a constructor that asks for the term.
  Four more are listed as undecidable, because they ask whether a code and the
  words beside it mean the same thing. The published artefacts do not decide
  those either: their test is `true()`.
- The 21 rules of BR-DEC hold every monetary total, line amount, allowance,
  charge and VAT figure to two decimals. The terms the family leaves out stay
  out: a unit price (BT-146) or a quantity (BT-129) may carry more, and
  rounding them would change what is being sold. The model holds a `Decimal`
  rather than the text an amount was typed as, so what is checked is whether
  the amount can be written with two decimals at all.
- The 23 rules of BR-CL check a code against the list it is drawn from, and
  the lists ship with the package: ISO 3166-1 countries, ISO 4217 currencies,
  UN/ECE Recommendation 20 units, ISO 6523 schemes, several UNTDID lists, and
  the EAS and VATEX lists the European Commission publishes. Nothing has to be
  downloaded or configured.
- `VatCategory` gained the code B, VAT transferred to the buyer, which the
  enum was missing. A test now holds the enum and UNCL 5305 to each other in
  both directions, so neither can drift from the other again.
- The ninety eight rules that hold for one VAT category at a time are stated
  as a table of nine profiles rather than as nine near identical families. A
  category answers six questions: how many breakdown entries it may have, what
  its rate has to be, how its VAT is arrived at, whether it has to say why no
  VAT is due, and which identifiers the seller and the buyer need. What is
  left over is written out: the delivery an intra-community supply has to
  name, the exclusivity an invoice outside the scope of VAT demands, and the
  two rules that hold only for Italian split payment.
- A test fails when a rule of the catalogue has no answer, so what is covered
  is a fact rather than a claim.
- No XML, no HTTP, no Flutter. Writing the model out as UBL or CII, and the
  rules a profile adds on top, belong to the companion packages.
