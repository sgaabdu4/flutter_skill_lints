import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_enums_by_name_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_enums_by_name.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferEnumsByNameTest>('PreferEnumsByNameTest', PreferEnumsByNameTest.new, {
    'reportsFirstWhereOnEnumValues': (t) => t.reportsFirstWhereOnEnumValues(),
    'reportsReversedComparison': (t) => t.reportsReversedComparison(),
    'reportsBlockBodyCallback': (t) => t.reportsBlockBodyCallback(),
    'acceptsComparisonOnOtherProperty': (t) => t.acceptsComparisonOnOtherProperty(),
    'acceptsNonEnumTargets': (t) => t.acceptsNonEnumTargets(),
    'acceptsNotEqualComparison': (t) => t.acceptsNotEqualComparison(),
    'acceptsNamedPredicate': (t) => t.acceptsNamedPredicate(),
    'rewritesToByName': (t) => t.rewritesToByName(),
    'rewritesReversedComparison': (t) => t.rewritesReversedComparison(),
  });
}

final class PreferEnumsByNameTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferEnumsByName();
    super.setUp();
  }

  static const _color = '''
enum Color { red, green }

''';

  static const _plain =
      '''
${_color}Color f(String value) => Color.values.firstWhere((e) => e.name == value);
''';

  Future<void> reportsFirstWhereOnEnumValues() => assertDiagnostics(_plain, [
    lint(
      _plain.indexOf('Color.values.firstWhere'),
      'Color.values.firstWhere((e) => e.name == value)'.length,
    ),
  ]);

  Future<void> reportsReversedComparison() async {
    const source =
        '''
${_color}Color f(String value) => Color.values.firstWhere((e) => value == e.name);
''';
    const call = 'Color.values.firstWhere((e) => value == e.name)';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> reportsBlockBodyCallback() async {
    const source =
        '''
${_color}Color f(String value) => Color.values.firstWhere((e) {
  return e.name == value;
});
''';
    const call = '''Color.values.firstWhere((e) {
  return e.name == value;
})''';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> acceptsComparisonOnOtherProperty() => assertNoDiagnostics('''
enum Color {
  red('r'),
  green('g');

  const Color(this.code);
  final String code;
}

Color f(String value) => Color.values.firstWhere((e) => e.code == value);
''');

  Future<void> acceptsNonEnumTargets() => assertNoDiagnostics('''
class Item {
  final String name = '';
}

Item f(List<Item> items, String value) => items.firstWhere((e) => e.name == value);
''');

  Future<void> acceptsNotEqualComparison() => assertNoDiagnostics('''
${_color}Color f(String value) => Color.values.firstWhere((e) => e.name != value);
''');

  Future<void> acceptsNamedPredicate() => assertNoDiagnostics('''
${_color}bool matches(Color e) => e.name == 'red';

Color f() => Color.values.firstWhere(matches);
''');

  Future<void> rewritesToByName() => expectFix(
    _plain,
    (context) => PreferEnumsByNameFix(context: context),
    expected:
        '''
${_color}Color f(String value) => Color.values.byName(value);
''',
  );

  Future<void> rewritesReversedComparison() => expectFix(
    '''
${_color}Color f(String value) => Color.values.firstWhere((e) => value == e.name);
''',
    (context) => PreferEnumsByNameFix(context: context),
    expected:
        '''
${_color}Color f(String value) => Color.values.byName(value);
''',
  );
}
