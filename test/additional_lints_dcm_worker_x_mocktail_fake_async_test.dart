// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_async_callback_in_fake_async.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_any_matcher.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_then_answer.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAsyncCallbackInFakeAsyncTest);
    defineReflectiveTests(UseThenAnswerTest);
    defineReflectiveTests(PreferCorrectAnyMatcherTest);
  });
}

@reflectiveTest
final class AvoidAsyncCallbackInFakeAsyncTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAsyncCallbackInFakeAsync();
    super.setUp();
  }

  Future<void> test_fakeAsyncAsyncCallback_lint() async {
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

  Future<void> test_fakeAsyncRunAsyncCallback_lint() async {
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

  Future<void> test_fakeAsyncSyncCallback_noLint() async {
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

@reflectiveTest
final class UseThenAnswerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseThenAnswer();
    super.setUp();
  }

  Future<void> test_futureValue_lint() async {
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

  Future<void> test_streamValue_lint() async {
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

  Future<void> test_plainValue_noLint() async {
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

@reflectiveTest
final class PreferCorrectAnyMatcherTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectAnyMatcher();
    super.setUp();
  }

  Future<void> test_whenNamedMatcherMismatch_lint() async {
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

  Future<void> test_verifyNamedMatcherMismatch_lint() async {
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

  Future<void> test_matchingNamedMatcher_noLint() async {
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

  Future<void> test_positionalMatcher_noLint() async {
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
