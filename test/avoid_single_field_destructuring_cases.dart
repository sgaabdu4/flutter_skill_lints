import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_single_field_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_field_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidSingleFieldDestructuringTest>(
    'AvoidSingleFieldDestructuringTest',
    AvoidSingleFieldDestructuringTest.new,
    {
      'reportsSingleFieldObjectPattern': (t) => t.reportsSingleFieldObjectPattern(),
      'reportsSingleNamedRecordField': (t) => t.reportsSingleNamedRecordField(),
      'acceptsTwoFieldPattern': (t) => t.acceptsTwoFieldPattern(),
      'replacesObjectPatternWithPropertyRead': (t) => t.replacesObjectPatternWithPropertyRead(),
      'replacesRecordPatternWithPropertyRead': (t) => t.replacesRecordPatternWithPropertyRead(),
      'keepsPositionalRecordPattern': (t) => t.keepsPositionalRecordPattern(),
      'keepsNestedPatterns': (t) => t.keepsNestedPatterns(),
    },
  );
}

final class AvoidSingleFieldDestructuringTest extends FixRuleTest {
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

  Future<void> reportsSingleFieldObjectPattern() => assertDiagnostics(_object, [
    lint(_object.indexOf('final P(:x) = p'), 'final P(:x) = p'.length),
  ]);

  Future<void> reportsSingleNamedRecordField() async {
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

  Future<void> acceptsTwoFieldPattern() => assertNoDiagnostics('''
class P {
  final int x = 0;
  final int y = 0;
}

int f(P p) {
  final P(:x, :y) = p;
  return x + y;
}
''');

  Future<void> replacesObjectPatternWithPropertyRead() => expectFix(
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

  Future<void> replacesRecordPatternWithPropertyRead() => expectFix(
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

  Future<void> keepsPositionalRecordPattern() => expectNoFix('''
int f((int, int) r) {
  final (a,) = r;
  return a;
}
''', (context) => AvoidSingleFieldDestructuringFix(context: context));

  Future<void> keepsNestedPatterns() => expectNoFix(
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
