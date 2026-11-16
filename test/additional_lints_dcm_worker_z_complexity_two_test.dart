import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_complex_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_files.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_functions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidComplexConditionsTest>(
    'AvoidComplexConditionsTest',
    AvoidComplexConditionsTest.new,
    {
      'test_fiveLogicalOperands_lint_maxFourOperands': (t) =>
          t._fiveLogicalOperandsLintMaxFourOperands(),
      'test_fourLogicalOperands_noLint_maxFourOperands': (t) =>
          t._fourLogicalOperandsNoLintMaxFourOperands(),
      'test_nonConditionExpression_noLint': (t) => t._nonConditionExpressionNoLint(),
      'test_whenClause_lint': (t) => t._whenClauseLint(),
    },
  );
  analysisRuleSuite<AvoidLongFilesTest>('AvoidLongFilesTest', AvoidLongFilesTest.new, {
    'test_fileOverSixHundredLines_lint': (t) => t._fileOverSixHundredLinesLint(),
    'test_fileAtSixHundredLines_noLint': (t) => t._fileAtSixHundredLinesNoLint(),
    'test_generatedLocalizationOverSixHundredLines_noLint': (t) =>
        t._generatedLocalizationOverSixHundredLinesNoLint(),
  });
  analysisRuleSuite<AvoidLongFunctionsTest>('AvoidLongFunctionsTest', AvoidLongFunctionsTest.new, {
    'test_functionOverEightyLines_lint': (t) => t._functionOverEightyLinesLint(),
    'test_functionAtEightyLines_noLint': (t) => t._functionAtEightyLinesNoLint(),
    'test_expressionBody_noLint': (t) => t._expressionBodyNoLint(),
    'test_longTestMain_noLint': (t) => t._longTestMainNoLint(),
    'test_longTestGroupCallback_noLint': (t) => t._longTestGroupCallbackNoLint(),
    'test_longTestCallback_noLint': (t) => t._longTestCallbackNoLint(),
    'test_longTestRegistrationHelper_noLint': (t) => t._longTestRegistrationHelperNoLint(),
    'test_longTestHelperFunction_lint': (t) => t._longTestHelperFunctionLint(),
  });
}

final class AvoidComplexConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidComplexConditions();
    super.setUp();
  }

  Future<void> _fiveLogicalOperandsLintMaxFourOperands() async {
    const source = r'''
bool allowed(bool a, bool b, bool c, bool d, bool e) {
  if (a && b && c && d && e) {
    return true;
  }

  return false;
}
''';

    const condition = 'a && b && c && d && e';
    await assertDiagnostics(source, [lint(source.indexOf(condition), condition.length)]);
  }

  Future<void> _fourLogicalOperandsNoLintMaxFourOperands() async {
    await assertNoDiagnostics(r'''
bool allowed(bool a, bool b, bool c, bool d) {
  if (a && b && c && d) {
    return true;
  }

  return false;
}
''');
  }

  Future<void> _nonConditionExpressionNoLint() async {
    await assertNoDiagnostics(r'''
bool allowed(bool a, bool b, bool c, bool d, bool e) {
  final combined = a && b && c && d && e;
  return combined;
}
''');
  }

  Future<void> _whenClauseLint() async {
    const source = r'''
String label(Object value, bool a, bool b, bool c, bool d, bool e) {
  return switch (value) {
    int() when a || b || c || d || e => 'number',
    _ => 'other',
  };
}
''';

    const condition = 'a || b || c || d || e';
    await assertDiagnostics(source, [lint(source.indexOf(condition), condition.length)]);
  }
}

final class AvoidLongFilesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFiles();
    super.setUp();
  }

  Future<void> _fileOverSixHundredLinesLint() async {
    final source = _fileWithLines(AvoidLongFiles.maxLines + 1);

    await assertDiagnostics(source, [lint(0, 'void'.length)]);
  }

  Future<void> _fileAtSixHundredLinesNoLint() async {
    await assertNoDiagnostics(_fileWithLines(AvoidLongFiles.maxLines));
  }

  Future<void> _generatedLocalizationOverSixHundredLinesNoLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, _fileWithLines(AvoidLongFiles.maxLines + 1));

    await assertNoDiagnosticsInFile(filePath);
  }
}

final class AvoidLongFunctionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFunctions();
    super.setUp();
  }

  Future<void> _functionOverEightyLinesLint() async {
    final body = _statements(AvoidLongFunctions.maxLines - 1);
    final source =
        '''
void process() {
$body
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('process'), 'process'.length)]);
  }

  Future<void> _functionAtEightyLinesNoLint() async {
    final body = _statements(AvoidLongFunctions.maxLines - 2);

    await assertNoDiagnostics('''
void process() {
$body
}
''');
  }

  Future<void> _expressionBodyNoLint() async {
    await assertNoDiagnostics(r'''
int process(int value) => value + 1;
''');
  }

  Future<void> _longTestMainNoLint() async {
    final body = _statements(AvoidLongFunctions.maxLines);
    final source =
        '''
void main() {
$body
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _longTestGroupCallbackNoLint() async {
    final body = _statements(AvoidLongFunctions.maxLines);
    final source =
        '''
void group(String name, void Function() body) => body();

void main() {
  group('feature', () {
$body
  });
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _longTestCallbackNoLint() async {
    final body = _statements(AvoidLongFunctions.maxLines);
    final source =
        '''
void test(String name, void Function() body) => body();

void main() {
  test('feature', () {
$body
  });
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _longTestRegistrationHelperNoLint() async {
    final body = _statements(AvoidLongFunctions.maxLines);
    final source =
        '''
void group(String name, void Function() body) => body();

void registerFeatureTests() {
  group('feature', () {
$body
  });
}

void main() {
  registerFeatureTests();
}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _longTestHelperFunctionLint() async {
    final body = _statements(AvoidLongFunctions.maxLines - 1);
    final source =
        '''
void helper() {
$body
}

void main() {}
''';
    final path = '$testPackageRootPath/test/example_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf('helper'), 'helper'.length)]);
  }
}

String _fileWithLines(int lineCount) {
  final fillerLineCount = lineCount - 1;
  final filler = List.filled(fillerLineCount, '// filler').join('\n');
  return 'void process() {}\n$filler';
}

String _statements(int count) {
  return List.generate(count, (index) => '  print($index);').join('\n');
}
