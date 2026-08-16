// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_accessing_other_classes_private_members.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_names.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_banned_types.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAccessingOtherClassesPrivateMembersTest);
    defineReflectiveTests(AvoidBannedNamesTest);
    defineReflectiveTests(AvoidBannedTypesTest);
  });
}

@reflectiveTest
final class AvoidAccessingOtherClassesPrivateMembersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidAccessingOtherClassesPrivateMembers();
    super.setUp();
  }

  Future<void> test_privateInstanceFieldFromOtherObject_lint() async {
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

  Future<void> test_privateStaticFieldFromOtherClass_lint() async {
    const source = r'''
class Cache {
  static final Object _store = Object();
}

Object read() => Cache._store;
''';

    await assertDiagnostics(source, [lint(source.indexOf('_store;'), '_store'.length)]);
  }

  Future<void> test_privateMethodFromOtherObject_lint() async {
    const source = r'''
class User {
  String _label() => 'Ada';
}

String read(User user) => user._label();
''';

    await assertDiagnostics(source, [lint(source.indexOf('_label();'), '_label'.length)]);
  }

  Future<void> test_ownPrivateAccess_noLint() async {
    await assertNoDiagnostics(r'''
class User {
  final String _name = 'Ada';

  String get title => _name;
  String get explicitTitle => this._name;
}
''');
  }

  Future<void> test_publicMemberFromOtherObject_noLint() async {
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

@reflectiveTest
final class AvoidBannedNamesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedNames();
    super.setUp();
  }

  Future<void> test_placeholderLocalVariableName_lint() async {
    const source = r'''
void read() {
  final foo = 1;
  print(foo);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('foo ='), 'foo'.length)]);
  }

  Future<void> test_placeholderClassName_lint() async {
    const source = r'''
class bar {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('bar'), 'bar'.length)]);
  }

  Future<void> test_placeholderParameterName_lint() async {
    const source = r'''
void read(String baz) {
  print(baz);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('baz)'), 'baz'.length)]);
  }

  Future<void> test_descriptiveNames_noLint() async {
    await assertNoDiagnostics(r'''
class UserPresenter {
  String title(String userName) => userName;
}
''');
  }

  Future<void> test_overrideMethodName_lintsBaseDeclarationOnly() async {
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

@reflectiveTest
final class AvoidBannedTypesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidBannedTypes();
    super.setUp();
  }

  Future<void> test_dynamicParameter_lint() async {
    const source = r'''
void read(dynamic value) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> test_dynamicReturnType_lint() async {
    const source = r'''
dynamic read() => 1;
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> test_listDynamic_lint() async {
    const source = r'''
List<dynamic> read() => const [];
''';

    await assertDiagnostics(source, [lint(source.indexOf('dynamic'), 'dynamic'.length)]);
  }

  Future<void> test_jsonMapDynamicValue_noLint() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> toJson() => {};
''');
  }

  Future<void> test_generatedLocalizationDynamic_noLint() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    newFile(filePath, 'List<dynamic> delegates = <dynamic>[];');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_objectBoundary_noLint() async {
    await assertNoDiagnostics(r'''
Object? read(Object? value) => value;
''');
  }
}
