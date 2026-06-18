// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_if_with_many_branches.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_parameter_list.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_conditional_expressions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedConditionalExpressionsTest);
    defineReflectiveTests(AvoidIfWithManyBranchesTest);
    defineReflectiveTests(AvoidLongParameterListTest);
  });
}

@reflectiveTest
final class AvoidNestedConditionalExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedConditionalExpressions();
    super.setUp();
  }

  Future<void> test_thenBranchNestedConditional_lint() async {
    const source = r'''
int choose(bool first, bool second) {
  return first ? (second ? 1 : 2) : 3;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('second ? 1 : 2'), 'second ? 1 : 2'.length),
    ]);
  }

  Future<void> test_elseBranchNestedConditional_lint() async {
    const source = r'''
int choose(bool first, bool second) {
  return first ? 1 : second ? 2 : 3;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('second ? 2 : 3'), 'second ? 2 : 3'.length),
    ]);
  }

  Future<void> test_separateConditionalExpressions_noLint() async {
    await assertNoDiagnostics(r'''
int choose(bool first, bool second) {
  final firstValue = first ? 1 : 2;
  final secondValue = second ? 3 : 4;
  return firstValue + secondValue;
}
''');
  }
}

@reflectiveTest
final class AvoidIfWithManyBranchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIfWithManyBranches();
    super.setUp();
  }

  Future<void> test_fourBranches_lint_maxThreeBranches() async {
    const source = r'''
String label(int value) {
  if (value == 0) {
    return 'zero';
  } else if (value == 1) {
    return 'one';
  } else if (value == 2) {
    return 'two';
  } else {
    return 'many';
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('if (value == 0)'), 'if'.length)]);
  }

  Future<void> test_threeBranches_noLint_maxThreeBranches() async {
    await assertNoDiagnostics(r'''
String label(int value) {
  if (value == 0) {
    return 'zero';
  } else if (value == 1) {
    return 'one';
  } else {
    return 'many';
  }
}
''');
  }

  Future<void> test_nestedSeparateIfChains_noLint() async {
    await assertNoDiagnostics(r'''
String label(int value, bool verbose) {
  if (value == 0) {
    if (verbose) {
      return 'zero';
    } else {
      return '0';
    }
  }

  return 'many';
}
''');
  }
}

@reflectiveTest
final class AvoidLongParameterListTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    rule = AvoidLongParameterList();
    super.setUp();
  }

  Future<void> test_fiveFunctionParameters_lint_maxFourParameters() async {
    const source = r'''
void configure(int a, int b, int c, int d, int e) {}
''';

    const parameterList = '(int a, int b, int c, int d, int e)';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> test_fourFunctionParameters_noLint_maxFourParameters() async {
    await assertNoDiagnostics(r'''
void configure(int a, int b, int c, int d) {}
''');
  }

  Future<void> test_overrideMethodParameters_lintsBaseOnly() async {
    const source = r'''
class Base {
  void configure(int a, int b, int c, int d, int e) {}
}

class Derived extends Base {
  @override
  void configure(int a, int b, int c, int d, int e) {}
}
''';

    const parameterList = '(int a, int b, int c, int d, int e)';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> test_zoneSpecificationHandleUncaughtErrorCallback_noLint() async {
    await assertNoDiagnostics(r'''
class ZoneSpecification {
  ZoneSpecification({required Function handleUncaughtError});
}

void capture(List<Object> errors) {
  ZoneSpecification(
    handleUncaughtError: (self, parent, zone, error, stack) {
      errors.add(error);
    },
  );
}
''');
  }

  Future<void> test_fiveConstructorParameters_lint_maxFourParameters() async {
    const source = r'''
class Config {
  Config(int a, int b, int c, int d, int e);
}
''';

    const parameterList = '(int a, int b, int c, int d, int e)';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> test_widgetConstructorParameters_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.isDense,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isDense;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => trailing;
}
''');
  }

  Future<void> test_freezedFactoryConstructorParameters_noLint() async {
    await assertNoDiagnostics(r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();

@freezed
class ExerciseModel {
  factory ExerciseModel({
    required String id,
    required String name,
    required int category,
    required String muscleGroup,
    required bool isCustom,
  }) => _ExerciseModel();
}

class _ExerciseModel implements ExerciseModel {
  const _ExerciseModel();
}
''');
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}

class Key {
  const Key();
}

class Widget {
  const Widget({Key? key});
}

class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => const Widget();
}

typedef VoidCallback = void Function();
''');
  }
}
