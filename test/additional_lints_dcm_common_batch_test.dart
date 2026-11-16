import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_adjacent_strings.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_spread.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_ignore.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAdjacentStringsTest>(
    'AvoidAdjacentStringsTest',
    AvoidAdjacentStringsTest.new,
    {
      'test_adjacentStringLiterals_lint': (t) => t._adjacentStringLiteralsLint(),
      'test_singleStringLiteral_noLint': (t) => t._singleStringLiteralNoLint(),
      'test_generatedLocalizationAdjacentStrings_noLint': (t) =>
          t._generatedLocalizationAdjacentStringsNoLint(),
    },
  );
  analysisRuleSuite<AvoidEmptySpreadTest>('AvoidEmptySpreadTest', AvoidEmptySpreadTest.new, {
    'test_emptyListSpread_lint': (t) => t._emptyListSpreadLint(),
    'test_emptySetSpread_lint': (t) => t._emptySetSpreadLint(),
    'test_nonEmptySpread_noLint': (t) => t._nonEmptySpreadNoLint(),
  });
  analysisRuleSuite<AvoidFutureIgnoreTest>('AvoidFutureIgnoreTest', AvoidFutureIgnoreTest.new, {
    'test_futureIgnore_lint': (t) => t._futureIgnoreLint(),
    'test_nonFutureIgnore_noLint': (t) => t._nonFutureIgnoreNoLint(),
  });
  analysisRuleSuite<AvoidLabelsTest>('AvoidLabelsTest', AvoidLabelsTest.new, {
    'test_labeledStatement_lint': (t) => t._labeledStatementLint(),
    'test_unlabeledLoop_noLint': (t) => t._unlabeledLoopNoLint(),
  });
  analysisRuleSuite<AvoidLocalFunctionsTest>(
    'AvoidLocalFunctionsTest',
    AvoidLocalFunctionsTest.new,
    {
      'test_localFunction_lint': (t) => t._localFunctionLint(),
      'test_topLevelFunction_noLint': (t) => t._topLevelFunctionNoLint(),
    },
  );
}

final class AvoidAdjacentStringsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAdjacentStrings();
    super.setUp();
  }

  Future<void> _adjacentStringLiteralsLint() async {
    const source = r'''
const message = 'hello ' 'world';
''';

    await assertDiagnostics(source, [lint(source.indexOf("'hello '"), "'hello ' 'world'".length)]);
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

final class AvoidEmptySpreadTest extends AnalysisRuleTest {
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

final class AvoidFutureIgnoreTest extends AnalysisRuleTest {
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

final class AvoidLabelsTest extends AnalysisRuleTest {
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

final class AvoidLocalFunctionsTest extends AnalysisRuleTest {
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
