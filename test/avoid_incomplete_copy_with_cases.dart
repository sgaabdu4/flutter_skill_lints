import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_incomplete_copy_with_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_incomplete_copy_with.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidIncompleteCopyWithTest>(
    'AvoidIncompleteCopyWithTest',
    _AvoidIncompleteCopyWithTest.new,
    {
      'reportsMissingParameters': (t) => t._reportsMissingParameters(),
      'acceptsCompleteCopyWith': (t) => t._acceptsCompleteCopyWith(),
      'ignoresClassWithoutCopyWith': (t) => t._ignoresClassWithoutCopyWith(),
      'ignoresClassWithoutDefaultConstructor': (t) => t._ignoresClassWithoutDefaultConstructor(),
      'addsMissingNamedParameter': (t) => t._addsMissingNamedParameter(),
      'wrapsParameterInBracesWhenPositional': (t) => t._wrapsParameterInBracesWhenPositional(),
      'wrapsParameterInEmptyList': (t) => t._wrapsParameterInEmptyList(),
    },
  );
}

final class _AvoidIncompleteCopyWithTest extends FixRuleTest {
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

  Future<void> _reportsMissingParameters() =>
      assertDiagnostics(_missing, [lint(_missing.indexOf('copyWith'), 'copyWith'.length)]);

  Future<void> _acceptsCompleteCopyWith() => assertNoDiagnostics('''
class A {
  final int a;
  A({required int a}) : a = a;

  A copyWith({int? a}) => A(a: a ?? this.a);
}
''');

  Future<void> _ignoresClassWithoutCopyWith() => assertNoDiagnostics('''
class A {
  final int a;
  A({required int a}) : a = a;
}
''');

  Future<void> _ignoresClassWithoutDefaultConstructor() => assertNoDiagnostics('''
class A {
  final int a;
  A.named(int a) : a = a;

  A copyWith() => A.named(a);
}
''');

  Future<void> _addsMissingNamedParameter() => expectFix(
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

  Future<void> _wrapsParameterInBracesWhenPositional() => expectFix(
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

  Future<void> _wrapsParameterInEmptyList() => expectFix(
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
