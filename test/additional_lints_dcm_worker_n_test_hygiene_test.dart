// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/missing_test_assertion.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_test_file_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_unique_test_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingTestAssertionTest);
    defineReflectiveTests(PreferCorrectTestFileNameTest);
    defineReflectiveTests(PreferUniqueTestNamesTest);
  });
}

@reflectiveTest
final class MissingTestAssertionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MissingTestAssertion();
    super.setUp();
  }

  Future<void> test_testWithoutAssertion_lint() async {
    const source = r'''
void test(String name, void Function() body) {}

void main() {
  test('does work', () {
    final value = 1;
    print(value);
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("test('does work'"), 'test'.length)]);
  }

  Future<void> test_testWithExpect_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}
void expect(Object? actual, Object? matcher) {}

void main() {
  test('asserts work', () {
    expect(1, 1);
  });
}
''');
  }

  Future<void> test_testWidgetsWithExpectLater_noLint() async {
    await assertNoDiagnostics(r'''
void testWidgets(String name, void Function(Object tester) body) {}
void expectLater(Object? actual, Object? matcher) {}
const isNotNull = Object();

void main() {
  testWidgets('asserts widget work', (tester) {
    expectLater(tester, isNotNull);
  });
}
''');
  }

  Future<void> test_assertionInsideFakeAsync_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}
void fakeAsync(void Function(Object fake) body) {}
void expect(Object? actual, Object? matcher) {}

void main() {
  test('debounces work', () {
    fakeAsync((fake) {
      expect(1, 1);
    });
  });
}
''');
  }

  Future<void> test_verifyOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

final class VerificationResult {
  void called(int count) {}
}

VerificationResult verify(void Function() body) => VerificationResult();

void main() {
  test('persists through dependency', () {
    verify(() {
      print('save');
    }).called(1);
  });
}
''');
  }

  Future<void> test_asyncVerifyOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, Future<void> Function() body) {}

final class VerificationResult {
  void called(int count) {}
}

VerificationResult verify(void Function() body) => VerificationResult();

void main() {
  test('persists through dependency', () async {
    await Future<void>.value();
    verify(() {
      print('save');
    }).called(1);
  });
}
''');
  }

  Future<void> test_verifyInOrderOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, Future<void> Function() body) {}
void verifyInOrder(List<void Function()> calls) {}

void main() {
  test('persists in order', () async {
    await Future<void>.value();
    verifyInOrder([
      () {
        print('first');
      },
      () {
        print('second');
      },
    ]);
  });
}
''');
  }

  Future<void> test_verifyNeverOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}
void verifyNever(void Function() body) {}

void main() {
  test('skips dependency', () {
    verifyNever(() {
      print('save');
    });
  });
}
''');
  }

  Future<void> test_assertionOnlyInNestedHelper_lint() async {
    const source = r'''
void test(String name, void Function() body) {}
void expect(Object? actual, Object? matcher) {}

void main() {
  test('hides assertion', () {
    void helper() {
      expect(1, 1);
    }

    helper();
  });
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('hides assertion'"), 'test'.length),
    ]);
  }
}

@reflectiveTest
final class PreferUniqueTestNamesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferUniqueTestNames();
    super.setUp();
  }

  Future<void> test_duplicateSiblingTestName_lint() async {
    const source = r'''
void test(String name, void Function() body) {}

void main() {
  test('saves item', () {});
  test('saves item', () {});
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf("'saves item'"), "'saves item'".length),
    ]);
  }

  Future<void> test_sameNameInDifferentGroups_noLint() async {
    await assertNoDiagnostics(r'''
void group(String name, void Function() body) {}
void test(String name, void Function() body) {}

void main() {
  group('first', () {
    test('saves item', () {});
  });
  group('second', () {
    test('saves item', () {});
  });
}
''');
  }

  Future<void> test_dynamicNames_noLint() async {
    await assertNoDiagnostics(r'''
void test(String name, void Function() body) {}

void main() {
  for (final name in ['a', 'b']) {
    test(name, () {});
  }
}
''');
  }
}

@reflectiveTest
final class PreferCorrectTestFileNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectTestFileName();
    super.setUp();
  }

  Future<void> test_fileWithTestButWrongName_lint() async {
    const source = r'''
void test(String name, void Function() body) {}

void main() {
  test('runs', () {});
}
''';

    final path = '$testPackageRootPath/test/widget_spec.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf("test('runs'"), 'test'.length)]);
  }

  Future<void> test_correctTestFileName_noLint() async {
    const source = r'''
void test(String name, void Function() body) {}

void main() {
  test('runs', () {});
}
''';
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}
