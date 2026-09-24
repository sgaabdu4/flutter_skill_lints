// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_hardcoded_strings.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedStringsTest);
  });
}

@reflectiveTest
final class AvoidHardcodedStringsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    rule = AvoidHardcodedStrings();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(AvoidHardcodedStrings.code.severity, DiagnosticSeverity.ERROR);
  }

  void _addFlutterPackage() {
    newPackage('flutter')
      ..addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

class Text extends Widget {
  const Text(this.data, {this.semanticsLabel});
  final String? data;
  final String? semanticsLabel;
}

class Icon extends Widget {
  const Icon({this.icon, this.semanticLabel});
  final Object? icon;
  final String? semanticLabel;
}

class AppButton extends Widget {
  const AppButton({this.label});
  final String? label;
}

class InputField extends Widget {
  const InputField({this.hintText});
  final String? hintText;
}
''')
      ..addFile('lib/widget_previews.dart', r'''
base class Preview {
  const Preview({String? name});
}

abstract base class MultiPreview {
  const MultiPreview();
}
''');
  }

  Future<void> test_textPositionalLiteral_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Save');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> test_sampleTextInsideResolvedPreview_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

@Preview(name: 'Button')
Widget buttonPreview() => const AppButton(label: 'Suture Kit');
''');
  }

  Future<void> test_textUnderLookalikePreviewAnnotation_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Preview {
  const Preview({String? name});
}

@Preview(name: 'Button')
Widget buttonPreview() => const AppButton(label: 'Suture Kit');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Suture Kit'"), "'Suture Kit'".length)]);
  }

  Future<void> test_textFromStringsConstantsClass_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

abstract final class AppStrings {
  static const welcome = 'Welcome back';
}

Widget build() => const Text(AppStrings.welcome);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('AppStrings.welcome);'), 'AppStrings.welcome'.length),
    ]);
  }

  Future<void> test_labelFromTopLevelConstant_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

const saveLabel = 'Save';

Widget build() => const AppButton(label: saveLabel);
''';

    await assertDiagnostics(source, [lint(source.indexOf('saveLabel);'), 'saveLabel'.length)]);
  }

  Future<void> test_textFromLocalizationsGetter_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class AppLocalizations {
  String get welcome => 'Welcome back';
}

Widget build(AppLocalizations l10n) => Text(l10n.welcome);
''');
  }

  Future<void> test_constantWithoutLetters_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract final class Separators {
  static const dash = ' - ';
}

Widget build() => const Text(Separators.dash);
''');
  }

  Future<void> test_stringsFileWidget_lint() async {
    final filePath = '$testPackageLibPath/core/constants/app_strings.dart';
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Save');
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> test_textFromVariable_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(String label) => Text(label);
''');
  }

  Future<void> test_emptyText_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('');
''');
  }

  Future<void> test_numericText_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('5');
''');
  }

  Future<void> test_namedLabelLiteral_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const AppButton(label: 'Save');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> test_namedHintTextLiteral_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const InputField(hintText: 'Email');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Email'"), "'Email'".length)]);
  }

  Future<void> test_namedSemanticLabelLiteral_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Icon(semanticLabel: 'Add exercise');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Add exercise'"), "'Add exercise'".length),
    ]);
  }

  Future<void> test_namedLabelFromVariable_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(String label) => AppButton(label: label);
''');
  }

  Future<void> test_interpolationWithLiteralText_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(String name) => Text('Hello $name');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf(r"'Hello $name'"), r"'Hello $name'".length),
    ]);
  }

  Future<void> test_interpolationWithoutLiteralText_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(int count) => Text('$count');
''');
  }
}
