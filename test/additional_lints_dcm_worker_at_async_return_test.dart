import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_redundant_async.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_returning_void.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_futures.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidRedundantAsyncTest>(
    'AvoidRedundantAsyncTest',
    _AvoidRedundantAsyncTest.new,
    _AvoidRedundantAsyncTest._allCases,
  );
  analysisRuleSuite<_AvoidReturningVoidTest>(
    'AvoidReturningVoidTest',
    _AvoidReturningVoidTest.new,
    _AvoidReturningVoidTest._allCases,
  );
  analysisRuleSuite<_AvoidUnnecessaryFuturesTest>(
    'AvoidUnnecessaryFuturesTest',
    _AvoidUnnecessaryFuturesTest.new,
    _AvoidUnnecessaryFuturesTest._allCases,
  );
}

final class _AvoidRedundantAsyncTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidRedundantAsyncTest)> get _allCases =>
      caseSet<_AvoidRedundantAsyncTest>(
        parent: const {},
        own: {
          'test_expressionBodyReturnsFuture_lint': (t) => t._expressionBodyReturnsFutureLint(),
          'test_blockBodyOnlyReturnsFuture_lint': (t) => t._blockBodyOnlyReturnsFutureLint(),
          'test_awaitedFuture_noLint': (t) => t._awaitedFutureNoLint(),
          'test_extraStatement_noLint': (t) => t._extraStatementNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRedundantAsync();
    super.setUp();
  }

  Future<void> _expressionBodyReturnsFutureLint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() async => load();
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('start'), 'start'.length)]);
  }

  Future<void> _blockBodyOnlyReturnsFutureLint() async {
    const source = r'''
Future<int> load() async => 1;

Future<int> start() async {
  return load();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('start'), 'start'.length)]);
  }

  Future<void> _awaitedFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

Future<int> start() async {
  return await load();
}
''');
  }

  Future<void> _extraStatementNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() async => 1;

Future<int> start() async {
  final value = await load();
  return value;
}
''');
  }
}

final class _AvoidReturningVoidTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidReturningVoidTest)> get _allCases =>
      caseSet<_AvoidReturningVoidTest>(
        parent: const {},
        own: {
          'test_returnVoidExpression_lint': (t) => t._returnVoidExpressionLint(),
          'test_returnWithoutExpression_noLint': (t) => t._returnWithoutExpressionNoLint(),
          'test_returnValue_noLint': (t) => t._returnValueNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidReturningVoid();
    super.setUp();
  }

  Future<void> _returnVoidExpressionLint() async {
    const source = r'''
void logValue() {}

void start() {
  return logValue();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('logValue();'), 'logValue()'.length)]);
  }

  Future<void> _returnWithoutExpressionNoLint() async {
    await assertNoDiagnostics(r'''
void start() {
  return;
}
''');
  }

  Future<void> _returnValueNoLint() async {
    await assertNoDiagnostics(r'''
int value() => 1;

int start() {
  return value();
}
''');
  }
}

final class _AvoidUnnecessaryFuturesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryFuturesTest)> get _allCases =>
      caseSet<_AvoidUnnecessaryFuturesTest>(
        parent: const {},
        own: {
          'test_asyncReturnsImmediateValue_lint': (t) => t._asyncReturnsImmediateValueLint(),
          'test_blockReturnsImmediateValue_lint': (t) => t._blockReturnsImmediateValueLint(),
          'test_awaitedValue_noLint': (t) => t._awaitedValueNoLint(),
          'test_futureVoid_noLint': (t) => t._futureVoidNoLint(),
          'test_returnsExistingFuture_noLint': (t) => t._returnsExistingFutureNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnnecessaryFutures();
    super.setUp();
  }

  Future<void> _asyncReturnsImmediateValueLint() async {
    const source = r'''
Future<int> count() async => 1;
''';

    await assertDiagnostics(source, [lint(source.indexOf('Future<int>'), 'Future<int>'.length)]);
  }

  Future<void> _blockReturnsImmediateValueLint() async {
    const source = r'''
Future<String> label() async {
  return 'ready';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<String>'), 'Future<String>'.length),
    ]);
  }

  Future<void> _awaitedValueNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() => Future<int>.value(1);

Future<int> count() async {
  return await load();
}
''');
  }

  Future<void> _futureVoidNoLint() async {
    await assertNoDiagnostics(r'''
Future<void> save() async {}
''');
  }

  Future<void> _returnsExistingFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> load() => Future<int>.value(1);

Future<int> count() async => load();
''');
  }
}
