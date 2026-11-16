import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_single_field_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_field_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidSingleFieldDestructuringTest>(
    'AvoidSingleFieldDestructuringTest',
    _AvoidSingleFieldDestructuringTest.new,
    {
      'reportsSingleFieldObjectPattern': (t) => t._reportsSingleFieldObjectPattern(),
      'reportsSingleNamedRecordField': (t) => t._reportsSingleNamedRecordField(),
      'acceptsTwoFieldPattern': (t) => t._acceptsTwoFieldPattern(),
      'replacesObjectPatternWithPropertyRead': (t) => t._replacesObjectPatternWithPropertyRead(),
      'replacesRecordPatternWithPropertyRead': (t) => t._replacesRecordPatternWithPropertyRead(),
      'keepsPositionalRecordPattern': (t) => t._keepsPositionalRecordPattern(),
      'keepsNestedPatterns': (t) => t._keepsNestedPatterns(),
    },
  );
}

final class _AvoidSingleFieldDestructuringTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidSingleFieldDestructuring();
    super.setUp();
  }

  static const _object = '''
class P {
  final int x = 0;
  final int y = 0;
}

int f(P p) {
  final P(:x) = p;
  return x;
}
''';

  Future<void> _reportsSingleFieldObjectPattern() => assertDiagnostics(_object, [
    lint(_object.indexOf('final P(:x) = p'), 'final P(:x) = p'.length),
  ]);

  Future<void> _reportsSingleNamedRecordField() async {
    const source = '''
int f(({int x}) r) {
  final (x: a) = r;
  return a;
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('final (x: a) = r'), 'final (x: a) = r'.length),
    ]);
  }

  Future<void> _acceptsTwoFieldPattern() => assertNoDiagnostics('''
class P {
  final int x = 0;
  final int y = 0;
}

int f(P p) {
  final P(:x, :y) = p;
  return x + y;
}
''');

  Future<void> _replacesObjectPatternWithPropertyRead() => expectFix(
    _object,
    (context) => AvoidSingleFieldDestructuringFix(context: context),
    expected: '''
class P {
  final int x = 0;
  final int y = 0;
}

int f(P p) {
  final x = p.x;
  return x;
}
''',
  );

  Future<void> _replacesRecordPatternWithPropertyRead() => expectFix(
    '''
int f(({int x}) r) {
  final (x: a) = r;
  return a;
}
''',
    (context) => AvoidSingleFieldDestructuringFix(context: context),
    expected: '''
int f(({int x}) r) {
  final a = r.x;
  return a;
}
''',
  );

  Future<void> _keepsPositionalRecordPattern() => expectNoFix('''
int f((int, int) r) {
  final (a,) = r;
  return a;
}
''', (context) => AvoidSingleFieldDestructuringFix(context: context));

  Future<void> _keepsNestedPatterns() => expectNoFix(
    '''
class P {
  final (int, int) pair = (1, 2);
}

int f(P p) {
  final P(:pair) = p;
  final P(pair: (a, _)) = p;
  return a;
}
''',
    (context) => AvoidSingleFieldDestructuringFix(context: context),
    occurrence: 1,
  );
}
