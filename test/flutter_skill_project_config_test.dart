// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/flutter_skill_project_config.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSkillProjectConfigTest);
  });
}

@reflectiveTest
final class FlutterSkillProjectConfigTest extends AnalysisRuleTest {
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

  ExpectedDiagnostic projectLint(String name) => lint(0, 1, name: name);

  Future<void> test_reportsProjectConfigGaps() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
plugins:
  flutter_skill_lints:
    version: ^0.1.0
  many_lints:
    path: ../many_lints

analyzer:
  language:
    strict-casts: true
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
      projectLint('cfg_freezed_annotation_ignore'),
    ]);
  }

  Future<void> test_reportsBuildYamlExplicitToJsonGap() async {
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

  Future<void> test_reportsFlutterAppMissingDeterministicE2eEntrypoint() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dependencies:
  flutter:
    sdk: flutter
''');
    _writeCanonicalAnalysisOptions();

    await assertDiagnostics('void main() {}', [projectLint('cfg_e2e_entrypoint')]);
  }

  Future<void> test_allowsFlutterAppWithDeterministicE2eEntrypoint() async {
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

  Future<void> test_reportsProhibitedPubspecLintPackages() async {
    newFile('$testPackageRootPath/pubspec.yaml', r'''
name: test
environment:
  sdk: ^3.10.0
dev_dependencies: {"custom_lint": ^0.8.1}
''');
    _writeCanonicalAnalysisOptions();

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> test_allowsNestedFunctionAnalysisOptionsWithoutPluginBlock() async {
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

  Future<void> test_reportsProhibitedLocalPluginPathSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
    "path": ../flutter_skill_lints
  riverpod_lint: 3.1.4-dev.3

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    invalid_annotation_target: ignore

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
    - avoid_redundant_argument_values
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> test_reportsCanonicalErrorAndLintGaps() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
    version: ^0.1.0
  riverpod_lint: 3.1.4-dev.3

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore

linter:
  rules:
    - flutter_skill_project_config
    - avoid_dynamic_calls
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

  Future<void> test_reportsProhibitedLocalPluginGitSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
    version: ^0.1.0
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
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    invalid_annotation_target: ignore

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
    - avoid_redundant_argument_values
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> test_reportsProhibitedFlowStyleLocalPluginSources() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins: {flutter_skill_lints: {path: ../flutter_skill_lints}, riverpod_lint: 3.1.4-dev.3}

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    invalid_annotation_target: ignore

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
    - avoid_redundant_argument_values
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [
      projectLint('cfg_analysis_options_canonical'),
      projectLint('cfg_prohibited_lint_plugins'),
    ]);
  }

  Future<void> test_reportsQuotedProhibitedAnalysisOptionPlugins() async {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
    version: ^0.1.0
  riverpod_lint: 3.1.4-dev.3
  "many_lints": ^0.4.0

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    invalid_annotation_target: ignore

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
    - avoid_redundant_argument_values
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');

    await assertDiagnostics('void main() {}', [projectLint('cfg_prohibited_lint_plugins')]);
  }

  Future<void> test_allowsCanonicalConfig() async {
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

  void _writeCanonicalAnalysisOptions() {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  flutter_skill_lints:
    version: ^0.1.0
  riverpod_lint: 3.1.4-dev.3

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.gr.dart"
    - "**/*.arb"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    invalid_annotation_target: ignore

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
    - avoid_redundant_argument_values
    - flutter_skill_project_config
    - avoid_dynamic_calls
    - unawaited_futures
    - discarded_futures
    - avoid_void_async
    - avoid_print
    - cancel_subscriptions
    - close_sinks
''');
  }
}
