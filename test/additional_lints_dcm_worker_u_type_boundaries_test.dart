// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bottom_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_type_casts.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_private_extension_type_field.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBottomTypeInRecordsTest);
    defineReflectiveTests(AvoidTypeCastsTest);
    defineReflectiveTests(PreferPrivateExtensionTypeFieldTest);
  });
}

@reflectiveTest
final class AvoidBottomTypeInRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBottomTypeInRecords();
    super.setUp();
  }

  Future<void> test_namedNeverField_lint() async {
    const source = r'''
typedef Result = ({Never failure, String value});
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> test_positionalNeverField_lint() async {
    const source = r'''
typedef Result = (String, Never);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> test_recordValueTypes_noLint() async {
    await assertNoDiagnostics(r'''
typedef Result = ({Object? failure, String value});

void useRecord() {
  final value = (failure: null, value: 'ok');
  print(value);
}
''');
  }
}

@reflectiveTest
final class AvoidTypeCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidTypeCasts();
    super.setUp();
  }

  Future<void> test_objectToStringCast_lint() async {
    const source = r'''
String parse(Object? value) => value as String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value as String'), 'value as String'.length),
    ]);
  }

  Future<void> test_dynamicToIntCast_lint() async {
    const source = r'''
int parse(dynamic value) => value as int;
''';

    await assertDiagnostics(source, [lint(source.indexOf('value as int'), 'value as int'.length)]);
  }

  Future<void> test_jsonMapCast_noLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> parse(Object? value) => value as Map<String, dynamic>;
''');
  }

  Future<void> test_objectCast_noLint() async {
    await assertNoDiagnostics(r'''
Object normalize(String value) => value as Object;
''');
  }
}

@reflectiveTest
final class PreferPrivateExtensionTypeFieldTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPrivateExtensionTypeField();
    super.setUp();
  }

  Future<void> test_publicRepresentationField_lint() async {
    const source = r'''
extension type UserId(String value) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_privateRepresentationField_noLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String _value) {
  String get value => _value;
}
''');
  }

  Future<void> test_memberParameterNames_noLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String _value) {
  UserId copyWith(String value) => UserId(value);
}
''');
  }
}
