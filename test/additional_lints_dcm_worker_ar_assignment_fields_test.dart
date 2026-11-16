import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_final_reassignment.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unassigned_late_fields.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidLateFinalReassignmentTest>(
    'AvoidLateFinalReassignmentTest',
    AvoidLateFinalReassignmentTest.new,
    {
      'test_lateFinalFieldReassignmentInSameBody_lint': (t) =>
          t._lateFinalFieldReassignmentInSameBodyLint(),
      'test_constructorInitializersAndBodyReassignment_lint': (t) =>
          t._constructorInitializersAndBodyReassignmentLint(),
      'test_singleLateFinalAssignment_noLint': (t) => t._singleLateFinalAssignmentNoLint(),
      'test_shadowingLocal_noLint': (t) => t._shadowingLocalNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnassignedLateFieldsTest>(
    'AvoidUnassignedLateFieldsTest',
    AvoidUnassignedLateFieldsTest.new,
    {
      'test_flutterInitStateAssignsField_noLint': (t) => t._flutterInitStateAssignsFieldNoLint(),
      'test_explicitThisInitStateAssignsField_noLint': (t) =>
          t._explicitThisInitStateAssignsFieldNoLint(),
      'test_otherInstanceAssignmentStillReports_lint': (t) =>
          t._otherInstanceAssignmentStillReportsLint(),
      'test_asyncInitStateStillReports_lint': (t) => t._asyncInitStateStillReportsLint(),
      'test_conditionalInitStateStillReports_lint': (t) =>
          t._conditionalInitStateStillReportsLint(),
      'test_earlyReturnBeforeAssignmentStillReports_lint': (t) =>
          t._earlyReturnBeforeAssignmentStillReportsLint(),
      'test_deferredInitStateStillReports_lint': (t) => t._deferredInitStateStillReportsLint(),
      'test_shadowedLocalIsNotFieldInitialization_lint': (t) =>
          t._shadowedLocalIsNotFieldInitializationLint(),
      'test_nonFlutterLifecycleStillReports_lint': (t) => t._nonFlutterLifecycleStillReportsLint(),
      'test_lateFieldWithoutConstructor_lint': (t) => t._lateFieldWithoutConstructorLint(),
      'test_constructorMissesLateField_lint': (t) => t._constructorMissesLateFieldLint(),
      'test_allConstructorsAssignLateField_noLint': (t) =>
          t._allConstructorsAssignLateFieldNoLint(),
      'test_requiredNamedLateFieldFormal_noLint': (t) => t._requiredNamedLateFieldFormalNoLint(),
      'test_constructorMissesLateFieldAssignedByAnotherConstructor_lint': (t) =>
          t._constructorMissesLateFieldAssignedByAnotherConstructorLint(),
      'test_redirectingConstructorToLateFieldTarget_noLint': (t) =>
          t._redirectingConstructorToLateFieldTargetNoLint(),
      'test_lateFieldWithInitializer_noLint': (t) => t._lateFieldWithInitializerNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnassignedFieldsTest>(
    'AvoidUnassignedFieldsTest',
    AvoidUnassignedFieldsTest.new,
    {
      'test_nullableFieldWithoutConstructor_noLint': (t) =>
          t._nullableFieldWithoutConstructorNoLint(),
      'test_nonNullableFieldWithoutConstructor_lint': (t) =>
          t._nonNullableFieldWithoutConstructorLint(),
      'test_constructorMissesNullableField_noLint': (t) =>
          t._constructorMissesNullableFieldNoLint(),
      'test_constructorMissesNonNullableField_lint': (t) =>
          t._constructorMissesNonNullableFieldLint(),
      'test_allConstructorsAssignField_noLint': (t) => t._allConstructorsAssignFieldNoLint(),
      'test_requiredNamedFieldFormal_noLint': (t) => t._requiredNamedFieldFormalNoLint(),
      'test_optionalNamedFieldFormalWithDefault_noLint': (t) =>
          t._optionalNamedFieldFormalWithDefaultNoLint(),
      'test_constructorMissesFieldAssignedByAnotherConstructor_lint': (t) =>
          t._constructorMissesFieldAssignedByAnotherConstructorLint(),
      'test_redirectingConstructorToPrimary_noLint': (t) =>
          t._redirectingConstructorToPrimaryNoLint(),
      'test_redirectingConstructorToPrivateTarget_noLint': (t) =>
          t._redirectingConstructorToPrivateTargetNoLint(),
      'test_fieldWithInitializer_noLint': (t) => t._fieldWithInitializerNoLint(),
    },
  );
}

final class AvoidLateFinalReassignmentTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidLateFinalReassignment();
    super.setUp();
  }

  Future<void> _lateFinalFieldReassignmentInSameBodyLint() async {
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

  Future<void> _constructorInitializersAndBodyReassignmentLint() async {
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

  Future<void> _singleLateFinalAssignmentNoLint() async {
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

  Future<void> _shadowingLocalNoLint() async {
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

final class AvoidUnassignedLateFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedLateFields();
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {
  void initState() {}
}
''');
    super.setUp();
  }

  Future<void> _flutterInitStateAssignsFieldNoLint() async {
    await assertNoDiagnostics(_stateSource('value = Object();'));
  }

  Future<void> _explicitThisInitStateAssignsFieldNoLint() async {
    await assertNoDiagnostics(_stateSource('this.value = Object();'));
  }

  Future<void> _otherInstanceAssignmentStillReportsLint() async {
    final source = _stateSource('final other = Host(); other.value = Object();');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _asyncInitStateStillReportsLint() async {
    final source = _stateSource('value = Object();')
        .replaceFirst('void initState() {', 'void initState() async {');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _conditionalInitStateStillReportsLint() async {
    final source = _stateSource('if (enabled) value = Object();');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _earlyReturnBeforeAssignmentStillReportsLint() async {
    final source = _stateSource('if (enabled) return; value = Object();');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _deferredInitStateStillReportsLint() async {
    final source = _stateSource('Future<void>.microtask(() { value = Object(); });');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _shadowedLocalIsNotFieldInitializationLint() async {
    final source = _stateSource('final value = Object(); print(value);');
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  Future<void> _nonFlutterLifecycleStillReportsLint() async {
    const source = r'''
class State {}
class Host extends State {
  late Object value;
  void initState() { value = Object(); }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('value;'), 5)]);
  }

  String _stateSource(String body) =>
      '''
import 'package:flutter/widgets.dart';
class Host extends State<StatefulWidget> {
  bool enabled = true;
  late Object value;
  @override
  void initState() {
    super.initState();
    $body
  }
}
''';

  Future<void> _lateFieldWithoutConstructorLint() async {
    const source = r'''
class Cache {
  late Object value;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> _constructorMissesLateFieldLint() async {
    const source = r'''
class Cache {
  late Object value;

  Cache();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> _allConstructorsAssignLateFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache(this.value);

  Cache.named() : value = Object();
}
''');
  }

  Future<void> _requiredNamedLateFieldFormalNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache({required this.value});
}
''');
  }

  Future<void> _constructorMissesLateFieldAssignedByAnotherConstructorLint() async {
    const source = r'''
class Cache {
  late Object value;

  Cache(this.value);

  Cache.empty();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> _redirectingConstructorToLateFieldTargetNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value;

  Cache(Object value) : this._(value);

  Cache._(this.value);
}
''');
  }

  Future<void> _lateFieldWithInitializerNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  late Object value = Object();
}
''');
  }
}

final class AvoidUnassignedFieldsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnassignedFields();
    super.setUp();
  }

  Future<void> _nullableFieldWithoutConstructorNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value;
}
''');
  }

  Future<void> _nonNullableFieldWithoutConstructorLint() async {
    const source = r'''
// ignore_for_file: not_initialized_non_nullable_instance_field

class Cache {
  Object value;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> _constructorMissesNullableFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value;

  Cache();
}
''');
  }

  Future<void> _constructorMissesNonNullableFieldLint() async {
    const source = r'''
// ignore_for_file: not_initialized_non_nullable_instance_field

class Cache {
  Object value;

  Cache();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value'), 'value'.length)]);
  }

  Future<void> _allConstructorsAssignFieldNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(this.value);

  Cache.named() : value = Object();
}
''');
  }

  Future<void> _requiredNamedFieldFormalNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache({required this.value});
}
''');
  }

  Future<void> _optionalNamedFieldFormalWithDefaultNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  int value;

  Cache({this.value = 0});
}
''');
  }

  Future<void> _constructorMissesFieldAssignedByAnotherConstructorLint() async {
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

  Future<void> _redirectingConstructorToPrimaryNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(this.value);

  Cache.named(Object value) : this(value);
}
''');
  }

  Future<void> _redirectingConstructorToPrivateTargetNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object value;

  Cache(Object value) : this._(value);

  Cache._(this.value);
}
''');
  }

  Future<void> _fieldWithInitializerNoLint() async {
    await assertNoDiagnostics(r'''
class Cache {
  Object? value = Object();
}
''');
  }
}
