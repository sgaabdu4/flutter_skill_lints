import 'package:flutter_skill_lints/src/additional_lints/rules/missing_test_assertion.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/mocktail_stub.dart';

void main() {
  analysisRuleSuite<MissingTestAssertionCallTest>(
    'MissingTestAssertionCallTest',
    MissingTestAssertionCallTest.new,
    {
      'parenthesizedVerifyInTestBody': (t) => t.parenthesizedVerifyInTestBody(),
      'parenthesizedUnrelatedCallInTestBody': (t) => t.parenthesizedUnrelatedCallInTestBody(),
      'parenthesizedVerifyInHelper': (t) => t.parenthesizedVerifyInHelper(),
      'parenthesizedPrefixedVerifyInHelper': (t) => t.parenthesizedPrefixedVerifyInHelper(),
      'shadowedParenthesizedVerifyInHelper': (t) => t.shadowedParenthesizedVerifyInHelper(),
      'shadowedPrefixInHelper': (t) => t.shadowedPrefixInHelper(),
    },
  );
}

final class MissingTestAssertionCallTest extends FixRuleTest {
  @override
  void setUp() {
    rule = MissingTestAssertion();
    addMocktail(this);
    super.setUp();
  }

  static const _testStub = 'void test(String name, void Function() body) {}\n';

  Future<void> _expectHelper(String helper, {required bool reported}) async {
    newFile('$testPackageLibPath/assertions.dart', helper);
    const source =
        '''
import '../lib/assertions.dart';

$_testStub
void main() {
  test('delegates', () {
    check();
  });
}
''';
    final path = '$testPackageRootPath/test/helper_test.dart';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      if (reported) lint(source.indexOf("test('delegates'"), 'test'.length),
    ]);
  }

  Future<void> parenthesizedVerifyInTestBody() => assertNoDiagnostics('''
import 'package:mocktail/mocktail.dart';

${_testStub}void main() {
  test('verifies', () {
    (verify)(() => 'save').called(1);
  });
}
''');

  Future<void> parenthesizedUnrelatedCallInTestBody() async {
    const source =
        '''
$_testStub
void main() {
  test('prints', () {
    (print)('save');
  });
}
''';
    await assertDiagnostics(source, [lint(source.indexOf("test('prints'"), 'test'.length)]);
  }

  Future<void> parenthesizedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart';

void check() {
  (verify)(() => 'save').called(1);
}
''', reported: false);

  Future<void> parenthesizedPrefixedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart' as mocktail;

void check() {
  (mocktail.verify)(() => 'save').called(1);
}
''', reported: false);

  Future<void> shadowedParenthesizedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart';

void check() {
  final verify = (Object? value) => value;
  (verify)('save');
}
''', reported: true);

  Future<void> shadowedPrefixInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart' as mocktail;

void check() {
  final mocktail = _Local();
  (mocktail.verify)(() => 'save');
}

class _Local {
  Object? verify(Object? value) => value;
}
''', reported: true);
}
