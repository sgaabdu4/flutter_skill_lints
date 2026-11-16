import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_ignore.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_futures.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidFutureIgnoreTest>('AvoidFutureIgnoreTest', AvoidFutureIgnoreTest.new, {
    'test_futureIgnore_lint': (t) => t._futureIgnoreLint(),
    'test_nonFutureIgnore_noLint': (t) => t._nonFutureIgnoreNoLint(),
    'test_unawaitedFuture_noLint': (t) => t._unawaitedFutureNoLint(),
  });
  analysisRuleSuite<AvoidFutureToStringTest>(
    'AvoidFutureToStringTest',
    AvoidFutureToStringTest.new,
    {
      'test_futureToString_lint': (t) => t._futureToStringLint(),
      'test_futureInterpolation_lint': (t) => t._futureInterpolationLint(),
      'test_nonFutureToString_noLint': (t) => t._nonFutureToStringNoLint(),
      'test_nonFutureInterpolation_noLint': (t) => t._nonFutureInterpolationNoLint(),
    },
  );
  analysisRuleSuite<AvoidNestedFuturesTest>('AvoidNestedFuturesTest', AvoidNestedFuturesTest.new, {
    'test_futureOfFuture_lint': (t) => t._futureOfFutureLint(),
    'test_nestedFutureInGeneric_lint': (t) => t._nestedFutureInGenericLint(),
    'test_userTypeNamedFuture_noLint': (t) => t._userTypeNamedFutureNoLint(),
    'test_flatFuture_noLint': (t) => t._flatFutureNoLint(),
  });
}

final class AvoidFutureIgnoreTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureIgnore();
    super.setUp();
  }

  Future<void> _futureIgnoreLint() async {
    const source = r'''
Future<void> save() async {}

extension FutureIgnore on Future<void> {
  void ignore() {}
}

void f() {
  save().ignore();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('ignore'), 'ignore'.length)]);
  }

  Future<void> _nonFutureIgnoreNoLint() async {
    await assertNoDiagnostics(r'''
class Ignorable {
  void ignore() {}
}

void f(Ignorable value) {
  value.ignore();
}
''');
  }

  Future<void> _unawaitedFutureNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void f() {
  unawaited(save());
}
''');
  }
}

final class AvoidFutureToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureToString();
    super.setUp();
  }

  Future<void> _futureToStringLint() async {
    const source = r'''
Future<int> load() async => 1;

String f() => load().toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _futureInterpolationLint() async {
    const source = r'''
Future<int> load() async => 1;

String f() => '${load()}';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('load()'), 'load()'.length)]);
  }

  Future<void> _nonFutureToStringNoLint() async {
    await assertNoDiagnostics(r'''
String f(Object value) => value.toString();
''');
  }

  Future<void> _nonFutureInterpolationNoLint() async {
    await assertNoDiagnostics(r'''
String f(int value) => '$value';
''');
  }
}

final class AvoidNestedFuturesTest extends AnalysisRuleTest {
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

  Future<void> _nestedFutureInGenericLint() async {
    const source = r'''
Future<List<Future<int>>> loadValues() async => <Future<int>>[];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<List<Future<int>>>'), 'Future<List<Future<int>>>'.length),
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

  Future<void> _flatFutureNoLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;
''');
  }
}
