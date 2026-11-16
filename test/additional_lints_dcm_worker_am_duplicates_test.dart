import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_constant_values.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_exports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_map_keys.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidDuplicateExportsTest>(
    'AvoidDuplicateExportsTest',
    _AvoidDuplicateExportsTest.new,
    _AvoidDuplicateExportsTest._allCases,
  );
  analysisRuleSuite<_AvoidDuplicateMapKeysTest>(
    'AvoidDuplicateMapKeysTest',
    _AvoidDuplicateMapKeysTest.new,
    _AvoidDuplicateMapKeysTest._allCases,
  );
  analysisRuleSuite<_AvoidDuplicateConstantValuesTest>(
    'AvoidDuplicateConstantValuesTest',
    _AvoidDuplicateConstantValuesTest.new,
    _AvoidDuplicateConstantValuesTest._allCases,
  );
}

final class _AvoidDuplicateExportsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidDuplicateExportsTest)> get _allCases =>
      caseSet<_AvoidDuplicateExportsTest>(
        parent: const {},
        own: {
          'test_sameSimpleExportUri_lint': (t) => t._sameSimpleExportUriLint(),
          'test_exportWithCombinators_noLint': (t) => t._exportWithCombinatorsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDuplicateExports();
    super.setUp();
  }

  Future<void> _sameSimpleExportUriLint() async {
    const source = r'''
// ignore_for_file: duplicate_export

export 'src/a.dart';
export 'src/b.dart';
export 'src/a.dart';
''';
    newFile('$testPackageRootPath/lib/src/a.dart', '');
    newFile('$testPackageRootPath/lib/src/b.dart', '');

    await assertDiagnostics(source, [
      lint(source.lastIndexOf("'src/a.dart'"), "'src/a.dart'".length),
    ]);
  }

  Future<void> _exportWithCombinatorsNoLint() async {
    newFile('$testPackageRootPath/lib/src/a.dart', 'class A {}\nclass B {}\n');

    await assertNoDiagnostics(r'''
export 'src/a.dart' show A;
export 'src/a.dart' show B;
''');
  }
}

final class _AvoidDuplicateMapKeysTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidDuplicateMapKeysTest)> get _allCases =>
      caseSet<_AvoidDuplicateMapKeysTest>(
        parent: const {},
        own: {
          'test_constMapDuplicateStringKey_lint': (t) => t._constMapDuplicateStringKeyLint(),
          'test_nonConstMapDuplicateKey_noLint': (t) => t._nonConstMapDuplicateKeyNoLint(),
          'test_nonLiteralMapKeys_noLint': (t) => t._nonLiteralMapKeysNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDuplicateMapKeys();
    super.setUp();
  }

  Future<void> _constMapDuplicateStringKeyLint() async {
    const source = r'''
// ignore_for_file: equal_keys_in_const_map

const values = {
  'a': 1,
  'b': 2,
  'a': 3,
};
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'a'"), "'a'".length)]);
  }

  Future<void> _nonConstMapDuplicateKeyNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: equal_keys_in_map

final values = {
  'a': 1,
  'a': 2,
};
''');
  }

  Future<void> _nonLiteralMapKeysNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: equal_keys_in_const_map

const first = 'a';
const second = 'a';
const values = {
  first: 1,
  second: 2,
};
''');
  }
}

final class _AvoidDuplicateConstantValuesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidDuplicateConstantValuesTest)> get _allCases =>
      caseSet<_AvoidDuplicateConstantValuesTest>(
        parent: const {},
        own: {
          'test_sameConstDeclarationGroupValue_lint': (t) =>
              t._sameConstDeclarationGroupValueLint(),
          'test_separateConstDeclarations_noLint': (t) => t._separateConstDeclarationsNoLint(),
          'test_nonLiteralConstValues_noLint': (t) => t._nonLiteralConstValuesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDuplicateConstantValues();
    super.setUp();
  }

  Future<void> _sameConstDeclarationGroupValueLint() async {
    const source = r'''
const first = 'a', second = 'b', third = 'a';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'a'"), "'a'".length)]);
  }

  Future<void> _separateConstDeclarationsNoLint() async {
    await assertNoDiagnostics(r'''
const first = 'a';
const second = 'a';
''');
  }

  Future<void> _nonLiteralConstValuesNoLint() async {
    await assertNoDiagnostics(r'''
const first = Object();
const second = Object();
''');
  }
}
