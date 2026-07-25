// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/flutter_skill_project_config.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecProjectConfigLintTest);
  });
}

@reflectiveTest
final class PubspecProjectConfigLintTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = FlutterSkillProjectConfig();
    super.setUp();
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());
    _writeCanonicalAnalysisOptions();
  }

  ExpectedDiagnostic projectLint(String name) => lint(0, 1, name: name);

  Future<void> test_reportsAnyDependencyVersions() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        dependencies: '''
dependencies:
  path: any
dev_dependencies:
  test: "any"
''',
      ),
    );

    await assertDiagnostics('void main() {}', [projectLint('avoid_any_version')]);
  }

  Future<void> test_reportsDependencyOverrides() async {
    newFile(
      '$testPackageRootPath/pubspec.yaml',
      _pubspec(
        dependencies: '''
dependencies:
  path: ^1.9.0
dependency_overrides:
  path: ^1.8.0
''',
      ),
    );

    await assertDiagnostics('void main() {}', [projectLint('avoid_dependency_overrides')]);
  }

  Future<void> test_reportsNonNonePublishTarget() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec(publishTo: 'https://pub.dev'));

    await assertDiagnostics('void main() {}', [projectLint('prefer_publish_to_none')]);
  }

  Future<void> test_allowsPinnedDependenciesWithoutOverrides() async {
    newFile('$testPackageRootPath/pubspec.yaml', _pubspec());

    await assertNoDiagnostics('void main() {}');
  }

  String _pubspec({
    String publishTo = 'none',
    String dependencies = '''
dependencies:
  path: ^1.9.0
dev_dependencies:
  test: ^1.30.0
''',
  }) {
    return '''
name: test
publish_to: $publishTo
environment:
  sdk: ^3.10.0
$dependencies
''';
  }

  void _writeCanonicalAnalysisOptions() {
    newFile('$testPackageRootPath/analysis_options.yaml', r'''
include: package:flutter_lints/flutter.yaml

plugins:
  riverpod_lint: 3.1.4
  flutter_skill_lints:

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
    - always_declare_return_types
    - type_annotate_public_apis
    - avoid_positional_boolean_parameters
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_private_typedef_functions
    - avoid_returning_this
    - avoid_setters_without_getters
    - prefer_mixin
    - use_to_and_as_if_applicable
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
