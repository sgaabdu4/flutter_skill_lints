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
    newPackage('test_api')
        .addFile('lib/src/expect/expect.dart', 'void expect(Object actual, Object matcher) {}');
    newPackage('fake_async').addFile('lib/fake_async.dart', r'''
void fakeAsync(void Function(Object clock) body) { body(Object()); }
''');
    final mocktail = newPackage('mocktail');
    mocktail.addFile('lib/mocktail.dart', "export 'src/mocktail.dart';");
    mocktail.addFile('lib/src/mocktail.dart', r'''
final class VerificationResult {
  void called(int count) {}
}

typedef Verify = VerificationResult Function<T>(T Function() invocation);
typedef VerifyInOrder = List<VerificationResult> Function<T>(List<T Function()> invocations);

Verify _makeVerify(bool never) => <T>(T Function() invocation) => VerificationResult();
VerifyInOrder _makeVerifyInOrder() => <T>(List<T Function()> invocations) => [];

Verify get verify => _makeVerify(false);
Verify get verifyNever => _makeVerify(true);
VerifyInOrder get verifyInOrder => _makeVerifyInOrder();
''');
    final mockito = newPackage('mockito');
    mockito.addFile('lib/mockito.dart', r'''
export 'src/mock.dart' show verify, verifyInOrder, verifyNever;
''');
    mockito.addFile('lib/src/mock.dart', r'''
final class VerificationResult {
  void called(Object matcher) {}
}

typedef Verification = VerificationResult Function<T>(T matchingInvocation);
typedef VerificationInOrder = List<VerificationResult> Function<T>(
  List<T> matchingInvocations,
);

Verification _makeVerify(bool never) => <T>(T matchingInvocation) => VerificationResult();
VerificationInOrder _makeVerifyInOrder() => <T>(List<T> matchingInvocations) => [];

Verification get verify => _makeVerify(false);
Verification get verifyNever => _makeVerify(true);
VerificationInOrder get verifyInOrder => _makeVerifyInOrder();
''');
    newPackage('other').addFile('lib/other.dart', r'''
final class VerificationResult {
  void called(int count) {}
}

typedef Verify = VerificationResult Function<T>(T Function() invocation);

Verify get verify => <T>(T Function() invocation) => VerificationResult();
''');
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

  Future<void> test_resolvedLocalHelperAssertion_noLint() async {
    newFile('$testPackageLibPath/test.dart', "export 'package:test_api/src/expect/expect.dart';");
    newFile('$testPackageLibPath/assertions.dart', r'''
import 'package:test/test.dart';
void assertOutput(int value) { expect(value, 1); }
void noAssertion(int value) { print(value); }
''');
    const source = r'''
import '../lib/assertions.dart';
void test(String name, void Function() body) {}
void main() {
  test('delegated assertion', () { assertOutput(1); });
  test('no assertion', () { noAssertion(1); });
}
''';
    final path = '$testPackageRootPath/test/helper_assertion_test.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      lint(source.indexOf("test('no assertion'"), 'test'.length),
    ]);
  }

  Future<void> test_helperDoesNotCountUnrelatedOrDeferredAssertions() async {
    newFile('$testPackageLibPath/test.dart', "export 'package:test_api/src/expect/expect.dart';");
    newFile('$testPackageLibPath/assertions.dart', r'''
import 'package:test/test.dart';
class Fake { void expect(Object? actual, Object? matcher) {} }
void receiverOnly() { Fake().expect(1, 1); }
void shadowed() { void expect(Object? actual, Object? matcher) {} expect(1, 1); }
void deferred() { () { expect(1, 1); }; }
''');
    const source = r'''
import '../lib/assertions.dart';
void test(String name, void Function() body) {}
void main() {
  test('receiver', () { receiverOnly(); });
  test('shadowed', () { shadowed(); });
  test('deferred', () { deferred(); });
}
''';
    final path = '$testPackageRootPath/test/negative_helpers_test.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      lint(source.indexOf("test('receiver'"), 'test'.length),
      lint(source.indexOf("test('shadowed'"), 'test'.length),
      lint(source.indexOf("test('deferred'"), 'test'.length),
    ]);
  }

  Future<void> test_helperWrapperPreservesResolvedAssertionIdentity() async {
    newFile('$testPackageLibPath/test.dart', "export 'package:test_api/src/expect/expect.dart';");
    newFile('$testPackageLibPath/assertions.dart', r'''
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
class Holder { void expect(Object? actual, Object? matcher) {} }
void realAssertion() { fakeAsync((_) { expect(1, 1); }); }
void unrelatedMember() { fakeAsync((_) { Holder().expect(1, 1); }); }
''');
    const source = r'''
import '../lib/assertions.dart';
void test(String name, void Function() body) {}
void main() {
  test('real', () { realAssertion(); });
  test('unrelated', () { unrelatedMember(); });
}
''';
    final path = '$testPackageRootPath/test/wrapped_assertions_test.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [lint(source.indexOf("test('unrelated'"), 'test'.length)]);
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

  Future<void> test_unitStubVerifyOnlyTest_lint() async {
    const source = r'''
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
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('persists through dependency'"), 'test'.length),
    ]);
  }

  Future<void> test_mocktailGetterVerifyOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart';

void test(String name, void Function() body) {}

void main() {
  test('verifies persisted behavior', () {
    verify(() {
      print('save');
    }).called(1);
  });
}
''');
  }

  Future<void> test_prefixedMocktailGetterVerifyOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart' as mocktail;

