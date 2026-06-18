// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_constant_values.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_exports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_map_keys.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDuplicateExportsTest);
    defineReflectiveTests(AvoidDuplicateMapKeysTest);
    defineReflectiveTests(AvoidDuplicateConstantValuesTest);
  });
}

@reflectiveTest
final class AvoidDuplicateExportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateExports();
    super.setUp();
  }

  Future<void> test_sameSimpleExportUri_lint() async {
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

  Future<void> test_exportWithCombinators_noLint() async {
    newFile('$testPackageRootPath/lib/src/a.dart', 'class A {}\nclass B {}\n');

    await assertNoDiagnostics(r'''
export 'src/a.dart' show A;
export 'src/a.dart' show B;
''');
  }
}

@reflectiveTest
final class AvoidDuplicateMapKeysTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateMapKeys();
    super.setUp();
  }

  Future<void> test_constMapDuplicateStringKey_lint() async {
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

  Future<void> test_nonConstMapDuplicateKey_noLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: equal_keys_in_map

final values = {
  'a': 1,
  'a': 2,
};
''');
  }

  Future<void> test_nonLiteralMapKeys_noLint() async {
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

@reflectiveTest
final class AvoidDuplicateConstantValuesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateConstantValues();
    super.setUp();
  }

  Future<void> test_sameConstDeclarationGroupValue_lint() async {
    const source = r'''
const first = 'a', second = 'b', third = 'a';
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf("'a'"), "'a'".length)]);
  }

  Future<void> test_separateConstDeclarations_noLint() async {
    await assertNoDiagnostics(r'''
const first = 'a';
const second = 'a';
''');
  }

  Future<void> test_nonLiteralConstValues_noLint() async {
    await assertNoDiagnostics(r'''
const first = Object();
const second = Object();
''');
  }
}
