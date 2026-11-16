import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bottom_type_in_records.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_type_casts.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_private_extension_type_field.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidBottomTypeInRecordsTest>(
    'AvoidBottomTypeInRecordsTest',
    AvoidBottomTypeInRecordsTest.new,
    {
      'test_namedNeverField_lint': (t) => t._namedNeverFieldLint(),
      'test_positionalNeverField_lint': (t) => t._positionalNeverFieldLint(),
      'test_recordValueTypes_noLint': (t) => t._recordValueTypesNoLint(),
    },
  );
  analysisRuleSuite<AvoidTypeCastsTest>('AvoidTypeCastsTest', AvoidTypeCastsTest.new, {
    'test_objectToStringCast_lint': (t) => t._objectToStringCastLint(),
    'test_dynamicToIntCast_lint': (t) => t._dynamicToIntCastLint(),
    'test_jsonMapCast_noLint': (t) => t._jsonMapCastNoLint(),
    'test_objectCast_noLint': (t) => t._objectCastNoLint(),
  });
  analysisRuleSuite<PreferPrivateExtensionTypeFieldTest>(
    'PreferPrivateExtensionTypeFieldTest',
    PreferPrivateExtensionTypeFieldTest.new,
    {
      'test_publicRepresentationField_lint': (t) => t._publicRepresentationFieldLint(),
      'test_publicValueRepresentationField_noLint': (t) =>
          t._publicValueRepresentationFieldNoLint(),
      'test_privateRepresentationField_noLint': (t) => t._privateRepresentationFieldNoLint(),
      'test_memberParameterNames_noLint': (t) => t._memberParameterNamesNoLint(),
    },
  );
}

final class AvoidBottomTypeInRecordsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBottomTypeInRecords();
    super.setUp();
  }

  Future<void> _namedNeverFieldLint() async {
    const source = r'''
typedef Result = ({Never failure, String value});
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> _positionalNeverFieldLint() async {
    const source = r'''
typedef Result = (String, Never);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> _recordValueTypesNoLint() async {
    await assertNoDiagnostics(r'''
typedef Result = ({Object? failure, String value});

void useRecord() {
  final value = (failure: null, value: 'ok');
  print(value);
}
''');
  }
}

final class AvoidTypeCastsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidTypeCasts();
    super.setUp();
  }

  Future<void> _objectToStringCastLint() async {
    const source = r'''
String parse(Object? value) => value as String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value as String'), 'value as String'.length),
    ]);
  }

  Future<void> _dynamicToIntCastLint() async {
    const source = r'''
int parse(dynamic value) => value as int;
''';

    await assertDiagnostics(source, [lint(source.indexOf('value as int'), 'value as int'.length)]);
  }

  Future<void> _jsonMapCastNoLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> parse(Object? value) => value as Map<String, dynamic>;
''');
  }

  Future<void> _objectCastNoLint() async {
    await assertNoDiagnostics(r'''
Object normalize(String value) => value as Object;
''');
  }
}

final class PreferPrivateExtensionTypeFieldTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferPrivateExtensionTypeField();
    super.setUp();
  }

  Future<void> _publicRepresentationFieldLint() async {
    const source = r'''
extension type UserId(String id) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('id)'), 'id'.length)]);
  }

  Future<void> _publicValueRepresentationFieldNoLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String value) {
  bool get isValid => value.isNotEmpty;
}
extension type ProductId(String value) {}

void deleteProduct(ProductId id) {}
''');
  }

  Future<void> _privateRepresentationFieldNoLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String _value) {
  String get value => _value;
}
''');
  }

  Future<void> _memberParameterNamesNoLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String _value) {
  UserId copyWith(String value) => UserId(value);
}
''');
  }
}
