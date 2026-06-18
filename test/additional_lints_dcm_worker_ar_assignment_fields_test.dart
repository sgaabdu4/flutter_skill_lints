// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_final_reassignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_late_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidLateFinalReassignmentTest);
    defineReflectiveTests(AvoidUnassignedLateFieldsTest);
    defineReflectiveTests(AvoidUnassignedFieldsTest);
  });
}

@reflectiveTest
final class AvoidLateFinalReassignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLateFinalReassignment();
    super.setUp();
  }

  Future<void> test_lateFinalFieldReassignmentInSameBody_lint() async {
    const source = r'''
class Cache {
  late final Object value;

  void init() {
    value = Object();
    this.value = Object();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value = Object();', 85), 'value'.length),
    ]);
  }

  Future<void> test_constructorInitializersAndBodyReassignment_lint() async {
    const source = r'''
class Cache {
  late final Object value;

  Cache(this.value) {
    value = Object();
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('value ='), 'value'.length)]);
  }

  Future<void> test_singleLateFinalAssignment_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final Object value;

  void init() {
    value = Object();
  }
}

void build() {
  late final value;
  value = 1;
}
''');
  }

  Future<void> test_shadowingLocal_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late final Object value;

  void init() {
    final value = Object();
    value.toString();
  }
}
''');
  }
}

@reflectiveTest
final class AvoidUnassignedLateFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedLateFields();
    super.setUp();
  }

  Future<void> test_lateFieldWithoutConstructor_lint() async {
    const source = r'''
class Cache {
  late Object value;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_constructorMissesLateField_lint() async {
    const source = r'''
class Cache {
  late Object value;

  Cache();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_allConstructorsAssignLateField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache(this.value);

  Cache.named() : value = Object();
}
''');
  }

  Future<void> test_requiredNamedLateFieldFormal_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache({required this.value});
}
''');
  }

  Future<void> test_constructorMissesLateFieldAssignedByAnotherConstructor_lint() async {
    const source = r'''
class Cache {
  late Object value;

  Cache(this.value);

  Cache.empty();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_redirectingConstructorToLateFieldTarget_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache(Object value) : this._(value);

  Cache._(this.value);
}
''');
  }

  Future<void> test_lateFieldWithInitializer_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value = Object();
}
''');
  }
}

@reflectiveTest
final class AvoidUnassignedFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedFields();
    super.setUp();
  }

  Future<void> test_nullableFieldWithoutConstructor_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value;
}
''');
  }

  Future<void> test_nonNullableFieldWithoutConstructor_lint() async {
    const source = r'''
// ignore_for_file: not_initialized_non_nullable_instance_field

class Cache {
  Object value;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_constructorMissesNullableField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value;

  Cache();
}
''');
  }

  Future<void> test_constructorMissesNonNullableField_lint() async {
    const source = r'''
// ignore_for_file: not_initialized_non_nullable_instance_field

class Cache {
  Object value;

  Cache();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_allConstructorsAssignField_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(this.value);

  Cache.named() : value = Object();
}
''');
  }

  Future<void> test_requiredNamedFieldFormal_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache({required this.value});
}
''');
  }

  Future<void> test_optionalNamedFieldFormalWithDefault_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  int value;

  Cache({this.value = 0});
}
''');
  }

  Future<void> test_constructorMissesFieldAssignedByAnotherConstructor_lint() async {
    const source = r'''
// ignore_for_file: not_initialized_non_nullable_instance_field

class Cache {
  Object value;

  Cache(this.value);

  Cache.empty();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> test_redirectingConstructorToPrimary_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(this.value);

  Cache.named(Object value) : this(value);
}
''');
  }

  Future<void> test_redirectingConstructorToPrivateTarget_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(Object value) : this._(value);

  Cache._(this.value);
}
''');
  }

  Future<void> test_fieldWithInitializer_noLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value = Object();
}
''');
  }
}
