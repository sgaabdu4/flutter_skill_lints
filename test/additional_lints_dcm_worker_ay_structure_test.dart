// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_declaring_call_method.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_extensions_on_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_non_empty_constructor_bodies.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNonEmptyConstructorBodiesTest);
    defineReflectiveTests(AvoidDeclaringCallMethodTest);
    defineReflectiveTests(AvoidExtensionsOnRecordsTest);
  });
}

@reflectiveTest
final class AvoidNonEmptyConstructorBodiesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNonEmptyConstructorBodies();
    super.setUp();
  }

  Future<void> test_blockBodyWithStatement_lint() async {
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

  Future<void> test_factoryExpressionBody_lint() async {
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

  Future<void> test_emptyBodyAndInitializerList_noLint() async {
    await assertNoDiagnostics(r'''
class Example {
  Example() : value = 0;
  Example.empty() {}
  Example.withInitializer() : value = 1;

  int? value;
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidNonEmptyConstructorBodies.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidDeclaringCallMethodTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDeclaringCallMethod();
    super.setUp();
  }

  Future<void> test_classCallMethod_lint() async {
    const source = r'''
class Example {
  void call() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('call'), 'call'.length)]);
  }

  Future<void> test_mixinCallMethod_lint() async {
    const source = r'''
mixin ExampleMixin {
  void call() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('call'), 'call'.length)]);
  }

  Future<void> test_extensionTypeCallMethod_lint() async {
    const source = r'''
extension type ExampleId(String value) {
  void call() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('call'), 'call'.length)]);
  }

  Future<void> test_extensionCallMethod_noLint() async {
    await assertNoDiagnostics(r'''
extension ExampleString on String {
  void call() {}
}
''');
  }

  Future<void> test_namedMethod_noLint() async {
    await assertNoDiagnostics(r'''
class Example {
  void execute() {}
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidDeclaringCallMethod.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidExtensionsOnRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidExtensionsOnRecords();
    super.setUp();
  }

  Future<void> test_positionalRecordExtension_lint() async {
    const source = r'''
extension PointRecord on (int, int) {
  int get x => $1;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('(int, int)'), '(int, int)'.length)]);
  }

  Future<void> test_namedRecordExtension_lint() async {
    const source = r'''
extension UserRecord on ({String name, int score}) {
  String get label => name;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('({String name'), '({String name, int score})'.length),
    ]);
  }

  Future<void> test_namedTypeExtension_noLint() async {
    await assertNoDiagnostics(r'''
extension ExampleString on String {
  String get label => this;
}
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidExtensionsOnRecords.code.severity, DiagnosticSeverity.ERROR);
  }
}
