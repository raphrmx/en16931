import 'package:en16931/src/model/invoice.dart';
import 'package:en16931/src/rules/catalogue.g.dart';
import 'package:en16931/src/rules/code_list_rules.dart';
import 'package:en16931/src/rules/condition_rules.dart';
import 'package:en16931/src/rules/decimal_rules.dart';
import 'package:en16931/src/rules/presence_rules.dart';
import 'package:en16931/src/rules/rule.dart';
import 'package:en16931/src/rules/support.dart';
import 'package:en16931/src/rules/vat_category_rules.dart';

/// The catalogue, indexed by identifier.
final Map<String, RuleDescriptor> _byIdentifier = {
  for (final rule in ruleCatalogue) rule.id: rule,
};

/// Every family of rules this library states, in the order they run.
final List<Map<String, RuleCheck>> _families = [
  presenceRules,
  conditionRules,
  decimalRules,
  codeListRules,
  vatCategoryRules,
];

/// The rule the standard publishes as [id].
///
/// Throws [ArgumentError] when the catalogue holds no such rule, which is how
/// a rule implemented under an identifier the standard does not define is
/// caught rather than run.
RuleDescriptor ruleFor(String id) {
  final rule = _byIdentifier[id];
  if (rule == null) {
    throw ArgumentError.value(id, 'id', 'Not a rule of EN 16931');
  }
  return rule;
}

/// The rules [validate] evaluates.
Set<String> get implementedRules => {
      for (final family in _families) ...family.keys,
    };

/// The rules met before an invoice exists, mapped to what meets them.
///
/// These are not skipped: the model asks for the term in its constructor, so
/// an invoice that breaks one cannot be built. A syntax package reading an
/// invoice from XML has to check them itself, since what it reads was not
/// built here.
Map<String, String> get rulesMetByConstruction => {
      ...presenceSatisfiedByConstruction,
      ...conditionSatisfiedByConstruction,
      ...codeListSatisfiedByConstruction,
    };

/// The rules no program can decide, mapped to what a reader has to judge.
///
/// The published artefacts do not decide them either: their test is `true()`.
/// Counting them as checked would be a claim this library cannot back.
Map<String, String> get rulesNotMachineCheckable => {
      ...conditionNotMachineCheckable,
    };

/// Every rule this library has an answer for, whichever the answer is.
Set<String> get accountedRules => {
      ...implementedRules,
      ...rulesMetByConstruction.keys,
      ...rulesNotMachineCheckable.keys,
    };

/// What [invoice] breaks, in the order the standard numbers its rules.
///
/// An empty list does not mean the invoice is compliant: only the rules this
/// library states are checked, and [implementedRules] says which those are.
/// Nothing here looks at a profile, which adds rules of its own.
List<RuleViolation> validate(Invoice invoice) {
  final violations = <RuleViolation>[];
  for (final family in _families) {
    for (final entry in family.entries) {
      violations.addAll(entry.value(invoice, ruleFor(entry.key)));
    }
  }
  violations.sort((a, b) => a.rule.id.compareTo(b.rule.id));
  return violations;
}

/// Whether [invoice] breaks no rule a receiver would reject it for.
///
/// A warning does not count: a receiver takes the invoice and reports it.
bool isAcceptable(Invoice invoice) => validate(
      invoice,
    ).every((violation) => violation.rule.severity != RuleSeverity.fatal);
