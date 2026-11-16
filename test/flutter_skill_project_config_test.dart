import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/flutter_skill_project_config.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_FlutterSkillProjectConfigTest>(
    'FlutterSkillProjectConfigTest',
    _FlutterSkillProjectConfigTest.new,
    _FlutterSkillProjectConfigTest._allCases,
  );
}

final class _FlutterSkillProjectConfigTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_FlutterSkillProjectConfigTest)> get _allCases =>
      caseSet<_FlutterSkillProjectConfigTest>(
        parent: const {},
        own: {
          'test_reportsProjectConfigGaps': (t) => t._reportsProjectConfigGaps(),
          'test_reportsBuildYamlExplicitToJsonGap': (t) => t._reportsBuildYamlExplicitToJsonGap(),
          'test_reportsFlutterAppMissingDeterministicE2eEntrypoint': (t) =>
              t._reportsFlutterAppMissingDeterministicE2eEntrypoint(),
          'test_allowsIntegrationTestWithoutDriverEntrypoint': (t) =>
              t._allowsIntegrationTestWithoutDriverEntrypoint(),
          'test_skipsProjectConfigDiagnosticsForNonAnchorFiles': (t) =>
              t._skipsProjectConfigDiagnosticsForNonAnchorFiles(),
          'test_allowsFlutterAppWithDeterministicE2eEntrypoint': (t) =>
              t._allowsFlutterAppWithDeterministicE2eEntrypoint(),
          'test_allowsFlutterAppWithQualifiedDeterministicE2eEntrypoint': (t) =>
              t._allowsFlutterAppWithQualifiedDeterministicE2eEntrypoint(),
          'test_reportsProhibitedPubspecLintPackages': (t) =>
              t._reportsProhibitedPubspecLintPackages(),
          'test_allowsNestedFunctionAnalysisOptionsWithoutPluginBlock': (t) =>
              t._allowsNestedFunctionAnalysisOptionsWithoutPluginBlock(),
          'test_allowsFlutterSkillLintsLocalPluginPathSource': (t) =>
              t._allowsFlutterSkillLintsLocalPluginPathSource(),
          'test_reportsProhibitedOtherLocalPluginPathSources': (t) =>
              t._reportsProhibitedOtherLocalPluginPathSources(),
          'test_reportsCanonicalErrorAndLintGaps': (t) => t._reportsCanonicalErrorAndLintGaps(),
          'test_reportsProhibitedLocalPluginGitSources': (t) =>
              t._reportsProhibitedLocalPluginGitSources(),
          'test_reportsProhibitedFlowStyleLocalPluginSources': (t) =>
              t._reportsProhibitedFlowStyleLocalPluginSources(),
          'test_reportsQuotedProhibitedAnalysisOptionPlugins': (t) =>
              t._reportsQuotedProhibitedAnalysisOptionPlugins(),
          'test_allowsCanonicalConfigWithoutDeprecatedLints': (t) =>
              t._allowsCanonicalConfigWithoutDeprecatedLints(),
          'test_allowsMissingRiverpodLintWithoutRiverpodDependency': (t) =>
              t._allowsMissingRiverpodLintWithoutRiverpodDependency(),
          'test_reportsMissingRiverpodLintWithRiverpodDependency': (t) =>
              t._reportsMissingRiverpodLintWithRiverpodDependency(),
          'test_allowsMissingArbExcludeWithoutArbFiles': (t) =>
              t._allowsMissingArbExcludeWithoutArbFiles(),
          'test_reportsMissingArbExcludeWithArbFiles': (t) =>
              t._reportsMissingArbExcludeWithArbFiles(),
          'test_acceptsRuleMapFormLints': (t) => t._acceptsRuleMapFormLints(),
          'test_followsIncludedSiblingOptionsFile': (t) => t._followsIncludedSiblingOptionsFile(),
          'test_followsIncludedParentOptionsFile': (t) => t._followsIncludedParentOptionsFile(),
          'test_reportsGapsInsideIncludedOptionsFile': (t) =>
              t._reportsGapsInsideIncludedOptionsFile(),
          'test_followsListFormInclude': (t) => t._followsListFormInclude(),
          'test_followsListIncludeWithCommentsAndQuotes': (t) =>
              t._followsListIncludeWithCommentsAndQuotes(),
          'test_ignoresIncludeTextInsideComments': (t) => t._ignoresIncludeTextInsideComments(),
          'test_survivesUnreadableIncludedOptionsFile': (t) =>
              t._survivesUnreadableIncludedOptionsFile(),
          'test_allowsMissingArbExcludeWhenArbFilesAreInToolFolders': (t) =>
              t._allowsMissingArbExcludeWhenArbFilesAreInToolFolders(),
          'test_followsFlowListInclude': (t) => t._followsFlowListInclude(),
        },
      );

  @override
  void setUp() {
    rule = FlutterSkillProjectConfig();
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
''');
    super.setUp();
  }

  T projectLint<T>(String name) => lint(0, 1, name: name) as T;

  Future<void> _reportsProjectConfigGaps() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
plugins:
  flutter_skill_lints:
  many_lints:
    path: ../many_lints

analyzer:
  language:
  errors:
    missing_return: error

linter:
  rules:
    - flutter_skill_project_config
    - avoid_print
''');

    await assertDiagnostics('void main() {}', [
      projectLint('cfg_analysis_options_canonical'),
      projectLint('cfg_prohibited_lint_plugins'),
      projectLint('cfg_strict_analysis'),
      projectLint('cfg_required_lints'),
      projectLint('cfg_generated_exclude'),
    ]);
  }

  Future<void> _reportsBuildYamlExplicitToJsonGap() async {
    _writeCanonicalAnalysisOptions();

    await assertDiagnostics(
      r'''
class User {
  User._();
  factory User.fromJson(Map<String, dynamic> json) => User._();
}
''',
      [projectLint('cfg_explicit_to_json')],
    );
  }

  Future<void> _reportsFlutterAppMissingDeterministicE2eEntrypoint() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
