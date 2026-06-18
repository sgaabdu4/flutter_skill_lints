// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_test_assertions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_test_groups.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_then_return_with_future.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEmptyTestGroupsTest);
    defineReflectiveTests(AvoidDuplicateTestAssertionsTest);
    defineReflectiveTests(AvoidThenReturnWithFutureTest);
  });
}

@reflectiveTest
final class AvoidEmptyTestGroupsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptyTestGroups();
    super.setUp();
  }

  Future<void> test_groupWithoutTests_lint() async {
    const source = r'''
void group(String name, void Function() body) {}
void test(String name, void Function() body) {}

void main() {
  group('empty', () {
    final value = 1;
    print(value);
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("group('empty'"), 'group'.length)]);
  }

  Future<void> test_groupWithTest_noLint() async {
    await assertNoDiagnostics(r'''
void group(String name, void Function() body) {}
void test(String name, void Function() body) {}

void main() {
  group('not empty', () {
    test('works', () {});
  });
}
''');
  }

  Future<void> test_groupWithTestWidgets_noLint() async {
    await assertNoDiagnostics(r'''
void group(String name, void Function() body) {}
void testWidgets(String name, Future<void> Function(Object tester) body) {}

void main() {
  group('not empty', () {
    testWidgets('renders', (tester) async {});
  });
}
''');
  }
}

@reflectiveTest
final class AvoidDuplicateTestAssertionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateTestAssertions();
    super.setUp();
  }

  Future<void> test_duplicateExpectInSameTest_lint() async {
    const source = r'''
void test(String name, void Function() body) {}
void expect(Object? actual, Object? expected) {}

void main() {
  test('repeats assertion', () {
    final value = 1;
    expect(value, 1);
    expect(value, 1);
  });
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('expect'), 'expect'.length)]);
  }

  Future<void> test_sameAssertionInDifferentTests_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}
void expect(Object? actual, Object? expected) {}

void main() {
  test('first', () {
    expect(1, 1);
  });
  test('second', () {
    expect(1, 1);
  });
}
''');
  }

  Future<void> test_distinctExpectedValue_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}
void expect(Object? actual, Object? expected) {}

void main() {
  test('distinct', () {
    final value = 1;
    expect(value, 1);
    expect(value, 2);
  });
}
''');
  }
}

@reflectiveTest
final class AvoidThenReturnWithFutureTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThenReturnWithFuture();
    super.setUp();
  }

  Future<void> test_thenReturnFuture_lint() async {
    const source = r'''
class Stub {
  void thenReturn(Object? value) {}
}

void main() {
  Stub().thenReturn(Future<int>.value(1));
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('thenReturn(Future'), 'thenReturn'.length),
    ]);
  }

  Future<void> test_thenReturnStream_lint() async {
    const source = r'''
class Stub {
  void thenReturn(Object? value) {}
}

void main() {
  Stub().thenReturn(Stream<int>.value(1));
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('thenReturn(Stream'), 'thenReturn'.length),
    ]);
  }

  Future<void> test_thenReturnSynchronousValue_noLint() async {
    await assertNoDiagnostics(r'''
class Stub {
  void thenReturn(Object? value) {}
}

void main() {
  Stub().thenReturn(1);
}
''');
  }
}
