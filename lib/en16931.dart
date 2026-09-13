/// The European electronic invoice, EN 16931, as Dart objects.
///
/// The library holds the semantic model: the terms the standard names, the
/// groups it puts them in, and the code lists it points at. A syntax package
/// writes that model out as UBL or as CII, and a profile package adds the
/// rules one country or one network puts on top. Neither is needed to build
/// an invoice or to read one back.
library;

export 'src/codes/code_value.dart';
export 'src/codes/invoice_type_code.dart';
export 'src/codes/lists.g.dart';
export 'src/codes/payment_means_code.dart';
export 'src/codes/schemes.dart';
export 'src/codes/unit_code.dart';
export 'src/codes/vat_category.dart';
export 'src/model/address.dart';
export 'src/model/allowance_charge.dart';
export 'src/model/contact.dart';
export 'src/model/derive.dart' show deriveBreakdown, deriveTotals;
export 'src/model/invoice.dart';
export 'src/model/item.dart';
export 'src/model/line.dart';
export 'src/model/parties.dart';
export 'src/model/payment.dart';
export 'src/model/references.dart';
export 'src/model/totals.dart';
export 'src/model/vat_breakdown.dart';
export 'src/rules/catalogue.g.dart';
export 'src/rules/code_list_rules.dart';
export 'src/rules/condition_rules.dart';
export 'src/rules/decimal_rules.dart';
export 'src/rules/presence_rules.dart'
    show presenceRules, presenceSatisfiedByConstruction;
export 'src/rules/rule.dart';
export 'src/rules/support.dart' show RuleCheck;
export 'src/rules/validator.dart';
export 'src/rules/vat_category_rules.dart' show vatCategoryRules;
export 'src/types/amount.dart' show exact;
export 'src/types/calendar_date.dart';
export 'src/types/identifier.dart';
