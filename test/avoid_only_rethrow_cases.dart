import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_only_rethrow_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_only_rethrow.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidOnlyRethrowTest>('AvoidOnlyRethrowTest', AvoidOnlyRethrowTest.new, {
    'reportsCatchThatOnlyRethrows': (t) => t.reportsCatchThatOnlyRethrows(),
    'acceptsCatchThatDoesMoreThanRethrow': (t) => t.acceptsCatchThatDoesMoreThanRethrow(),
    'unwrapsTryWhenItIsTheOnlyCatch': (t) => t.unwrapsTryWhenItIsTheOnlyCatch(),
    'removesOnlyTheCatchWhenFinallyExists': (t) => t.removesOnlyTheCatchWhenFinallyExists(),
    'removesOnlyTheCatchWhenOthersExist': (t) => t.removesOnlyTheCatchWhenOthersExist(),
  });
}

final class AvoidOnlyRethrowTest extends FixRuleTest {
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

  Future<void> reportsCatchThatOnlyRethrows() => assertDiagnostics(_only, [
    lint(_only.indexOf('catch (e)'), 'catch (e) {\n    rethrow;\n  }'.length),
  ]);

  Future<void> acceptsCatchThatDoesMoreThanRethrow() => assertNoDiagnostics('''
void f() {
  try {
    print(1);
  } catch (e) {
    print(e);
    rethrow;
  }
}
''');

  Future<void> unwrapsTryWhenItIsTheOnlyCatch() => expectFix(
    _only,
    (context) => AvoidOnlyRethrowFix(context: context),
    expected: '''
void f() {
  print(1);
print(2);
}
''',
  );

  Future<void> removesOnlyTheCatchWhenFinallyExists() => expectFix(
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

  Future<void> removesOnlyTheCatchWhenOthersExist() => expectFix(
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
