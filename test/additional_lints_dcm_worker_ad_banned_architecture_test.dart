// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_exports.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_file_names.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_imports.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBannedImportsTest);
    defineReflectiveTests(AvoidBannedExportsTest);
    defineReflectiveTests(AvoidBannedFileNamesTest);
  });
}

@reflectiveTest
final class AvoidBannedImportsTest extends _BannedArchitectureRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedImports();
    super.setUp();
  }

  Future<void> test_stateManagementImport_lint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'package:provider/provider.dart';

void main() {}
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:provider/provider.dart'"),
        "'package:provider/provider.dart'".length,
      ),
    ]);
  }

  Future<void> test_lintPluginImport_lint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'package:flutter_skill_lints/flutter_skill_lints.dart';

void main() {}
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:flutter_skill_lints/flutter_skill_lints.dart'"),
        "'package:flutter_skill_lints/flutter_skill_lints.dart'".length,
      ),
    ]);
  }

  Future<void> test_allowedAppImports_noLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/feature.dart';

void main() {}
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile('$testPackageRootPath/lib/src/feature.dart', '');
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_bannedImportOutsideLib_noLint() async {
    const source = r'''
// ignore_for_file: unused_import

import 'package:get_it/get_it.dart';

void main() {}
''';
    final path = '$testPackageRootPath/test/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}

@reflectiveTest
final class AvoidBannedExportsTest extends _BannedArchitectureRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedExports();
    super.setUp();
  }

  Future<void> test_stateManagementExport_lint() async {
    const source = r'''
export 'package:flutter_bloc/flutter_bloc.dart';
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:flutter_bloc/flutter_bloc.dart'"),
        "'package:flutter_bloc/flutter_bloc.dart'".length,
      ),
    ]);
  }

  Future<void> test_customLintExport_lint() async {
    const source = r'''
export 'package:custom_lint_builder/custom_lint_builder.dart';
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:custom_lint_builder/custom_lint_builder.dart'"),
        "'package:custom_lint_builder/custom_lint_builder.dart'".length,
      ),
    ]);
  }

  Future<void> test_allowedExports_noLint() async {
    const source = r'''
export 'src/app_theme.dart';
export 'package:flutter/widgets.dart';
''';
    final path = '$testPackageRootPath/lib/app.dart';
    newFile('$testPackageRootPath/lib/src/app_theme.dart', '');
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}

abstract class _BannedArchitectureRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addPackage('custom_lint_builder', 'custom_lint_builder.dart');
    _addPackage('flutter', 'widgets.dart');
    _addPackage('flutter_bloc', 'flutter_bloc.dart');
    _addPackage('flutter_riverpod', 'flutter_riverpod.dart');
    _addPackage('flutter_skill_lints', 'flutter_skill_lints.dart');
    _addPackage('get_it', 'get_it.dart');
    _addPackage('provider', 'provider.dart');
    super.setUp();
  }

  void _addPackage(String packageName, String fileName) {
    newPackage(packageName).addFile('lib/$fileName', '');
  }
}

@reflectiveTest
final class AvoidBannedFileNamesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedFileNames();
    super.setUp();
  }

  Future<void> test_uppercaseBasename_lint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/UserProfile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_spaceInBasename_lint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(0, 'class'.length)]);
  }

  Future<void> test_snakeCaseBasename_noLint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/user_profile.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> test_generatedBasename_noLint() async {
    const source = r'''
class UserProfile {}
''';
    final path = '$testPackageRootPath/lib/UserProfile.g.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}
