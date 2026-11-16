import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_duplicate_cascades_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_duplicate_cascades.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidDuplicateCascadesTest>(
    'AvoidDuplicateCascadesTest',
    _AvoidDuplicateCascadesTest.new,
    {
      'reportsRepeatedMethodCall': (t) => t._reportsRepeatedMethodCall(),
      'reportsRepeatedAssignment': (t) => t._reportsRepeatedAssignment(),
      'reportsRepeatedPropertyRead': (t) => t._reportsRepeatedPropertyRead(),
      'reportsRepeatedIndexRead': (t) => t._reportsRepeatedIndexRead(),
      'acceptsDifferentArguments': (t) => t._acceptsDifferentArguments(),
      'acceptsSingleSection': (t) => t._acceptsSingleSection(),
      'removesDuplicateInTheMiddle': (t) => t._removesDuplicateInTheMiddle(),
      'removesDuplicateAtTheEnd': (t) => t._removesDuplicateAtTheEnd(),
    },
  );
}

final class _AvoidDuplicateCascadesTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidDuplicateCascades();
    super.setUp();
  }

  static const _model = '''
class B {
  int value = 0;
  int get size => 0;
  int operator [](int i) => i;
  void add(int x) {}
}

''';

  Future<void> _reportsRepeatedMethodCall() async {
    const source =
        '''
${_model}void f(B b) {
  b..add(1)..add(1);
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('..add(1)'), '..add(1)'.length)]);
  }

  Future<void> _reportsRepeatedAssignment() async {
    const source =
        '''
${_model}void f(B b) {
  b..value = 1..value = 1;
}
''';
    await assertDiagnostics(source, [
      lint(source.lastIndexOf('..value = 1'), '..value = 1'.length),
    ]);
  }

  Future<void> _reportsRepeatedPropertyRead() async {
    const source =
        '''
${_model}void f(B b) {
  b..size..size;
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('..size'), '..size'.length)]);
  }

  Future<void> _reportsRepeatedIndexRead() async {
    const source =
        '''
${_model}void f(B b) {
  b..[1]..[1];
}
''';
    await assertDiagnostics(source, [lint(source.lastIndexOf('..[1]'), '..[1]'.length)]);
  }

  Future<void> _acceptsDifferentArguments() => assertNoDiagnostics('''
${_model}void f(B b) {
  b..add(1)..add(2)..value = 1..value = 2;
}
''');

  Future<void> _acceptsSingleSection() => assertNoDiagnostics('''
${_model}void f(B b) {
  b..add(1);
}
''');

  Future<void> _removesDuplicateInTheMiddle() => expectFix(
    '''
${_model}void f(B b) {
  b..add(1)..add(1)..value = 2;
}
''',
    (context) => AvoidDuplicateCascadesFix(context: context),
    expected:
        '''
${_model}void f(B b) {
  b..add(1)..value = 2;
}
''',
  );

  Future<void> _removesDuplicateAtTheEnd() => expectFix(
    '''
${_model}void f(B b) {
  b..add(1)..add(1);
}
''',
    (context) => AvoidDuplicateCascadesFix(context: context),
    expected:
        '''
${_model}void f(B b) {
  b..add(1);
}
''',
  );
}
