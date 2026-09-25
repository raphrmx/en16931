import 'package:decimal/decimal.dart';
import 'package:en16931/src/codes/vat_category.dart';
import 'package:en16931/src/model/allowance_charge.dart';
import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/model/line.dart';
import 'package:en16931/src/model/vat_breakdown.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';

/// How many entries of its own category a breakdown may hold.
enum _Cardinality { atLeastOne, exactlyOne }

/// What the VAT rate of a line, allowance or charge has to be.
enum _RateRule { positive, zero, zeroOrPositive, absent }

/// What the VAT amount of the breakdown has to be.
enum _TaxRule { fromRate, zero }

/// Whether the breakdown has to say why no VAT is due.
enum _ExemptionRule { forbidden, required }

/// Which identifiers the seller has to carry, or must not.
enum _SellerRule { taxIdentifiers, vatOrRepresentative, forbidden }

/// Which identifiers the buyer has to carry, or must not.
enum _BuyerRule { none, vatOrRegistration, vat, forbidden }

/// One VAT category, and what the standard asks of an invoice that uses it.
///
/// The ten categories are stated as ten near identical families of rules, and
/// what separates them is this handful of answers. Writing them as a table
/// keeps the differences visible: BR-S wants a rate above zero where BR-Z
/// wants zero, and BR-O wants no rate at all.
final class _VatProfile {
  const _VatProfile({
    required this.category,
    required this.prefix,
    required this.label,
    required this.cardinality,
    required this.rate,
    required this.tax,
    required this.exemption,
    required this.seller,
    this.buyer = _BuyerRule.none,
  });

  final VatCategory category;
  final String prefix;
  final String label;
  final _Cardinality cardinality;
  final _RateRule rate;
  final _TaxRule tax;
  final _ExemptionRule exemption;
  final _SellerRule seller;
  final _BuyerRule buyer;
}

const List<_VatProfile> _profiles = [
  _VatProfile(
    category: VatCategory.standardRate,
    prefix: 'BR-S',
    label: 'standard rated',
    cardinality: _Cardinality.atLeastOne,
    rate: _RateRule.positive,
    tax: _TaxRule.fromRate,
    exemption: _ExemptionRule.forbidden,
    seller: _SellerRule.taxIdentifiers,
  ),
  _VatProfile(
    category: VatCategory.zeroRated,
    prefix: 'BR-Z',
    label: 'zero rated',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.zero,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.forbidden,
    seller: _SellerRule.taxIdentifiers,
  ),
  _VatProfile(
    category: VatCategory.exempt,
    prefix: 'BR-E',
    label: 'exempt from VAT',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.zero,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.required,
    seller: _SellerRule.taxIdentifiers,
  ),
  _VatProfile(
    category: VatCategory.reverseCharge,
    prefix: 'BR-AE',
    label: 'reverse charge',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.zero,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.required,
    seller: _SellerRule.taxIdentifiers,
    buyer: _BuyerRule.vatOrRegistration,
  ),
  _VatProfile(
    category: VatCategory.intraCommunitySupply,
    prefix: 'BR-IC',
    label: 'intra-community supply',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.zero,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.required,
    seller: _SellerRule.vatOrRepresentative,
    buyer: _BuyerRule.vat,
  ),
  _VatProfile(
    category: VatCategory.exportOutsideEu,
    prefix: 'BR-G',
    label: 'export outside the European Union',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.zero,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.required,
    seller: _SellerRule.vatOrRepresentative,
  ),
  _VatProfile(
    category: VatCategory.outsideScope,
    prefix: 'BR-O',
    label: 'not subject to VAT',
    cardinality: _Cardinality.exactlyOne,
    rate: _RateRule.absent,
    tax: _TaxRule.zero,
    exemption: _ExemptionRule.required,
    seller: _SellerRule.forbidden,
    buyer: _BuyerRule.forbidden,
  ),
  _VatProfile(
    category: VatCategory.canaryIslands,
    prefix: 'BR-AF',
    label: 'Canary Islands general indirect tax',
    cardinality: _Cardinality.atLeastOne,
    rate: _RateRule.zeroOrPositive,
    tax: _TaxRule.fromRate,
    exemption: _ExemptionRule.forbidden,
    seller: _SellerRule.taxIdentifiers,
  ),
  _VatProfile(
    category: VatCategory.ceutaAndMelilla,
    prefix: 'BR-AG',
    label: 'tax of Ceuta and Melilla',
    cardinality: _Cardinality.atLeastOne,
    rate: _RateRule.zeroOrPositive,
    tax: _TaxRule.fromRate,
    exemption: _ExemptionRule.forbidden,
    seller: _SellerRule.taxIdentifiers,
  ),
];

