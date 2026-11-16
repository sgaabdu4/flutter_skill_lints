import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_identical_exception_handling_blocks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_try_statements.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_only_rethrow.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidNestedTryStatementsTest>(
    'AvoidNestedTryStatementsTest',
    _AvoidNestedTryStatementsTest.new,
    _AvoidNestedTryStatementsTest._allCases,
  );
  analysisRuleSuite<_AvoidIdenticalExceptionHandlingBlocksTest>(
    'AvoidIdenticalExceptionHandlingBlocksTest',
    _AvoidIdenticalExceptionHandlingBlocksTest.new,
    _AvoidIdenticalExceptionHandlingBlocksTest._allCases,
  );
  analysisRuleSuite<_AvoidOnlyRethrowTest>(
    'AvoidOnlyRethrowTest',
    _AvoidOnlyRethrowTest.new,
    _AvoidOnlyRethrowTest._allCases,
  );
}

final class _AvoidNestedTryStatementsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNestedTryStatementsTest)> get _allCases =>
      caseSet<_AvoidNestedTryStatementsTest>(
        parent: const {},
        own: {
          'test_tryInsideTryBody_lint': (t) => t._tryInsideTryBodyLint(),
          'test_tryInsideCatch_lint': (t) => t._tryInsideCatchLint(),
          'test_tryInsideLocalFunction_noLint': (t) => t._tryInsideLocalFunctionNoLint(),
          'test_sequentialTryStatements_noLint': (t) => t._sequentialTryStatementsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNestedTryStatements();
    super.setUp();
  }

  Future<void> _tryInsideTryBodyLint() async {
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

  Future<void> _tryInsideCatchLint() async {
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

  Future<void> _tryInsideLocalFunctionNoLint() async {
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

  Future<void> _sequentialTryStatementsNoLint() async {
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

final class _AvoidIdenticalExceptionHandlingBlocksTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidIdenticalExceptionHandlingBlocksTest)>
  get _allCases => caseSet<_AvoidIdenticalExceptionHandlingBlocksTest>(
    parent: const {},
    own: {
      'test_identicalCatchBodies_lintSecondBody': (t) => t._identicalCatchBodiesLintSecondBody(),
      'test_identicalCatchBodiesWithDifferentWhitespace_lintSecondBody': (t) =>
          t._identicalCatchBodiesWithDifferentWhitespaceLintSecondBody(),
      'test_differentCatchBodies_noLint': (t) => t._differentCatchBodiesNoLint(),
      'test_emptyCatchBodies_noLint': (t) => t._emptyCatchBodiesNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidIdenticalExceptionHandlingBlocks();
    super.setUp();
  }

  Future<void> _identicalCatchBodiesLintSecondBody() async {
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

  Future<void> _identicalCatchBodiesWithDifferentWhitespaceLintSecondBody() async {
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

  Future<void> _differentCatchBodiesNoLint() async {
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

  Future<void> _emptyCatchBodiesNoLint() async {
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

final class _AvoidOnlyRethrowTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidOnlyRethrowTest)> get _allCases =>
      caseSet<_AvoidOnlyRethrowTest>(
        parent: const {},
        own: {
          'test_trailingRethrowOnlyCatch_lint': (t) => t._trailingRethrowOnlyCatchLint(),
          'test_rethrowOnlyCatchBeforeFinally_lint': (t) => t._rethrowOnlyCatchBeforeFinallyLint(),
          'test_skillDataLayerCatches_noLint': (t) => t._skillDataLayerCatchesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidOnlyRethrow();
    super.setUp();
  }

  Future<void> _trailingRethrowOnlyCatchLint() async {
    const source = r'''
Future<void> load() async {
  try {
    await Future<void>.value();
  } catch (_) {
    rethrow;
  }
}
''';
    const clause = 'catch (_) {\n    rethrow;\n  }';
    await assertDiagnostics(source, [lint(source.indexOf(clause), clause.length)]);
  }

  Future<void> _rethrowOnlyCatchBeforeFinallyLint() async {
    const source = r'''
Future<void> load() async {
  try {
    await Future<void>.value();
  } on Exception {
    rethrow;
  } finally {
    await Future<void>.value();
  }
}
''';
    const clause = 'on Exception {\n    rethrow;\n  }';
    await assertDiagnostics(source, [lint(source.indexOf(clause), clause.length)]);
  }

  /// Datasource catches the skill allows (networking.md:30-43, hive-persistence.md:72, state-management-lifecycle.md:69-72). An earlier rethrow-only clause keeps its error type out of a later catch.
  Future<void> _skillDataLayerCatchesNoLint() async {
    await assertNoDiagnostics(r'''
class AppException implements Exception {
  const AppException(this.code);
  final String code;
}

class UserDatasource {
  Future<Object?> fetch() async {
    try {
      return await Future<Object?>.value();
    } on Exception {
      throw const AppException('network');
    }
  }

  Future<void> remove(String id) async {
    try {
      await Future<void>.value();
    } catch (_) {
      await restore(id);
      rethrow;
    }
  }

  Future<Object?> readOrNull() async {
    try {
      return await Future<Object?>.value();
    } on FormatException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> restore(String id) async {}
}
''');
  }
}
