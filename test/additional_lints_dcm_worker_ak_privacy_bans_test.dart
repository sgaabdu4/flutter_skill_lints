import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_accessing_other_classes_private_members.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_names.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_types.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidAccessingOtherClassesPrivateMembersTest>(
    'AvoidAccessingOtherClassesPrivateMembersTest',
    AvoidAccessingOtherClassesPrivateMembersTest.new,
    {
      'test_privateInstanceFieldFromOtherObject_lint': (t) =>
          t._privateInstanceFieldFromOtherObjectLint(),
      'test_privateStaticFieldFromOtherClass_lint': (t) =>
          t._privateStaticFieldFromOtherClassLint(),
      'test_privateMethodFromOtherObject_lint': (t) => t._privateMethodFromOtherObjectLint(),
      'test_ownPrivateAccess_noLint': (t) => t._ownPrivateAccessNoLint(),
      'test_publicMemberFromOtherObject_noLint': (t) => t._publicMemberFromOtherObjectNoLint(),
    },
  );
  analysisRuleSuite<AvoidBannedNamesTest>('AvoidBannedNamesTest', AvoidBannedNamesTest.new, {
    'test_placeholderLocalVariableName_lint': (t) => t._placeholderLocalVariableNameLint(),
    'test_placeholderClassName_lint': (t) => t._placeholderClassNameLint(),
    'test_placeholderParameterName_lint': (t) => t._placeholderParameterNameLint(),
    'test_descriptiveNames_noLint': (t) => t._descriptiveNamesNoLint(),
    'test_overrideMethodName_lintsBaseDeclarationOnly': (t) =>
        t._overrideMethodNameLintsBaseDeclarationOnly(),
  });
  analysisRuleSuite<AvoidBannedTypesTest>('AvoidBannedTypesTest', AvoidBannedTypesTest.new, {
    'test_dynamicParameter_lint': (t) => t._dynamicParameterLint(),
    'test_dynamicReturnType_lint': (t) => t._dynamicReturnTypeLint(),
    'test_listDynamic_lint': (t) => t._listDynamicLint(),
    'test_jsonMapDynamicValue_noLint': (t) => t._jsonMapDynamicValueNoLint(),
    'test_jsonMapLiteralDynamicValue_noLint': (t) => t._jsonMapLiteralDynamicValueNoLint(),
    'test_nonJsonMapLiteralDynamic_lint': (t) => t._nonJsonMapLiteralDynamicLint(),
    'test_generatedLocalizationDynamic_noLint': (t) => t._generatedLocalizationDynamicNoLint(),
    'test_objectBoundary_noLint': (t) => t._objectBoundaryNoLint(),
  });
}

final class AvoidAccessingOtherClassesPrivateMembersTest extends AnalysisRuleTest {
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

final class AvoidBannedNamesTest extends AnalysisRuleTest {
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

final class AvoidBannedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedTypes();
    super.setUp();
  }

  Future<void> _dynamicParameterLint() async {
    const source = r'''
void read(dynamic value) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> _dynamicReturnTypeLint() async {
    const source = r'''
dynamic read() => 1;
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> _listDynamicLint() async {
    const source = r'''
List<dynamic> read() => const [];
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> _jsonMapDynamicValueNoLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> toJson() => {};
''');
  }

  // hive-persistence.md:56: `<String, dynamic>{}` is a JSON map literal.
  Future<void> _jsonMapLiteralDynamicValueNoLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> normalize() {
  final normalized = <String, dynamic>{};
  return normalized;
}
''');
  }

  Future<void> _nonJsonMapLiteralDynamicLint() async {
    const source = r'''
final byId = <int, dynamic>{};
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> _generatedLocalizationDynamicNoLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, 'List<dynamic> delegates = <dynamic>[];');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _objectBoundaryNoLint() async {
    await assertNoDiagnostics(r'''
Object? read(Object? value) => value;
''');
  }
}
