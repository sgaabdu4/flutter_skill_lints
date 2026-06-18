// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_initializers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_mixins.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_patterns.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDuplicateInitializersTest);
    defineReflectiveTests(AvoidDuplicateMixinsTest);
    defineReflectiveTests(AvoidDuplicatePatternsTest);
  });
}

@reflectiveTest
final class AvoidDuplicateInitializersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateInitializers();
    super.setUp();
  }

  Future<void> test_duplicateFieldInitializer_lint() async {
    const source = r'''
// ignore_for_file: field_initialized_by_multiple_initializers

class User {
  final int id;
  final String name;

  User() : id = 1, name = 'a', id = 2;
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('id = 2'), 'id'.length)]);
  }

  Future<void> test_distinctFieldInitializers_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  final int id;
  final String name;

  User() : id = 1, name = 'a';
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidDuplicateInitializers.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidDuplicateMixinsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateMixins();
    super.setUp();
  }

  Future<void> test_duplicateMixin_lint() async {
    const source = r'''
mixin First {}
mixin Second {}

class User with First, Second, First {}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('First'), 'First'.length)]);
  }

  Future<void> test_distinctMixins_noLint() async {
    await assertNoDiagnostics(r'''
mixin First {}
mixin Second {}

class User with First, Second {}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidDuplicateMixins.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidDuplicatePatternsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicatePatterns();
    super.setUp();
  }

  Future<void> test_duplicateLiteralAlternative_lint() async {
    const source = r'''
String label(Object value) {
  return switch (value) {
    1 || 2 || 1 => 'small',
    _ => 'other',
  };
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('1 =>'), '1'.length)]);
  }

  Future<void> test_duplicateIdentifierAlternative_lint() async {
    const source = r'''
enum Status { ready, done, pending }

String label(Status value) {
  return switch (value) {
    Status.ready || Status.done || Status.ready => 'ready',
    _ => 'other',
  };
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('Status.ready'), 'Status.ready'.length),
    ]);
  }

  Future<void> test_nonConstantIdentifierPatterns_noLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) {
  return switch (value) {
    [final a] || [final a] => '$a',
    _ => 'other',
  };
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidDuplicatePatterns.code.severity, DiagnosticSeverity.ERROR);
  }
}
