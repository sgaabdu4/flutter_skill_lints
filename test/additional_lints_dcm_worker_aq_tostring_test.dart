// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_default_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_recursive_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_stream_tostring.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDefaultToStringTest);
    defineReflectiveTests(AvoidRecursiveToStringTest);
    defineReflectiveTests(AvoidStreamToStringTest);
  });
}

@reflectiveTest
final class AvoidDefaultToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDefaultToString();
    super.setUp();
  }

  Future<void> test_localClassWithoutToString_lint() async {
    const source = r'''
class User {
  const User();
}

String label(User user) => user.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_localClassWithToString_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  const User();

  @override
  String toString() => 'User';
}

String label(User user) => user.toString();
''');
  }

  Future<void> test_inheritsLocalToString_noLint() async {
    await assertNoDiagnostics(r'''
class Entity {
  const Entity();

  @override
  String toString() => 'Entity';
}

class User extends Entity {
  const User();
}

String label(User user) => user.toString();
''');
  }

  Future<void> test_coreObjectTarget_noLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) => value.toString();
''');
  }
}

@reflectiveTest
final class AvoidRecursiveToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRecursiveToString();
    super.setUp();
  }

  Future<void> test_directCall_lint() async {
    const source = r'''
class User {
  @override
  String toString() => toString();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_thisCall_lint() async {
    const source = r'''
class User {
  @override
  String toString() => this.toString();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_thisInterpolation_lint() async {
    const source = r'''
class User {
  @override
  String toString() => '$this';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('this'), 'this'.length)]);
  }

  Future<void> test_fieldToString_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  const User(this.name);

  final String name;

  @override
  String toString() => name.toString();
}
''');
  }

  Future<void> test_nestedClosure_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  @override
  String toString() {
    String nested(String value) => value.toString();
    return nested('User');
  }
}
''');
  }
}

@reflectiveTest
final class AvoidStreamToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidStreamToString();
    super.setUp();
  }

  Future<void> test_streamToString_lint() async {
    const source = r'''
Stream<int> values() async* {
  yield 1;
}

void f() {
  values().toString();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> test_nonStreamToString_noLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  value.toString();
}
''');
  }
}