/// The rules that hold for one VAT category at a time.
///
/// {@category validation}
final Map<String, RuleCheck> vatCategoryRules = {
  for (final profile in _profiles) ..._rulesOf(profile),
  'BR-IC-11': _brIc11,
  'BR-IC-12': _brIc12,
  'BR-O-11': _brO11,
  'BR-O-12': _brO12,
  'BR-O-13': _brO13,
  'BR-O-14': _brO14,
  'BR-B-01': _brB01,
  'BR-B-02': _brB02,
};

Map<String, RuleCheck> _rulesOf(_VatProfile p) => {
      '${p.prefix}-01': (invoice, rule) => _breakdownPresent(invoice, rule, p),
      '${p.prefix}-02': (invoice, rule) =>
          _identifiers(invoice, rule, p, _Scope.line),
      '${p.prefix}-03': (invoice, rule) =>
          _identifiers(invoice, rule, p, _Scope.allowance),
      '${p.prefix}-04': (invoice, rule) =>
          _identifiers(invoice, rule, p, _Scope.charge),
      '${p.prefix}-05': (invoice, rule) =>
          _rateOf(invoice, rule, p, _Scope.line),
      '${p.prefix}-06': (invoice, rule) =>
          _rateOf(invoice, rule, p, _Scope.allowance),
      '${p.prefix}-07': (invoice, rule) =>
          _rateOf(invoice, rule, p, _Scope.charge),
      '${p.prefix}-08': (invoice, rule) => _taxableAmount(invoice, rule, p),
      '${p.prefix}-09': (invoice, rule) => _taxAmount(invoice, rule, p),
      '${p.prefix}-10': (invoice, rule) => _exemption(invoice, rule, p),
    };

/// Which of the three places a category can be used the rule is about.
enum _Scope { line, allowance, charge }

// --- Reading the invoice ---------------------------------------------------

List<InvoiceLine> _linesOf(Invoice invoice, VatCategory category) =>
    invoice.lines.where((line) => line.vatCategory == category).toList();

List<DocumentAllowanceCharge> _entriesOf(
  Invoice invoice,
  VatCategory category,
  AllowanceOrCharge kind,
) =>
    invoice.allowancesAndCharges
        .where((entry) => entry.kind == kind && entry.vatCategory == category)
        .toList();

List<VatBreakdown> _breakdownsOf(Invoice invoice, VatCategory category) =>
    invoice.vatBreakdown.where((entry) => entry.category == category).toList();

/// Whether anything on the invoice is taxed under [category].
bool _uses(Invoice invoice, VatCategory category) =>
    _linesOf(invoice, category).isNotEmpty ||
    _entriesOf(invoice, category, AllowanceOrCharge.allowance).isNotEmpty ||
    _entriesOf(invoice, category, AllowanceOrCharge.charge).isNotEmpty;

String _nameOf(_Scope scope) => switch (scope) {
      _Scope.line => 'line',
      _Scope.allowance => 'document allowance',
      _Scope.charge => 'document charge',
    };

// --- The rules -------------------------------------------------------------

/// The -01 rule: what is used has to appear in the breakdown.
Iterable<RuleViolation> _breakdownPresent(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
) sync* {
  if (!_uses(invoice, p.category)) return;
  final entries = _breakdownsOf(invoice, p.category);
  if (entries.isEmpty) {
    yield at(
      rule,
      'The invoice is ${p.label} somewhere, so the VAT breakdown (BG-23) has '
      'to carry that category.',
    );
    return;
  }
  if (p.cardinality == _Cardinality.exactlyOne && entries.length > 1) {
    yield at(
      rule,
      'The VAT breakdown carries ${entries.length} entries that are '
      '${p.label}, where the standard allows exactly one.',
    );
  }
}

