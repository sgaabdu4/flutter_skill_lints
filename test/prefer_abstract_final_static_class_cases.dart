import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_abstract_final_static_class.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_PreferAbstractFinalStaticClassTest>(
    'PreferAbstractFinalStaticClassTest',
    _PreferAbstractFinalStaticClassTest.new,
    {
      'reportsStaticOnlyClass': (t) => t._reportsStaticOnlyClass(),
      'acceptsClassWithInstanceMember': (t) => t._acceptsClassWithInstanceMember(),
      'acceptsAlreadyAbstractFinalClass': (t) => t._acceptsAlreadyAbstractFinalClass(),
      'acceptsEmptyClass': (t) => t._acceptsEmptyClass(),
      'acceptsSealedAndBaseClasses': (t) => t._acceptsSealedAndBaseClasses(),
      'acceptsClassWithConstructor': (t) => t._acceptsClassWithConstructor(),
      'addsAbstractFinal': (t) => t._addsAbstractFinal(),
      'addsFinalToAbstractClass': (t) => t._addsFinalToAbstractClass(),
      'addsAbstractToFinalClass': (t) => t._addsAbstractToFinalClass(),
    },
  );
}

final class _PreferAbstractFinalStaticClassTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferAbstractFinalStaticClass();
    super.setUp();
  }

  static const _plain = '''
class Utils {
  static const int limit = 1;
  static int twice(int x) => x * 2;
}
''';

  Future<void> _reportsStaticOnlyClass() =>
      assertDiagnostics(_plain, [lint(_plain.indexOf('class Utils'), _plain.trimRight().length)]);

  Future<void> _acceptsClassWithInstanceMember() => assertNoDiagnostics('''
class Utils {
  static int twice(int x) => x * 2;
  int thrice(int x) => x * 3;
}
''');

  Future<void> _acceptsAlreadyAbstractFinalClass() => assertNoDiagnostics('''
abstract final class Utils {
  static int twice(int x) => x * 2;
}
''');

  Future<void> _acceptsEmptyClass() => assertNoDiagnostics('''
class Empty {}
''');

  Future<void> _acceptsSealedAndBaseClasses() => assertNoDiagnostics('''
sealed class A {
  static int one() => 1;
}

base class B {
  static int two() => 2;
}
''');

  Future<void> _acceptsClassWithConstructor() => assertNoDiagnostics('''
class Utils {
  const Utils();
  static int twice(int x) => x * 2;
}
''');

  Future<void> _addsAbstractFinal() => expectFix(
    _plain,
    (context) => PreferAbstractFinalStaticClassFix(context: context),
    expected: '''
abstract final class Utils {
  static const int limit = 1;
  static int twice(int x) => x * 2;
}
''',
  );

  Future<void> _addsFinalToAbstractClass() => expectFix(
    '''
abstract class Utils {
  static int twice(int x) => x * 2;
}
''',
    (context) => PreferAbstractFinalStaticClassFix(context: context),
    expected: '''
abstract final class Utils {
  static int twice(int x) => x * 2;
}
''',
  );

  Future<void> _addsAbstractToFinalClass() => expectFix(
    '''
final class Utils {
  static int twice(int x) => x * 2;
}
''',
    (context) => PreferAbstractFinalStaticClassFix(context: context),
    expected: '''
abstract final class Utils {
  static int twice(int x) => x * 2;
}
''',
  );
}
