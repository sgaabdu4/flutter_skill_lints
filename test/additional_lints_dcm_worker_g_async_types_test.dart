import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_completer_stack_trace.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_futures.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_streams_and_futures.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidNestedFuturesTest>(
    'AvoidNestedFuturesTest',
    _AvoidNestedFuturesTest.new,
    _AvoidNestedFuturesTest._allCases,
  );
  analysisRuleSuite<_AvoidNestedStreamsAndFuturesTest>(
    'AvoidNestedStreamsAndFuturesTest',
    _AvoidNestedStreamsAndFuturesTest.new,
    _AvoidNestedStreamsAndFuturesTest._allCases,
  );
  analysisRuleSuite<_AvoidMissingCompleterStackTraceTest>(
    'AvoidMissingCompleterStackTraceTest',
    _AvoidMissingCompleterStackTraceTest.new,
    _AvoidMissingCompleterStackTraceTest._allCases,
  );
}

final class _AvoidNestedFuturesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNestedFuturesTest)> get _allCases =>
      caseSet<_AvoidNestedFuturesTest>(
        parent: const {},
        own: {
          'test_futureOfFuture_lint': (t) => t._futureOfFutureLint(),
          'test_userTypeNamedFuture_noLint': (t) => t._userTypeNamedFutureNoLint(),
          'test_valueFuture_noLint': (t) => t._valueFutureNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNestedFutures();
    super.setUp();
  }

  Future<void> _futureOfFutureLint() async {
    const source = r'''
Future<Future<int>> loadValue() async => Future<int>.value(1);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<Future<int>>'), 'Future<Future<int>>'.length),
    ]);
  }

  Future<void> _userTypeNamedFutureNoLint() async {
    await assertNoDiagnostics(r'''
class Future<T> {
  const Future();
}

Future<Future<int>> loadValue() => const Future<Future<int>>();
''');
  }

  Future<void> _valueFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;
''');
  }
}

final class _AvoidNestedStreamsAndFuturesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNestedStreamsAndFuturesTest)> get _allCases =>
      caseSet<_AvoidNestedStreamsAndFuturesTest>(
        parent: const {},
        own: {
          'test_futureOfStream_lint': (t) => t._futureOfStreamLint(),
          'test_streamOfFuture_lint': (t) => t._streamOfFutureLint(),
          'test_streamOfStream_lint': (t) => t._streamOfStreamLint(),
          'test_futureOfFuture_noLint': (t) => t._futureOfFutureNoLint(),
          'test_flatAsyncTypes_noLint': (t) => t._flatAsyncTypesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNestedStreamsAndFutures();
    super.setUp();
  }

  Future<void> _futureOfStreamLint() async {
    const source = r'''
Future<Stream<int>> loadValues() async => Stream<int>.fromIterable(const <int>[]);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<Stream<int>>'), 'Future<Stream<int>>'.length),
    ]);
  }

  Future<void> _streamOfFutureLint() async {
    const source = r'''
Stream<Future<int>> loadValues() async* {
  yield Future<int>.value(1);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Stream<Future<int>>'), 'Stream<Future<int>>'.length),
    ]);
  }

  Future<void> _streamOfStreamLint() async {
    const source = r'''
Stream<Stream<int>> loadValues() async* {
  yield Stream<int>.fromIterable(const <int>[]);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Stream<Stream<int>>'), 'Stream<Stream<int>>'.length),
    ]);
  }

  Future<void> _futureOfFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<Future<int>> loadValue() async => Future<int>.value(1);
''');
  }

  Future<void> _flatAsyncTypesNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;

Stream<int> loadValues() async* {
  yield 1;
}
''');
  }
}

final class _AvoidMissingCompleterStackTraceTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMissingCompleterStackTraceTest)> get _allCases =>
      caseSet<_AvoidMissingCompleterStackTraceTest>(
        parent: const {},
        own: {
          'test_completeErrorWithoutStackTrace_lint': (t) =>
              t._completeErrorWithoutStackTraceLint(),
          'test_cascadeCompleteErrorWithoutStackTrace_lint': (t) =>
              t._cascadeCompleteErrorWithoutStackTraceLint(),
          'test_completeErrorWithStackTrace_noLint': (t) => t._completeErrorWithStackTraceNoLint(),
          'test_unrelatedCompleteError_noLint': (t) => t._unrelatedCompleteErrorNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMissingCompleterStackTrace();
    super.setUp();
  }

  Future<void> _completeErrorWithoutStackTraceLint() async {
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

  Future<void> _cascadeCompleteErrorWithoutStackTraceLint() async {
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

  Future<void> _completeErrorWithStackTraceNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void fail(Object error, StackTrace stackTrace) {
  final completer = Completer<void>();
  completer.completeError(error, stackTrace);
}
''');
  }

  Future<void> _unrelatedCompleteErrorNoLint() async {
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