/// The -02, -03 and -04 rules: who has to be identified for tax.
Iterable<RuleViolation> _identifiers(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
  _Scope scope,
) sync* {
  final used = switch (scope) {
    _Scope.line => _linesOf(invoice, p.category).isNotEmpty,
    _Scope.allowance =>
      _entriesOf(invoice, p.category, AllowanceOrCharge.allowance).isNotEmpty,
    _Scope.charge =>
      _entriesOf(invoice, p.category, AllowanceOrCharge.charge).isNotEmpty,
  };
  if (!used) return;

  final seller = invoice.seller;
  final representative = invoice.taxRepresentative?.vatIdentifier;
  final noun = _nameOf(scope);

  switch (p.seller) {
    case _SellerRule.taxIdentifiers:
      final identified = !blank(seller.vatIdentifier) ||
          !blank(seller.taxRegistrationIdentifier) ||
          !blank(representative);
      if (!identified) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the seller needs a VAT identifier '
          '(BT-31), a tax registration identifier (BT-32) or a tax '
          'representative VAT identifier (BT-63).',
        );
      }
    case _SellerRule.vatOrRepresentative:
      if (blank(seller.vatIdentifier) && blank(representative)) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the seller needs a VAT identifier '
          '(BT-31) or a tax representative VAT identifier (BT-63).',
        );
      }
    case _SellerRule.forbidden:
      if (!blank(seller.vatIdentifier) || !blank(representative)) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the invoice must carry no seller VAT '
          'identifier (BT-31) and no tax representative VAT identifier '
          '(BT-63).',
        );
      }
  }

  final buyer = invoice.buyer;
  switch (p.buyer) {
    case _BuyerRule.none:
      break;
    case _BuyerRule.vat:
      if (blank(buyer.vatIdentifier)) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the buyer needs a VAT identifier '
          '(BT-48). The buyer is the one accounting for the VAT.',
        );
      }
    case _BuyerRule.vatOrRegistration:
      if (blank(buyer.vatIdentifier) &&
          buyer.legalRegistrationIdentifier == null) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the buyer needs a VAT identifier (BT-48) '
          'or a legal registration identifier (BT-47).',
        );
      }
    case _BuyerRule.forbidden:
      if (!blank(buyer.vatIdentifier)) {
        yield at(
          rule,
          'A $noun is ${p.label}, so the invoice must carry no buyer VAT '
          'identifier (BT-48).',
        );
      }
  }
}

/// The -05, -06 and -07 rules: what the rate has to be.
Iterable<RuleViolation> _rateOf(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
  _Scope scope,
) sync* {
  final rates = <(Decimal?, String)>[];
  switch (scope) {
    case _Scope.line:
      for (final line in _linesOf(invoice, p.category)) {
        rates.add((line.vatRate, pathOf(line)));
      }
    case _Scope.allowance:
      for (final (index, entry) in _entriesOf(
        invoice,
        p.category,
        AllowanceOrCharge.allowance,
      ).indexed) {
        rates.add((entry.vatRate, 'document allowance $index'));
      }
    case _Scope.charge:
      for (final (index, entry) in _entriesOf(
        invoice,
        p.category,
        AllowanceOrCharge.charge,
      ).indexed) {
        rates.add((entry.vatRate, 'document charge $index'));
      }
  }

  final noun = _nameOf(scope);
  for (final (rate, path) in rates) {
    final wrong = switch (p.rate) {
      _RateRule.positive => rate == null || rate <= Decimal.zero,
      _RateRule.zero => rate == null || rate != Decimal.zero,
      _RateRule.zeroOrPositive => rate == null || rate < Decimal.zero,
      _RateRule.absent => rate != null,
    };
    if (!wrong) continue;
    final wanted = switch (p.rate) {
      _RateRule.positive => 'a rate above zero',
      _RateRule.zero => 'a rate of zero',
      _RateRule.zeroOrPositive => 'a rate of zero or more',
      _RateRule.absent => 'no rate at all',
    };
    yield at(
      rule,
      'The $noun is ${p.label}, which takes $wanted. It carries '
      '${rate ?? 'none'}.',
      path,
    );
  }
}

