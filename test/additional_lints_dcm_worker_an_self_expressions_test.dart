import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_equal_expressions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_self_assignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_self_compare.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidEqualExpressionsTest>(
    'AvoidEqualExpressionsTest',
    AvoidEqualExpressionsTest.new,
    {
      'test_logicalAndSameExpression_lint': (t) => t._logicalAndSameExpressionLint(),
      'test_ifNullSameExpression_lint': (t) => t._ifNullSameExpressionLint(),
      'test_differentLogicalOperands_noLint': (t) => t._differentLogicalOperandsNoLint(),
      'test_repeatedCall_noLint': (t) => t._repeatedCallNoLint(),
    },
  );
  analysisRuleSuite<AvoidSelfAssignmentTest>(
    'AvoidSelfAssignmentTest',
    AvoidSelfAssignmentTest.new,
    {
      'test_localSelfAssignment_lint': (t) => t._localSelfAssignmentLint(),
      'test_fieldSelfAssignment_lint': (t) => t._fieldSelfAssignmentLint(),
      'test_compoundAssignment_noLint': (t) => t._compoundAssignmentNoLint(),
      'test_differentAssignment_noLint': (t) => t._differentAssignmentNoLint(),
    },
  );
  analysisRuleSuite<AvoidSelfCompareTest>('AvoidSelfCompareTest', AvoidSelfCompareTest.new, {
    'test_identifierSelfCompare_lint': (t) => t._identifierSelfCompareLint(),
    'test_propertySelfCompare_lint': (t) => t._propertySelfCompareLint(),
    'test_differentCompare_noLint': (t) => t._differentCompareNoLint(),
    'test_repeatedCall_noLint': (t) => t._repeatedCallNoLint(),
  });
}

final class AvoidEqualExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEqualExpressions();
    super.setUp();
  }

  Future<void> _logicalAndSameExpressionLint() async {
    const source = r'''
bool ready(bool enabled, bool valid) => (enabled && valid) && (enabled && valid);
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('(enabled && valid) &&'),
        '(enabled && valid) && (enabled && valid)'.length,
      ),
    ]);
  }

  Future<void> _ifNullSameExpressionLint() async {
    const source = r'''
String? value(String? name) => name ?? name;
''';

    await assertDiagnostics(source, [lint(source.indexOf('name ?? name'), 'name ?? name'.length)]);
  }

  Future<void> _differentLogicalOperandsNoLint() async {
    await assertNoDiagnostics(r'''
bool ready(bool enabled, bool valid) => enabled && valid;
''');
  }

  Future<void> _repeatedCallNoLint() async {
    await assertNoDiagnostics(r'''
bool ready(bool Function() enabled) => enabled() && enabled();
''');
  }
}

final class AvoidSelfAssignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfAssignment();
    super.setUp();
  }

  Future<void> _localSelfAssignmentLint() async {
    const source = r'''
void normalize(int value) {
  value = value;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value = value'), 'value = value'.length),
    ]);
  }

  Future<void> _fieldSelfAssignmentLint() async {
    const source = r'''
class User {
  String name = '';

  void rename() {
    this.name = this.name;
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('this.name = this.name'), 'this.name = this.name'.length),
    ]);
  }

  Future<void> _compoundAssignmentNoLint() async {
    await assertNoDiagnostics(r'''
void increment(int value) {
  value += value;
}
''');
  }

  Future<void> _differentAssignmentNoLint() async {
    await assertNoDiagnostics(r'''
void normalize(int value) {
  final next = value.abs();
  value = next;
}
''');
  }
}

final class AvoidSelfCompareTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidSelfCompare();
    super.setUp();
  }

  Future<void> _identifierSelfCompareLint() async {
    const source = r'''
bool same(int value) => value == value;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value == value'), 'value == value'.length),
    ]);
  }

  Future<void> _propertySelfCompareLint() async {
    const source = r'''
class User {
  User(this.name);

  final String name;
}

bool same(User user) => user.name != user.name;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('user.name != user.name'), 'user.name != user.name'.length),
    ]);
  }

  Future<void> _differentCompareNoLint() async {
    await assertNoDiagnostics(r'''
bool same(int left, int right) => left == right;
''');
  }

  Future<void> _repeatedCallNoLint() async {
    await assertNoDiagnostics(r'''
bool same(int Function() next) => next() == next();
''');
  }
}
