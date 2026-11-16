import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_if_with_many_branches.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_parameter_list.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_conditional_expressions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidNestedConditionalExpressionsTest>(
    'AvoidNestedConditionalExpressionsTest',
    AvoidNestedConditionalExpressionsTest.new,
    {
      'test_thenBranchNestedConditional_lint': (t) => t._thenBranchNestedConditionalLint(),
      'test_elseBranchNestedConditional_lint': (t) => t._elseBranchNestedConditionalLint(),
      'test_separateConditionalExpressions_noLint': (t) =>
          t._separateConditionalExpressionsNoLint(),
    },
  );
  analysisRuleSuite<AvoidIfWithManyBranchesTest>(
    'AvoidIfWithManyBranchesTest',
    AvoidIfWithManyBranchesTest.new,
    {
      'test_fourBranches_lint_maxThreeBranches': (t) => t._fourBranchesLintMaxThreeBranches(),
      'test_threeBranches_noLint_maxThreeBranches': (t) => t._threeBranchesNoLintMaxThreeBranches(),
      'test_nestedSeparateIfChains_noLint': (t) => t._nestedSeparateIfChainsNoLint(),
    },
  );
  analysisRuleSuite<AvoidLongParameterListTest>(
    'AvoidLongParameterListTest',
    AvoidLongParameterListTest.new,
    {
      'test_fiveFunctionParameters_lint_maxFourParameters': (t) =>
          t._fiveFunctionParametersLintMaxFourParameters(),
      'test_optionalNamedParametersNotCounted_noLint': (t) =>
          t._optionalNamedParametersNotCountedNoLint(),
      'test_fiveRequiredNamedAndPositionalParameters_lint': (t) =>
          t._fiveRequiredNamedAndPositionalParametersLint(),
      'test_fivePositionalWithOptionalPositionalParameters_lint': (t) =>
          t._fivePositionalWithOptionalPositionalParametersLint(),
      'test_fourFunctionParameters_noLint_maxFourParameters': (t) =>
          t._fourFunctionParametersNoLintMaxFourParameters(),
      'test_overrideMethodParameters_lintsBaseOnly': (t) =>
          t._overrideMethodParametersLintsBaseOnly(),
      'test_zoneSpecificationHandleUncaughtErrorCallback_noLint': (t) =>
          t._zoneSpecificationHandleUncaughtErrorCallbackNoLint(),
      'test_fiveConstructorParameters_lint_maxFourParameters': (t) =>
          t._fiveConstructorParametersLintMaxFourParameters(),
      'test_widgetConstructorParameters_noLint': (t) => t._widgetConstructorParametersNoLint(),
      'test_freezedFactoryConstructorParameters_noLint': (t) =>
          t._freezedFactoryConstructorParametersNoLint(),
    },
  );
}

final class AvoidNestedConditionalExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedConditionalExpressions();
    super.setUp();
  }

  Future<void> _thenBranchNestedConditionalLint() async {
    const source = r'''
int choose(bool first, bool second) {
  return first ? (second ? 1 : 2) : 3;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('second ? 1 : 2'), 'second ? 1 : 2'.length),
    ]);
  }

  Future<void> _elseBranchNestedConditionalLint() async {
    const source = r'''
int choose(bool first, bool second) {
  return first ? 1 : second ? 2 : 3;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('second ? 2 : 3'), 'second ? 2 : 3'.length),
    ]);
  }

  Future<void> _separateConditionalExpressionsNoLint() async {
    await assertNoDiagnostics(r'''
int choose(bool first, bool second) {
  final firstValue = first ? 1 : 2;
  final secondValue = second ? 3 : 4;
  return firstValue + secondValue;
}
''');
  }
}

final class AvoidIfWithManyBranchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIfWithManyBranches();
    super.setUp();
  }

  Future<void> _fourBranchesLintMaxThreeBranches() async {
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

  Future<void> _threeBranchesNoLintMaxThreeBranches() async {
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

  Future<void> _nestedSeparateIfChainsNoLint() async {
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

final class AvoidLongParameterListTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    rule = AvoidLongParameterList();
    super.setUp();
  }

  Future<void> _fiveFunctionParametersLintMaxFourParameters() async {
    const source = r'''
void configure(int a, int b, int c, int d, int e) {}
''';

    const parameterList = '(int a, int b, int c, int d, int e)';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> _optionalNamedParametersNotCountedNoLint() async {
    await assertNoDiagnostics(r'''
abstract final class Crash {
  static void error(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
    Map<String, Object?> extras = const {},
  }) {}
}
''');
  }

  Future<void> _fiveRequiredNamedAndPositionalParametersLint() async {
    const source = r'''
void configure(int a, int b, int c, {required int d, required int e}) {}
''';

    const parameterList = '(int a, int b, int c, {required int d, required int e})';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> _fivePositionalWithOptionalPositionalParametersLint() async {
    const source = r'''
void configure(int a, int b, int c, int d, [int e = 0]) {}
''';

    const parameterList = '(int a, int b, int c, int d, [int e = 0])';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> _fourFunctionParametersNoLintMaxFourParameters() async {
    await assertNoDiagnostics(r'''
void configure(int a, int b, int c, int d) {}
''');
  }

  Future<void> _overrideMethodParametersLintsBaseOnly() async {
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

  Future<void> _zoneSpecificationHandleUncaughtErrorCallbackNoLint() async {
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

  Future<void> _fiveConstructorParametersLintMaxFourParameters() async {
    const source = r'''
class Config {
  Config(int a, int b, int c, int d, int e);
}
''';

    const parameterList = '(int a, int b, int c, int d, int e)';
    await assertDiagnostics(source, [lint(source.indexOf(parameterList), parameterList.length)]);
  }

  Future<void> _widgetConstructorParametersNoLint() async {
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

  Future<void> _freezedFactoryConstructorParametersNoLint() async {
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