/// The -08 rule: the taxable amount is what the invoice adds up to.
Iterable<RuleViolation> _taxableAmount(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
) sync* {
  // Only a category that may appear more than once splits its taxable amount
  // by rate. The others carry one entry, and the standard sums everything of
  // that category into it without looking at a rate. Splitting them by rate
  // too would report a breach whenever a document states a rate of zero on
  // the breakdown and none on the lines, which is correct and common.
  final byRate = p.cardinality == _Cardinality.atLeastOne;

  for (final (index, entry) in invoice.vatBreakdown.indexed) {
    if (entry.category != p.category) continue;
    bool matches(Decimal? rate) => !byRate || _sameRate(rate, entry.rate);

    final lines = _linesOf(
      invoice,
      p.category,
    ).where((line) => matches(line.vatRate));
    final allowances = _entriesOf(
      invoice,
      p.category,
      AllowanceOrCharge.allowance,
    ).where((item) => matches(item.vatRate));
    final charges = _entriesOf(
      invoice,
      p.category,
      AllowanceOrCharge.charge,
    ).where((item) => matches(item.vatRate));

    final expected = sum(lines.map((line) => line.netAmount)) +
        sum(charges.map((item) => item.amount)) -
        sum(allowances.map((item) => item.amount));
    if (withinOneUnit(entry.taxableAmount, expected)) continue;
    yield at(
      rule,
      'The taxable amount (BT-116) is ${entry.taxableAmount} where what the '
          'invoice taxes as ${p.label} comes to ${round2(expected)}.',
      'VAT breakdown $index',
    );
  }
}

/// The -09 rule: the VAT due on the taxable amount.
Iterable<RuleViolation> _taxAmount(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
) sync* {
  for (final (index, entry) in invoice.vatBreakdown.indexed) {
    if (entry.category != p.category) continue;
    final path = 'VAT breakdown $index';

    if (p.tax == _TaxRule.zero) {
      if (entry.taxAmount != Decimal.zero) {
        yield at(
          rule,
          'The VAT category tax amount (BT-117) is ${entry.taxAmount} where '
          '${p.label} carries no VAT.',
          path,
        );
      }
      continue;
    }

    final rate = entry.rate;
    if (rate == null) continue;
    final expected = round2(
      entry.taxableAmount.abs() *
          (rate / Decimal.fromInt(100)).toDecimal(
            scaleOnInfinitePrecision: 20,
          ),
    );
    if (withinOneUnit(entry.taxAmount.abs(), expected)) continue;
    yield at(
      rule,
      'The VAT category tax amount (BT-117) is ${entry.taxAmount} where '
      '${entry.taxableAmount} at $rate% comes to $expected.',
      path,
    );
  }
}

/// The -10 rule: whether a reason for charging no VAT is called for.
Iterable<RuleViolation> _exemption(
  Invoice invoice,
  RuleDescriptor rule,
  _VatProfile p,
) sync* {
  for (final (index, entry) in invoice.vatBreakdown.indexed) {
    if (entry.category != p.category) continue;
    final given =
        !blank(entry.exemptionReason) || !blank(entry.exemptionReasonCode);
    final path = 'VAT breakdown $index';
    switch (p.exemption) {
      case _ExemptionRule.forbidden:
        if (given) {
          yield at(
            rule,
            'The breakdown is ${p.label} and still gives an exemption reason '
            '(BT-120 or BT-121). VAT is charged, so there is nothing to '
            'excuse.',
            path,
          );
        }
      case _ExemptionRule.required:
        if (!given) {
          yield at(
            rule,
            'The breakdown is ${p.label}, so it has to say why no VAT is due, '
            'as a reason (BT-120) or a reason code (BT-121).',
            path,
          );
        }
    }
  }
}

bool _sameRate(Decimal? left, Decimal? right) {
  if (left == null || right == null) return left == right;
  return left == right;
}

// --- The rules that stand on their own -------------------------------------

