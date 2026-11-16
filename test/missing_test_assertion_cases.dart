import 'package:flutter_skill_lints/src/additional_lints/rules/missing_test_assertion.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/mocktail_stub.dart';

void main() {
  analysisRuleSuite<_MissingTestAssertionCallTest>(
    'MissingTestAssertionCallTest',
    _MissingTestAssertionCallTest.new,
    {
      'parenthesizedVerifyInTestBody': (t) => t._parenthesizedVerifyInTestBody(),
      'parenthesizedUnrelatedCallInTestBody': (t) => t._parenthesizedUnrelatedCallInTestBody(),
      'parenthesizedVerifyInHelper': (t) => t._parenthesizedVerifyInHelper(),
      'parenthesizedPrefixedVerifyInHelper': (t) => t._parenthesizedPrefixedVerifyInHelper(),
      'shadowedParenthesizedVerifyInHelper': (t) => t._shadowedParenthesizedVerifyInHelper(),
      'shadowedPrefixInHelper': (t) => t._shadowedPrefixInHelper(),
    },
  );
}

final class _MissingTestAssertionCallTest extends FixRuleTest {
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

  Future<void> _parenthesizedVerifyInTestBody() => assertNoDiagnostics('''
import 'package:mocktail/mocktail.dart';

${_testStub}void main() {
  test('verifies', () {
    (verify)(() => 'save').called(1);
  });
}
''');

  Future<void> _parenthesizedUnrelatedCallInTestBody() async {
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

  Future<void> _parenthesizedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart';

void check() {
  (verify)(() => 'save').called(1);
}
''', reported: false);

  Future<void> _parenthesizedPrefixedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart' as mocktail;

void check() {
  (mocktail.verify)(() => 'save').called(1);
}
''', reported: false);

  Future<void> _shadowedParenthesizedVerifyInHelper() => _expectHelper('''
import 'package:mocktail/mocktail.dart';

void check() {
  final verify = (Object? value) => value;
  (verify)('save');
}
''', reported: true);

  Future<void> _shadowedPrefixInHelper() => _expectHelper('''
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
