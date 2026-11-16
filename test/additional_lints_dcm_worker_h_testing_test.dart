import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_test_assertions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_test_groups.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_then_return_with_future.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidEmptyTestGroupsTest>(
    'AvoidEmptyTestGroupsTest',
    AvoidEmptyTestGroupsTest.new,
    {
      'test_groupWithoutTests_lint': (t) => t._groupWithoutTestsLint(),
      'test_groupWithTest_noLint': (t) => t._groupWithTestNoLint(),
      'test_groupWithTestWidgets_noLint': (t) => t._groupWithTestWidgetsNoLint(),
    },
  );
  analysisRuleSuite<AvoidDuplicateTestAssertionsTest>(
    'AvoidDuplicateTestAssertionsTest',
    AvoidDuplicateTestAssertionsTest.new,
    {
      'test_duplicateExpectInSameTest_lint': (t) => t._duplicateExpectInSameTestLint(),
      'test_sameAssertionInDifferentTests_noLint': (t) => t._sameAssertionInDifferentTestsNoLint(),
      'test_distinctExpectedValue_noLint': (t) => t._distinctExpectedValueNoLint(),
    },
  );
  analysisRuleSuite<AvoidThenReturnWithFutureTest>(
    'AvoidThenReturnWithFutureTest',
    AvoidThenReturnWithFutureTest.new,
    {
      'test_thenReturnFuture_lint': (t) => t._thenReturnFutureLint(),
      'test_thenReturnStream_lint': (t) => t._thenReturnStreamLint(),
      'test_thenReturnSynchronousValue_noLint': (t) => t._thenReturnSynchronousValueNoLint(),
    },
  );
}

final class AvoidEmptyTestGroupsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptyTestGroups();
    super.setUp();
  }

  Future<void> _groupWithoutTestsLint() async {
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

  Future<void> _groupWithTestNoLint() async {
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

  Future<void> _groupWithTestWidgetsNoLint() async {
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

final class AvoidDuplicateTestAssertionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateTestAssertions();
    super.setUp();
  }

  Future<void> _duplicateExpectInSameTestLint() async {
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

  Future<void> _sameAssertionInDifferentTestsNoLint() async {
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

  Future<void> _distinctExpectedValueNoLint() async {
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

final class AvoidThenReturnWithFutureTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidThenReturnWithFuture();
    super.setUp();
  }

  Future<void> _thenReturnFutureLint() async {
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

  Future<void> _thenReturnStreamLint() async {
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

  Future<void> _thenReturnSynchronousValueNoLint() async {
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
