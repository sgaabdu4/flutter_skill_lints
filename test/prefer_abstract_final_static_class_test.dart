import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_abstract_final_static_class_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_abstract_final_static_class.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferAbstractFinalStaticClassTest>(
    'PreferAbstractFinalStaticClassTest',
    PreferAbstractFinalStaticClassTest.new,
    {
      'reportsStaticOnlyClass': (t) => t.reportsStaticOnlyClass(),
      'acceptsClassWithInstanceMember': (t) => t.acceptsClassWithInstanceMember(),
      'acceptsAlreadyAbstractFinalClass': (t) => t.acceptsAlreadyAbstractFinalClass(),
      'acceptsEmptyClass': (t) => t.acceptsEmptyClass(),
      'acceptsSealedAndBaseClasses': (t) => t.acceptsSealedAndBaseClasses(),
      'acceptsClassWithConstructor': (t) => t.acceptsClassWithConstructor(),
      'addsAbstractFinal': (t) => t.addsAbstractFinal(),
      'addsFinalToAbstractClass': (t) => t.addsFinalToAbstractClass(),
      'addsAbstractToFinalClass': (t) => t.addsAbstractToFinalClass(),
    },
  );
}

final class PreferAbstractFinalStaticClassTest extends FixRuleTest {
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

  Future<void> reportsStaticOnlyClass() =>
      assertDiagnostics(_plain, [lint(_plain.indexOf('class Utils'), _plain.trimRight().length)]);

  Future<void> acceptsClassWithInstanceMember() => assertNoDiagnostics('''
class Utils {
  static int twice(int x) => x * 2;
  int thrice(int x) => x * 3;
}
''');

  Future<void> acceptsAlreadyAbstractFinalClass() => assertNoDiagnostics('''
abstract final class Utils {
  static int twice(int x) => x * 2;
}
''');

  Future<void> acceptsEmptyClass() => assertNoDiagnostics('''
class Empty {}
''');

  Future<void> acceptsSealedAndBaseClasses() => assertNoDiagnostics('''
sealed class A {
  static int one() => 1;
}

base class B {
  static int two() => 2;
}
''');

  Future<void> acceptsClassWithConstructor() => assertNoDiagnostics('''
class Utils {
  const Utils();
  static int twice(int x) => x * 2;
}
''');

  Future<void> addsAbstractFinal() => expectFix(
    _plain,
    (context) => PreferAbstractFinalStaticClassFix(context: context),
    expected: '''
abstract final class Utils {
  static const int limit = 1;
  static int twice(int x) => x * 2;
}
''',
  );

  Future<void> addsFinalToAbstractClass() => expectFix(
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

  Future<void> addsAbstractToFinalClass() => expectFix(
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