void test(String name, void Function() body) {}

void main() {
  test('verifies persisted behavior through an import prefix', () {
    mocktail.verify(() => 'save').called(1);
  });
}
''');
  }

  Future<void> test_asyncVerifyOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart';

void test(String name, Future<void> Function() body) {}

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

  Future<void> test_mocktailVerifyInOrderOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart';

void test(String name, Future<void> Function() body) {}

void main() {
  test('persists in order', () async {
    await Future<void>.value();
    verifyInOrder([
      () => 'first',
      () => 'second',
    ]);
  });
}
''');
  }

  Future<void> test_prefixedMocktailVerifyInOrderOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart' as mocktail;

void test(String name, void Function() body) {}

void main() {
  test('verifies order through an import prefix', () {
    mocktail.verifyInOrder([
      () => 'first',
      () => 'second',
    ]);
  });
}
''');
  }

  Future<void> test_mocktailVerifyNeverOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart';

void test(String name, void Function() body) {}

void main() {
  test('skips dependency', () {
    verifyNever(() => 'save');
  });
}
''');
  }

  Future<void> test_prefixedMocktailVerifyNeverOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mocktail/mocktail.dart' as mocktail;

void test(String name, void Function() body) {}

void main() {
  test('skips dependency through an import prefix', () {
    mocktail.verifyNever(() => 'delete');
  });
}
''');
  }

  Future<void> test_mockitoVerifyGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart';

void test(String name, void Function() body) {}

void main() {
  test('verifies calls with Mockito verify', () {
    verify('save').called(1);
  });
}
''');
  }

  Future<void> test_prefixedMockitoVerifyGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart' as mockito;

void test(String name, void Function() body) {}

void main() {
  test('verifies calls with prefixed Mockito verify', () {
    mockito.verify('save').called(1);
  });
}
''');
  }

  Future<void> test_mockitoVerifyNeverGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart';

void test(String name, void Function() body) {}

void main() {
  test('verifies calls with Mockito verifyNever', () {
    verifyNever('delete').called(0);
  });
}
''');
  }

  Future<void> test_prefixedMockitoVerifyNeverGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart' as mockito;

void test(String name, void Function() body) {}

void main() {
  test('verifies calls with prefixed Mockito verifyNever', () {
    mockito.verifyNever('delete').called(0);
  });
}
''');
  }

  Future<void> test_mockitoVerifyInOrderGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart';

void test(String name, void Function() body) {}

void main() {
  test('verifies call order with Mockito', () {
    verifyInOrder(['first', 'second']);
  });
}
''');
  }

  Future<void> test_prefixedMockitoVerifyInOrderGetterOnlyTest_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:mockito/mockito.dart' as mockito;

void test(String name, void Function() body) {}

void main() {
  test('verifies call order with prefixed Mockito', () {
    mockito.verifyInOrder(['first', 'second']);
  });
}
''');
  }

  Future<void> test_fakeMemberVerifyGetter_lint() async {
    const source = r'''
void test(String name, void Function() body) {}

final class VerificationResult {
  void called(int count) {}
}

typedef Verify = VerificationResult Function<T>(T Function() invocation);

final class FakeVerifier {
  Verify get verify => <T>(T Function() invocation) => VerificationResult();
}

