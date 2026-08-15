// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_any_version.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_dependency_overrides.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_publish_to_none.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnyVersionTest);
    defineReflectiveTests(AvoidDependencyOverridesTest);
    defineReflectiveTests(PreferPublishToNoneTest);
  });
}

@reflectiveTest
final class AvoidAnyVersionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAnyVersion();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> test_allowsPinnedDependencies_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> test_reportsAnyInDependencies_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        dependencies: '''
dependencies:
  analyzer: any
dev_dependencies:
  test: ^1.30.0
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsQuotedAnyInDevDependencies_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        dependencies: '''
dependencies:
  analyzer: ^12.1.0
dev_dependencies:
  test: "any" # temporary
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_allowsPathDependencyWithoutVersionAny_noLint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        dependencies: '''
dependencies:
  local_package:
    path: ../local_package
dev_dependencies:
  test: ^1.30.0
''',
      ),
    );

    await assertNoDiagnostics('library;');
  }

  Future<void> test_usesErrorSeverity() async {
    expect(AvoidAnyVersion.code.severity, DiagnosticSeverity.ERROR);
  }

  String _pubspec({
    String dependencies = '''
dependencies:
  analyzer: ^12.1.0
dev_dependencies:
  test: ^1.30.0
''',
  }) {
    return '''
name: test
publish_to: none
environment:
  sdk: ^3.10.0
$dependencies
''';
  }
}

@reflectiveTest
final class AvoidDependencyOverridesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDependencyOverrides();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> test_allowsNoDependencyOverrides_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> test_allowsEmptyDependencyOverrides_noLint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        overrides: '''
dependency_overrides: {}
''',
      ),
    );

    await assertNoDiagnostics('library;');
  }

  Future<void> test_allowsResolvedLockfileWithoutOverride_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec.lock', '''
packages:
  analyzer:
    dependency: "direct main"
    description:
      name: analyzer
      url: https://pub.dev
    source: hosted
    version: 14.1.0
sdks:
  dart: ">=3.10.0 <4.0.0"
''');

    await assertNoDiagnostics('library;');
  }

  Future<void> test_reportsDependencyOverrides_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        overrides: '''
dependency_overrides:
  analyzer: ^12.0.0
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsInlineDependencyOverrides_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        overrides: '''
dependency_overrides: { analyzer: ^12.0.0 }
''',
      ),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_allowsEmptyPubspecOverrides_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec_overrides.yaml', 'dependency_overrides: {}\n');

    await assertNoDiagnostics('library;');
  }

  Future<void> test_reportsPubspecOverrides_lint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec_overrides.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
''');

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsAuditedPubspecOverride_lint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec_overrides.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
''');
    newFile('$testPackageRootPath/tool/dependency_override_audit.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
proof:
  - dart run build_runner build
  - dart test
''');

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsWorkspaceMemberOverride_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(workspace: 'workspace:\n  - packages/member'),
    );
    newFile('$testPackageRootPath/packages/member/pubspec.yaml', '''
name: member
resolution: workspace
environment:
  sdk: ^3.10.0
''');
    newFile('$testPackageRootPath/packages/member/pubspec_overrides.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
''');

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsWorkspaceGlobMemberOverride_lint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec(workspace: 'workspace:\n  - packages/*'));
    newFile('$testPackageRootPath/packages/member/pubspec.yaml', '''
name: member
resolution: workspace
environment:
  sdk: ^3.10.0
''');
    newFile('$testPackageRootPath/packages/member/pubspec_overrides.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
''');

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_usesErrorSeverity() async {
    expect(AvoidDependencyOverrides.code.severity, DiagnosticSeverity.ERROR);
  }

  String _pubspec({String overrides = '', String workspace = ''}) {
    return '''
name: test
publish_to: none
environment:
  sdk: ^3.10.0
dependencies:
  analyzer: ^12.1.0
dev_dependencies:
  test: ^1.30.0
$workspace
$overrides
''';
  }
}

@reflectiveTest
final class PreferPublishToNoneTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPublishToNone();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> test_allowsPublishToNone_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> test_allowsMissingPublishTo_noLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec(publishToLine: ''));

    await assertNoDiagnostics('library;');
  }

  Future<void> test_reportsNonNonePublishTarget_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(publishToLine: 'publish_to: https://pub.dev'),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_reportsQuotedNonNonePublishTarget_lint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(publishToLine: 'publish_to: "https://pub.dev" # public package'),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> test_usesInfoSeverity() async {
    expect(PreferPublishToNone.code.severity, DiagnosticSeverity.INFO);
  }

  String _pubspec({String publishToLine = 'publish_to: none'}) {
    return '''
name: test
$publishToLine
environment:
  sdk: ^3.10.0
dependencies:
  analyzer: ^12.1.0
dev_dependencies:
  test: ^1.30.0
''';
  }
}
