import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_enum_arguments.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_boolean_literal_compare.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_empty_block.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryEnumArgumentsTest>(
    'AvoidUnnecessaryEnumArgumentsTest',
    _AvoidUnnecessaryEnumArgumentsTest.new,
    _AvoidUnnecessaryEnumArgumentsTest._allCases,
  );
  analysisRuleSuite<_NoBooleanLiteralCompareTest>(
    'NoBooleanLiteralCompareTest',
    _NoBooleanLiteralCompareTest.new,
    _NoBooleanLiteralCompareTest._allCases,
  );
  analysisRuleSuite<_NoEmptyBlockTest>(
    'NoEmptyBlockTest',
    _NoEmptyBlockTest.new,
    _NoEmptyBlockTest._allCases,
  );
}

final class _AvoidUnnecessaryEnumArgumentsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryEnumArgumentsTest)> get _allCases =>
      caseSet<_AvoidUnnecessaryEnumArgumentsTest>(
        parent: const {},
        own: {
          'test_namedEnumArgumentMatchingDefault_lint': (t) =>
              t._namedEnumArgumentMatchingDefaultLint(),
          'test_namedEnumArgumentDifferentFromDefault_noLint': (t) =>
              t._namedEnumArgumentDifferentFromDefaultNoLint(),
          'test_namedEnumArgumentWithoutDefault_noLint': (t) =>
              t._namedEnumArgumentWithoutDefaultNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnnecessaryEnumArguments();
    super.setUp();
  }

  Future<void> _namedEnumArgumentMatchingDefaultLint() async {
    const source = r'''
enum Priority { low, normal, high }

void schedule({Priority priority = Priority.normal}) {}

void f() {
  schedule(priority: Priority.normal);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('priority: Priority.normal'), 'priority: Priority.normal'.length),
    ]);
  }

  Future<void> _namedEnumArgumentDifferentFromDefaultNoLint() async {
    await assertNoDiagnostics(r'''
enum Priority { low, normal, high }

void schedule({Priority priority = Priority.normal}) {}

void f() {
  schedule(priority: Priority.high);
}
''');
  }

  Future<void> _namedEnumArgumentWithoutDefaultNoLint() async {
    await assertNoDiagnostics(r'''
enum Priority { low, normal, high }

void schedule({required Priority priority}) {}

void f() {
  schedule(priority: Priority.normal);
}
''');
  }
}

final class _NoBooleanLiteralCompareTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_NoBooleanLiteralCompareTest)> get _allCases =>
      caseSet<_NoBooleanLiteralCompareTest>(
        parent: const {},
        own: {
          'test_boolEqualsTrue_lint': (t) => t._boolEqualsTrueLint(),
          'test_falseNotEqualsBool_lint': (t) => t._falseNotEqualsBoolLint(),
          'test_nullableBoolEqualsTrue_noLint': (t) => t._nullableBoolEqualsTrueNoLint(),
          'test_boolVariableComparison_noLint': (t) => t._boolVariableComparisonNoLint(),
        },
      );

  @override
  void setUp() {
    rule = NoBooleanLiteralCompare();
    super.setUp();
  }

  Future<void> _boolEqualsTrueLint() async {
    const source = r'''
bool enabled = true;

bool f() => enabled == true;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('enabled == true'), 'enabled == true'.length),
    ]);
  }

  Future<void> _falseNotEqualsBoolLint() async {
    const source = r'''
bool enabled = true;

bool f() => false != enabled;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('false != enabled'), 'false != enabled'.length),
    ]);
  }

  Future<void> _nullableBoolEqualsTrueNoLint() async {
    await assertNoDiagnostics(r'''
bool? enabled;

bool f() => enabled == true;
''');
  }

  Future<void> _boolVariableComparisonNoLint() async {
    await assertNoDiagnostics(r'''
bool left = true;
bool right = false;

bool f() => left == right;
''');
  }
}

final class _NoEmptyBlockTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_NoEmptyBlockTest)> get _allCases =>
      caseSet<_NoEmptyBlockTest>(
        parent: const {},
        own: {
          'test_emptyIfBlock_lint': (t) => t._emptyIfBlockLint(),
          'test_emptyCatchBlock_lint': (t) => t._emptyCatchBlockLint(),
          'test_emptyCallbackBody_noLint': (t) => t._emptyCallbackBodyNoLint(),
          'test_emptyOverrideBody_noLint': (t) => t._emptyOverrideBodyNoLint(),
          'test_nonEmptyBlock_noLint': (t) => t._nonEmptyBlockNoLint(),
        },
      );

  @override
  void setUp() {
    rule = NoEmptyBlock();
    super.setUp();
  }

  Future<void> _emptyIfBlockLint() async {
    const source = r'''
void f(bool enabled) {
  if (enabled) {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('{}'), '{}'.length)]);
  }

  Future<void> _emptyCatchBlockLint() async {
    const source = r'''
void f() {
  try {
    throw 'bad';
  } catch (_) {}
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('{}'), '{}'.length)]);
  }

  Future<void> _emptyCallbackBodyNoLint() async {
    await assertNoDiagnostics(r'''
void f(void Function() callback) {
  f(() {});
}
''');
  }

  Future<void> _emptyOverrideBodyNoLint() async {
    await assertNoDiagnostics(r'''
class Base {
  void close() {}
}

class FakeBase extends Base {
  @override
  void close() {}
}
''');
  }

  Future<void> _nonEmptyBlockNoLint() async {
    await assertNoDiagnostics(r'''
void f(bool enabled) {
  if (enabled) {
    print('enabled');
  }
}
''');
  }
}
