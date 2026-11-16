import 'package:flutter_skill_lints/src/additional_lints/fixes/use_existing_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_UseExistingDestructuringCasesTest>(
    'UseExistingDestructuringCasesTest',
    _UseExistingDestructuringCasesTest.new,
    {
      'reportsDirectAccessOfUndestructuredField': (t) =>
          t._reportsDirectAccessOfUndestructuredField(),
      'reportsPropertyAccessForm': (t) => t._reportsPropertyAccessForm(),
      'acceptsAlreadyDestructuredField': (t) => t._acceptsAlreadyDestructuredField(),
      'acceptsAssignmentToField': (t) => t._acceptsAssignmentToField(),
      'acceptsAccessBeforeDestructuring': (t) => t._acceptsAccessBeforeDestructuring(),
      'acceptsOtherVariables': (t) => t._acceptsOtherVariables(),
      'ignoresNestedClosures': (t) => t._ignoresNestedClosures(),
      'addsFieldToExistingPattern': (t) => t._addsFieldToExistingPattern(),
    },
  );
}

final class _UseExistingDestructuringCasesTest extends FixRuleTest {
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

  Future<void> _reportsDirectAccessOfUndestructuredField() =>
      assertDiagnostics(_direct, [lint(_direct.indexOf('p.y'), 'p.y'.length)]);

  Future<void> _reportsPropertyAccessForm() async {
    const source =
        '''
${_model}int f(P p) {
  final P(:x) = p;
  return x + p.next!.x;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('p.next'), 'p.next'.length)]);
  }

  Future<void> _acceptsAlreadyDestructuredField() => assertNoDiagnostics('''
${_model}int f(P p) {
  final P(:x) = p;
  return x + p.x;
}
''');

  Future<void> _acceptsAssignmentToField() => assertNoDiagnostics('''
class M {
  int x = 0;
  int y = 0;
}

void f(M m) {
  final M(:x) = m;
  m.y = x;
}
''');

  Future<void> _acceptsAccessBeforeDestructuring() => assertNoDiagnostics('''
${_model}int f(P p) {
  final a = p.y;
  final P(:x) = p;
  return x + a;
}
''');

  Future<void> _acceptsOtherVariables() => assertNoDiagnostics('''
${_model}int f(P p, P q) {
  final P(:x) = p;
  return x + q.y;
}
''');

  Future<void> _ignoresNestedClosures() => assertNoDiagnostics('''
${_model}int Function() f(P p) {
  final P(:x) = p;
  return () => x + p.y;
}
''');

  Future<void> _addsFieldToExistingPattern() => expectFix(
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
