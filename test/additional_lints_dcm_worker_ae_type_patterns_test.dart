import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_bottom_type_in_patterns.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_implicitly_nullable_extension_types.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidBottomTypeInPatternsTest>(
    'AvoidBottomTypeInPatternsTest',
    _AvoidBottomTypeInPatternsTest.new,
    _AvoidBottomTypeInPatternsTest._allCases,
  );
  analysisRuleSuite<_AvoidImplicitlyNullableExtensionTypesTest>(
    'AvoidImplicitlyNullableExtensionTypesTest',
    _AvoidImplicitlyNullableExtensionTypesTest.new,
    _AvoidImplicitlyNullableExtensionTypesTest._allCases,
  );
}

final class _AvoidBottomTypeInPatternsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidBottomTypeInPatternsTest)> get _allCases =>
      caseSet<_AvoidBottomTypeInPatternsTest>(
        parent: const {},
        own: {
          'test_declaredVariablePattern_lint': (t) => t._declaredVariablePatternLint(),
          'test_objectPattern_lint': (t) => t._objectPatternLint(),
          'test_reachablePatterns_noLint': (t) => t._reachablePatternsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidBottomTypeInPatterns();
    super.setUp();
  }

  Future<void> _declaredVariablePatternLint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  Never impossible => 'never',
  _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> _objectPatternLint() async {
    const source = r'''
String describe(Object value) => switch (value) {
  Never() => 'never',
  _ => 'value',
};
''';

    await assertDiagnostics(source, [lint(source.indexOf('Never'), 'Never'.length)]);
  }

  Future<void> _reachablePatternsNoLint() async {
    await assertNoDiagnostics(r'''
String describe(Object value) => switch (value) {
  String text => text,
  int() => 'int',
  _ => 'value',
};
''');
  }
}

final class _AvoidImplicitlyNullableExtensionTypesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidImplicitlyNullableExtensionTypesTest)>
  get _allCases => caseSet<_AvoidImplicitlyNullableExtensionTypesTest>(
    parent: const {},
    own: {
      'test_unconstrainedRepresentationTypeParameter_lint': (t) =>
          t._unconstrainedRepresentationTypeParameterLint(),
      'test_nonNullableBound_noLint': (t) => t._nonNullableBoundNoLint(),
      'test_concreteRepresentationType_noLint': (t) => t._concreteRepresentationTypeNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidImplicitlyNullableExtensionTypes();
    super.setUp();
  }

  Future<void> _unconstrainedRepresentationTypeParameterLint() async {
    const source = r'''
extension type Box<T>(T value) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('T value'), 'T'.length)]);
  }

  Future<void> _nonNullableBoundNoLint() async {
    await assertNoDiagnostics(r'''
extension type Box<T extends Object>(T value) {}
''');
  }

  Future<void> _concreteRepresentationTypeNoLint() async {
    await assertNoDiagnostics(r'''
extension type UserId(String value) {}
''');
  }
}
