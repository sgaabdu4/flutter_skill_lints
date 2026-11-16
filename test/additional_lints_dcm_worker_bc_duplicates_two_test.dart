import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_initializers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_mixins.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_patterns.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidDuplicateInitializersTest>(
    'AvoidDuplicateInitializersTest',
    AvoidDuplicateInitializersTest.new,
    {
      'test_duplicateFieldInitializer_lint': (t) => t._duplicateFieldInitializerLint(),
      'test_distinctFieldInitializers_noLint': (t) => t._distinctFieldInitializersNoLint(),
      'test_severity_error': (t) => t._severityError(),
    },
  );
  analysisRuleSuite<AvoidDuplicateMixinsTest>(
    'AvoidDuplicateMixinsTest',
    AvoidDuplicateMixinsTest.new,
    {
      'test_duplicateMixin_lint': (t) => t._duplicateMixinLint(),
      'test_distinctMixins_noLint': (t) => t._distinctMixinsNoLint(),
      'test_severity_error': (t) => t._severityError(),
    },
  );
  analysisRuleSuite<AvoidDuplicatePatternsTest>(
    'AvoidDuplicatePatternsTest',
    AvoidDuplicatePatternsTest.new,
    {
      'test_duplicateLiteralAlternative_lint': (t) => t._duplicateLiteralAlternativeLint(),
      'test_duplicateIdentifierAlternative_lint': (t) => t._duplicateIdentifierAlternativeLint(),
      'test_nonConstantIdentifierPatterns_noLint': (t) => t._nonConstantIdentifierPatternsNoLint(),
      'test_severity_error': (t) => t._severityError(),
    },
  );
}

final class AvoidDuplicateInitializersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateInitializers();
    super.setUp();
  }

  Future<void> _duplicateFieldInitializerLint() async {
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

  Future<void> _distinctFieldInitializersNoLint() async {
    await assertNoDiagnostics(r'''
class User {
  final int id;
  final String name;

  User() : id = 1, name = 'a';
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidDuplicateInitializers.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class AvoidDuplicateMixinsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateMixins();
    super.setUp();
  }

  Future<void> _duplicateMixinLint() async {
    const source = r'''
mixin First {}
mixin Second {}

class User with First, Second, First {}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('First'), 'First'.length)]);
  }

  Future<void> _distinctMixinsNoLint() async {
    await assertNoDiagnostics(r'''
mixin First {}
mixin Second {}

class User with First, Second {}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidDuplicateMixins.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class AvoidDuplicatePatternsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicatePatterns();
    super.setUp();
  }

  Future<void> _duplicateLiteralAlternativeLint() async {
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

  Future<void> _duplicateIdentifierAlternativeLint() async {
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

  Future<void> _nonConstantIdentifierPatternsNoLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) {
  return switch (value) {
    [final a] || [final a] => '$a',
    _ => 'other',
  };
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidDuplicatePatterns.code.severity, DiagnosticSeverity.ERROR);
  }
}
