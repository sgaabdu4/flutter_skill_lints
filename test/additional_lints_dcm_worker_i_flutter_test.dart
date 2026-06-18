// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_safe_area.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_type_assertions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_using_list_view.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferUsingListViewTest);
    defineReflectiveTests(AvoidUnnecessarySafeAreaTest);
    defineReflectiveTests(AvoidUnnecessaryTypeAssertionsTest);
  });
}

abstract class _FlutterRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
enum Axis { horizontal, vertical }

class Widget {
  const Widget();
}

class Column extends Widget {
  const Column({double spacing = 0, List<Widget> children = const <Widget>[]});
}

class Row extends Widget {
  const Row({double spacing = 0, List<Widget> children = const <Widget>[]});
}

class SizedBox extends Widget {
  const SizedBox();
}

class SingleChildScrollView extends Widget {
  const SingleChildScrollView({
    Axis scrollDirection = Axis.vertical,
    Widget? child,
  });
}

class SafeArea extends Widget {
  const SafeArea({
    bool left = true,
    bool top = true,
    bool right = true,
    bool bottom = true,
    Widget? child,
  });
}
''');
  }
}

@reflectiveTest
final class PreferUsingListViewTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferUsingListView();
    super.setUp();
  }

  Future<void> test_verticalScrollViewWrappingDynamicColumn_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(List<Widget> children) {
  return SingleChildScrollView(
    child: Column(children: [for (final child in children) child]),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('SingleChildScrollView'), 'SingleChildScrollView'.length),
    ]);
  }

  Future<void> test_horizontalScrollViewWrappingDynamicRow_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(List<Widget> children) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [...children]),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('SingleChildScrollView'), 'SingleChildScrollView'.length),
    ]);
  }

  Future<void> test_verticalScrollViewWrappingSizedBox_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SingleChildScrollView(child: SizedBox());
}
''');
  }

  Future<void> test_verticalScrollViewWrappingFixedColumn_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return SingleChildScrollView(
    child: Column(
      spacing: 8,
      children: const <Widget>[SizedBox(), SizedBox()],
    ),
  );
}
''');
  }

  Future<void> test_horizontalScrollViewWrappingColumn_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Column(children: const <Widget>[]),
  );
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessarySafeAreaTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessarySafeArea();
    super.setUp();
  }

  Future<void> test_allEdgesDisabled_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SafeArea(
    left: false,
    top: false,
    right: false,
    bottom: false,
    child: SizedBox(),
  );
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('SafeArea'), 'SafeArea'.length)]);
  }

  Future<void> test_nestedSafeArea_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SafeArea(child: SafeArea(child: SizedBox()));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('SafeArea'), 'SafeArea'.length)]);
  }

  Future<void> test_defaultSafeArea_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SafeArea(child: SizedBox());
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryTypeAssertionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryTypeAssertions();
    super.setUp();
  }

  Future<void> test_isSameType_lint() async {
    const source = r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value is String'), 'value is String'.length),
    ]);
  }

  Future<void> test_asSameType_lint() async {
    const source = r'''
// ignore_for_file: unnecessary_cast

String cast(String value) => value as String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value as String'), 'value as String'.length),
    ]);
  }

  Future<void> test_isObjectFromNonNullableValue_lint() async {
    const source = r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is Object;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value is Object'), 'value is Object'.length),
    ]);
  }

  Future<void> test_nullableIsNonNullable_noLint() async {
    await assertNoDiagnostics(r'''
bool check(String? value) => value is String;
''');
  }

  Future<void> test_downcast_noLint() async {
    await assertNoDiagnostics(r'''
String cast(Object value) => value as String;
''');
  }

  Future<void> test_negatedIsCheck_noLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is! String;
''');
  }
}
