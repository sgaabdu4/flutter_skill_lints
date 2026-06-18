// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_explicit_pattern_field_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_keywords_in_wildcard_pattern.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_wildcard_pattern.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidKeywordsInWildcardPatternTest);
    defineReflectiveTests(AvoidMisusedWildcardPatternTest);
    defineReflectiveTests(AvoidExplicitPatternFieldNameTest);
  });
}

@reflectiveTest
final class AvoidKeywordsInWildcardPatternTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidKeywordsInWildcardPattern();
    super.setUp();
  }

  Future<void> test_finalWildcard_lint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  final _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('final _'), 'final'.length)]);
  }

  Future<void> test_varWildcard_lint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  var _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('var _'), 'var'.length)]);
  }

  Future<void> test_plainWildcard_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  _ => 'value',
};
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidKeywordsInWildcardPattern.code.severity, DiagnosticSeverity.INFO);
  }
}

@reflectiveTest
final class AvoidMisusedWildcardPatternTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedWildcardPattern();
    super.setUp();
  }

  Future<void> test_leftWildcardInLogicalOr_lint() async {
    const source = r'''
// ignore_for_file: dead_code

String describe(Object value) => switch (value) {
  _ || int() => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('_ ||'), 1)]);
  }

  Future<void> test_rightWildcardInLogicalOr_lint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  int() || _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('_ =>'), 1)]);
  }

  Future<void> test_typedWildcardInLogicalOr_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  int _ || String _ => 'typed',
  _ => 'value',
};
''');
  }

  Future<void> test_withoutWildcardInLogicalOr_noLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  int() || String() => 'typed',
  _ => 'value',
};
''');
  }

  Future<void> test_severity_error() async {
    expect(AvoidMisusedWildcardPattern.code.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class AvoidExplicitPatternFieldNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidExplicitPatternFieldName();
    super.setUp();
  }

  Future<void> test_explicitObjectPatternFieldName_lint() async {
    const source = r'''
class User {
  User(this.name);
  final String name;
}

void read(User user) {
  final User(name: name) = user;
  print(name);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('name: name'), 'name:'.length)]);
  }

  Future<void> test_shorthandObjectPatternFieldName_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  User(this.name);
  final String name;
}

void read(User user) {
  final User(:name) = user;
  print(name);
}
''');
  }

  Future<void> test_differentVariableName_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  User(this.name);
  final String name;
}

void read(User user) {
  final User(name: label) = user;
  print(label);
}
''');
  }

  Future<void> test_typedPattern_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  User(this.name);
  final String name;
}

void read(User user) {
  final User(name: String name) = user;
  print(name);
}
''');
  }

  Future<void> test_recordPattern_noLint() async {
    await assertNoDiagnostics(r'''
void read(({String name}) user) {
  final (name: name) = user;
  print(name);
}
''');
  }

  Future<void> test_severity_info() async {
    expect(AvoidExplicitPatternFieldName.code.severity, DiagnosticSeverity.INFO);
  }
}
