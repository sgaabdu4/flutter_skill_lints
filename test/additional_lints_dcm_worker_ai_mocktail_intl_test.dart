import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_implementation_in_mocks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_mock_object.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_intl_name.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidImplementationInMocksTest>(
    'AvoidImplementationInMocksTest',
    _AvoidImplementationInMocksTest.new,
    _AvoidImplementationInMocksTest._allCases,
  );
  analysisRuleSuite<_PassMockObjectTest>(
    'PassMockObjectTest',
    _PassMockObjectTest.new,
    _PassMockObjectTest._allCases,
  );
  analysisRuleSuite<_PreferIntlNameTest>(
    'PreferIntlNameTest',
    _PreferIntlNameTest.new,
    _PreferIntlNameTest._allCases,
  );
}

final class _AvoidImplementationInMocksTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidImplementationInMocksTest)> get _allCases =>
      caseSet<_AvoidImplementationInMocksTest>(
        parent: const {},
        own: {
          'test_overrideMethodInMock_lint': (t) => t._overrideMethodInMockLint(),
          'test_overrideFieldInMock_lint': (t) => t._overrideFieldInMockLint(),
          'test_emptyMock_noLint': (t) => t._emptyMockNoLint(),
          'test_fakeImplementation_noLint': (t) => t._fakeImplementationNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidImplementationInMocks();
    super.setUp();
  }

  Future<void> _overrideMethodInMockLint() async {
    const source = r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  String sound();
}

class MockCat extends Mock implements Cat {
  @override
  String sound() => 'meow';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('sound() =>'), 'sound'.length)]);
  }

  Future<void> _overrideFieldInMockLint() async {
    const source = r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  int get lives;
}

class MockCat extends Mock implements Cat {
  @override
  final int lives = 9;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('lives ='), 'lives'.length)]);
  }

  Future<void> _emptyMockNoLint() async {
    await assertNoDiagnostics(r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  String sound();
}

class MockCat extends Mock implements Cat {}
''');
  }

  Future<void> _fakeImplementationNoLint() async {
    await assertNoDiagnostics(r'''
abstract class Cat {
  String sound();
}

class FakeCat implements Cat {
  @override
  String sound() => 'meow';
}
''');
  }
}

final class _PassMockObjectTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PassMockObjectTest)> get _allCases =>
      caseSet<_PassMockObjectTest>(
        parent: const {},
        own: {
          'test_whenTargetsRegularObject_lint': (t) => t._whenTargetsRegularObjectLint(),
          'test_verifyTargetsRegularObject_lint': (t) => t._verifyTargetsRegularObjectLint(),
          'test_whenTargetsMock_noLint': (t) => t._whenTargetsMockNoLint(),
          'test_nonCallbackWhen_noLint': (t) => t._nonCallbackWhenNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PassMockObject();
    super.setUp();
  }

  Future<void> _whenTargetsRegularObjectLint() async {
    const source = r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  String sound();
}

class RealCat implements Cat {
  @override
  String sound() => 'meow';
}

void when(Object? Function() call) {}

void test(RealCat cat) {
  when(() => cat.sound());
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('cat.sound'), 'cat'.length)]);
  }

  Future<void> _verifyTargetsRegularObjectLint() async {
    const source = r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  String sound();
}

class RealCat implements Cat {
  @override
  String sound() => 'meow';
}

void verify(Object? Function() call) {}

void test(RealCat cat) {
  verify(() => cat.sound());
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('cat.sound'), 'cat'.length)]);
  }

  Future<void> _whenTargetsMockNoLint() async {
    await assertNoDiagnostics(r'''
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
abstract class Cat {
  String sound();
}

class MockCat extends Mock implements Cat {}

void when(Object? Function() call) {}

void test(MockCat cat) {
  when(() => cat.sound());
}
''');
  }

  Future<void> _nonCallbackWhenNoLint() async {
    await assertNoDiagnostics(r'''
void when(Object? call) {}
String sound() => 'meow';

void test() {
  when(sound());
}
''');
  }
}

final class _PreferIntlNameTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_PreferIntlNameTest)> get _allCases =>
      caseSet<_PreferIntlNameTest>(
        parent: const {},
        own: {
          'test_fieldNameMismatch_lint': (t) => t._fieldNameMismatchLint(),
          'test_getterNameMismatch_lint': (t) => t._getterNameMismatchLint(),
          'test_methodNameMismatch_lint': (t) => t._methodNameMismatchLint(),
          'test_matchingName_noLint': (t) => t._matchingNameNoLint(),
          'test_topLevelIntl_noLint': (t) => t._topLevelIntlNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferIntlName();
    super.setUp();
  }

  Future<void> _fieldNameMismatchLint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? name}) => value;
}

class CatLabels {
  static final title = Intl.message('Title', name: 'wrong');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'wrong'"), "'wrong'".length)]);
  }

  Future<void> _getterNameMismatchLint() async {
    const source = r'''
class Intl {
  static String message(String value, {String? name}) => value;
}

class CatLabels {
  String get title => Intl.message('Title', name: 'CatLabels_heading');
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'CatLabels_heading'"), "'CatLabels_heading'".length),
    ]);
  }

  Future<void> _methodNameMismatchLint() async {
    const source = r'''
class Intl {
  static String plural(int count, {String? name}) => '$count';
}

class CatLabels {
  String count(int value) => Intl.plural(value, name: 'count');
}
''';

    await assertDiagnostics(source, [lint(source.indexOf("'count'"), "'count'".length)]);
  }

  Future<void> _matchingNameNoLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(String value, {String? name}) => value;
}

class CatLabels {
  static final title = Intl.message('Title', name: 'CatLabels_title');
  String get subtitle => Intl.message('Subtitle', name: 'CatLabels_subtitle');
  String action() => Intl.message('Action', name: 'CatLabels_action');
}
''');
  }

  Future<void> _topLevelIntlNoLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(String value, {String? name}) => value;
}

final title = Intl.message('Title', name: 'title');
''');
  }
}
