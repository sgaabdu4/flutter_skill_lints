// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_async.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_returning_void.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_futures.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRedundantAsyncTest);
    defineReflectiveTests(AvoidReturningVoidTest);
    defineReflectiveTests(AvoidUnnecessaryFuturesTest);
  });
}

@reflectiveTest
final class AvoidRedundantAsyncTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRedundantAsync();
    super.setUp();
  }

  Future<void> test_expressionBodyReturnsFuture_lint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() async => load();
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('start'), 'start'.length)]);
  }

  Future<void> test_blockBodyOnlyReturnsFuture_lint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() async {
  return load();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('start'), 'start'.length)]);
  }

  Future<void> test_awaitedFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

Future<int> start() async {
  return await load();
}
''');
  }

  Future<void> test_extraStatement_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

Future<int> start() async {
  final value = await load();
  return value;
}
''');
  }
}

@reflectiveTest
final class AvoidReturningVoidTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidReturningVoid();
    super.setUp();
  }

  Future<void> test_returnVoidExpression_lint() async {
    const source = r'''
void logValue() {}

void start() {
  return logValue();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('logValue();'), 'logValue()'.length)]);
  }

  Future<void> test_returnWithoutExpression_noLint() async {
    await assertNoDiagnostics(r'''
void start() {
  return;
}
''');
  }

  Future<void> test_returnValue_noLint() async {
    await assertNoDiagnostics(r'''
int value() => 1;

int start() {
  return value();
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryFuturesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryFutures();
    super.setUp();
  }

  Future<void> test_asyncReturnsImmediateValue_lint() async {
    const source = r'''
Future<int> count() async => 1;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Future<int>'), 'Future<int>'.length)]);
  }

  Future<void> test_blockReturnsImmediateValue_lint() async {
    const source = r'''
Future<String> label() async {
  return 'ready';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<String>'), 'Future<String>'.length),
    ]);
  }

  Future<void> test_awaitedValue_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() => Future<int>.value(1);

Future<int> count() async {
  return await load();
}
''');
  }

  Future<void> test_futureVoid_noLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}
''');
  }

  Future<void> test_returnsExistingFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() => Future<int>.value(1);

Future<int> count() async => load();
''');
  }
}
