// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_ignore.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_future_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nested_futures.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFutureIgnoreTest);
    defineReflectiveTests(AvoidFutureToStringTest);
    defineReflectiveTests(AvoidNestedFuturesTest);
  });
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

  Future<void> test_nonFutureIgnore_noLint() async {
    await assertNoDiagnostics(r'''
class Ignorable {
  void ignore() {}
}

void f(Ignorable value) {
  value.ignore();
}
''');
  }

  Future<void> test_unawaitedFuture_noLint() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

Future<void> save() async {}

void f() {
  unawaited(save());
}
''');
  }
}

@reflectiveTest
final class AvoidFutureToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFutureToString();
    super.setUp();
  }

  Future<void> test_futureToString_lint() async {
    const source = r'''
Future<int> load() async => 1;

String f() => load().toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_futureInterpolation_lint() async {
    const source = r'''
Future<int> load() async => 1;

String f() => '${load()}';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('load()'), 'load()'.length)]);
  }

  Future<void> test_nonFutureToString_noLint() async {
    await assertNoDiagnostics(r'''
String f(Object value) => value.toString();
''');
  }

  Future<void> test_nonFutureInterpolation_noLint() async {
    await assertNoDiagnostics(r'''
String f(int value) => '$value';
''');
  }
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

  Future<void> test_nestedFutureInGeneric_lint() async {
    const source = r'''
Future<List<Future<int>>> loadValues() async => <Future<int>>[];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<List<Future<int>>>'), 'Future<List<Future<int>>>'.length),
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

  Future<void> test_flatFuture_noLint() async {
    await assertNoDiagnostics(r'''
Future<int> loadValue() async => 1;
''');
  }
}