void main() {
  final fake = FakeVerifier();
  test('fake verification member', () {
    fake.verify(() => 'save').called(1);
  });
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('fake verification member'"), 'test'.length),
    ]);
  }

  Future<void> test_differentLibraryVerifyGetter_lint() async {
    const source = r'''
import 'package:other/other.dart' as other;

void test(String name, void Function() body) {}

void main() {
  test('other library verification', () {
    other.verify(() => 'save').called(1);
  });
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('other library verification'"), 'test'.length),
    ]);
  }

  Future<void> test_localVerifyGetter_lint() async {
    const source = r'''
void test(String name, void Function() body) {}

final class VerificationResult {
  void called(int count) {}
}

typedef Verify = VerificationResult Function<T>(T Function() invocation);
Verify get verify => <T>(T Function() invocation) => VerificationResult();

void main() {
  test('local getter is not an assertion', () {
    verify(() => 'save').called(1);
  });
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('local getter is not an assertion'"), 'test'.length),
    ]);
  }

  Future<void> test_deferredMocktailGetter_lint() async {
    const source = r'''
import 'package:mocktail/mocktail.dart';

void test(String name, void Function() body) {}

void main() {
  test('defers verification until after the test', () {
    final verifyLater = () => verify(() => 'save').called(1);
    print(verifyLater);
  });
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("test('defers verification until after the test'"), 'test'.length),
    ]);
  }

  Future<void> test_resolvedMocktailHelperAssertion_noLint() async {
    newFile('$testPackageLibPath/assertions.dart', r'''
import 'package:mocktail/mocktail.dart' as mocktail;

void assertSaved() {
  mocktail.verify(() => 'save').called(1);
}
''');
    const source = r'''
import '../lib/assertions.dart';

void test(String name, void Function() body) {}

void main() {
  test('delegates to a Mocktail verification helper', () {
    assertSaved();
  });
}
''';
    final path = '$testPackageRootPath/test/mocktail_helper_assertion_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_shadowedMocktailBindingsInHelper_lint() async {
    newFile('$testPackageLibPath/assertions.dart', r'''
import 'package:mocktail/mocktail.dart';

void shadowedVerifier() {
  void verify<T>(T invocation) {}
  verify('save');
}
''');
    newFile('$testPackageLibPath/shadowed_prefix_assertions.dart', r'''
import 'package:mocktail/mocktail.dart' as mocktail;

typedef _LocalVerify = _LocalVerificationResult Function<T>(T Function() invocation);

final class _LocalVerificationResult {
  void called(int count) {}
}

final class _LocalMocktail {
  _LocalVerify get verify => <T>(T Function() invocation) => _LocalVerificationResult();
}

void shadowedPrefix() {
  final mocktail = _LocalMocktail();
  mocktail.verify(() => 'save').called(1);
}
''');
    const source = r'''
import '../lib/assertions.dart';
import '../lib/shadowed_prefix_assertions.dart';

void test(String name, void Function() body) {}

void main() {
  test('uses a shadowing local verifier', () {
    shadowedVerifier();
  });
  test('uses a shadowing local prefix', () {
    shadowedPrefix();
  });
}
''';
    final path = '$testPackageRootPath/test/shadowed_mocktail_helper_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(source.indexOf("test('uses a shadowing local verifier'"), 'test'.length),
      lint(source.indexOf("test('uses a shadowing local prefix'"), 'test'.length),
    ]);
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
    newPackage('flutter_test').addFile('lib/flutter_test.dart', r'''
void testWidgets(String name, void Function(Object tester) body) {}
''');
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', r'''
void group(String name, void Function() body) {}
void test(String name, void Function() body) {}
''');
  }

  Future<void> test_fileWithTestButWrongName_lint() async {
    const source = r'''
import 'package:test/test.dart';

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
import 'package:test/test.dart';

void main() {
  test('runs', () {});
}
''';
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_prefixedTestApis_lint() async {
    const source = r'''
import 'package:test/test.dart' as spec;
import 'package:flutter_test/flutter_test.dart' as widgets;

void main() {
  spec.group('suite', () {});
  spec.test('case', () {});
  widgets.testWidgets('widget', (tester) {});
}
''';
    final path = '$testPackageRootPath/test/widget_spec.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      lint(source.indexOf('group('), 'group'.length),
      lint(source.indexOf('test('), 'test'.length),
      lint(source.indexOf('testWidgets('), 'testWidgets'.length),
    ]);
  }

  Future<void> test_unrelatedSameNamedCalls_noLint() async {
    const source = r'''
void group(String value) {}
void test(String value) {}
void testWidgets(String value) {}
class RegExpMatch { String? group(int index) => null; }

void main() {
  group('local');
  test('local');
  testWidgets('local');
  final match = RegExpMatch();
  match.group(1);
}
''';
    final path = '$testPackageRootPath/test/widget_spec.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, []);
  }
}
