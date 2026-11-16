import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_test_matchers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_expect_later.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidMisusedTestMatchersTest>(
    'AvoidMisusedTestMatchersTest',
    _AvoidMisusedTestMatchersTest.new,
    {
      'reportsNullMatcherOnNonNullableValue': (t) => t._reportsNullMatcherOnNonNullableValue(),
      'reportsEmptinessMatcherOnNumber': (t) => t._reportsEmptinessMatcherOnNumber(),
      'reportsListMatcherOnString': (t) => t._reportsListMatcherOnString(),
      'reportsMapMatcherOnList': (t) => t._reportsMapMatcherOnList(),
      'reportsLengthMatcherOnNumber': (t) => t._reportsLengthMatcherOnNumber(),
      'reportsNumericMatcherOnString': (t) => t._reportsNumericMatcherOnString(),
      'reportsBooleanMatcherOnNumber': (t) => t._reportsBooleanMatcherOnNumber(),
      'acceptsMatchingTypes': (t) => t._acceptsMatchingTypes(),
      'acceptsDynamicAndUnknownMatchers': (t) => t._acceptsDynamicAndUnknownMatchers(),
    },
  );
  analysisRuleSuite<_PreferExpectLaterTest>('PreferExpectLaterTest', _PreferExpectLaterTest.new, {
    'reportsFutureValue': (t) => t._reportsFutureValue(),
    'reportsFutureOrValue': (t) => t._reportsFutureOrValue(),
    'reportsFutureSubtype': (t) => t._reportsFutureSubtype(),
    'acceptsNonFutureValues': (t) => t._acceptsNonFutureValues(),
    'acceptsLocalFutureLookalike': (t) => t._acceptsLocalFutureLookalike(),
  });
}

const _matcherStubs = '''
void expect(Object? actual, Object? matcher) {}
const isNull = Object();
const isEmpty = Object();
const isList = Object();
const isMap = Object();
const isZero = Object();
const isTrue = Object();
Object hasLength(int count) => Object();
Object equals(Object? value) => Object();
''';

final class _AvoidMisusedTestMatchersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedTestMatchers();
    super.setUp();
  }

  Future<void> _expectReported(String actual, String matcher) async {
    final source =
        '$_matcherStubs\nvoid f(int number, String text, int? maybe) {\n'
        '  expect($actual, $matcher);\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf('$matcher);'), matcher.length)]);
  }

  Future<void> _reportsNullMatcherOnNonNullableValue() => _expectReported('number', 'isNull');

  Future<void> _reportsEmptinessMatcherOnNumber() => _expectReported('number', 'isEmpty');

  Future<void> _reportsListMatcherOnString() => _expectReported('text', 'isList');

  Future<void> _reportsMapMatcherOnList() => _expectReported('[1]', 'isMap');

  Future<void> _reportsLengthMatcherOnNumber() => _expectReported('number', 'hasLength(1)');

  Future<void> _reportsNumericMatcherOnString() => _expectReported('text', 'isZero');

  Future<void> _reportsBooleanMatcherOnNumber() => _expectReported('number', 'isTrue');

  Future<void> _acceptsMatchingTypes() => assertNoDiagnostics('''
$_matcherStubs
void f(int? maybe, int number, String text) {
  expect(maybe, isNull);
  expect([1], isEmpty);
  expect(text, isEmpty);
  expect([1], isList);
  expect({1: 2}, isMap);
  expect([1], hasLength(1));
  expect(number, isZero);
  expect(true, isTrue);
}
''');

  Future<void> _acceptsDynamicAndUnknownMatchers() => assertNoDiagnostics('''
$_matcherStubs
void f(dynamic anything, int number) {
  expect(anything, isNull);
  expect(number, equals(1));
  expect(number, 1);
}
''');
}

final class _PreferExpectLaterTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferExpectLater();
    super.setUp();
  }

  static const _expectStub = 'void expect(Object? actual, Object? matcher) {}\n';

  Future<void> _expectReported(String parameter) async {
    final source =
        "import 'dart:async';\n$_expectStub\nabstract class Slow implements Future<int> {}\n"
        'void f($parameter) {\n  expect(value, 1);\n}\n';
    await assertDiagnostics(source, [lint(source.indexOf('expect(value'), 'expect'.length)]);
  }

  Future<void> _reportsFutureValue() => _expectReported('Future<int> value');

  Future<void> _reportsFutureOrValue() => _expectReported('FutureOr<int> value');

  Future<void> _reportsFutureSubtype() => _expectReported('Slow value');

  Future<void> _acceptsNonFutureValues() => assertNoDiagnostics('''
$_expectStub
void f(int number, dynamic anything, Stream<int> stream) {
  expect(number, 1);
  expect(anything, 1);
  expect(stream, 1);
}
''');

  Future<void> _acceptsLocalFutureLookalike() => assertNoDiagnostics('''
$_expectStub
class Future {}

void f(Future value) {
  expect(value, 1);
}
''');
}
