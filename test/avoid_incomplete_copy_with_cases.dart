import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incomplete_copy_with_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incomplete_copy_with.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidIncompleteCopyWithTest>(
    'AvoidIncompleteCopyWithTest',
    AvoidIncompleteCopyWithTest.new,
    {
      'reportsMissingParameters': (t) => t.reportsMissingParameters(),
      'acceptsCompleteCopyWith': (t) => t.acceptsCompleteCopyWith(),
      'ignoresClassWithoutCopyWith': (t) => t.ignoresClassWithoutCopyWith(),
      'ignoresClassWithoutDefaultConstructor': (t) => t.ignoresClassWithoutDefaultConstructor(),
      'addsMissingNamedParameter': (t) => t.addsMissingNamedParameter(),
      'wrapsParameterInBracesWhenPositional': (t) => t.wrapsParameterInBracesWhenPositional(),
      'wrapsParameterInEmptyList': (t) => t.wrapsParameterInEmptyList(),
    },
  );
}

final class AvoidIncompleteCopyWithTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidIncompleteCopyWith();
    super.setUp();
  }

  static const _missing = '''
class A {
  final int a;
  final String? b;
  A({required int a, String? b}) : a = a, b = b;

  A copyWith({int? a}) => A(a: a ?? this.a, b: b);
}
''';

  Future<void> reportsMissingParameters() =>
      assertDiagnostics(_missing, [lint(_missing.indexOf('copyWith'), 'copyWith'.length)]);

  Future<void> acceptsCompleteCopyWith() => assertNoDiagnostics('''
class A {
  final int a;
  A({required int a}) : a = a;

  A copyWith({int? a}) => A(a: a ?? this.a);
}
''');

  Future<void> ignoresClassWithoutCopyWith() => assertNoDiagnostics('''
class A {
  final int a;
  A({required int a}) : a = a;
}
''');

  Future<void> ignoresClassWithoutDefaultConstructor() => assertNoDiagnostics('''
class A {
  final int a;
  A.named(int a) : a = a;

  A copyWith() => A.named(a);
}
''');

  Future<void> addsMissingNamedParameter() => expectFix(
    _missing,
    (context) => AvoidIncompleteCopyWithFix(context: context),
    expected: '''
class A {
  final int a;
  final String? b;
  A({required int a, String? b}) : a = a, b = b;

  A copyWith({int? a, String? b}) => A(a: a ?? this.a, b: b);
}
''',
  );

  Future<void> wrapsParameterInBracesWhenPositional() => expectFix(
    '''
class A {
  final int a;
  final int b;
  A(int a, int b) : a = a, b = b;

  A copyWith(int a) => A(a, b);
}
''',
    (context) => AvoidIncompleteCopyWithFix(context: context),
    expected: '''
class A {
  final int a;
  final int b;
  A(int a, int b) : a = a, b = b;

  A copyWith(int a, {int? b}) => A(a, b);
}
''',
  );

  Future<void> wrapsParameterInEmptyList() => expectFix(
    '''
class A {
  final int a;
  A(int a) : a = a;

  A copyWith() => A(a);
}
''',
    (context) => AvoidIncompleteCopyWithFix(context: context),
    expected: '''
class A {
  final int a;
  A(int a) : a = a;

  A copyWith({int? a}) => A(a);
}
''',
  );
}
