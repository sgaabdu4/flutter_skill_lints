// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_enum_arguments.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_boolean_literal_compare.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/no_empty_block.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnnecessaryEnumArgumentsTest);
    defineReflectiveTests(NoBooleanLiteralCompareTest);
    defineReflectiveTests(NoEmptyBlockTest);
  });
}

@reflectiveTest
final class AvoidUnnecessaryEnumArgumentsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryEnumArguments();
    super.setUp();
  }

  Future<void> test_namedEnumArgumentMatchingDefault_lint() async {
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

  Future<void> test_namedEnumArgumentDifferentFromDefault_noLint() async {
    await assertNoDiagnostics(r'''
enum Priority { low, normal, high }

void schedule({Priority priority = Priority.normal}) {}

void f() {
  schedule(priority: Priority.high);
}
''');
  }

  Future<void> test_namedEnumArgumentWithoutDefault_noLint() async {
    await assertNoDiagnostics(r'''
enum Priority { low, normal, high }

void schedule({required Priority priority}) {}

void f() {
  schedule(priority: Priority.normal);
}
''');
  }
}

@reflectiveTest
final class NoBooleanLiteralCompareTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBooleanLiteralCompare();
    super.setUp();
  }

  Future<void> test_boolEqualsTrue_lint() async {
    const source = r'''
bool enabled = true;

bool f() => enabled == true;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('enabled == true'), 'enabled == true'.length),
    ]);
  }

  Future<void> test_falseNotEqualsBool_lint() async {
    const source = r'''
bool enabled = true;

bool f() => false != enabled;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('false != enabled'), 'false != enabled'.length),
    ]);
  }

  Future<void> test_nullableBoolEqualsTrue_noLint() async {
    await assertNoDiagnostics(r'''
bool? enabled;

bool f() => enabled == true;
''');
  }

  Future<void> test_boolVariableComparison_noLint() async {
    await assertNoDiagnostics(r'''
bool left = true;
bool right = false;

bool f() => left == right;
''');
  }
}

@reflectiveTest
final class NoEmptyBlockTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEmptyBlock();
    super.setUp();
  }

  Future<void> test_emptyIfBlock_lint() async {
    const source = r'''
void f(bool enabled) {
  if (enabled) {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('{}'), '{}'.length)]);
  }

  Future<void> test_emptyCatchBlock_lint() async {
    const source = r'''
void f() {
  try {
    throw 'bad';
  } catch (_) {}
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('{}'), '{}'.length)]);
  }

  Future<void> test_emptyCallbackBody_noLint() async {
    await assertNoDiagnostics(r'''
void f(void Function() callback) {
  f(() {});
}
''');
  }

  Future<void> test_emptyOverrideBody_noLint() async {
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

  Future<void> test_nonEmptyBlock_noLint() async {
    await assertNoDiagnostics(r'''
void f(bool enabled) {
  if (enabled) {
    print('enabled');
  }
}
''');
  }
}