''');
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/test_driver/app_test.dart', r'''
import 'package:flutter_driver/flutter_driver.dart';
void main() { FlutterDriver.connect(); }
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_e2e_entrypoint')]);
  }

  Future<void> _allowsIntegrationTestWithoutDriverEntrypoint() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  integration_test:
    sdk: flutter
''');
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/integration_test/app_test.dart', r'''
import 'package:integration_test/integration_test.dart';
void main() { IntegrationTestWidgetsFlutterBinding.ensureInitialized(); }
''');
    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _skipsProjectConfigDiagnosticsForNonAnchorFiles() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
''');
    newFile('$testPackageRootPath/lib/main.dart', 'void main() {}');
    final filePath = '$testPackageRootPath/lib/feature.dart';
    newFile(filePath, 'void helper() {}');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsFlutterAppWithDeterministicE2eEntrypoint() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
''');
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/lib/main_dev.dart', r'''
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(App());
}

void runApp(Object app) {}
Object App() => Object();
''');

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _allowsFlutterAppWithQualifiedDeterministicE2eEntrypoint() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
''');
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/lib/main_dev.dart', r'''
import 'package:flutter_driver/driver_extension.dart';
import 'package:test/main.dart' as app;

Future<void> main() async {
  enableFlutterDriverExtension();
  await app.runSampleApp(overrides: _e2eOverrides);
}

