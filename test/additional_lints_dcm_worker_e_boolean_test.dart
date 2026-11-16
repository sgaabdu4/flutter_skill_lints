import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inverted_boolean_checks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_negations_in_equality_checks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_equal_then_else.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidInvertedBooleanChecksTest>(
    'AvoidInvertedBooleanChecksTest',
    _AvoidInvertedBooleanChecksTest.new,
    _AvoidInvertedBooleanChecksTest._allCases,
  );
  analysisRuleSuite<_AvoidNegationsInEqualityChecksTest>(
    'AvoidNegationsInEqualityChecksTest',
    _AvoidNegationsInEqualityChecksTest.new,
    _AvoidNegationsInEqualityChecksTest._allCases,
  );
  analysisRuleSuite<_NoEqualThenElseTest>(
    'NoEqualThenElseTest',
    _NoEqualThenElseTest.new,
    _NoEqualThenElseTest._allCases,
  );
}

final class _AvoidInvertedBooleanChecksTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidInvertedBooleanChecksTest)> get _allCases =>
      caseSet<_AvoidInvertedBooleanChecksTest>(
        parent: const {},
        own: {
          'test_negatedEqualityCondition_lint': (t) => t._negatedEqualityConditionLint(),
          'test_negatedIsCondition_lint': (t) => t._negatedIsConditionLint(),
          'test_plainBooleanNegation_noLint': (t) => t._plainBooleanNegationNoLint(),
          'test_negatedMethodCall_noLint': (t) => t._negatedMethodCallNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidInvertedBooleanChecks();
    super.setUp();
  }

  Future<void> _negatedEqualityConditionLint() async {
    const source = r'''
bool same(int left, int right) {
  if (!(left == right)) {
    return false;
  }
  return true;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!(left == right)'), '!(left == right)'.length),
    ]);
  }

  Future<void> _negatedIsConditionLint() async {
    const source = r'''
bool isText(Object value) {
  if (!(value is String)) {
    return false;
  }
  return true;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!(value is String)'), '!(value is String)'.length),
    ]);
  }

  Future<void> _plainBooleanNegationNoLint() async {
    await assertNoDiagnostics(r'''
bool missing(bool enabled) => !enabled;
''');
  }

  Future<void> _negatedMethodCallNoLint() async {
    await assertNoDiagnostics(r'''
bool missing(String value) => !value.isEmpty;
''');
  }
}

final class _AvoidNegationsInEqualityChecksTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNegationsInEqualityChecksTest)> get _allCases =>
      caseSet<_AvoidNegationsInEqualityChecksTest>(
        parent: const {},
        own: {
          'test_leftNegatedEquality_lint': (t) => t._leftNegatedEqualityLint(),
          'test_rightNegatedInequality_lint': (t) => t._rightNegatedInequalityLint(),
          'test_bothSidesNegated_noLint': (t) => t._bothSidesNegatedNoLint(),
          'test_plainEquality_noLint': (t) => t._plainEqualityNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNegationsInEqualityChecks();
    super.setUp();
  }

  Future<void> _leftNegatedEqualityLint() async {
    const source = r'''
bool matches(bool ready, bool expected) => !ready == expected;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('!ready == expected'), '!ready == expected'.length),
    ]);
  }

  Future<void> _rightNegatedInequalityLint() async {
    const source = r'''
bool differs(bool ready, bool expected) => ready != !expected;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ready != !expected'), 'ready != !expected'.length),
    ]);
  }

  Future<void> _bothSidesNegatedNoLint() async {
    await assertNoDiagnostics(r'''
bool matches(bool left, bool right) => !left == !right;
''');
  }

  Future<void> _plainEqualityNoLint() async {
    await assertNoDiagnostics(r'''
bool matches(bool left, bool right) => left == right;
''');
  }
}

final class _NoEqualThenElseTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_NoEqualThenElseTest)> get _allCases =>
      caseSet<_NoEqualThenElseTest>(
        parent: const {},
        own: {
          'test_conditionalSameExpressions_lint': (t) => t._conditionalSameExpressionsLint(),
          'test_ifElseSameReturns_lint': (t) => t._ifElseSameReturnsLint(),
          'test_conditionalDifferentExpressions_noLint': (t) =>
              t._conditionalDifferentExpressionsNoLint(),
          'test_ifElseIf_noLint': (t) => t._ifElseIfNoLint(),
        },
      );

  @override
  void setUp() {
    rule = NoEqualThenElse();
    super.setUp();
  }

  Future<void> _conditionalSameExpressionsLint() async {
    const source = r'''
int value(bool ready, int count) => ready ? count + 1 : count + 1;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ready ?'), 'ready ? count + 1 : count + 1'.length),
    ]);
  }

  Future<void> _ifElseSameReturnsLint() async {
    const source = r'''
int value(bool ready, int count) {
  if (ready) {
    return count;
  } else {
    return count;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('if (ready)'), source.indexOf('\n}') - source.indexOf('if (ready)')),
    ]);
  }

  Future<void> _conditionalDifferentExpressionsNoLint() async {
    await assertNoDiagnostics(r'''
int value(bool ready, int count) => ready ? count + 1 : count - 1;
''');
  }

  Future<void> _ifElseIfNoLint() async {
    await assertNoDiagnostics(r'''
int value(bool first, bool second) {
  if (first) {
    return 1;
  } else if (second) {
    return 1;
  }
  return 0;
}
''');
  }
}
