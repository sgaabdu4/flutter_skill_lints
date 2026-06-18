// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_child_column_or_row.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_static_icon_provider.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_extracting_callbacks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSingleChildColumnOrRowTest);
    defineReflectiveTests(PreferExtractingCallbacksTest);
    defineReflectiveTests(PreferCorrectStaticIconProviderTest);
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
class Widget {
  const Widget();
}

class Column extends Widget {
  const Column({List<Widget> children = const <Widget>[]});
}

class Row extends Widget {
  const Row({List<Widget> children = const <Widget>[]});
}

class SizedBox extends Widget {
  const SizedBox();
}

class TextButton extends Widget {
  const TextButton({void Function()? onPressed, Widget? child});
}
''');

    newPackage('flutter').addFile('lib/widgets/icon_data.dart', r'''
class IconData {
  const IconData(int codePoint, {String? fontFamily});
}
''');
  }
}

@reflectiveTest
final class AvoidSingleChildColumnOrRowTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = AvoidSingleChildColumnOrRow();
    super.setUp();
  }

  Future<void> test_columnWithSingleChild_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Column(children: <Widget>[SizedBox()]);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> test_rowWithSingleChild_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Row(children: <Widget>[SizedBox()]);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row'), 'Row'.length)]);
  }

  Future<void> test_columnWithTwoChildren_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Column(children: <Widget>[SizedBox(), SizedBox()]);
}
''');
  }

  Future<void> test_conditionalChild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(bool show) {
  return Column(children: <Widget>[if (show) const SizedBox()]);
}
''');
  }
}

@reflectiveTest
final class PreferExtractingCallbacksTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferExtractingCallbacks();
    super.setUp();
  }

  Future<void> test_blockCallbackWithTwoStatements_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void logTap() {}
void submit() {}

Widget build() {
  return TextButton(
    onPressed: () {
      logTap();
      submit();
    },
    child: const SizedBox(),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('() {', source.indexOf('onPressed')), '()'.length),
    ]);
  }

  Future<void> test_callbackWithControlFlow_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void submit() {}

Widget build(bool enabled) {
  return TextButton(
    onPressed: () {
      if (enabled) submit();
    },
    child: const SizedBox(),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('() {', source.indexOf('onPressed')), '()'.length),
    ]);
  }

  Future<void> test_trivialExpressionCallback_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void submit() {}

Widget build() {
  return TextButton(
    onPressed: () => submit(),
    child: const SizedBox(),
  );
}
''');
  }

  Future<void> test_callbackReference_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void submit() {}

Widget build() {
  return TextButton(
    onPressed: submit,
    child: const SizedBox(),
  );
}
''');
  }
}

@reflectiveTest
final class PreferCorrectStaticIconProviderTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferCorrectStaticIconProvider();
    super.setUp();
  }

  Future<void> test_topLevelIconDataConstant_lint() async {
    const source = r'''
import 'package:flutter/widgets/icon_data.dart';

const IconData appAdd = IconData(0xe001, fontFamily: 'AppIcons');
''';

    await assertDiagnostics(source, [lint(source.indexOf('appAdd'), 'appAdd'.length)]);
  }

  Future<void> test_staticProviderIconData_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets/icon_data.dart';

abstract final class AppIcons {
  static const IconData add = IconData(0xe001, fontFamily: 'AppIcons');
}
''');
  }

  Future<void> test_nonIconDataConstant_noLint() async {
    await assertNoDiagnostics(r'''
const int codePoint = 0xe001;
''');
  }
}
