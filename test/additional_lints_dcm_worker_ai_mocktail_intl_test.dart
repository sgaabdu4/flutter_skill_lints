// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_implementation_in_mocks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_mock_object.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_intl_name.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidImplementationInMocksTest);
    defineReflectiveTests(PassMockObjectTest);
    defineReflectiveTests(PreferIntlNameTest);
  });
}

@reflectiveTest
final class AvoidImplementationInMocksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidImplementationInMocks();
    super.setUp();
  }

  Future<void> test_overrideMethodInMock_lint() async {
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

  Future<void> test_overrideFieldInMock_lint() async {
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

  Future<void> test_emptyMock_noLint() async {
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

  Future<void> test_fakeImplementation_noLint() async {
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

@reflectiveTest
final class PassMockObjectTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PassMockObject();
    super.setUp();
  }

  Future<void> test_whenTargetsRegularObject_lint() async {
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

  Future<void> test_verifyTargetsRegularObject_lint() async {
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

  Future<void> test_whenTargetsMock_noLint() async {
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

  Future<void> test_nonCallbackWhen_noLint() async {
    await assertNoDiagnostics(r'''
void when(Object? call) {}
String sound() => 'meow';

void test() {
  when(sound());
}
''');
  }
}

@reflectiveTest
final class PreferIntlNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferIntlName();
    super.setUp();
  }

  Future<void> test_fieldNameMismatch_lint() async {
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

  Future<void> test_getterNameMismatch_lint() async {
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

  Future<void> test_methodNameMismatch_lint() async {
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

  Future<void> test_matchingName_noLint() async {
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

  Future<void> test_topLevelIntl_noLint() async {
    await assertNoDiagnostics(r'''
class Intl {
  static String message(String value, {String? name}) => value;
}

final title = Intl.message('Title', name: 'title');
''');
  }
}
