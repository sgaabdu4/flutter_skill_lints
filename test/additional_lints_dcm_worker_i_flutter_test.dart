import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_safe_area.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_type_assertions.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_using_list_view.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferUsingListViewTest>(
    'PreferUsingListViewTest',
    PreferUsingListViewTest.new,
    {
      'test_verticalScrollViewWrappingDynamicColumn_lint': (t) =>
          t._verticalScrollViewWrappingDynamicColumnLint(),
      'test_horizontalScrollViewWrappingDynamicRow_lint': (t) =>
          t._horizontalScrollViewWrappingDynamicRowLint(),
      'test_verticalScrollViewWrappingSizedBox_noLint': (t) =>
          t._verticalScrollViewWrappingSizedBoxNoLint(),
      'test_verticalScrollViewWrappingFixedColumn_noLint': (t) =>
          t._verticalScrollViewWrappingFixedColumnNoLint(),
      'test_horizontalScrollViewWrappingColumn_noLint': (t) =>
          t._horizontalScrollViewWrappingColumnNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnnecessarySafeAreaTest>(
    'AvoidUnnecessarySafeAreaTest',
    AvoidUnnecessarySafeAreaTest.new,
    {
      'test_allEdgesDisabled_lint': (t) => t._allEdgesDisabledLint(),
      'test_nestedSafeArea_lint': (t) => t._nestedSafeAreaLint(),
      'test_defaultSafeArea_noLint': (t) => t._defaultSafeAreaNoLint(),
    },
  );
  analysisRuleSuite<AvoidUnnecessaryTypeAssertionsTest>(
    'AvoidUnnecessaryTypeAssertionsTest',
    AvoidUnnecessaryTypeAssertionsTest.new,
    {
      'test_isSameType_lint': (t) => t._isSameTypeLint(),
      'test_asSameType_lint': (t) => t._asSameTypeLint(),
      'test_isObjectFromNonNullableValue_lint': (t) => t._isObjectFromNonNullableValueLint(),
      'test_nullableIsNonNullable_noLint': (t) => t._nullableIsNonNullableNoLint(),
      'test_downcast_noLint': (t) => t._downcastNoLint(),
      'test_negatedIsCheck_noLint': (t) => t._negatedIsCheckNoLint(),
    },
  );
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

final class PreferUsingListViewTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferUsingListView();
    super.setUp();
  }

  Future<void> _verticalScrollViewWrappingDynamicColumnLint() async {
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

  Future<void> _horizontalScrollViewWrappingDynamicRowLint() async {
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

  Future<void> _verticalScrollViewWrappingSizedBoxNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SingleChildScrollView(child: SizedBox());
}
''');
  }

  Future<void> _verticalScrollViewWrappingFixedColumnNoLint() async {
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

  Future<void> _horizontalScrollViewWrappingColumnNoLint() async {
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

final class AvoidUnnecessarySafeAreaTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessarySafeArea();
    super.setUp();
  }

  Future<void> _allEdgesDisabledLint() async {
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

  Future<void> _nestedSafeAreaLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SafeArea(child: SafeArea(child: SizedBox()));
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('SafeArea'), 'SafeArea'.length)]);
  }

  Future<void> _defaultSafeAreaNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const SafeArea(child: SizedBox());
}
''');
  }
}

final class AvoidUnnecessaryTypeAssertionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryTypeAssertions();
    super.setUp();
  }

  Future<void> _isSameTypeLint() async {
    const source = r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value is String'), 'value is String'.length),
    ]);
  }

  Future<void> _asSameTypeLint() async {
    const source = r'''
// ignore_for_file: unnecessary_cast

String cast(String value) => value as String;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value as String'), 'value as String'.length),
    ]);
  }

  Future<void> _isObjectFromNonNullableValueLint() async {
    const source = r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is Object;
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('value is Object'), 'value is Object'.length),
    ]);
  }

  Future<void> _nullableIsNonNullableNoLint() async {
    await assertNoDiagnostics(r'''
bool check(String? value) => value is String;
''');
  }

  Future<void> _downcastNoLint() async {
    await assertNoDiagnostics(r'''
String cast(Object value) => value as String;
''');
  }

  Future<void> _negatedIsCheckNoLint() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: unnecessary_type_check

bool check(String value) => value is! String;
''');
  }
}
