import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_only_rethrow_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_only_rethrow.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidOnlyRethrowTest>('AvoidOnlyRethrowTest', _AvoidOnlyRethrowTest.new, {
    'reportsCatchThatOnlyRethrows': (t) => t._reportsCatchThatOnlyRethrows(),
    'acceptsCatchThatDoesMoreThanRethrow': (t) => t._acceptsCatchThatDoesMoreThanRethrow(),
    'unwrapsTryWhenItIsTheOnlyCatch': (t) => t._unwrapsTryWhenItIsTheOnlyCatch(),
    'removesOnlyTheCatchWhenFinallyExists': (t) => t._removesOnlyTheCatchWhenFinallyExists(),
    'removesOnlyTheCatchWhenOthersExist': (t) => t._removesOnlyTheCatchWhenOthersExist(),
  });
}

final class _AvoidOnlyRethrowTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidOnlyRethrow();
    super.setUp();
  }

  static const _only = '''
void f() {
  try {
    print(1);
    print(2);
  } catch (e) {
    rethrow;
  }
}
''';

  Future<void> _reportsCatchThatOnlyRethrows() => assertDiagnostics(_only, [
    lint(_only.indexOf('catch (e)'), 'catch (e) {\n    rethrow;\n  }'.length),
  ]);

  Future<void> _acceptsCatchThatDoesMoreThanRethrow() => assertNoDiagnostics('''
void f() {
  try {
    print(1);
  } catch (e) {
    print(e);
    rethrow;
  }
}
''');

  Future<void> _unwrapsTryWhenItIsTheOnlyCatch() => expectFix(
    _only,
    (context) => AvoidOnlyRethrowFix(context: context),
    expected: '''
void f() {
  print(1);
print(2);
}
''',
  );

  Future<void> _removesOnlyTheCatchWhenFinallyExists() => expectFix(
    '''
void f() {
  try {
    print(1);
  } catch (e) {
    rethrow;
  } finally {
    print(2);
  }
}
''',
    (context) => AvoidOnlyRethrowFix(context: context),
    expected: '''
void f() {
  try {
    print(1);
  }  finally {
    print(2);
  }
}
''',
  );

  Future<void> _removesOnlyTheCatchWhenOthersExist() => expectFix(
    '''
void f() {
  try {
    print(1);
  } on FormatException {
    print(3);
  } catch (e) {
    rethrow;
  }
}
''',
    (context) => AvoidOnlyRethrowFix(context: context),
    expected: '''
void f() {
  try {
    print(1);
  } on FormatException {
    print(3);
  } 
}
''',
  );
}
