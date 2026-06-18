// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bottom_type_in_patterns.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_implicitly_nullable_extension_types.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/move_records_to_typedefs.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidBottomTypeInPatternsTest);
    defineReflectiveTests(AvoidImplicitlyNullableExtensionTypesTest);
    defineReflectiveTests(MoveRecordsToTypedefsTest);
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

@reflectiveTest
final class MoveRecordsToTypedefsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MoveRecordsToTypedefs();
    super.setUp();
  }

  Future<void> test_functionReturnRecord_lint() async {
    const source = r'''
(String, int) loadUser() => ('id', 1);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String, int)'), '(String, int)'.length),
    ]);
  }

  Future<void> test_parameterRecord_lint() async {
    const source = r'''
void save(({String id, int count}) user) {}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('({String id'), '({String id, int count})'.length),
    ]);
  }

  Future<void> test_nestedFunctionReturnRecord_lint() async {
    const source = r'''
Future<(String, int)> loadUser() async => ('id', 1);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String, int)'), '(String, int)'.length),
    ]);
  }

  Future<void> test_fieldRecord_lint() async {
    const source = r'''
class Cache {
  final (String, int) value = ('id', 1);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String, int)'), '(String, int)'.length),
    ]);
  }

  Future<void> test_typedefRecord_noLint() async {
    await assertNoDiagnostics(r'''
typedef UserRecord = ({String id, int count});

UserRecord loadUser() => (id: 'id', count: 1);
''');
  }

  Future<void> test_localRecordAnnotation_lint() async {
    const source = r'''
void build() {
  (String, int) value = ('id', 1);
  print(value);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('(String, int)'), '(String, int)'.length),
    ]);
  }

  Future<void> test_untypedNamedRecordLiteral_lint() async {
    const source = r'''
void f() {
  final value = (calendar: true, loggedExercises: null, recentSessions: false);
  print(value);
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('(calendar: true'),
        '(calendar: true, loggedExercises: null, recentSessions: false)'.length,
      ),
    ]);
  }

  Future<void> test_typedNamedRecordLiteral_noLint() async {
    await assertNoDiagnostics(r'''
typedef PreferencesProjection = ({bool? calendar, bool? loggedExercises, bool? recentSessions});

PreferencesProjection f() {
  return (calendar: true, loggedExercises: null, recentSessions: false);
}
''');
  }
}
