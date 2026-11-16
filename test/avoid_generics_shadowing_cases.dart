import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_generics_shadowing_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_generics_shadowing.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidGenericsShadowingTest>(
    'AvoidGenericsShadowingTest',
    AvoidGenericsShadowingTest.new,
    {
      'reportsTypeParameterNamedLikeClass': (t) => t.reportsTypeParameterNamedLikeClass(),
      'reportsMethodTypeParameterNamedLikeEnum': (t) => t.reportsMethodTypeParameterNamedLikeEnum(),
      'acceptsUnrelatedTypeParameters': (t) => t.acceptsUnrelatedTypeParameters(),
      'renamesParameterAndUsages': (t) => t.renamesParameterAndUsages(),
      'skipsNamesAlreadyUsedInScope': (t) => t.skipsNamesAlreadyUsedInScope(),
      'renamesMethodTypeParameter': (t) => t.renamesMethodTypeParameter(),
      'fallsBackToNumberedNames': (t) => t.fallsBackToNumberedNames(),
    },
  );
}

final class AvoidGenericsShadowingTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidGenericsShadowing();
    super.setUp();
  }

  Future<void> reportsTypeParameterNamedLikeClass() async {
    const source = '''
class T {}

class Box<T> {
  T? value;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('<T>') + 1, 1)]);
  }

  Future<void> reportsMethodTypeParameterNamedLikeEnum() async {
    const source = '''
enum Kind { a }

class Holder {
  void run<Kind>(Kind value) {}
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('<Kind>') + 1, 'Kind'.length)]);
  }

  Future<void> acceptsUnrelatedTypeParameters() => assertNoDiagnostics('''
class Box<T> {
  T? value;
}
''');

  Future<void> renamesParameterAndUsages() => expectFix(
    '''
class T {}

class Box<T> {
  T? value;
  T? read() => value;
}
''',
    (context) => AvoidGenericsShadowingFix(context: context),
    expected: '''
class T {}

class Box<R> {
  R? value;
  R? read() => value;
}
''',
  );

  Future<void> skipsNamesAlreadyUsedInScope() => expectFix(
    '''
class T {}

class Box<T, R> {
  T? value;
  R? other;
}
''',
    (context) => AvoidGenericsShadowingFix(context: context),
    expected: '''
class T {}

class Box<E, R> {
  E? value;
  R? other;
}
''',
  );

  Future<void> renamesMethodTypeParameter() => expectFix(
    '''
enum Kind { a }

class Holder {
  void run<Kind>(Kind value) {}
}
''',
    (context) => AvoidGenericsShadowingFix(context: context),
    expected: '''
enum Kind { a }

class Holder {
  void run<T>(T value) {}
}
''',
  );

  Future<void> fallsBackToNumberedNames() => expectFix(
    '''
class T {}
class R {}
class E {}
class S {}
class U {}
class V {}
class W {}

class Box<T> {
  T? value;
}
''',
    (context) => AvoidGenericsShadowingFix(context: context),
    expected: '''
class T {}
class R {}
class E {}
class S {}
class U {}
class V {}
class W {}

class Box<T0> {
  T0? value;
}
''',
  );
}
