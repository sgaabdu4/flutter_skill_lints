import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_equality_checks.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidCollectionEqualityChecksTest>(
    'AvoidCollectionEqualityChecksTest',
    AvoidCollectionEqualityChecksTest.new,
    {
      'reportsListEquality': (t) => t.reportsListEquality(),
      'reportsMapInequality': (t) => t.reportsMapInequality(),
      'reportsSetAgainstLiteral': (t) => t.reportsSetAgainstLiteral(),
      'reportsIterableComparison': (t) => t.reportsIterableComparison(),
      'acceptsNullChecks': (t) => t.acceptsNullChecks(),
      'acceptsTwoConstantCollections': (t) => t.acceptsTwoConstantCollections(),
      'acceptsParenthesizedConstants': (t) => t.acceptsParenthesizedConstants(),
      'acceptsNonCollections': (t) => t.acceptsNonCollections(),
      'acceptsOtherOperators': (t) => t.acceptsOtherOperators(),
    },
  );
}

final class AvoidCollectionEqualityChecksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionEqualityChecks();
    super.setUp();
  }

  Future<void> reportsListEquality() async {
    const source = '''
bool f(List<int> a, List<int> b) => a == b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == b'), 'a == b'.length)]);
  }

  Future<void> reportsMapInequality() async {
    const source = '''
bool f(Map<int, int> a, Map<int, int> b) => a != b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a != b'), 'a != b'.length)]);
  }

  Future<void> reportsSetAgainstLiteral() async {
    const source = '''
bool f(Set<int> a) => a == {1};
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == {1}'), 'a == {1}'.length)]);
  }

  Future<void> reportsIterableComparison() async {
    const source = '''
bool f(Iterable<int> a, List<int> b) => a == b;
''';
    await assertDiagnostics(source, [lint(source.indexOf('a == b'), 'a == b'.length)]);
  }

  Future<void> acceptsNullChecks() => assertNoDiagnostics('''
bool f(List<int>? a, List<int>? b) => a == null || b != null;
''');

  Future<void> acceptsTwoConstantCollections() => assertNoDiagnostics('''
bool f() => const [1] == const [1];
''');

  Future<void> acceptsParenthesizedConstants() => assertNoDiagnostics('''
bool f() => (const {1}) == (const {1});
''');

  Future<void> acceptsNonCollections() => assertNoDiagnostics('''
bool f(int a, String b, Object c) => a == 1 || b == 'x' || c == a;
''');

  Future<void> acceptsOtherOperators() => assertNoDiagnostics('''
bool f(List<int> a, List<int> b) => a.length < b.length && a.isEmpty;
''');
}
