import 'package:flutter_skill_lints/src/additional_lints/fixes/use_existing_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<UseExistingDestructuringCasesTest>(
    'UseExistingDestructuringCasesTest',
    UseExistingDestructuringCasesTest.new,
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
}

final class UseExistingDestructuringCasesTest extends FixRuleTest {
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
