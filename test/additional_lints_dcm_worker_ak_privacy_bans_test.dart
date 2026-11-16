import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_accessing_other_classes_private_members.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_names.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidAccessingOtherClassesPrivateMembersTest>(
    'AvoidAccessingOtherClassesPrivateMembersTest',
    _AvoidAccessingOtherClassesPrivateMembersTest.new,
    _AvoidAccessingOtherClassesPrivateMembersTest._allCases,
  );
  analysisRuleSuite<_AvoidBannedNamesTest>(
    'AvoidBannedNamesTest',
    _AvoidBannedNamesTest.new,
    _AvoidBannedNamesTest._allCases,
  );
}

final class _AvoidAccessingOtherClassesPrivateMembersTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidAccessingOtherClassesPrivateMembersTest)>
  get _allCases => caseSet<_AvoidAccessingOtherClassesPrivateMembersTest>(
    parent: const {},
    own: {
      'test_privateInstanceFieldFromOtherObject_lint': (t) =>
          t._privateInstanceFieldFromOtherObjectLint(),
      'test_privateStaticFieldFromOtherClass_lint': (t) =>
          t._privateStaticFieldFromOtherClassLint(),
      'test_privateMethodFromOtherObject_lint': (t) => t._privateMethodFromOtherObjectLint(),
      'test_ownPrivateAccess_noLint': (t) => t._ownPrivateAccessNoLint(),
      'test_publicMemberFromOtherObject_noLint': (t) => t._publicMemberFromOtherObjectNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidAccessingOtherClassesPrivateMembers();
    super.setUp();
  }

  Future<void> _privateInstanceFieldFromOtherObjectLint() async {
    const source = r'''
class User {
  final String _name = 'Ada';
}

class Presenter {
  String title(User user) => user._name;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('_name;'), '_name'.length)]);
  }

  Future<void> _privateStaticFieldFromOtherClassLint() async {
    const source = r'''
class Cache {
  static final Object _store = Object();
}

Object read() => Cache._store;
''';

    await assertDiagnostics(source, [lint(source.indexOf('_store;'), '_store'.length)]);
  }

  Future<void> _privateMethodFromOtherObjectLint() async {
    const source = r'''
class User {
  String _label() => 'Ada';
}

String read(User user) => user._label();
''';

    await assertDiagnostics(source, [lint(source.indexOf('_label();'), '_label'.length)]);
  }

  Future<void> _ownPrivateAccessNoLint() async {
    await assertNoDiagnostics(r'''
class User {
  final String _name = 'Ada';

  String get title => _name;
  String get explicitTitle => this._name;
}
''');
  }

  Future<void> _publicMemberFromOtherObjectNoLint() async {
    await assertNoDiagnostics(r'''
class User {
  final String name = 'Ada';
}

class Presenter {
  String title(User user) => user.name;
}
''');
  }
}

final class _AvoidBannedNamesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidBannedNamesTest)> get _allCases =>
      caseSet<_AvoidBannedNamesTest>(
        parent: const {},
        own: {
          'test_placeholderLocalVariableName_lint': (t) => t._placeholderLocalVariableNameLint(),
          'test_placeholderClassName_lint': (t) => t._placeholderClassNameLint(),
          'test_placeholderParameterName_lint': (t) => t._placeholderParameterNameLint(),
          'test_descriptiveNames_noLint': (t) => t._descriptiveNamesNoLint(),
          'test_overrideMethodName_lintsBaseDeclarationOnly': (t) =>
              t._overrideMethodNameLintsBaseDeclarationOnly(),
        },
      );

  @override
  void setUp() {
    rule = AvoidBannedNames();
    super.setUp();
  }

  Future<void> _placeholderLocalVariableNameLint() async {
    const source = r'''
void read() {
  final foo = 1;
  print(foo);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('foo ='), 'foo'.length)]);
  }

  Future<void> _placeholderClassNameLint() async {
    const source = r'''
class bar {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('bar'), 'bar'.length)]);
  }

  Future<void> _placeholderParameterNameLint() async {
    const source = r'''
void read(String baz) {
  print(baz);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('baz)'), 'baz'.length)]);
  }

  Future<void> _descriptiveNamesNoLint() async {
    await assertNoDiagnostics(r'''
class UserPresenter {
  String title(String userName) => userName;
}
''');
  }

  Future<void> _overrideMethodNameLintsBaseDeclarationOnly() async {
    const source = r'''
class Base {
  void foo() {}
}

class Child extends Base {
  @override
  void foo() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('foo()'), 'foo'.length)]);
  }
}
