import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/missing_test_assertion.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_test_file_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_unique_test_names.dart';

import 'analysis_rule_suite.dart';
import 'support/mocktail_stub.dart';

void main() {
  analysisRuleSuite<_MissingTestAssertionTest>(
    'MissingTestAssertionTest',
    _MissingTestAssertionTest.new,
    _MissingTestAssertionTest._allCases,
  );
  analysisRuleSuite<_PreferCorrectTestFileNameTest>(
    'PreferCorrectTestFileNameTest',
    _PreferCorrectTestFileNameTest.new,
    _PreferCorrectTestFileNameTest._allCases,
  );
  analysisRuleSuite<_PreferUniqueTestNamesTest>(
    'PreferUniqueTestNamesTest',
    _PreferUniqueTestNamesTest.new,
    _PreferUniqueTestNamesTest._allCases,
  );
}

final class _MissingTestAssertionTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_MissingTestAssertionTest)> get _allCases =>
      caseSet<_MissingTestAssertionTest>(
        parent: const {},
        own: {
          'test_testWithoutAssertion_lint': (t) => t._testWithoutAssertionLint(),
          'test_testWithExpect_noLint': (t) => t._testWithExpectNoLint(),
          'test_resolvedLocalHelperAssertion_noLint': (t) =>
              t._resolvedLocalHelperAssertionNoLint(),
          'test_helperDoesNotCountUnrelatedOrDeferredAssertions': (t) =>
              t._helperDoesNotCountUnrelatedOrDeferredAssertions(),
          'test_helperWrapperPreservesResolvedAssertionIdentity': (t) =>
              t._helperWrapperPreservesResolvedAssertionIdentity(),
          'test_testWidgetsWithExpectLater_noLint': (t) => t._testWidgetsWithExpectLaterNoLint(),
          'test_assertionInsideFakeAsync_noLint': (t) => t._assertionInsideFakeAsyncNoLint(),
          'test_unitStubVerifyOnlyTest_lint': (t) => t._unitStubVerifyOnlyTestLint(),
          'test_mocktailGetterVerifyOnlyTest_noLint': (t) =>
              t._mocktailGetterVerifyOnlyTestNoLint(),
          'test_prefixedMocktailGetterVerifyOnlyTest_noLint': (t) =>
              t._prefixedMocktailGetterVerifyOnlyTestNoLint(),
          'test_asyncVerifyOnlyTest_noLint': (t) => t._asyncVerifyOnlyTestNoLint(),
          'test_mocktailVerifyInOrderOnlyTest_noLint': (t) =>
              t._mocktailVerifyInOrderOnlyTestNoLint(),
          'test_prefixedMocktailVerifyInOrderOnlyTest_noLint': (t) =>
              t._prefixedMocktailVerifyInOrderOnlyTestNoLint(),
          'test_mocktailVerifyNeverOnlyTest_noLint': (t) => t._mocktailVerifyNeverOnlyTestNoLint(),
          'test_prefixedMocktailVerifyNeverOnlyTest_noLint': (t) =>
              t._prefixedMocktailVerifyNeverOnlyTestNoLint(),
          'test_mockitoVerifyGetterOnlyTest_noLint': (t) => t._mockitoVerifyGetterOnlyTestNoLint(),
          'test_prefixedMockitoVerifyGetterOnlyTest_noLint': (t) =>
              t._prefixedMockitoVerifyGetterOnlyTestNoLint(),
          'test_mockitoVerifyNeverGetterOnlyTest_noLint': (t) =>
              t._mockitoVerifyNeverGetterOnlyTestNoLint(),
          'test_prefixedMockitoVerifyNeverGetterOnlyTest_noLint': (t) =>
              t._prefixedMockitoVerifyNeverGetterOnlyTestNoLint(),
          'test_mockitoVerifyInOrderGetterOnlyTest_noLint': (t) =>
              t._mockitoVerifyInOrderGetterOnlyTestNoLint(),
          'test_prefixedMockitoVerifyInOrderGetterOnlyTest_noLint': (t) =>
              t._prefixedMockitoVerifyInOrderGetterOnlyTestNoLint(),
          'test_fakeMemberVerifyGetter_lint': (t) => t._fakeMemberVerifyGetterLint(),
          'test_differentLibraryVerifyGetter_lint': (t) => t._differentLibraryVerifyGetterLint(),
          'test_localVerifyGetter_lint': (t) => t._localVerifyGetterLint(),
          'test_deferredMocktailGetter_lint': (t) => t._deferredMocktailGetterLint(),
          'test_resolvedMocktailHelperAssertion_noLint': (t) =>
              t._resolvedMocktailHelperAssertionNoLint(),
          'test_shadowedMocktailBindingsInHelper_lint': (t) =>
              t._shadowedMocktailBindingsInHelperLint(),
          'test_assertionOnlyInNestedHelper_lint': (t) => t._assertionOnlyInNestedHelperLint(),
        },
      );

  @override
  void setUp() {
    rule = MissingTestAssertion();
    newPackage('test_api')
        .addFile('lib/src/expect/expect.dart', 'void expect(Object actual, Object matcher) {}');
    newPackage('fake_async').addFile('lib/fake_async.dart', r'''
void fakeAsync(void Function(Object clock) body) { body(Object()); }
''');
    addMocktail(this);
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

  Future<void> _testWithoutAssertionLint() async {
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

  Future<void> _testWithExpectNoLint() async {
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

  Future<void> _resolvedLocalHelperAssertionNoLint() async {
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

  Future<void> _helperDoesNotCountUnrelatedOrDeferredAssertions() async {
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

  Future<void> _helperWrapperPreservesResolvedAssertionIdentity() async {
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

  Future<void> _testWidgetsWithExpectLaterNoLint() async {
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

  Future<void> _assertionInsideFakeAsyncNoLint() async {
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

  Future<void> _unitStubVerifyOnlyTestLint() async {
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

  Future<void> _mocktailGetterVerifyOnlyTestNoLint() async {
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

  Future<void> _prefixedMocktailGetterVerifyOnlyTestNoLint() async {
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

  Future<void> _asyncVerifyOnlyTestNoLint() async {
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

  Future<void> _mocktailVerifyInOrderOnlyTestNoLint() async {
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

  Future<void> _prefixedMocktailVerifyInOrderOnlyTestNoLint() async {
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

  Future<void> _mocktailVerifyNeverOnlyTestNoLint() async {
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

  Future<void> _prefixedMocktailVerifyNeverOnlyTestNoLint() async {
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

  Future<void> _mockitoVerifyGetterOnlyTestNoLint() async {
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

  Future<void> _prefixedMockitoVerifyGetterOnlyTestNoLint() async {
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

  Future<void> _mockitoVerifyNeverGetterOnlyTestNoLint() async {
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

  Future<void> _prefixedMockitoVerifyNeverGetterOnlyTestNoLint() async {
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

  Future<void> _mockitoVerifyInOrderGetterOnlyTestNoLint() async {
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

  Future<void> _prefixedMockitoVerifyInOrderGetterOnlyTestNoLint() async {
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

  Future<void> _fakeMemberVerifyGetterLint() async {
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

  Future<void> _differentLibraryVerifyGetterLint() async {
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

  Future<void> _localVerifyGetterLint() async {
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

  Future<void> _deferredMocktailGetterLint() async {
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

  Future<void> _resolvedMocktailHelperAssertionNoLint() async {
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

  Future<void> _shadowedMocktailBindingsInHelperLint() async {
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

  Future<void> _assertionOnlyInNestedHelperLint() async {
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

final class _PreferUniqueTestNamesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferUniqueTestNamesTest)> get _allCases =>
      caseSet<_PreferUniqueTestNamesTest>(
        parent: const {},
        own: {
          'test_duplicateSiblingTestName_lint': (t) => t._duplicateSiblingTestNameLint(),
          'test_sameNameInDifferentGroups_noLint': (t) => t._sameNameInDifferentGroupsNoLint(),
          'test_dynamicNames_noLint': (t) => t._dynamicNamesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferUniqueTestNames();
    super.setUp();
  }

  Future<void> _duplicateSiblingTestNameLint() async {
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

  Future<void> _sameNameInDifferentGroupsNoLint() async {
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

  Future<void> _dynamicNamesNoLint() async {
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

final class _PreferCorrectTestFileNameTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferCorrectTestFileNameTest)> get _allCases =>
      caseSet<_PreferCorrectTestFileNameTest>(
        parent: const {},
        own: {
          'test_fileWithTestButWrongName_lint': (t) => t._fileWithTestButWrongNameLint(),
          'test_correctTestFileName_noLint': (t) => t._correctTestFileNameNoLint(),
          'test_prefixedTestApis_lint': (t) => t._prefixedTestApisLint(),
          'test_unrelatedSameNamedCalls_noLint': (t) => t._unrelatedSameNamedCallsNoLint(),
        },
      );

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

  Future<void> _fileWithTestButWrongNameLint() async {
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

  Future<void> _correctTestFileNameNoLint() async {
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

  Future<void> _prefixedTestApisLint() async {
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

  Future<void> _unrelatedSameNamedCallsNoLint() async {
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
