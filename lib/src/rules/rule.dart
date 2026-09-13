/// How a receiver treats an invoice that breaks a rule.
enum RuleSeverity {
  /// The invoice is rejected.
  fatal,

  /// The invoice is accepted and the breach is reported.
  warning,
}

/// The family a rule belongs to, which says what it is about.
enum RuleFamily {
  /// BR. A term is present, or a group is complete.
  presence('BR'),

  /// BR-CO. A figure follows from the figures it is computed from.
  condition('BR-CO'),

  /// BR-CL. A code belongs to the list its term draws from.
  codeList('BR-CL'),

  /// BR-DEC. An amount is written with no more decimals than allowed.
  decimals('BR-DEC'),

  /// BR-S. Standard rated VAT.
  vatStandardRate('BR-S'),

  /// BR-Z. Zero rated VAT.
  vatZeroRated('BR-Z'),

  /// BR-E. VAT exempt.
  vatExempt('BR-E'),

  /// BR-AE. VAT reverse charge.
  vatReverseCharge('BR-AE'),

  /// BR-IC. Intra-community supply.
  vatIntraCommunity('BR-IC'),

  /// BR-G. Export outside the European Union.
  vatExport('BR-G'),

  /// BR-O. Outside the scope of VAT.
  vatOutsideScope('BR-O'),

  /// BR-AF. Canary Islands general indirect tax.
  vatCanaryIslands('BR-AF'),

  /// BR-AG. Tax of Ceuta and Melilla.
  vatCeutaAndMelilla('BR-AG'),

  /// BR-B. An invoice mixing VAT categories that cannot be mixed.
  vatCategoryMix('BR-B'),

  /// A rule a profile adds on top of the standard. Its identifier is the
  /// profile's own, so no prefix here claims it.
  profile('');

  const RuleFamily(this.prefix);

  /// The prefix every rule of the family carries in its identifier.
  final String prefix;

  /// The family [id] belongs to, or null when no family claims it.
  static RuleFamily? of(String id) {
    RuleFamily? found;
    for (final family in values) {
      if (family.prefix.isEmpty) continue;
      if (!id.startsWith('${family.prefix}-')) continue;
      // BR-CO-10 starts with BR- as well, so the longest prefix wins.
      if (found == null || family.prefix.length > found.prefix.length) {
        found = family;
      }
    }
    return found;
  }
}

/// One business rule of EN 16931, as the catalogue knows it.
///
/// The catalogue is read from the validation artefacts the standard is
/// published with, so it lists every rule that exists rather than the ones
/// that came to mind. What a rule means is implemented here, in Dart, against
/// the semantic model: nothing of the artefacts themselves is carried into
/// this package.
final class RuleDescriptor {
  /// The rule [id], of [family] and [severity], bearing on [terms].
  const RuleDescriptor({
    required this.id,
    required this.family,
    required this.severity,
    required this.terms,
  });

  /// The identifier the standard gives the rule, `BR-CO-10` for instance.
  final String id;

  /// What the rule is about.
  final RuleFamily family;

  /// What a receiver does with an invoice that breaks it.
  final RuleSeverity severity;

  /// The business terms and groups the rule bears on, `BT-106` and `BG-23`
  /// for instance, in the order the standard names them.
  final List<String> terms;

  @override
  String toString() => id;
}

/// An invoice breaking one rule.
final class RuleViolation {
  /// The breach of [rule], explained by [message] and found at [path].
  const RuleViolation({required this.rule, required this.message, this.path});

  /// The rule that was broken.
  final RuleDescriptor rule;

  /// What is wrong, in words, written by this package.
  final String message;

  /// Where in the invoice, when the rule bears on one line or one entry
  /// rather than on the invoice as a whole.
  final String? path;

  @override
  String toString() =>
      path == null ? '[${rule.id}] $message' : '[${rule.id}] $path: $message';
}