const _e2eOverrides = <Object>[];
''');

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _reportsProhibitedPubspecLintPackages() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dev_dependencies: {"custom_lint": ^0.8.1}
''');
    _writeCanonicalAnalysisOptions();

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> _allowsNestedFunctionAnalysisOptionsWithoutPluginBlock() async {
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/functions/shared/analysis_options.yaml', r'''
linter:
  rules:
    avoid_dynamic_calls: false
''');
    final filePath = '$testPackageRootPath/functions/shared/lib/http.dart';
    newFile(filePath, 'void main() {}');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsFlutterSkillLintsLocalPluginPathSource() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: ^3.1.9
  flutter_skill_lints:
    "path": ../flutter_skill_lints

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _reportsProhibitedOtherLocalPluginPathSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
  riverpod_lint:
    "path": ../riverpod_lint

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> _reportsCanonicalErrorAndLintGaps() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: ^3.1.9
  flutter_skill_lints: ^0.11.2

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:

linter:
  rules:
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [
      projectLint('cfg_strict_analysis'),
      projectLint('cfg_required_lints'),
    ]);
  }

  Future<void> _reportsProhibitedLocalPluginGitSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
  riverpod_lint:
    "git":
      url: https://example.invalid/riverpod_lint.git

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> _reportsProhibitedFlowStyleLocalPluginSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins: {flutter_skill_lints: {path: ../flutter_skill_lints}, riverpod_lint: ^3.1.9}

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_analysis_options_canonical')]);
  }

  Future<void> _reportsQuotedProhibitedAnalysisOptionPlugins() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: ^3.1.9
  flutter_skill_lints: ^0.11.2
  "many_lints": ^0.4.0

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> _allowsCanonicalConfigWithoutDeprecatedLints() async {
    _writeCanonicalAnalysisOptions();
    newFile('$testPackageRootPath/build.yaml', r'''
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
''');

    await assertNoDiagnostics(r'''
class User {
  User._();
  factory User.fromJson(Map<String, dynamic> json) => User._();
}
''');
  }

  Future<void> _allowsMissingRiverpodLintWithoutRiverpodDependency() async {
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      _canonicalOptions.replaceAll('  riverpod_lint: ^3.1.9\n', ''),
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _reportsMissingRiverpodLintWithRiverpodDependency() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter_riverpod: ^3.0.0
''');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      _canonicalOptions.replaceAll('  riverpod_lint: ^3.1.9\n', ''),
    );

    await assertDiagnostics('void main() {}', [projectLint('cfg_analysis_options_canonical')]);
  }

  Future<void> _allowsMissingArbExcludeWithoutArbFiles() async {
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      _canonicalOptions.replaceAll('    - "**/*.arb"\n', ''),
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _reportsMissingArbExcludeWithArbFiles() async {
    newFile('$testPackageRootPath/lib/l10n/app_en.arb', '{}');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      _canonicalOptions.replaceAll('    - "**/*.arb"\n', ''),
    );

    await assertDiagnostics('void main() {}', [projectLint('cfg_generated_exclude')]);
  }

  Future<void> _acceptsRuleMapFormLints() async {
    final mapForm = _canonicalOptions.replaceAllMapped(
      RegExp(r'^    - (\w+)$', multiLine: true),
      (match) => '    ${match[1]}: true',
    );
    newFile('$testPackageRootPath/analysis_options.yaml', mapForm);

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _followsIncludedSiblingOptionsFile() async {
    newFile('$testPackageRootPath/base_options.yaml', _canonicalOptions);
    newFile('$testPackageRootPath/analysis_options.yaml', 'include: base_options.yaml\n');

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _followsIncludedParentOptionsFile() async {
    newFile('/home/root_options.yaml', _canonicalOptions);
    newFile('$testPackageRootPath/analysis_options.yaml', 'include: ../root_options.yaml\n');

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _reportsGapsInsideIncludedOptionsFile() async {
    newFile(
      '$testPackageRootPath/base_options.yaml',
      _canonicalOptions.replaceAll('    - avoid_print\n', ''),
    );
    newFile('$testPackageRootPath/analysis_options.yaml', 'include: base_options.yaml\n');

    await assertDiagnostics('void main() {}', [projectLint('cfg_required_lints')]);
  }

  Future<void> _followsListFormInclude() async {
    newFile(
      '$testPackageRootPath/base_options.yaml',
      _canonicalOptions.replaceAll('    - avoid_print\n', ''),
    );
    newFile('$testPackageRootPath/extra_options.yaml', 'linter:\n  rules:\n    - avoid_print\n');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      'include:\n  - base_options.yaml\n  - extra_options.yaml\n',
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _followsFlowListInclude() async {
    newFile(
      '$testPackageRootPath/base_options.yaml',
      _canonicalOptions.replaceAll('    - avoid_print\n', ''),
    );
    newFile('$testPackageRootPath/extra_options.yaml', 'linter:\n  rules:\n    - avoid_print\n');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      'include: [base_options.yaml, extra_options.yaml]\n',
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _allowsMissingArbExcludeWhenArbFilesAreInToolFolders() async {
    for (final folder in [
      '.fvm/flutter_sdk/packages/flutter_tools',
      'ios/.symlinks/plugins/some_plugin',
      '.pub-cache/hosted/some_package',
      'ios/Pods/SomePod',
      'android/.gradle/caches',
      'macos/Pods/SomePod',
    ]) {
      newFile('$testPackageRootPath/$folder/app_en.arb', '{}');
    }
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      _canonicalOptions.replaceAll('    - "**/*.arb"\n', ''),
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _followsListIncludeWithCommentsAndQuotes() async {
    newFile(
      '$testPackageRootPath/base_options.yaml',
      _canonicalOptions.replaceAll('    - avoid_print\n', ''),
    );
    newFile('$testPackageRootPath/extra_options.yaml', 'linter:\n  rules:\n    - avoid_print\n');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      "include:  # shared options\n  # the base set\n  - 'base_options.yaml'\n\n  # lints split out\n  - \"extra_options.yaml\" # extra\n",
    );

    await assertNoDiagnostics('void main() {}');
  }

  Future<void> _ignoresIncludeTextInsideComments() async {
    newFile('$testPackageRootPath/base_options.yaml', _canonicalOptions);
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      '# include: base_options.yaml\nplugins:\n  flutter_skill_lints:\nlinter:\n  rules:\n    - flutter_skill_project_config\n',
    );

    await assertDiagnostics('void main() {}', [
      projectLint('cfg_strict_analysis'),
      projectLint('cfg_required_lints'),
      projectLint('cfg_generated_exclude'),
    ]);
  }

  Future<void> _survivesUnreadableIncludedOptionsFile() async {
    newFile('$testPackageRootPath/base_options.yaml', 'plugins: [\n  - : :\n');
    newFile(
      '$testPackageRootPath/analysis_options.yaml',
      'include: base_options.yaml\nlinter:\n  rules:\n    - flutter_skill_project_config\n',
    );

    await assertDiagnostics('void main() {}', [
      projectLint('cfg_analysis_options_canonical'),
      projectLint('cfg_strict_analysis'),
      projectLint('cfg_required_lints'),
      projectLint('cfg_generated_exclude'),
    ]);
  }

  void _writeCanonicalAnalysisOptions() {
    newFile('$testPackageRootPath/analysis_options.yaml', _canonicalOptions);
  }

  static const _canonicalOptions = r'''
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: ^3.1.9
  flutter_skill_lints: ^0.11.2

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-inference: true
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_use_package_imports
    - require_trailing_commas
    - prefer_single_quotes
    - directives_ordering
    - avoid_multiple_declarations_per_line
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_locals
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - no_dynamic_casts
    - no_raw_types
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''';
}
