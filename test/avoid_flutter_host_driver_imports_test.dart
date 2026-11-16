import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/avoid_flutter_host_driver_imports.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidFlutterHostDriverImportsTest>(
    'AvoidFlutterHostDriverImportsTest',
    AvoidFlutterHostDriverImportsTest.new,
    {
      'test_reportsFlutterUiImport_lint': (t) => t._reportsFlutterUiImportLint(),
      'test_reportsAppImport_lint': (t) => t._reportsAppImportLint(),
      'test_reportsTargetDriverExtensionImport_lint': (t) =>
          t._reportsTargetDriverExtensionImportLint(),
      'test_reportsTransitiveFlutterUiImport_lint': (t) =>
          t._reportsTransitiveFlutterUiImportLint(),
      'test_allowsHostDriverImports_noLint': (t) => t._allowsHostDriverImportsNoLint(),
      'test_ignoresTargetIntegrationTestFile_noLint': (t) =>
          t._ignoresTargetIntegrationTestFileNoLint(),
    },
  );
}

final class AvoidFlutterHostDriverImportsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFlutterHostDriverImports();
    newPackage('flutter').addFile('lib/widgets.dart', 'class Widget {}');
    newPackage('flutter_driver').addFile('lib/driver_extension.dart', '');
    newPackage('flutter_driver').addFile('lib/flutter_driver.dart', '');
    newPackage('integration_test').addFile('lib/integration_test.dart', '');
    newPackage('integration_test').addFile('lib/integration_test_driver.dart', '');
    newPackage('host_helper').addFile('lib/helper.dart', '''
import 'package:flutter/widgets.dart';

Widget makeWidget() => Widget();
''');
    super.setUp();
    newFile('$testPackageRootPath/pubspec.yaml', '''
name: sample_app
environment:
  sdk: ^3.10.0
''');
    newFile('$testPackageRootPath/lib/app.dart', 'library;');
  }

  Future<void> _reportsFlutterUiImportLint() async {
    const source =
        "// ignore_for_file: uri_does_not_exist, unused_import\nimport 'package:flutter/widgets.dart';\n";
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:flutter/widgets.dart'"),
        "'package:flutter/widgets.dart'".length,
      ),
    ]);
  }

  Future<void> _reportsAppImportLint() async {
    const source =
        "// ignore_for_file: uri_does_not_exist, unused_import\nimport 'package:sample_app/app.dart';\n";
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(source.indexOf("'package:sample_app/app.dart'"), "'package:sample_app/app.dart'".length),
    ]);
  }

  Future<void> _reportsTargetDriverExtensionImportLint() async {
    const source =
        "// ignore_for_file: uri_does_not_exist, unused_import\nimport 'package:flutter_driver/driver_extension.dart';\n";
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf("'package:flutter_driver/driver_extension.dart'"),
        "'package:flutter_driver/driver_extension.dart'".length,
      ),
    ]);
  }

  Future<void> _reportsTransitiveFlutterUiImportLint() async {
    const source = "// ignore_for_file: unused_import\nimport 'package:host_helper/helper.dart';\n";
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf("import '"), 'import'.length)]);
  }

  Future<void> _allowsHostDriverImportsNoLint() async {
    const source = '''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';
''';
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _ignoresTargetIntegrationTestFileNoLint() async {
    const source =
        "// ignore_for_file: uri_does_not_exist, unused_import\nimport 'package:flutter/widgets.dart';\n";
    final path = '$testPackageRootPath/integration_test/app_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, []);
  }
}
