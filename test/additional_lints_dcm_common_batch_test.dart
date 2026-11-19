import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_adjacent_strings.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_spread.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_ignore.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidAdjacentStringsTest>(
    'AvoidAdjacentStringsTest',
    _AvoidAdjacentStringsTest.new,
    _AvoidAdjacentStringsTest._allCases,
  );
  analysisRuleSuite<_AvoidEmptySpreadTest>(
    'AvoidEmptySpreadTest',
    _AvoidEmptySpreadTest.new,
    _AvoidEmptySpreadTest._allCases,
  );
  analysisRuleSuite<_AvoidFutureIgnoreTest>(
    'AvoidFutureIgnoreTest',
    _AvoidFutureIgnoreTest.new,
    _AvoidFutureIgnoreTest._allCases,
  );
  analysisRuleSuite<_AvoidLabelsTest>(
    'AvoidLabelsTest',
    _AvoidLabelsTest.new,
    _AvoidLabelsTest._allCases,
  );
  analysisRuleSuite<_AvoidLocalFunctionsTest>(
    'AvoidLocalFunctionsTest',
    _AvoidLocalFunctionsTest.new,
    _AvoidLocalFunctionsTest._allCases,
  );
}

final class _AvoidAdjacentStringsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidAdjacentStringsTest)> get _allCases =>
      caseSet<_AvoidAdjacentStringsTest>(
        parent: const {},
        own: {
          'test_adjacentStringLiteralsInList_lint': (t) => t._adjacentStringLiteralsInListLint(),
          'test_adjacentStringLiteralsInConditionalElement_lint': (t) =>
              t._adjacentStringLiteralsInConditionalElementLint(),
          'test_adjacentStringLiteralsInConditionExpression_noLint': (t) =>
              t._adjacentStringLiteralsInConditionExpressionNoLint(),
          'test_adjacentStringLiteralsInSet_lint': (t) => t._adjacentStringLiteralsInSetLint(),
          'test_adjacentStringLiteralsConcatenation_noLint': (t) =>
              t._adjacentStringLiteralsConcatenationNoLint(),
          'test_adjacentStringLiteralsArgument_noLint': (t) =>
              t._adjacentStringLiteralsArgumentNoLint(),
          'test_adjacentStringLiteralsMapValue_noLint': (t) =>
              t._adjacentStringLiteralsMapValueNoLint(),
          'test_singleStringLiteral_noLint': (t) => t._singleStringLiteralNoLint(),
          'test_generatedLocalizationAdjacentStrings_noLint': (t) =>
              t._generatedLocalizationAdjacentStringsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidAdjacentStrings();
    super.setUp();
  }

  Future<void> _adjacentStringLiteralsInListLint() async {
    const source = r'''
final items = <String>['first' 'second', 'third'];
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf("'first'"),
        "'first' 'second'".length,
        messageContainsAll: ['missing comma'],
      ),
    ]);
  }

  Future<void> _adjacentStringLiteralsInConditionalElementLint() async {
    const source = r'''
List<String> build(bool advanced) => ['basic', if (advanced) 'archived' 'active'];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'archived'"), "'archived' 'active'".length),
    ]);
  }

  Future<void> _adjacentStringLiteralsInConditionExpressionNoLint() async {
    await assertNoDiagnostics(r'''
List<int> build(String name) => [if (name == 'a' 'b') 1];
''');
  }

  Future<void> _adjacentStringLiteralsInSetLint() async {
    const source = r'''
final items = <String>{'first' 'second', 'third'};
''';

    await assertDiagnostics(source, [lint(source.indexOf("'first'"), "'first' 'second'".length)]);
  }

  Future<void> _adjacentStringLiteralsConcatenationNoLint() async {
    await assertNoDiagnostics(r'''
const message = 'hello ' 'world';
''');
  }

  Future<void> _adjacentStringLiteralsArgumentNoLint() async {
    await assertNoDiagnostics(r'''
void show(String text) {}

void run() {
  show('hello ' 'world');
}
''');
  }

  Future<void> _adjacentStringLiteralsMapValueNoLint() async {
    await assertNoDiagnostics(r'''
final labels = <String, String>{'greeting': 'hello ' 'world'};
''');
  }

  Future<void> _singleStringLiteralNoLint() async {
    await assertNoDiagnostics(r'''
const message = 'hello world';
''');
  }

  Future<void> _generatedLocalizationAdjacentStringsNoLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, "const message = 'hello ' 'world';");

    await assertNoDiagnosticsInFile(filePath);
  }
}

