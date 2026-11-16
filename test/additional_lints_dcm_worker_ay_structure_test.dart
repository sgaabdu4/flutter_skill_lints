import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_extensions_on_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_non_empty_constructor_bodies.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidNonEmptyConstructorBodiesTest>(
    'AvoidNonEmptyConstructorBodiesTest',
    _AvoidNonEmptyConstructorBodiesTest.new,
    _AvoidNonEmptyConstructorBodiesTest._allCases,
  );
  analysisRuleSuite<_AvoidExtensionsOnRecordsTest>(
    'AvoidExtensionsOnRecordsTest',
    _AvoidExtensionsOnRecordsTest.new,
    _AvoidExtensionsOnRecordsTest._allCases,
  );
}

final class _AvoidNonEmptyConstructorBodiesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidNonEmptyConstructorBodiesTest)> get _allCases =>
      caseSet<_AvoidNonEmptyConstructorBodiesTest>(
        parent: const {},
        own: {
          'test_blockBodyWithStatement_lint': (t) => t._blockBodyWithStatementLint(),
          'test_factoryExpressionBody_lint': (t) => t._factoryExpressionBodyLint(),
          'test_emptyBodyAndInitializerList_noLint': (t) => t._emptyBodyAndInitializerListNoLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNonEmptyConstructorBodies();
    super.setUp();
  }

  Future<void> _blockBodyWithStatementLint() async {
    const source = r'''
class Example {
  Example() {
    print('created');
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('{\n    print'), '{\n    print(\'created\');\n  }'.length),
    ]);
  }

  Future<void> _factoryExpressionBodyLint() async {
    const source = r'''
class Example {
  Example._();
  factory Example.create() => Example._();
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('Example._()'), 'Example._()'.length),
    ]);
  }

  Future<void> _emptyBodyAndInitializerListNoLint() async {
    await assertNoDiagnostics(r'''
class Example {
  Example() : value = 0;
  Example.empty() {}
  Example.withInitializer() : value = 1;

  int? value;
}
''');
  }

  Future<void> _severityInfo() async {
    expect(AvoidNonEmptyConstructorBodies.code.severity, DiagnosticSeverity.INFO);
  }
}

final class _AvoidExtensionsOnRecordsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidExtensionsOnRecordsTest)> get _allCases =>
      caseSet<_AvoidExtensionsOnRecordsTest>(
        parent: const {},
        own: {
          'test_positionalRecordExtension_lint': (t) => t._positionalRecordExtensionLint(),
          'test_namedRecordExtension_lint': (t) => t._namedRecordExtensionLint(),
          'test_namedTypeExtension_noLint': (t) => t._namedTypeExtensionNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidExtensionsOnRecords();
    super.setUp();
  }

  Future<void> _positionalRecordExtensionLint() async {
    const source = r'''
extension PointRecord on (int, int) {
  int get x => $1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> _namedRecordExtensionLint() async {
    const source = r'''
extension UserRecord on ({String name, int score}) {
  String get label => name;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('({String name'), '({String name, int score})'.length),
    ]);
  }

  Future<void> _namedTypeExtensionNoLint() async {
    await assertNoDiagnostics(r'''
extension ExampleString on String {
  String get label => this;
}
''');
  }

  Future<void> _severityError() async {
    expect(AvoidExtensionsOnRecords.code.severity, DiagnosticSeverity.ERROR);
  }
}
