import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bitwise_operators_with_booleans.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conditions_with_boolean_literals.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_constant_assert_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_contradictory_expressions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidBitwiseOperatorsWithBooleansTest>(
    'AvoidBitwiseOperatorsWithBooleansTest',
    _AvoidBitwiseOperatorsWithBooleansTest.new,
    _AvoidBitwiseOperatorsWithBooleansTest._allCases,
  );
  analysisRuleSuite<_AvoidConditionsWithBooleanLiteralsTest>(
    'AvoidConditionsWithBooleanLiteralsTest',
    _AvoidConditionsWithBooleanLiteralsTest.new,
    _AvoidConditionsWithBooleanLiteralsTest._allCases,
  );
  analysisRuleSuite<_AvoidConstantAssertConditionsTest>(
    'AvoidConstantAssertConditionsTest',
    _AvoidConstantAssertConditionsTest.new,
    _AvoidConstantAssertConditionsTest._allCases,
  );
  analysisRuleSuite<_AvoidContradictoryExpressionsTest>(
    'AvoidContradictoryExpressionsTest',
    _AvoidContradictoryExpressionsTest.new,
    _AvoidContradictoryExpressionsTest._allCases,
  );
}

final class _AvoidBitwiseOperatorsWithBooleansTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidBitwiseOperatorsWithBooleansTest)> get _allCases =>
      caseSet<_AvoidBitwiseOperatorsWithBooleansTest>(
        parent: const {},
        own: {
          'test_ampersandWithBools_lint': (t) => t._ampersandWithBoolsLint(),
          'test_barWithBools_lint': (t) => t._barWithBoolsLint(),
          'test_caretWithBools_lint': (t) => t._caretWithBoolsLint(),
          'test_logicalOperators_noLint': (t) => t._logicalOperatorsNoLint(),
          'test_intBitwiseOperators_noLint': (t) => t._intBitwiseOperatorsNoLint(),
          'test_customOperatorReturnBool_noLint': (t) => t._customOperatorReturnBoolNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidBitwiseOperatorsWithBooleans();
    super.setUp();
  }

  Future<void> _ampersandWithBoolsLint() async {
    const source = r'''
bool both(bool left, bool right) => left & right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left & right'), 'left & right'.length)]);
  }

  Future<void> _barWithBoolsLint() async {
    const source = r'''
bool either(bool left, bool right) => left | right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left | right'), 'left | right'.length)]);
  }

  Future<void> _caretWithBoolsLint() async {
    const source = r'''
bool different(bool left, bool right) => left ^ right;
''';

    await assertDiagnostics(source, [lint(source.indexOf('left ^ right'), 'left ^ right'.length)]);
  }

  Future<void> _logicalOperatorsNoLint() async {
    await assertNoDiagnostics(r'''
bool both(bool left, bool right) => left && right;
bool either(bool left, bool right) => left || right;
''');
  }

  Future<void> _intBitwiseOperatorsNoLint() async {
    await assertNoDiagnostics(r'''
int mask(int left, int right) => left & right;
''');
  }

  Future<void> _customOperatorReturnBoolNoLint() async {
    await assertNoDiagnostics(r'''
final class Flag {
  const Flag();
  bool operator &(Flag other) => true;
}

bool both(Flag left, Flag right) => left & right;
''');
  }
}

final class _AvoidConditionsWithBooleanLiteralsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidConditionsWithBooleanLiteralsTest)>
  get _allCases => caseSet<_AvoidConditionsWithBooleanLiteralsTest>(
    parent: const {},
    own: {
      'test_whileTrueLoop_noLint': (t) => t._whileTrueLoopNoLint(),
      'test_doWhileTrueLoop_noLint': (t) => t._doWhileTrueLoopNoLint(),
      'test_doWhileFalseLoop_lint': (t) => t._doWhileFalseLoopLint(),
      'test_whileTrueCombinedCondition_lint': (t) => t._whileTrueCombinedConditionLint(),
      'test_ifTrueCondition_lint': (t) => t._ifTrueConditionLint(),
      'test_logicalConditionLiteral_lint': (t) => t._logicalConditionLiteralLint(),
      'test_conditionalExpressionLiteral_lint': (t) => t._conditionalExpressionLiteralLint(),
      'test_nullableBoolComparison_noLint': (t) => t._nullableBoolComparisonNoLint(),
      'test_booleanLiteralArgument_noLint': (t) => t._booleanLiteralArgumentNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidConditionsWithBooleanLiterals();
    super.setUp();
  }

  Future<void> _whileTrueLoopNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> retry(Future<int> Function() fn, int maxAttempts) async {
  var attempt = 0;
  while (true) {
    try {
      return await fn();
    } on Object {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
    }
  }
}
''');
  }

  Future<void> _doWhileTrueLoopNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool Function() done) {
  do {
    if (done()) break;
  } while (true);
}
''');
  }

  Future<void> _doWhileFalseLoopLint() async {
    const source = r'''
void f() {
  do {
    print(1);
  } while (false);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('false'), 'false'.length)]);
  }

  Future<void> _whileTrueCombinedConditionLint() async {
    const source = r'''
void f(bool ready) {
  while (true && ready) {
    break;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> _ifTrueConditionLint() async {
    const source = r'''
void f(List<int> values) {
  if (true) {
    values.add(1);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> _logicalConditionLiteralLint() async {
    const source = r'''
int value(bool ready) {
  if (ready && true) {
    return 1;
  }
  return 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> _conditionalExpressionLiteralLint() async {
    const source = r'''
int value(bool ready) => ready && true ? 1 : 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> _nullableBoolComparisonNoLint() async {
    await assertNoDiagnostics(r'''
bool value(bool? ready) => ready == true;
''');
  }

  Future<void> _booleanLiteralArgumentNoLint() async {
    await assertNoDiagnostics(r'''
bool isReady(bool value) => value;
int value(bool ready) {
  if (isReady(true)) {
    return 1;
  }
  return 0;
}
''');
  }
}

final class _AvoidConstantAssertConditionsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidConstantAssertConditionsTest)> get _allCases =>
      caseSet<_AvoidConstantAssertConditionsTest>(
        parent: const {},
        own: {
          'test_assertBoolLiteral_lint': (t) => t._assertBoolLiteralLint(),
          'test_assertConstantComparison_lint': (t) => t._assertConstantComparisonLint(),
          'test_assertConstIdentifier_lint': (t) => t._assertConstIdentifierLint(),
          'test_assertRuntimeCondition_noLint': (t) => t._assertRuntimeConditionNoLint(),
          'test_assertRuntimeComparison_noLint': (t) => t._assertRuntimeComparisonNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidConstantAssertConditions();
    super.setUp();
  }

  Future<void> _assertBoolLiteralLint() async {
    const source = r'''
void f() {
  assert(true);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('true'), 'true'.length)]);
  }

  Future<void> _assertConstantComparisonLint() async {
    const source = r'''
void f() {
  assert(1 == 1);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('1 == 1'), '1 == 1'.length)]);
  }

  Future<void> _assertConstIdentifierLint() async {
    const source = r'''
const ready = true;
void f() {
  assert(ready);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('ready);'), 'ready'.length)]);
  }

  Future<void> _assertRuntimeConditionNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool ready) {
  assert(ready);
}
''');
  }

  Future<void> _assertRuntimeComparisonNoLint() async {
    await assertNoDiagnostics(r'''
void f(int value) {
  assert(value > 0);
}
''');
  }
}

final class _AvoidContradictoryExpressionsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidContradictoryExpressionsTest)> get _allCases =>
      caseSet<_AvoidContradictoryExpressionsTest>(
        parent: const {},
        own: {
          'test_distinctReceiversCanOverlap_noLint': (t) => t._distinctReceiversCanOverlapNoLint(),
          'test_sameReceiverContradiction_lint': (t) => t._sameReceiverContradictionLint(),
          'test_distinctNestedReceivers_noLint': (t) => t._distinctNestedReceiversNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  Future<void> _distinctReceiversCanOverlapNoLint() async {
    await assertNoDiagnostics(r'''
class Point { final int value; Point(this.value); }
bool overlaps(Point start, Point end, Point otherStart, Point otherEnd) =>
    start.value < otherEnd.value && end.value > otherStart.value;
''');
  }

  Future<void> _sameReceiverContradictionLint() async {
    const source = r'''
class Point { final int value; Point(this.value); }
bool impossible(Point point, int bound) => point.value < bound && point.value > bound;
''';
    const expression = 'point.value < bound && point.value > bound';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _distinctNestedReceiversNoLint() async {
    await assertNoDiagnostics(r'''
class Point { final int value; Point(this.value); }
Point first() => Point(1);
Point second() => Point(2);
bool possible() => first().value < 2 && second().value > 1;
''');
  }
}
