// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_adjacent_strings.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_spread.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_ignore.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_labels.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_local_functions.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAdjacentStringsTest);
    defineReflectiveTests(AvoidEmptySpreadTest);
    defineReflectiveTests(AvoidFutureIgnoreTest);
    defineReflectiveTests(AvoidLabelsTest);
    defineReflectiveTests(AvoidLocalFunctionsTest);
  });
}

@reflectiveTest
final class AvoidAdjacentStringsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAdjacentStrings();
    super.setUp();
  }

  Future<void> test_adjacentStringLiterals_lint() async {
    const source = r'''
const message = 'hello ' 'world';
''';

    await assertDiagnostics(source, [lint(source.indexOf("'hello '"), "'hello ' 'world'".length)]);
  }

  Future<void> test_singleStringLiteral_noLint() async {
    await assertNoDiagnostics(r'''
const message = 'hello world';
''');
  }

  Future<void> test_generatedLocalizationAdjacentStrings_noLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, "const message = 'hello ' 'world';");

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class AvoidEmptySpreadTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptySpread();
    super.setUp();
  }

  Future<void> test_emptyListSpread_lint() async {
    const source = r'''
const values = [1, ...[], 2];
''';

    await assertDiagnostics(source, [lint(source.indexOf('...[]'), '...[]'.length)]);
  }

  Future<void> test_emptySetSpread_lint() async {
    const source = r'''
const values = {1, ...<int>{}, 2};
''';

    await assertDiagnostics(source, [lint(source.indexOf('...<int>{}'), '...<int>{}'.length)]);
  }

  Future<void> test_nonEmptySpread_noLint() async {
    await assertNoDiagnostics(r'''
const values = [1, ...[2], 3];
''');
  }
}

@reflectiveTest
final class AvoidFutureIgnoreTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureIgnore();
    super.setUp();
  }

  Future<void> test_futureIgnore_lint() async {
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

  Future<void> test_nonFutureIgnore_noLint() async {
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

@reflectiveTest
final class AvoidLabelsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLabels();
    super.setUp();
  }

  Future<void> test_labeledStatement_lint() async {
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

  Future<void> test_unlabeledLoop_noLint() async {
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

@reflectiveTest
final class AvoidLocalFunctionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLocalFunctions();
    super.setUp();
  }

  Future<void> test_localFunction_lint() async {
    const source = r'''
void f() {
  int normalize(int value) => value.abs();
  print(normalize(-1));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('normalize'), 'normalize'.length)]);
  }

  Future<void> test_topLevelFunction_noLint() async {
    await assertNoDiagnostics(r'''
int normalize(int value) => value.abs();

void f() {
  print(normalize(-1));
}
''');
  }
}
