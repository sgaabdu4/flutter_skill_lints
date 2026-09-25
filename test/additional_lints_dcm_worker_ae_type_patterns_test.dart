// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bottom_type_in_patterns.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_implicitly_nullable_extension_types.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBottomTypeInPatternsTest);
    defineReflectiveTests(AvoidImplicitlyNullableExtensionTypesTest);
  });
}

@reflectiveTest
final class AvoidBottomTypeInPatternsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBottomTypeInPatterns();
    super.setUp();
  }

  Future<void> test_declaredVariablePattern_lint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  Never impossible => 'never',
  _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> test_objectPattern_lint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  Never() => 'never',
  _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> test_reachablePatterns_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  String text => text,
  int() => 'int',
  _ => 'value',
};
''');
  }
}

@reflectiveTest
final class AvoidImplicitlyNullableExtensionTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidImplicitlyNullableExtensionTypes();
    super.setUp();
  }

  Future<void> test_unconstrainedRepresentationTypeParameter_lint() async {
    const source = r'''
extension type Box<T>(T value) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('T value'), 'T'.length)]);
  }

  Future<void> test_nonNullableBound_noLint() async {
    await assertNoDiagnostics(r'''
extension type Box<T extends Object>(T value) {}
''');
  }

  Future<void> test_concreteRepresentationType_noLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String value) {}
''');
  }
}
