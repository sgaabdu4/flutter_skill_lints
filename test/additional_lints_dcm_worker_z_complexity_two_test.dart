// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_complex_conditions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_files.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_long_functions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidComplexConditionsTest);
    defineReflectiveTests(AvoidLongFilesTest);
    defineReflectiveTests(AvoidLongFunctionsTest);
  });
}

@reflectiveTest
final class AvoidComplexConditionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidComplexConditions();
    super.setUp();
  }

  Future<void> test_fiveLogicalOperands_lint_maxFourOperands() async {
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

  Future<void> test_fourLogicalOperands_noLint_maxFourOperands() async {
    await assertNoDiagnostics(r'''
bool allowed(bool a, bool b, bool c, bool d) {
  if (a && b && c && d) {
    return true;
  }

  return false;
}
''');
  }

  Future<void> test_nonConditionExpression_noLint() async {
    await assertNoDiagnostics(r'''
bool allowed(bool a, bool b, bool c, bool d, bool e) {
  final combined = a && b && c && d && e;
  return combined;
}
''');
  }

  Future<void> test_whenClause_lint() async {
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

@reflectiveTest
final class AvoidLongFilesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFiles();
    super.setUp();
  }

  Future<void> test_fileOverSixHundredLines_lint() async {
    final source = _fileWithLines(AvoidLongFiles.maxLines + 1);

    await assertDiagnostics(source, [lint(0, 'void'.length)]);
  }

  Future<void> test_fileAtSixHundredLines_noLint() async {
    await assertNoDiagnostics(_fileWithLines(AvoidLongFiles.maxLines));
  }
}

@reflectiveTest
final class AvoidLongFunctionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLongFunctions();
    super.setUp();
  }

  Future<void> test_functionOverEightyLines_lint() async {
    final body = _statements(AvoidLongFunctions.maxLines - 1);
    final source =
        '''
void process() {
$body
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('process'), 'process'.length)]);
  }

  Future<void> test_functionAtEightyLines_noLint() async {
    final body = _statements(AvoidLongFunctions.maxLines - 2);

    await assertNoDiagnostics('''
void process() {
$body
}
''');
  }

  Future<void> test_expressionBody_noLint() async {
    await assertNoDiagnostics(r'''
int process(int value) => value + 1;
''');
  }

  Future<void> test_longTestMain_noLint() async {
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

  Future<void> test_longTestGroupCallback_noLint() async {
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

  Future<void> test_longTestCallback_noLint() async {
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

  Future<void> test_longTestRegistrationHelper_noLint() async {
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

  Future<void> test_longTestHelperFunction_lint() async {
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
