import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_default_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_recursive_tostring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_stream_tostring.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidDefaultToStringTest>(
    'AvoidDefaultToStringTest',
    AvoidDefaultToStringTest.new,
    {
      'test_localClassWithoutToString_lint': (t) => t._localClassWithoutToStringLint(),
      'test_localClassWithToString_noLint': (t) => t._localClassWithToStringNoLint(),
      'test_inheritsLocalToString_noLint': (t) => t._inheritsLocalToStringNoLint(),
      'test_coreObjectTarget_noLint': (t) => t._coreObjectTargetNoLint(),
    },
  );
  analysisRuleSuite<AvoidRecursiveToStringTest>(
    'AvoidRecursiveToStringTest',
    AvoidRecursiveToStringTest.new,
    {
      'test_directCall_lint': (t) => t._directCallLint(),
      'test_thisCall_lint': (t) => t._thisCallLint(),
      'test_thisInterpolation_lint': (t) => t._thisInterpolationLint(),
      'test_fieldToString_noLint': (t) => t._fieldToStringNoLint(),
      'test_nestedClosure_noLint': (t) => t._nestedClosureNoLint(),
    },
  );
  analysisRuleSuite<AvoidStreamToStringTest>(
    'AvoidStreamToStringTest',
    AvoidStreamToStringTest.new,
    {
      'test_streamToString_lint': (t) => t._streamToStringLint(),
      'test_nonStreamToString_noLint': (t) => t._nonStreamToStringNoLint(),
    },
  );
}

final class AvoidDefaultToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidDefaultToString();
    super.setUp();
  }

  Future<void> _localClassWithoutToStringLint() async {
    const source = r'''
class User {
  const User();
}

String label(User user) => user.toString();
''';

    await assertDiagnostics(source, [lint(source.indexOf('toString'), 'toString'.length)]);
  }

  Future<void> _localClassWithToStringNoLint() async {
    await assertNoDiagnostics(r'''
class User {
  const User();

  @override
  String toString() => 'User';
}

String label(User user) => user.toString();
''');
  }

  Future<void> _inheritsLocalToStringNoLint() async {
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

  Future<void> _coreObjectTargetNoLint() async {
    await assertNoDiagnostics(r'''
String label(Object value) => value.toString();
''');
  }
}

final class AvoidRecursiveToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidRecursiveToString();
    super.setUp();
  }

  Future<void> _directCallLint() async {
    const source = r'''
class User {
  @override
  String toString() => toString();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('toString'), 'toString'.length)]);
  }

  Future<void> _thisCallLint() async {
    const source = r'''
class User {
  @override
  String toString() => this.toString();
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('toString'), 'toString'.length)]);
  }

  Future<void> _thisInterpolationLint() async {
    const source = r'''
class User {
  @override
  String toString() => '$this';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('this'), 'this'.length)]);
  }

  Future<void> _fieldToStringNoLint() async {
    await assertNoDiagnostics(r'''
class User {
  const User(this.name);

  final String name;

  @override
  String toString() => name.toString();
}
''');
  }

  Future<void> _nestedClosureNoLint() async {
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

final class AvoidStreamToStringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidStreamToString();
    super.setUp();
  }

  Future<void> _streamToStringLint() async {
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

  Future<void> _nonStreamToStringNoLint() async {
    await assertNoDiagnostics(r'''
void f(Object value) {
  value.toString();
}
''');
  }
}
