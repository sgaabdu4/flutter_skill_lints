import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_class_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_class_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferClassDestructuringTest>(
    'PreferClassDestructuringTest',
    PreferClassDestructuringTest.new,
    {
      'reportsThreeDistinctProperties': (t) => t.reportsThreeDistinctProperties(),
      'acceptsTwoProperties': (t) => t.acceptsTwoProperties(),
      'acceptsRepeatedSingleProperty': (t) => t.acceptsRepeatedSingleProperty(),
      'ignoresMethodCallsAndAssignments': (t) => t.ignoresMethodCallsAndAssignments(),
      'ignoresConstructorArguments': (t) => t.ignoresConstructorArguments(),
      'ignoresLocalizationObjects': (t) => t.ignoresLocalizationObjects(),
      'reportsOnceInsideLocalFunctionBlock': (t) => t.reportsOnceInsideLocalFunctionBlock(),
      'ignoresFieldsOfThis': (t) => t.ignoresFieldsOfThis(),
      'insertsDestructuringBeforeFirstUse': (t) => t.insertsDestructuringBeforeFirstUse(),
      'sortsDestructuredProperties': (t) => t.sortsDestructuredProperties(),
    },
  );
}

final class PreferClassDestructuringTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferClassDestructuring();
    super.setUp();
  }

  static const _model = '''
class User {
  final String name = '';
  final int age = 0;
  final bool admin = false;
  String greet() => name;
}

''';

  static const _used =
      '''
${_model}String f(User user) {
  final a = user.name;
  final b = user.age;
  final c = user.admin;
  return '\$a\$b\$c';
}
''';

  Future<void> reportsThreeDistinctProperties() =>
      assertDiagnostics(_used, [lint(_used.indexOf('user.name'), 'user.name'.length)]);

  Future<void> acceptsTwoProperties() => assertNoDiagnostics('''
${_model}String f(User user) => '\${user.name}\${user.age}';
''');

  Future<void> acceptsRepeatedSingleProperty() => assertNoDiagnostics('''
${_model}String f(User user) => '\${user.name}\${user.name}\${user.name}';
''');

  Future<void> ignoresMethodCallsAndAssignments() => assertNoDiagnostics('''
class Box {
  String name = '';
  int age = 0;
  bool admin = false;
  String greet() => name;
}

void f(Box box) {
  box.name = 'x';
  box.age = 1;
  box.admin = true;
  box.greet();
}
''');

  Future<void> ignoresConstructorArguments() => assertNoDiagnostics('''
${_model}class Wrap {
  const Wrap(this.a, this.b, this.c);
  final String a;
  final int b;
  final bool c;
}

Wrap f(User user) => Wrap(user.name, user.age, user.admin);
''');

  Future<void> ignoresLocalizationObjects() => assertNoDiagnostics('''
class AppLocalizations {
  final String title = '';
  final String body = '';
  final String footer = '';
}

String f(AppLocalizations l10n, AppLocalizations other) {
  final a = l10n.title + l10n.body + l10n.footer;
  return a + other.title + other.body + other.footer;
}
''');

  Future<void> reportsOnceInsideLocalFunctionBlock() async {
    const source =
        '''
${_model}void f(User user) {
  void inner() {
    print(user.name);
    print(user.age);
    print(user.admin);
  }
  inner();
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('user.name'), 'user.name'.length)]);
  }

  Future<void> ignoresFieldsOfThis() => assertNoDiagnostics('''
class Holder {
  final user = _Inner();
  void f() {
    print(user.a);
    print(user.b);
    print(user.c);
  }
}

class _Inner {
  final int a = 0;
  final int b = 0;
  final int c = 0;
}
''');

  Future<void> insertsDestructuringBeforeFirstUse() => expectFix(
    _used,
    (context) => PreferClassDestructuringFix(context: context),
    expected:
        '''
${_model}String f(User user) {
  final User(:admin, :age, :name) = user;
  final a = user.name;
  final b = user.age;
  final c = user.admin;
  return '\$a\$b\$c';
}
''',
  );

  Future<void> sortsDestructuredProperties() => expectFix(
    '''
${_model}String f(User user) {
  print(user.admin);
  print(user.name);
  return '\${user.age}';
}
''',
    (context) => PreferClassDestructuringFix(context: context),
    expected:
        '''
${_model}String f(User user) {
  final User(:admin, :age, :name) = user;
  print(user.admin);
  print(user.name);
  return '\${user.age}';
}
''',
  );
}
