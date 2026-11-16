import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_async_callback_in_fake_async.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_any_matcher.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_then_answer.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidAsyncCallbackInFakeAsyncTest>(
    'AvoidAsyncCallbackInFakeAsyncTest',
    _AvoidAsyncCallbackInFakeAsyncTest.new,
    _AvoidAsyncCallbackInFakeAsyncTest._allCases,
  );
  analysisRuleSuite<_UseThenAnswerTest>(
    'UseThenAnswerTest',
    _UseThenAnswerTest.new,
    _UseThenAnswerTest._allCases,
  );
  analysisRuleSuite<_PreferCorrectAnyMatcherTest>(
    'PreferCorrectAnyMatcherTest',
    _PreferCorrectAnyMatcherTest.new,
    _PreferCorrectAnyMatcherTest._allCases,
  );
}

final class _AvoidAsyncCallbackInFakeAsyncTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidAsyncCallbackInFakeAsyncTest)> get _allCases =>
      caseSet<_AvoidAsyncCallbackInFakeAsyncTest>(
        parent: const {},
        own: {
          'test_fakeAsyncAsyncCallback_lint': (t) => t._fakeAsyncAsyncCallbackLint(),
          'test_fakeAsyncRunAsyncCallback_lint': (t) => t._fakeAsyncRunAsyncCallbackLint(),
          'test_fakeAsyncSyncCallback_noLint': (t) => t._fakeAsyncSyncCallbackNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidAsyncCallbackInFakeAsync();
    super.setUp();
  }

  Future<void> _fakeAsyncAsyncCallbackLint() async {
    const source = r'''
void fakeAsync(void Function(Object async) callback) {}

void test() {
  fakeAsync((async) async {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(async) async'), '(async) async {}'.length),
    ]);
  }

  Future<void> _fakeAsyncRunAsyncCallbackLint() async {
    const source = r'''
class FakeAsync {
  static void run(void Function(Object async) callback) {}
}

void test() {
  FakeAsync.run((async) async {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(async) async'), '(async) async {}'.length),
    ]);
  }

  Future<void> _fakeAsyncSyncCallbackNoLint() async {
    await assertNoDiagnostics(r'''
void fakeAsync(void Function(Object async) callback) {}

void test() {
  fakeAsync((async) {
    async.toString();
  });
}
''');
  }
}

final class _UseThenAnswerTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_UseThenAnswerTest)> get _allCases =>
      caseSet<_UseThenAnswerTest>(
        parent: const {},
        own: {
          'test_futureValue_lint': (t) => t._futureValueLint(),
          'test_streamValue_lint': (t) => t._streamValueLint(),
          'test_plainValue_noLint': (t) => t._plainValueNoLint(),
        },
      );

  @override
  void setUp() {
    rule = UseThenAnswer();
    super.setUp();
  }

  Future<void> _futureValueLint() async {
    const source = r'''
class Stub {
  void thenReturn(Object? value) {}
}

Stub when(Object? call) => Stub();
Future<int> load() async => 1;

void test() {
  when(load()).thenReturn(Future<int>.value(1));
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('thenReturn'), 'thenReturn'.length)]);
  }

  Future<void> _streamValueLint() async {
    const source = r'''
class Stub {
  void thenReturn(Object? value) {}
}

Stub when(Object? call) => Stub();
Stream<int> watch() => Stream<int>.value(1);

void test() {
  when(watch()).thenReturn(Stream<int>.value(1));
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('thenReturn'), 'thenReturn'.length)]);
  }

  Future<void> _plainValueNoLint() async {
    await assertNoDiagnostics(r'''
class Stub {
  void thenReturn(Object? value) {}
}

Stub when(Object? call) => Stub();
int count() => 1;

void test() {
  when(count()).thenReturn(1);
}
''');
  }
}

final class _PreferCorrectAnyMatcherTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferCorrectAnyMatcherTest)> get _allCases =>
      caseSet<_PreferCorrectAnyMatcherTest>(
        parent: const {},
        own: {
          'test_whenNamedMatcherMismatch_lint': (t) => t._whenNamedMatcherMismatchLint(),
          'test_verifyNamedMatcherMismatch_lint': (t) => t._verifyNamedMatcherMismatchLint(),
          'test_matchingNamedMatcher_noLint': (t) => t._matchingNamedMatcherNoLint(),
          'test_positionalMatcher_noLint': (t) => t._positionalMatcherNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferCorrectAnyMatcher();
    super.setUp();
  }

  Future<void> _whenNamedMatcherMismatchLint() async {
    const source = r'''
T any<T>({String? named}) => throw 'mock';
void when(Object? Function() call) {}

class Cat {
  void eat({required String food}) {}
}

void test(Cat cat) {
  when(() => cat.eat(food: any(named: 'wrong')));
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('any'), 'any'.length)]);
  }

  Future<void> _verifyNamedMatcherMismatchLint() async {
    const source = r'''
T any<T>({String? named}) => throw 'mock';
void verify(Object? Function() call) {}

class Cat {
  void eat({required String food}) {}
}

void test(Cat cat) {
  verify(() => cat.eat(food: any(named: 'wrong')));
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('any'), 'any'.length)]);
  }

  Future<void> _matchingNamedMatcherNoLint() async {
    await assertNoDiagnostics(r'''
T any<T>({String? named}) => throw 'mock';
void when(Object? Function() call) {}

class Cat {
  void eat({required String food}) {}
}

void test(Cat cat) {
  when(() => cat.eat(food: any(named: 'food')));
}
''');
  }

  Future<void> _positionalMatcherNoLint() async {
    await assertNoDiagnostics(r'''
T any<T>({String? named}) => throw 'mock';
void when(Object? Function() call) {}

class Cat {
  void eat(String food) {}
}

void test(Cat cat) {
  when(() => cat.eat(any(named: 'food')));
}
''');
  }
}
