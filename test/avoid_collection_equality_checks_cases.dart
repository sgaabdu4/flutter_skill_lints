import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_equality_checks.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidCollectionEqualityChecksTest>(
    'AvoidCollectionEqualityChecksTest',
    _AvoidCollectionEqualityChecksTest.new,
    {
      'reportsListEquality': (t) => t._reportsListEquality(),
      'reportsMapInequality': (t) => t._reportsMapInequality(),
      'reportsSetAgainstLiteral': (t) => t._reportsSetAgainstLiteral(),
      'reportsIterableComparison': (t) => t._reportsIterableComparison(),
      'acceptsNullChecks': (t) => t._acceptsNullChecks(),
      'acceptsTwoConstantCollections': (t) => t._acceptsTwoConstantCollections(),
      'acceptsParenthesizedConstants': (t) => t._acceptsParenthesizedConstants(),
      'acceptsNonCollections': (t) => t._acceptsNonCollections(),
      'acceptsOtherOperators': (t) => t._acceptsOtherOperators(),
    },
  );
}

final class _AvoidCollectionEqualityChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionEqualityChecks();
    super.setUp();
  }

  Future<void> _reportsListEquality() async {
    const source = '''
bool f(List<int> a, List<int> b) => a == b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == b'), 'a == b'.length)]);
  }

  Future<void> _reportsMapInequality() async {
    const source = '''
bool f(Map<int, int> a, Map<int, int> b) => a != b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a != b'), 'a != b'.length)]);
  }

  Future<void> _reportsSetAgainstLiteral() async {
    const source = '''
bool f(Set<int> a) => a == {1};
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == {1}'), 'a == {1}'.length)]);
  }

  Future<void> _reportsIterableComparison() async {
    const source = '''
bool f(Iterable<int> a, List<int> b) => a == b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == b'), 'a == b'.length)]);
  }

  Future<void> _acceptsNullChecks() => assertNoDiagnostics('''
bool f(List<int>? a, List<int>? b) => a == null || b != null;
''');

  Future<void> _acceptsTwoConstantCollections() => assertNoDiagnostics('''
bool f() => const [1] == const [1];
''');

  Future<void> _acceptsParenthesizedConstants() => assertNoDiagnostics('''
bool f() => (const {1}) == (const {1});
''');

  Future<void> _acceptsNonCollections() => assertNoDiagnostics('''
bool f(int a, String b, Object c) => a == 1 || b == 'x' || c == a;
''');

  Future<void> _acceptsOtherOperators() => assertNoDiagnostics('''
bool f(List<int> a, List<int> b) => a.length < b.length && a.isEmpty;
''');
}
