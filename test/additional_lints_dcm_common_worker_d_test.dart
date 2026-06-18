// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assigning_to_static_field.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_annotations.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_referencing_discarded_variables.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAssigningToStaticFieldTest);
    defineReflectiveTests(AvoidReferencingDiscardedVariablesTest);
    defineReflectiveTests(AvoidBannedAnnotationsTest);
  });
}

@reflectiveTest
final class AvoidAssigningToStaticFieldTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAssigningToStaticField();
    super.setUp();
  }

  Future<void> test_instanceFieldAssignment_noLint() async {
    await assertNoDiagnostics(r'''
class Counter {
  int value = 0;

  void update() {
    value = 1;
  }
}
''');
  }

  Future<void> test_staticFieldAssignment_lint() async {
    const source = r'''
class Counter {
  static int value = 0;

  void update() {
    Counter.value = 1;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value = 1'), 'value'.length)]);
  }

  Future<void> test_staticFieldIncrement_lint() async {
    const source = r'''
class Counter {
  static int value = 0;

  void update() {
    Counter.value++;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value++'), 'value'.length)]);
  }

  Future<void> test_visibleForTestingStaticAssignment_noLint() async {
    await assertNoDiagnostics(r'''
const visibleForTesting = _VisibleForTesting();

final class _VisibleForTesting {
  const _VisibleForTesting();
}

class Counter {
  static int value = 0;

  @visibleForTesting
  static void debugReset() {
    Counter.value = 0;
  }
}
''');
  }
}

@reflectiveTest
final class AvoidReferencingDiscardedVariablesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidReferencingDiscardedVariables();
    super.setUp();
  }

  Future<void> test_discardedVariableDeclarationOnly_noLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  final __ = value;
}
''');
  }

  Future<void> test_namedVariableReference_noLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  final used = value;
  print(used);
}
''');
  }

  Future<void> test_referencedDiscardedVariable_lint() async {
    const source = r'''
void f(Object value) {
  final __ = value;
  print(__);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('__);'), 2)]);
  }
}

@reflectiveTest
final class AvoidBannedAnnotationsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedAnnotations();
    super.setUp();
  }

  Future<void> test_deprecatedConstantAnnotation_lint() async {
    const source = r'''
@deprecated
void f() {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('@deprecated'), '@deprecated'.length)]);
  }

  Future<void> test_deprecatedConstructorAnnotation_lint() async {
    const source = r'''
@Deprecated('Use g')
void f() {}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("@Deprecated('Use g')"), "@Deprecated('Use g')".length),
    ]);
  }

  Future<void> test_overrideAnnotation_noLint() async {
    await assertNoDiagnostics(r'''
class Parent {
  void f() {}
}

class Child extends Parent {
  @override
  void f() {}
}
''');
  }
}
