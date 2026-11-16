import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assigning_to_static_field.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_annotations.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_referencing_discarded_variables.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidAssigningToStaticFieldTest>(
    'AvoidAssigningToStaticFieldTest',
    _AvoidAssigningToStaticFieldTest.new,
    _AvoidAssigningToStaticFieldTest._allCases,
  );
  analysisRuleSuite<_AvoidReferencingDiscardedVariablesTest>(
    'AvoidReferencingDiscardedVariablesTest',
    _AvoidReferencingDiscardedVariablesTest.new,
    _AvoidReferencingDiscardedVariablesTest._allCases,
  );
  analysisRuleSuite<_AvoidBannedAnnotationsTest>(
    'AvoidBannedAnnotationsTest',
    _AvoidBannedAnnotationsTest.new,
    _AvoidBannedAnnotationsTest._allCases,
  );
}

final class _AvoidAssigningToStaticFieldTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidAssigningToStaticFieldTest)> get _allCases =>
      caseSet<_AvoidAssigningToStaticFieldTest>(
        parent: const {},
        own: {
          'test_instanceFieldAssignment_noLint': (t) => t._instanceFieldAssignmentNoLint(),
          'test_staticFieldAssignment_lint': (t) => t._staticFieldAssignmentLint(),
          'test_staticFieldIncrement_lint': (t) => t._staticFieldIncrementLint(),
          'test_visibleForTestingStaticAssignment_noLint': (t) =>
              t._visibleForTestingStaticAssignmentNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidAssigningToStaticField();
    super.setUp();
  }

  Future<void> _instanceFieldAssignmentNoLint() async {
    await assertNoDiagnostics(r'''
class Counter {
  int value = 0;

  void update() {
    value = 1;
  }
}
''');
  }

  Future<void> _staticFieldAssignmentLint() async {
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

  Future<void> _staticFieldIncrementLint() async {
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

  Future<void> _visibleForTestingStaticAssignmentNoLint() async {
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

final class _AvoidReferencingDiscardedVariablesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidReferencingDiscardedVariablesTest)>
  get _allCases => caseSet<_AvoidReferencingDiscardedVariablesTest>(
    parent: const {},
    own: {
      'test_discardedVariableDeclarationOnly_noLint': (t) =>
          t._discardedVariableDeclarationOnlyNoLint(),
      'test_namedVariableReference_noLint': (t) => t._namedVariableReferenceNoLint(),
      'test_referencedDiscardedVariable_lint': (t) => t._referencedDiscardedVariableLint(),
      'test_privateNamedConstructorReferences_noLint': (t) =>
          t._privateNamedConstructorReferencesNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidReferencingDiscardedVariables();
    super.setUp();
  }

  Future<void> _discardedVariableDeclarationOnlyNoLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  final __ = value;
}
''');
  }

  Future<void> _namedVariableReferenceNoLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  final used = value;
  print(used);
}
''');
  }

  Future<void> _referencedDiscardedVariableLint() async {
    const source = r'''
void f(Object value) {
  final __ = value;
  print(__);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('__);'), 2)]);
  }

  Future<void> _privateNamedConstructorReferencesNoLint() async {
    await assertNoDiagnostics(r'''
final class Cache {
  Cache._();
  static final Cache instance = ._();
}

final class Message {
  Message._(this.text);
  final String text;
}

Message create() => Message._('hello');
''');
  }
}

final class _AvoidBannedAnnotationsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidBannedAnnotationsTest)> get _allCases =>
      caseSet<_AvoidBannedAnnotationsTest>(
        parent: const {},
        own: {
          'test_deprecatedConstantAnnotation_lint': (t) => t._deprecatedConstantAnnotationLint(),
          'test_deprecatedConstructorAnnotation_lint': (t) =>
              t._deprecatedConstructorAnnotationLint(),
          'test_overrideAnnotation_noLint': (t) => t._overrideAnnotationNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidBannedAnnotations();
    super.setUp();
  }

  Future<void> _deprecatedConstantAnnotationLint() async {
    const source = r'''
@deprecated
void f() {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('@deprecated'), '@deprecated'.length)]);
  }

  Future<void> _deprecatedConstructorAnnotationLint() async {
    const source = r'''
@Deprecated('Use g')
void f() {}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("@Deprecated('Use g')"), "@Deprecated('Use g')".length),
    ]);
  }

  Future<void> _overrideAnnotationNoLint() async {
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
