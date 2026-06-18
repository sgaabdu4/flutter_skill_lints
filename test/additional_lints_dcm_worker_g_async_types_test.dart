// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_completer_stack_trace.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_futures.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_streams_and_futures.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNestedFuturesTest);
    defineReflectiveTests(AvoidNestedStreamsAndFuturesTest);
    defineReflectiveTests(AvoidMissingCompleterStackTraceTest);
  });
}

@reflectiveTest
final class AvoidNestedFuturesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedFutures();
    super.setUp();
  }

  Future<void> test_futureOfFuture_lint() async {
    const source = r'''
Future<Future<int>> loadValue() async => Future<int>.value(1);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<Future<int>>'), 'Future<Future<int>>'.length),
    ]);
  }

  Future<void> test_userTypeNamedFuture_noLint() async {
    await assertNoDiagnostics(r'''
class Future<T> {
  const Future();
}

Future<Future<int>> loadValue() => const Future<Future<int>>();
''');
  }

  Future<void> test_valueFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;
''');
  }
}

@reflectiveTest
final class AvoidNestedStreamsAndFuturesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNestedStreamsAndFutures();
    super.setUp();
  }

  Future<void> test_futureOfStream_lint() async {
    const source = r'''
Future<Stream<int>> loadValues() async => Stream<int>.fromIterable(const <int>[]);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<Stream<int>>'), 'Future<Stream<int>>'.length),
    ]);
  }

  Future<void> test_streamOfFuture_lint() async {
    const source = r'''
Stream<Future<int>> loadValues() async* {
  yield Future<int>.value(1);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Stream<Future<int>>'), 'Stream<Future<int>>'.length),
    ]);
  }

  Future<void> test_streamOfStream_lint() async {
    const source = r'''
Stream<Stream<int>> loadValues() async* {
  yield Stream<int>.fromIterable(const <int>[]);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Stream<Stream<int>>'), 'Stream<Stream<int>>'.length),
    ]);
  }

  Future<void> test_futureOfFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<Future<int>> loadValue() async => Future<int>.value(1);
''');
  }

  Future<void> test_flatAsyncTypes_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;

Stream<int> loadValues() async* {
  yield 1;
}
''');
  }
}

@reflectiveTest
final class AvoidMissingCompleterStackTraceTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingCompleterStackTrace();
    super.setUp();
  }

  Future<void> test_completeErrorWithoutStackTrace_lint() async {
    const source = r'''
import 'dart:async';

void fail(Object error) {
  final completer = Completer<void>();
  completer.completeError(error);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('completeError'), 'completeError'.length),
    ]);
  }

  Future<void> test_cascadeCompleteErrorWithoutStackTrace_lint() async {
    const source = r'''
import 'dart:async';

void fail(Object error) {
  Completer<void>()..completeError(error);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('completeError'), 'completeError'.length),
    ]);
  }

  Future<void> test_completeErrorWithStackTrace_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void fail(Object error, StackTrace stackTrace) {
  final completer = Completer<void>();
  completer.completeError(error, stackTrace);
}
''');
  }

  Future<void> test_unrelatedCompleteError_noLint() async {
    await assertNoDiagnostics(r'''
class Reporter {
  void completeError(Object error) {}
}

void fail(Object error) {
  Reporter().completeError(error);
}
''');
  }
}
