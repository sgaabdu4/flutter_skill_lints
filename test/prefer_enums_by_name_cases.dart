import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_enums_by_name_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_enums_by_name.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_PreferEnumsByNameTest>('PreferEnumsByNameTest', _PreferEnumsByNameTest.new, {
    'reportsFirstWhereOnEnumValues': (t) => t._reportsFirstWhereOnEnumValues(),
    'reportsReversedComparison': (t) => t._reportsReversedComparison(),
    'reportsBlockBodyCallback': (t) => t._reportsBlockBodyCallback(),
    'acceptsComparisonOnOtherProperty': (t) => t._acceptsComparisonOnOtherProperty(),
    'acceptsNonEnumTargets': (t) => t._acceptsNonEnumTargets(),
    'acceptsNotEqualComparison': (t) => t._acceptsNotEqualComparison(),
    'acceptsNamedPredicate': (t) => t._acceptsNamedPredicate(),
    'rewritesToByName': (t) => t._rewritesToByName(),
    'rewritesReversedComparison': (t) => t._rewritesReversedComparison(),
  });
}

final class _PreferEnumsByNameTest extends FixRuleTest {
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

  Future<void> _reportsFirstWhereOnEnumValues() => assertDiagnostics(_plain, [
    lint(
      _plain.indexOf('Color.values.firstWhere'),
      'Color.values.firstWhere((e) => e.name == value)'.length,
    ),
  ]);

  Future<void> _reportsReversedComparison() async {
    const source =
        '''
${_color}Color f(String value) => Color.values.firstWhere((e) => value == e.name);
''';
    const call = 'Color.values.firstWhere((e) => value == e.name)';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> _reportsBlockBodyCallback() async {
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

  Future<void> _acceptsComparisonOnOtherProperty() => assertNoDiagnostics('''
enum Color {
  red('r'),
  green('g');

  const Color(this.code);
  final String code;
}

Color f(String value) => Color.values.firstWhere((e) => e.code == value);
''');

  Future<void> _acceptsNonEnumTargets() => assertNoDiagnostics('''
class Item {
  final String name = '';
}

Item f(List<Item> items, String value) => items.firstWhere((e) => e.name == value);
''');

  Future<void> _acceptsNotEqualComparison() => assertNoDiagnostics('''
${_color}Color f(String value) => Color.values.firstWhere((e) => e.name != value);
''');

  Future<void> _acceptsNamedPredicate() => assertNoDiagnostics('''
${_color}bool matches(Color e) => e.name == 'red';

Color f() => Color.values.firstWhere(matches);
''');

  Future<void> _rewritesToByName() => expectFix(
    _plain,
    (context) => PreferEnumsByNameFix(context: context),
    expected:
        '''
${_color}Color f(String value) => Color.values.byName(value);
''',
  );

  Future<void> _rewritesReversedComparison() => expectFix(
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
