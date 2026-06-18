// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_switch_case_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_switch_expressions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_switches.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDuplicateSwitchCaseConditionsTest);
    defineReflectiveTests(AvoidNestedSwitchesTest);
    defineReflectiveTests(AvoidNestedSwitchExpressionsTest);
  });
}

@reflectiveTest
final class AvoidDuplicateSwitchCaseConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateSwitchCaseConditions();
    super.setUp();
  }

  Future<void> test_severity_error() async {
    expect(AvoidDuplicateSwitchCaseConditions.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_switchStatementDuplicateSimpleCaseExpression_lint() async {
    const source = r'''
// ignore_for_file: unreachable_switch_case

String describe(int value) {
  switch (value) {
    case 1:
      return 'one';
    case 2:
      return 'two';
    case 1:
      return 'again';
    default:
      return 'other';
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('1:'), '1'.length)]);
  }

  Future<void> test_switchStatementDuplicateConstantPattern_lint() async {
    const source = r'''
// ignore_for_file: unreachable_switch_case

String describe(Object value) {
  switch (value) {
    case 'a':
      return 'a';
    case 'b':
      return 'b';
    case 'a':
      return 'again';
    default:
      return 'other';
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'a'"), "'a'".length)]);
  }

  Future<void> test_switchExpressionDuplicateConstantPattern_lint() async {
    const source = r'''
// ignore_for_file: unreachable_switch_case

String describe(Object value) => switch (value) {
  'a' => 'a',
  'b' => 'b',
  'a' => 'again',
  _ => 'other',
};
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'a'"), "'a'".length)]);
  }

  Future<void> test_distinctSimpleCases_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  'a' => 'a',
  'b' => 'b',
  1 => 'one',
  _ => 'other',
};
''');
  }

  Future<void> test_duplicatePatternWithDifferentGuards_noLint() async {
    await assertNoDiagnostics(r'''
String f(String? selected, List<String> values) {
  return switch (selected) {
    final value? => value,
    null when values.isNotEmpty => values.first,
    null => 'none',
  };
}
''');
  }

  Future<void> test_nonSimplePatterns_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  String(:final length) when length > 1 => 'long',
  String(:final length) when length == 1 => 'short',
  _ => 'other',
};
''');
  }
}

@reflectiveTest
final class AvoidNestedSwitchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedSwitches();
    super.setUp();
  }

  Future<void> test_severity_info() async {
    expect(AvoidNestedSwitches.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> test_nestedSwitchStatementDirectInCase_lint() async {
    const source = r'''
String describe(int outer, int inner) {
  switch (outer) {
    case 1:
      switch (inner) {
        case 1:
          return 'both';
        default:
          return 'outer';
      }
    default:
      return 'other';
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('switch (inner)'), 108)]);
  }

  Future<void> test_switchInsideBlock_noLint() async {
    await assertNoDiagnostics(r'''
String describe(int outer, int inner) {
  switch (outer) {
    case 1:
      {
        switch (inner) {
          case 1:
            return 'both';
          default:
            return 'outer';
        }
      }
    default:
      return 'other';
  }
}
''');
  }
}

@reflectiveTest
final class AvoidNestedSwitchExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedSwitchExpressions();
    super.setUp();
  }

  Future<void> test_severity_info() async {
    expect(AvoidNestedSwitchExpressions.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> test_nestedSwitchExpressionDirectInArm_lint() async {
    const source = r'''
String describe(int outer, int inner) => switch (outer) {
  1 => switch (inner) {
    1 => 'both',
    _ => 'outer',
  },
  _ => 'other',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('switch (inner)'), 55)]);
  }

  Future<void> test_switchExpressionInsideOtherExpression_noLint() async {
    await assertNoDiagnostics(r'''
String describe(int outer, int inner) => switch (outer) {
  1 => 'value ${switch (inner) {
    1 => 'both',
    _ => 'outer',
  }}',
  _ => 'other',
};
''');
  }
}
