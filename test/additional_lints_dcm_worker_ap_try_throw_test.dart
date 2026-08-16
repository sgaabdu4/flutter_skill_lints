// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_identical_exception_handling_blocks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_try_statements.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedTryStatementsTest);
    defineReflectiveTests(AvoidIdenticalExceptionHandlingBlocksTest);
    defineReflectiveTests(AvoidThrowTest);
  });
}

@reflectiveTest
final class AvoidNestedTryStatementsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedTryStatements();
    super.setUp();
  }

  Future<void> test_tryInsideTryBody_lint() async {
    const source = r'''
void f() {
  try {
    try {
      print('inner');
    } catch (_) {
      print('inner failed');
    }
  } catch (_) {
    print('outer failed');
  }
}
''';

    final offset = source.indexOf('try {', source.indexOf('try {') + 1);
    final end = source.indexOf('\n  } catch (_) {\n    print(\'outer failed\');');

    await assertDiagnostics(source, [lint(offset, end - offset)]);
  }

  Future<void> test_tryInsideCatch_lint() async {
    const source = r'''
void f() {
  try {
    print('work');
  } catch (_) {
    try {
      print('recover');
    } catch (_) {}
  }
}
''';

    final offset = source.indexOf('try {', source.indexOf('catch (_)'));
    final end = source.indexOf('\n  }\n}', offset);

    await assertDiagnostics(source, [lint(offset, end - offset)]);
  }

  Future<void> test_tryInsideLocalFunction_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    void recover() {
      try {
        print('recover');
      } catch (_) {}
    }

    recover();
  } catch (_) {}
}
''');
  }

  Future<void> test_sequentialTryStatements_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('first');
  } catch (_) {}

  try {
    print('second');
  } catch (_) {}
}
''');
  }
}

@reflectiveTest
final class AvoidIdenticalExceptionHandlingBlocksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidIdenticalExceptionHandlingBlocks();
    super.setUp();
  }

  Future<void> test_identicalCatchBodies_lintSecondBody() async {
    const source = r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print('failed');
  } on StateFailure {
    print('failed');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{', source.indexOf('on StateFailure')),
        source.indexOf('}', source.indexOf('on StateFailure')) -
            source.indexOf('{', source.indexOf('on StateFailure')) +
            1,
      ),
    ]);
  }

  Future<void> test_identicalCatchBodiesWithDifferentWhitespace_lintSecondBody() async {
    const source = r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print(
      'failed',
    );
  } on StateFailure {
    print('failed');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('{', source.indexOf('on StateFailure')),
        source.indexOf('}', source.indexOf('on StateFailure')) -
            source.indexOf('{', source.indexOf('on StateFailure')) +
            1,
      ),
    ]);
  }

  Future<void> test_differentCatchBodies_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
    print('format');
  } on StateFailure {
    print('state');
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''');
  }

  Future<void> test_emptyCatchBodies_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } on FormatFailure {
  } on StateFailure {
  }
}

class FormatFailure implements Exception {}

class StateFailure implements Exception {}
''');
  }
}

@reflectiveTest
final class AvoidThrowTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThrow();
    super.setUp();
  }

  Future<void> test_throwStatement_lint() async {
    const source = r'''
void f() {
  throw 'failed';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('throw'), "throw 'failed'".length)]);
  }

  Future<void> test_throwExpressionBody_lint() async {
    const source = r'''
Never f() => throw 'failed';
''';

    await assertDiagnostics(source, [lint(source.indexOf('throw'), "throw 'failed'".length)]);
  }

  Future<void> test_rethrow_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
    print('work');
  } catch (_) {
    rethrow;
  }
}
''');
  }

  Future<void> test_generatedLocalizationThrow_noLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, "Never lookup() => throw 'missing';");

    await assertNoDiagnosticsInFile(filePath);
  }
}
