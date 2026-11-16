import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_class_destructuring_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_class_destructuring.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_PreferClassDestructuringTest>(
    'PreferClassDestructuringTest',
    _PreferClassDestructuringTest.new,
    {
      'reportsThreeDistinctProperties': (t) => t._reportsThreeDistinctProperties(),
      'acceptsTwoProperties': (t) => t._acceptsTwoProperties(),
      'acceptsRepeatedSingleProperty': (t) => t._acceptsRepeatedSingleProperty(),
      'ignoresMethodCallsAndAssignments': (t) => t._ignoresMethodCallsAndAssignments(),
      'ignoresConstructorArguments': (t) => t._ignoresConstructorArguments(),
      'ignoresLocalizationObjects': (t) => t._ignoresLocalizationObjects(),
      'reportsOnceInsideLocalFunctionBlock': (t) => t._reportsOnceInsideLocalFunctionBlock(),
      'ignoresFieldsOfThis': (t) => t._ignoresFieldsOfThis(),
      'insertsDestructuringBeforeFirstUse': (t) => t._insertsDestructuringBeforeFirstUse(),
      'sortsDestructuredProperties': (t) => t._sortsDestructuredProperties(),
    },
  );
}

final class _PreferClassDestructuringTest extends FixRuleTest {
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

  Future<void> _reportsThreeDistinctProperties() =>
      assertDiagnostics(_used, [lint(_used.indexOf('user.name'), 'user.name'.length)]);

  Future<void> _acceptsTwoProperties() => assertNoDiagnostics('''
${_model}String f(User user) => '\${user.name}\${user.age}';
''');

  Future<void> _acceptsRepeatedSingleProperty() => assertNoDiagnostics('''
${_model}String f(User user) => '\${user.name}\${user.name}\${user.name}';
''');

  Future<void> _ignoresMethodCallsAndAssignments() => assertNoDiagnostics('''
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

  Future<void> _ignoresConstructorArguments() => assertNoDiagnostics('''
${_model}class Wrap {
  const Wrap(this.a, this.b, this.c);
  final String a;
  final int b;
  final bool c;
}

Wrap f(User user) => Wrap(user.name, user.age, user.admin);
''');

  Future<void> _ignoresLocalizationObjects() => assertNoDiagnostics('''
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

  Future<void> _reportsOnceInsideLocalFunctionBlock() async {
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

  Future<void> _ignoresFieldsOfThis() => assertNoDiagnostics('''
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

  Future<void> _insertsDestructuringBeforeFirstUse() => expectFix(
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

  Future<void> _sortsDestructuredProperties() => expectFix(
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
