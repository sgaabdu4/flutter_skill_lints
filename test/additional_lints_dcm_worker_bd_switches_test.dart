import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_switch_case_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_switch_expressions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_switches.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidDuplicateSwitchCaseConditionsTest>(
    'AvoidDuplicateSwitchCaseConditionsTest',
    AvoidDuplicateSwitchCaseConditionsTest.new,
    {
      'test_severity_error': (t) => t._severityError(),
      'test_switchStatementDuplicateSimpleCaseExpression_lint': (t) =>
          t._switchStatementDuplicateSimpleCaseExpressionLint(),
      'test_switchStatementDuplicateConstantPattern_lint': (t) =>
          t._switchStatementDuplicateConstantPatternLint(),
      'test_switchExpressionDuplicateConstantPattern_lint': (t) =>
          t._switchExpressionDuplicateConstantPatternLint(),
      'test_distinctSimpleCases_noLint': (t) => t._distinctSimpleCasesNoLint(),
      'test_duplicatePatternWithDifferentGuards_noLint': (t) =>
          t._duplicatePatternWithDifferentGuardsNoLint(),
      'test_nonSimplePatterns_noLint': (t) => t._nonSimplePatternsNoLint(),
    },
  );
  analysisRuleSuite<AvoidNestedSwitchesTest>(
    'AvoidNestedSwitchesTest',
    AvoidNestedSwitchesTest.new,
    {
      'test_severity_info': (t) => t._severityInfo(),
      'test_nestedSwitchStatementDirectInCase_lint': (t) =>
          t._nestedSwitchStatementDirectInCaseLint(),
      'test_switchInsideBlock_noLint': (t) => t._switchInsideBlockNoLint(),
    },
  );
  analysisRuleSuite<AvoidNestedSwitchExpressionsTest>(
    'AvoidNestedSwitchExpressionsTest',
    AvoidNestedSwitchExpressionsTest.new,
    {
      'test_severity_info': (t) => t._severityInfo(),
      'test_nestedSwitchExpressionDirectInArm_lint': (t) =>
          t._nestedSwitchExpressionDirectInArmLint(),
      'test_switchExpressionInsideOtherExpression_noLint': (t) =>
          t._switchExpressionInsideOtherExpressionNoLint(),
    },
  );
}

final class AvoidDuplicateSwitchCaseConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateSwitchCaseConditions();
    super.setUp();
  }

  Future<void> _severityError() async {
    expect(AvoidDuplicateSwitchCaseConditions.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _switchStatementDuplicateSimpleCaseExpressionLint() async {
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

  Future<void> _switchStatementDuplicateConstantPatternLint() async {
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

  Future<void> _switchExpressionDuplicateConstantPatternLint() async {
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

  Future<void> _distinctSimpleCasesNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  'a' => 'a',
  'b' => 'b',
  1 => 'one',
  _ => 'other',
};
''');
  }

  Future<void> _duplicatePatternWithDifferentGuardsNoLint() async {
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

  Future<void> _nonSimplePatternsNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  String(:final length) when length > 1 => 'long',
  String(:final length) when length == 1 => 'short',
  _ => 'other',
};
''');
  }
}

final class AvoidNestedSwitchesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedSwitches();
    super.setUp();
  }

  Future<void> _severityInfo() async {
    expect(AvoidNestedSwitches.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> _nestedSwitchStatementDirectInCaseLint() async {
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

  Future<void> _switchInsideBlockNoLint() async {
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

final class AvoidNestedSwitchExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedSwitchExpressions();
    super.setUp();
  }

  Future<void> _severityInfo() async {
    expect(AvoidNestedSwitchExpressions.code.severity, DiagnosticSeverity.INFO);
  }

  Future<void> _nestedSwitchExpressionDirectInArmLint() async {
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

  Future<void> _switchExpressionInsideOtherExpressionNoLint() async {
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
