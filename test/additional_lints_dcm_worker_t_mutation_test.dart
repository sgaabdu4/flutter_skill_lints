// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_mutating_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_global_state.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mutating_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidGlobalStateTest);
    defineReflectiveTests(AvoidMutatingParametersTest);
    defineReflectiveTests(AvoidCollectionMutatingMethodsTest);
  });
}

@reflectiveTest
final class AvoidGlobalStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidGlobalState();
    super.setUp();
  }

  Future<void> test_mutableStaticField_lint() async {
    const source = r'''
class Cache {
  static var values = <int>[];
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('values'), 'values'.length)]);
  }

  Future<void> test_mutableTopLevelVariable_lint() async {
    const source = r'''
var attempts = 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('attempts'), 'attempts'.length)]);
  }

  Future<void> test_finalAndLocalVariables_noLint() async {
    await assertNoDiagnostics(r'''
final attempts = 0;

class Cache {
  static final values = <int>[];
}

void f() {
  var local = 0;
  local++;
}
''');
  }
}

@reflectiveTest
final class AvoidMutatingParametersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMutatingParameters();
    super.setUp();
  }

  Future<void> test_assignmentToParameter_lint() async {
    const source = r'''
void normalize(int value) {
  value = value.abs();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value ='), 'value'.length)]);
  }

  Future<void> test_parameterPropertyWrite_lint() async {
    const source = r'''
class User {
  String name = '';
}

void rename(User user) {
  user.name = 'Ada';
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('name ='), 'name'.length)]);
  }

  Future<void> test_localMutation_noLint() async {
    await assertNoDiagnostics(r'''
void normalize(int value) {
  var local = value;
  local++;
}
''');
  }
}

@reflectiveTest
final class AvoidCollectionMutatingMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMutatingMethods();
    super.setUp();
  }

  Future<void> test_globalCollectionMutation_lint() async {
    const source = r'''
final values = <int>[];

void store(int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> test_parameterCollectionMutation_lint() async {
    const source = r'''
void store(List<int> values, int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> test_localCollectionMutation_noLint() async {
    await assertNoDiagnostics(r'''
void store(int value) {
  final values = <int>[];
  values.add(value);
}
''');
  }
}
