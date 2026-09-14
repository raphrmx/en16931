import 'package:en16931/en16931.dart';
import 'package:test/test.dart';

void main() {
  group('rule catalogue', () {
    test('holds every rule once', () {
      final identifiers = ruleCatalogue.map((rule) => rule.id).toSet();
      expect(identifiers, hasLength(ruleCatalogue.length));
      expect(ruleCatalogue, isNotEmpty);
    });

    test('is read from the artefacts, not from memory', () {
      // The count is what the published artefacts assert once the syntax
      // bound rules are left out. It moves when the standard moves, and the
      // scheduled job that refreshes the catalogue is what should move it.
      expect(ruleCatalogue, hasLength(223));
    });

    test('says which release of the artefacts it was read from', () {
      // The generator reads a tag rather than a branch, so generating twice
      // gives the same catalogue twice. Without it the package could say
      // which rules it covers without being able to say against what.
      expect(en16931ArtefactRelease, 'validation-1.3.16');
    });

    test('gives every rule a family', () {
      for (final rule in ruleCatalogue) {
        expect(RuleFamily.of(rule.id), rule.family, reason: rule.id);
      }
    });

    test('reads the longest family prefix, not the first that matches', () {
      expect(RuleFamily.of('BR-CO-10'), RuleFamily.condition);
      expect(RuleFamily.of('BR-CL-01'), RuleFamily.codeList);
      expect(RuleFamily.of('BR-01'), RuleFamily.presence);
      expect(RuleFamily.of('UBL-CR-001'), isNull);
    });

    test('carries the terms each rule bears on', () {
      // A code list rule names the list rather than a term, so it is the one
      // family that comes with no term attached. Which element it bears on is
      // decided when the rule is implemented, not read from the artefacts.
      final withoutTerms =
          ruleCatalogue.where((rule) => rule.terms.isEmpty).toList();
      expect(
        withoutTerms.every((rule) => rule.family == RuleFamily.codeList),
        isTrue,
        reason: 'Rules with no business term outside BR-CL: '
            '${withoutTerms.where((rule) => rule.family != RuleFamily.codeList).map((rule) => rule.id).join(', ')}',
      );
      expect(
        ruleCatalogue
            .where((rule) => rule.family != RuleFamily.codeList)
            .every((rule) => rule.terms.isNotEmpty),
        isTrue,
      );
    });

    test('anchors on the rule that catches a wrong line total', () {
      final rule = ruleCatalogue.firstWhere((rule) => rule.id == 'BR-CO-10');
      expect(rule.family, RuleFamily.condition);
      expect(rule.severity, RuleSeverity.fatal);
      expect(rule.terms, ['BT-106', 'BT-131']);
    });

    test('covers the VAT categories one family each', () {
      final families = ruleCatalogue.map((rule) => rule.family).toSet();
      expect(families, contains(RuleFamily.vatStandardRate));
      expect(families, contains(RuleFamily.vatReverseCharge));
      expect(families, contains(RuleFamily.vatIntraCommunity));
      expect(families, contains(RuleFamily.vatOutsideScope));
    });
  });
}