final class _AvoidEmptySpreadTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidEmptySpreadTest)> get _allCases =>
      caseSet<_AvoidEmptySpreadTest>(
        parent: const {},
        own: {
          'test_emptyListSpread_lint': (t) => t._emptyListSpreadLint(),
          'test_emptySetSpread_lint': (t) => t._emptySetSpreadLint(),
          'test_nonEmptySpread_noLint': (t) => t._nonEmptySpreadNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidEmptySpread();
    super.setUp();
  }

  Future<void> _emptyListSpreadLint() async {
    const source = r'''
const values = [1, ...[], 2];
''';

    await assertDiagnostics(source, [lint(source.indexOf('...[]'), '...[]'.length)]);
  }

  Future<void> _emptySetSpreadLint() async {
    const source = r'''
const values = {1, ...<int>{}, 2};
''';

    await assertDiagnostics(source, [lint(source.indexOf('...<int>{}'), '...<int>{}'.length)]);
  }

  Future<void> _nonEmptySpreadNoLint() async {
    await assertNoDiagnostics(r'''
const values = [1, ...[2], 3];
''');
  }
}

final class _AvoidFutureIgnoreTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidFutureIgnoreTest)> get _allCases =>
      caseSet<_AvoidFutureIgnoreTest>(
        parent: const {},
        own: {
          'test_futureIgnore_lint': (t) => t._futureIgnoreLint(),
          'test_nonFutureIgnore_noLint': (t) => t._nonFutureIgnoreNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidFutureIgnore();
    super.setUp();
  }

  Future<void> _futureIgnoreLint() async {
    const source = r'''
Future<void> load() async {}

extension IgnoreFuture on Future<void> {
  void ignore() {}
}

void f() {
  load().ignore();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('ignore'), 'ignore'.length)]);
  }

  Future<void> _nonFutureIgnoreNoLint() async {
    await assertNoDiagnostics(r'''
class Task {
  void ignore() {}
}

void f(Task task) {
  task.ignore();
}
''');
  }
}

final class _AvoidLabelsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLabelsTest)> get _allCases =>
      caseSet<_AvoidLabelsTest>(
        parent: const {},
        own: {
          'test_labeledStatement_lint': (t) => t._labeledStatementLint(),
          'test_unlabeledLoop_noLint': (t) => t._unlabeledLoopNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLabels();
    super.setUp();
  }

  Future<void> _labeledStatementLint() async {
    const source = r'''
void f() {
  outer:
  for (var i = 0; i < 3; i++) {
    if (i == 1) {
      break outer;
    }
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('outer:'), 'outer:'.length)]);
  }

  Future<void> _unlabeledLoopNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i = 0; i < 3; i++) {
    if (i == 1) {
      break;
    }
  }
}
''');
  }
}

final class _AvoidLocalFunctionsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidLocalFunctionsTest)> get _allCases =>
      caseSet<_AvoidLocalFunctionsTest>(
        parent: const {},
        own: {
          'test_localFunction_lint': (t) => t._localFunctionLint(),
          'test_topLevelFunction_noLint': (t) => t._topLevelFunctionNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLocalFunctions();
    super.setUp();
  }

  Future<void> _localFunctionLint() async {
    const source = r'''
void f() {
  int normalize(int value) => value.abs();
  print(normalize(-1));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('normalize'), 'normalize'.length)]);
  }

  Future<void> _topLevelFunctionNoLint() async {
    await assertNoDiagnostics(r'''
int normalize(int value) => value.abs();

void f() {
  print(normalize(-1));
}
''');
  }
}
