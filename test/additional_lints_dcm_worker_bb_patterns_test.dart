import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_explicit_pattern_field_name.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_keywords_in_wildcard_pattern.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_wildcard_pattern.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidKeywordsInWildcardPatternTest>(
    'AvoidKeywordsInWildcardPatternTest',
    _AvoidKeywordsInWildcardPatternTest.new,
    _AvoidKeywordsInWildcardPatternTest._allCases,
  );
  analysisRuleSuite<_AvoidMisusedWildcardPatternTest>(
    'AvoidMisusedWildcardPatternTest',
    _AvoidMisusedWildcardPatternTest.new,
    _AvoidMisusedWildcardPatternTest._allCases,
  );
  analysisRuleSuite<_AvoidExplicitPatternFieldNameTest>(
    'AvoidExplicitPatternFieldNameTest',
    _AvoidExplicitPatternFieldNameTest.new,
    _AvoidExplicitPatternFieldNameTest._allCases,
  );
}

final class _AvoidKeywordsInWildcardPatternTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidKeywordsInWildcardPatternTest)> get _allCases =>
      caseSet<_AvoidKeywordsInWildcardPatternTest>(
        parent: const {},
        own: {
          'test_finalWildcard_lint': (t) => t._finalWildcardLint(),
          'test_varWildcard_lint': (t) => t._varWildcardLint(),
          'test_plainWildcard_noLint': (t) => t._plainWildcardNoLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidKeywordsInWildcardPattern();
    super.setUp();
  }

  Future<void> _finalWildcardLint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  final _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('final _'), 'final'.length)]);
  }

  Future<void> _varWildcardLint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  var _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('var _'), 'var'.length)]);
  }

  Future<void> _plainWildcardNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  _ => 'value',
};
''');
  }

  Future<void> _severityInfo() async {
    expect(AvoidKeywordsInWildcardPattern.code.severity, DiagnosticSeverity.INFO);
  }
}

final class _AvoidMisusedWildcardPatternTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidMisusedWildcardPatternTest)> get _allCases =>
      caseSet<_AvoidMisusedWildcardPatternTest>(
        parent: const {},
        own: {
          'test_leftWildcardInLogicalOr_lint': (t) => t._leftWildcardInLogicalOrLint(),
          'test_rightWildcardInLogicalOr_lint': (t) => t._rightWildcardInLogicalOrLint(),
          'test_typedWildcardInLogicalOr_noLint': (t) => t._typedWildcardInLogicalOrNoLint(),
          'test_withoutWildcardInLogicalOr_noLint': (t) => t._withoutWildcardInLogicalOrNoLint(),
          'test_severity_error': (t) => t._severityError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidMisusedWildcardPattern();
    super.setUp();
  }

  Future<void> _leftWildcardInLogicalOrLint() async {
    const source = r'''
// ignore_for_file: dead_code

String describe(Object value) => switch (value) {
  _ || int() => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('_ ||'), 1)]);
  }

  Future<void> _rightWildcardInLogicalOrLint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  int() || _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('_ =>'), 1)]);
  }

  Future<void> _typedWildcardInLogicalOrNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  int _ || String _ => 'typed',
  _ => 'value',
};
''');
  }

  Future<void> _withoutWildcardInLogicalOrNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  int() || String() => 'typed',
  _ => 'value',
};
''');
  }

  Future<void> _severityError() async {
    expect(AvoidMisusedWildcardPattern.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _AvoidExplicitPatternFieldNameTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidExplicitPatternFieldNameTest)> get _allCases =>
      caseSet<_AvoidExplicitPatternFieldNameTest>(
        parent: const {},
        own: {
          'test_explicitObjectPatternFieldName_lint': (t) =>
              t._explicitObjectPatternFieldNameLint(),
          'test_shorthandObjectPatternFieldName_noLint': (t) =>
              t._shorthandObjectPatternFieldNameNoLint(),
          'test_differentVariableName_noLint': (t) => t._differentVariableNameNoLint(),
          'test_typedPattern_noLint': (t) => t._typedPatternNoLint(),
          'test_recordPattern_noLint': (t) => t._recordPatternNoLint(),
          'test_severity_info': (t) => t._severityInfo(),
        },
      );

  @override
  void setUp() {
    rule = AvoidExplicitPatternFieldName();
    super.setUp();
  }

  Future<void> _explicitObjectPatternFieldNameLint() async {
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

  Future<void> _shorthandObjectPatternFieldNameNoLint() async {
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

  Future<void> _differentVariableNameNoLint() async {
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

  Future<void> _typedPatternNoLint() async {
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

  Future<void> _recordPatternNoLint() async {
    await assertNoDiagnostics(r'''
void read(({String name}) user) {
  final (name: name) = user;
  print(name);
}
''');
  }

  Future<void> _severityInfo() async {
    expect(AvoidExplicitPatternFieldName.code.severity, DiagnosticSeverity.INFO);
  }
}
