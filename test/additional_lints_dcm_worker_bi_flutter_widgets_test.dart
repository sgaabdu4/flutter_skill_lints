import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_child_column_or_row.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_static_icon_provider.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_extracting_callbacks.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidSingleChildColumnOrRowTest>(
    'AvoidSingleChildColumnOrRowTest',
    _AvoidSingleChildColumnOrRowTest.new,
    _AvoidSingleChildColumnOrRowTest._allCases,
  );
  analysisRuleSuite<_PreferExtractingCallbacksTest>(
    'PreferExtractingCallbacksTest',
    _PreferExtractingCallbacksTest.new,
    _PreferExtractingCallbacksTest._allCases,
  );
  analysisRuleSuite<_PreferCorrectStaticIconProviderTest>(
    'PreferCorrectStaticIconProviderTest',
    _PreferCorrectStaticIconProviderTest.new,
    _PreferCorrectStaticIconProviderTest._allCases,
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

final class _AvoidSingleChildColumnOrRowTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_AvoidSingleChildColumnOrRowTest)> get _allCases =>
      caseSet<_AvoidSingleChildColumnOrRowTest>(
        parent: const {},
        own: {
          'test_columnWithSingleChild_lint': (t) => t._columnWithSingleChildLint(),
          'test_rowWithSingleChild_lint': (t) => t._rowWithSingleChildLint(),
          'test_columnWithTwoChildren_noLint': (t) => t._columnWithTwoChildrenNoLint(),
          'test_conditionalChild_noLint': (t) => t._conditionalChildNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidSingleChildColumnOrRow();
    super.setUp();
  }

  Future<void> _columnWithSingleChildLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Column(children: <Widget>[SizedBox()]);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> _rowWithSingleChildLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Row(children: <Widget>[SizedBox()]);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row'), 'Row'.length)]);
  }

  Future<void> _columnWithTwoChildrenNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const Column(children: <Widget>[SizedBox(), SizedBox()]);
}
''');
  }

  Future<void> _conditionalChildNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(bool show) {
  return Column(children: <Widget>[if (show) const SizedBox()]);
}
''');
  }
}

final class _PreferExtractingCallbacksTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_PreferExtractingCallbacksTest)> get _allCases =>
      caseSet<_PreferExtractingCallbacksTest>(
        parent: const {},
        own: {
          'test_blockCallbackWithTwoStatements_lint': (t) =>
              t._blockCallbackWithTwoStatementsLint(),
          'test_inlineCallbackCorrection_namesOnlyMethod': (t) =>
              t._inlineCallbackCorrectionNamesOnlyMethod(),
          'test_callbackWithControlFlow_lint': (t) => t._callbackWithControlFlowLint(),
          'test_trivialExpressionCallback_noLint': (t) => t._trivialExpressionCallbackNoLint(),
          'test_callbackReference_noLint': (t) => t._callbackReferenceNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferExtractingCallbacks();
    super.setUp();
  }

  Future<void> _blockCallbackWithTwoStatementsLint() async {
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

  Future<void> _inlineCallbackCorrectionNamesOnlyMethod() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void a() {}
void b() {}

Widget build() {
  return TextButton(
    onPressed: () { a(); b(); },
    child: const SizedBox(),
  );
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('() {', source.indexOf('onPressed')),
        '()'.length,
        correctionContains: 'Move the callback body to a named method.',
      ),
    ]);
  }

  Future<void> _callbackWithControlFlowLint() async {
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

  Future<void> _trivialExpressionCallbackNoLint() async {
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

  Future<void> _callbackReferenceNoLint() async {
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

final class _PreferCorrectStaticIconProviderTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_PreferCorrectStaticIconProviderTest)> get _allCases =>
      caseSet<_PreferCorrectStaticIconProviderTest>(
        parent: const {},
        own: {
          'test_topLevelIconDataConstant_lint': (t) => t._topLevelIconDataConstantLint(),
          'test_staticProviderIconData_noLint': (t) => t._staticProviderIconDataNoLint(),
          'test_nonIconDataConstant_noLint': (t) => t._nonIconDataConstantNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferCorrectStaticIconProvider();
    super.setUp();
  }

  Future<void> _topLevelIconDataConstantLint() async {
    const source = r'''
import 'package:flutter/widgets/icon_data.dart';

const IconData appAdd = IconData(0xe001, fontFamily: 'AppIcons');
''';

    await assertDiagnostics(source, [lint(source.indexOf('appAdd'), 'appAdd'.length)]);
  }

  Future<void> _staticProviderIconDataNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets/icon_data.dart';

abstract final class AppIcons {
  static const IconData add = IconData(0xe001, fontFamily: 'AppIcons');
}
''');
  }

  Future<void> _nonIconDataConstantNoLint() async {
    await assertNoDiagnostics(r'''
const int codePoint = 0xe001;
''');
  }
}
