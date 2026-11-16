import 'package:flutter_skill_lints/src/additional_lints/fixes/use_existing_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<UseExistingDestructuringTest>(
    'UseExistingDestructuringTest',
    UseExistingDestructuringTest.new,
    {
      'reportsDirectAccessOfUndestructuredField': (t) =>
          t.reportsDirectAccessOfUndestructuredField(),
      'reportsPropertyAccessForm': (t) => t.reportsPropertyAccessForm(),
      'acceptsAlreadyDestructuredField': (t) => t.acceptsAlreadyDestructuredField(),
      'acceptsAssignmentToField': (t) => t.acceptsAssignmentToField(),
      'acceptsAccessBeforeDestructuring': (t) => t.acceptsAccessBeforeDestructuring(),
      'acceptsOtherVariables': (t) => t.acceptsOtherVariables(),
      'ignoresNestedClosures': (t) => t.ignoresNestedClosures(),
      'addsFieldToExistingPattern': (t) => t.addsFieldToExistingPattern(),
    },
  );
  analysisRuleSuite<UseExistingDestructuringFreezedTest>(
    'UseExistingDestructuringFreezedTest',
    UseExistingDestructuringFreezedTest.new,
    {
      'allowsGeneratedFreezedCopyWithButReportsDataField': (t) =>
          t.allowsGeneratedFreezedCopyWithButReportsDataField(),
      'reportsOrdinaryGetterNamedCopyWith': (t) => t.reportsOrdinaryGetterNamedCopyWith(),
    },
  );
}

final class UseExistingDestructuringTest extends FixRuleTest {
  @override
  void setUp() {
    rule = UseExistingDestructuring();
    super.setUp();
  }

  static const _model = '''
class P {
  final int x = 0;
  final int y = 0;
  final P? next = null;
}

''';

  static const _direct =
      '''
${_model}int f(P p) {
  final P(:x) = p;
  return x + p.y;
}
''';

  Future<void> reportsDirectAccessOfUndestructuredField() =>
      assertDiagnostics(_direct, [lint(_direct.indexOf('p.y'), 'p.y'.length)]);

  Future<void> reportsPropertyAccessForm() async {
    const source =
        '''
${_model}int f(P p) {
  final P(:x) = p;
  return x + p.next!.x;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('p.next'), 'p.next'.length)]);
  }

  Future<void> acceptsAlreadyDestructuredField() => assertNoDiagnostics('''
${_model}int f(P p) {
  final P(:x) = p;
  return x + p.x;
}
''');

  Future<void> acceptsAssignmentToField() => assertNoDiagnostics('''
class M {
  int x = 0;
  int y = 0;
}

void f(M m) {
  final M(:x) = m;
  m.y = x;
}
''');

  Future<void> acceptsAccessBeforeDestructuring() => assertNoDiagnostics('''
${_model}int f(P p) {
  final a = p.y;
  final P(:x) = p;
  return x + a;
}
''');

  Future<void> acceptsOtherVariables() => assertNoDiagnostics('''
${_model}int f(P p, P q) {
  final P(:x) = p;
  return x + q.y;
}
''');

  Future<void> ignoresNestedClosures() => assertNoDiagnostics('''
${_model}int Function() f(P p) {
  final P(:x) = p;
  return () => x + p.y;
}
''');

  Future<void> addsFieldToExistingPattern() => expectFix(
    _direct,
    (context) => UseExistingDestructuringFix(context: context),
    expected:
        '''
${_model}int f(P p) {
  final P(:x, :y) = p;
  return x + y;
}
''',
  );
}

final class UseExistingDestructuringFreezedTest extends FixRuleTest {
  @override
  void setUp() {
    rule = UseExistingDestructuring();
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed { const Freezed(); }
const freezed = Freezed();
''');
    super.setUp();
  }

  Future<void> allowsGeneratedFreezedCopyWithButReportsDataField() async {
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

  Future<void> reportsOrdinaryGetterNamedCopyWith() async {
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