Iterable<RuleViolation> _brIc11(Invoice invoice, RuleDescriptor rule) sync* {
  if (_breakdownsOf(invoice, VatCategory.intraCommunitySupply).isEmpty) return;
  final period = invoice.invoicingPeriod;
  final dated = invoice.delivery?.date != null ||
      period?.start != null ||
      period?.end != null;
  if (!dated) {
    yield at(
      rule,
      'The invoice is an intra-community supply, so it has to carry the '
      'actual delivery date (BT-72) or an invoicing period (BG-14). The tax '
      'authority reads it to decide which period the supply falls in.',
    );
  }
}

Iterable<RuleViolation> _brIc12(Invoice invoice, RuleDescriptor rule) sync* {
  if (_breakdownsOf(invoice, VatCategory.intraCommunitySupply).isEmpty) return;
  if (blank(invoice.delivery?.address?.country)) {
    yield at(
      rule,
      'The invoice is an intra-community supply, so the deliver to country '
      'code (BT-80) has to be given. It is what makes the supply '
      'intra-community.',
    );
  }
}

Iterable<RuleViolation> _brO11(Invoice invoice, RuleDescriptor rule) sync* {
  if (_breakdownsOf(invoice, VatCategory.outsideScope).isEmpty) return;
  final others = invoice.vatBreakdown
      .where((entry) => entry.category != VatCategory.outsideScope)
      .length;
  if (others > 0) {
    yield at(
      rule,
      'The invoice is not subject to VAT and still carries $others other VAT '
      'breakdown entries. An invoice is outside the scope of VAT as a whole '
      'or not at all.',
    );
  }
}

Iterable<RuleViolation> _brO12(Invoice invoice, RuleDescriptor rule) sync* {
  if (_breakdownsOf(invoice, VatCategory.outsideScope).isEmpty) return;
  for (final line in invoice.lines) {
    if (line.vatCategory == VatCategory.outsideScope) continue;
    yield at(
      rule,
      'The invoice is not subject to VAT, so no line may carry another '
      'category. This one is ${line.vatCategory}.',
      pathOf(line),
    );
  }
}

Iterable<RuleViolation> _brO13(Invoice invoice, RuleDescriptor rule) sync* {
  yield* _outsideScopeEntries(invoice, rule, AllowanceOrCharge.allowance);
}

Iterable<RuleViolation> _brO14(Invoice invoice, RuleDescriptor rule) sync* {
  yield* _outsideScopeEntries(invoice, rule, AllowanceOrCharge.charge);
}

Iterable<RuleViolation> _outsideScopeEntries(
  Invoice invoice,
  RuleDescriptor rule,
  AllowanceOrCharge kind,
) sync* {
  if (_breakdownsOf(invoice, VatCategory.outsideScope).isEmpty) return;
  final noun = kind == AllowanceOrCharge.allowance ? 'allowance' : 'charge';
  for (final (index, entry) in invoice.allowancesAndCharges.indexed) {
    if (entry.kind != kind) continue;
    if (entry.vatCategory == VatCategory.outsideScope) continue;
    yield at(
      rule,
      'The invoice is not subject to VAT, so no document level $noun may '
          'carry another category. This one is ${entry.vatCategory}.',
      'document $noun $index',
    );
  }
}

Iterable<RuleViolation> _brB01(Invoice invoice, RuleDescriptor rule) sync* {
  if (!_uses(invoice, VatCategory.transferred) &&
      _breakdownsOf(invoice, VatCategory.transferred).isEmpty) {
    return;
  }
  final domestic = invoice.seller.address.country == 'IT' &&
      invoice.buyer.address.country == 'IT';
  if (!domestic) {
    yield at(
      rule,
      'Split payment is an Italian arrangement, so both the seller (BT-40) '
      'and the buyer (BT-55) have to be in IT.',
    );
  }
}

Iterable<RuleViolation> _brB02(Invoice invoice, RuleDescriptor rule) sync* {
  final split = _uses(invoice, VatCategory.transferred) ||
      _breakdownsOf(invoice, VatCategory.transferred).isNotEmpty;
  if (!split) return;
  final standard = _uses(invoice, VatCategory.standardRate) ||
      _breakdownsOf(invoice, VatCategory.standardRate).isNotEmpty;
  if (standard) {
    yield at(
      rule,
      'The invoice mixes split payment with standard rated VAT. An invoice '
      'carries one or the other.',
    );
  }
}
