import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_destructuring.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<UseExistingDestructuringTest>(
    'UseExistingDestructuringTest',
    UseExistingDestructuringTest.new,
    {
      'test_allowsGeneratedFreezedCopyWithButReportsDataField': (t) =>
          t._allowsGeneratedFreezedCopyWithButReportsDataField(),
      'test_reportsOrdinaryGetterNamedCopyWith': (t) => t._reportsOrdinaryGetterNamedCopyWith(),
    },
  );
}

final class UseExistingDestructuringTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseExistingDestructuring();
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed { const Freezed(); }
const freezed = Freezed();
''');
    super.setUp();
  }

  Future<void> _allowsGeneratedFreezedCopyWithButReportsDataField() async {
    newFile('$testPackageLibPath/form_state.dart', r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'form_state.freezed.dart';
@freezed
class FormState with _$FormState {
  const FormState(this.value, this.valid);
  final String value;
  final bool valid;
}
''');
    newFile('$testPackageLibPath/form_state.freezed.dart', r'''
part of 'form_state.dart';
mixin _$FormState {
  FormStateCopyWith get copyWith => FormStateCopyWith(this as FormState);
}
class FormStateCopyWith {
  FormStateCopyWith(this.state);
  final FormState state;
  FormState call({String? value}) => FormState(value ?? state.value, state.valid);
}
''');
    const source = r'''
import 'form_state.dart';
FormState update(FormState state) {
  final FormState(:value) = state;
  return state.copyWith(value: '$value!');
}
bool readOther(FormState state) {
  final FormState(:value) = state;
  return value.isNotEmpty && state.valid;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('state.valid'), 'state.valid'.length)]);
  }

  Future<void> _reportsOrdinaryGetterNamedCopyWith() async {
    const source = r'''
class Manual {
  const Manual(this.value);
  final String value;
  Manual Function(String) get copyWith => (value) => Manual(value);
}
Manual update(Manual state) {
  final Manual(:value) = state;
  return state.copyWith(value);
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('state.copyWith'), 'state.copyWith'.length),
    ]);
  }
}
