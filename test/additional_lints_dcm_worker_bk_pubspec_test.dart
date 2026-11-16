import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_any_version.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_dependency_overrides.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_publish_to_none.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAnyVersionTest>('AvoidAnyVersionTest', AvoidAnyVersionTest.new, {
    'test_allowsPinnedDependencies_noLint': (t) => t._allowsPinnedDependenciesNoLint(),
    'test_reportsAnyInDependencies_lint': (t) => t._reportsAnyInDependenciesLint(),
    'test_reportsQuotedAnyInDevDependencies_lint': (t) =>
        t._reportsQuotedAnyInDevDependenciesLint(),
    'test_allowsPathDependencyWithoutVersionAny_noLint': (t) =>
        t._allowsPathDependencyWithoutVersionAnyNoLint(),
    'test_usesErrorSeverity': (t) => t._usesErrorSeverity(),
  });
  analysisRuleSuite<AvoidDependencyOverridesTest>(
    'AvoidDependencyOverridesTest',
    AvoidDependencyOverridesTest.new,
    {
      'test_allowsNoDependencyOverrides_noLint': (t) => t._allowsNoDependencyOverridesNoLint(),
      'test_allowsEmptyDependencyOverrides_noLint': (t) =>
          t._allowsEmptyDependencyOverridesNoLint(),
      'test_allowsResolvedLockfileWithoutOverride_noLint': (t) =>
          t._allowsResolvedLockfileWithoutOverrideNoLint(),
      'test_reportsDependencyOverrides_lint': (t) => t._reportsDependencyOverridesLint(),
      'test_reportsInlineDependencyOverrides_lint': (t) =>
          t._reportsInlineDependencyOverridesLint(),
      'test_allowsEmptyPubspecOverrides_noLint': (t) => t._allowsEmptyPubspecOverridesNoLint(),
      'test_reportsPubspecOverrides_lint': (t) => t._reportsPubspecOverridesLint(),
      'test_reportsAuditedPubspecOverride_lint': (t) => t._reportsAuditedPubspecOverrideLint(),
      'test_reportsWorkspaceMemberOverride_lint': (t) => t._reportsWorkspaceMemberOverrideLint(),
      'test_reportsWorkspaceGlobMemberOverride_lint': (t) =>
          t._reportsWorkspaceGlobMemberOverrideLint(),
      'test_usesErrorSeverity': (t) => t._usesErrorSeverity(),
    },
  );
  analysisRuleSuite<PreferPublishToNoneTest>(
    'PreferPublishToNoneTest',
    PreferPublishToNoneTest.new,
    {
      'test_allowsPublishToNone_noLint': (t) => t._allowsPublishToNoneNoLint(),
      'test_allowsMissingPublishTo_noLint': (t) => t._allowsMissingPublishToNoLint(),
      'test_reportsNonNonePublishTarget_lint': (t) => t._reportsNonNonePublishTargetLint(),
      'test_reportsQuotedNonNonePublishTarget_lint': (t) =>
          t._reportsQuotedNonNonePublishTargetLint(),
      'test_usesInfoSeverity': (t) => t._usesInfoSeverity(),
    },
  );
}

final class AvoidAnyVersionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAnyVersion();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> _allowsPinnedDependenciesNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> _reportsAnyInDependenciesLint() async {
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

  Future<void> _reportsQuotedAnyInDevDependenciesLint() async {
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

  Future<void> _allowsPathDependencyWithoutVersionAnyNoLint() async {
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

  Future<void> _usesErrorSeverity() async {
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

final class AvoidDependencyOverridesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDependencyOverrides();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> _allowsNoDependencyOverridesNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> _allowsEmptyDependencyOverridesNoLint() async {
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

  Future<void> _allowsResolvedLockfileWithoutOverrideNoLint() async {
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

  Future<void> _reportsDependencyOverridesLint() async {
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

  Future<void> _reportsInlineDependencyOverridesLint() async {
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

  Future<void> _allowsEmptyPubspecOverridesNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec_overrides.yaml', 'dependency_overrides: {}\n');

    await assertNoDiagnostics('library;');
  }

  Future<void> _reportsPubspecOverridesLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    newFile('$testPackageRootPath/pubspec_overrides.yaml', '''
dependency_overrides:
  analyzer: 14.1.0
''');

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> _reportsAuditedPubspecOverrideLint() async {
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

  Future<void> _reportsWorkspaceMemberOverrideLint() async {
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

  Future<void> _reportsWorkspaceGlobMemberOverrideLint() async {
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

  Future<void> _usesErrorSeverity() async {
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

final class PreferPublishToNoneTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPublishToNone();
    super.setUp();
    newFile('$testPackageRootPath/lib/test.dart', 'library;');
  }

  Future<void> _allowsPublishToNoneNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('library;');
  }

  Future<void> _allowsMissingPublishToNoLint() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec(publishToLine: ''));

    await assertNoDiagnostics('library;');
  }

  Future<void> _reportsNonNonePublishTargetLint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(publishToLine: 'publish_to: https://pub.dev'),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> _reportsQuotedNonNonePublishTargetLint() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(publishToLine: 'publish_to: "https://pub.dev" # public package'),
    );

    await assertDiagnostics('library;', [lint(0, 'library'.length)]);
  }

  Future<void> _usesInfoSeverity() async {
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
