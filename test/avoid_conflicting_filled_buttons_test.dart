import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conflicting_filled_buttons.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidConflictingFilledButtonsTest>(
    'AvoidConflictingFilledButtonsTest',
    _AvoidConflictingFilledButtonsTest.new,
    {
      'reportsDifferentStyleFromColours': (t) => t._reportsDifferentStyleFromColours(),
      'reportsDifferentButtonStyleColours': (t) => t._reportsDifferentButtonStyleColours(),
      'reportsExplicitColourBesideDefaultFill': (t) => t._reportsExplicitColourBesideDefaultFill(),
      'reportsMixedFilledKindsInWrap': (t) => t._reportsMixedFilledKindsInWrap(),
      'reportsButtonsInsideWrappers': (t) => t._reportsButtonsInsideWrappers(),
      'reportsOnceForThreeButtons': (t) => t._reportsOnceForThreeButtons(),
      'reportsDefaultFilledBesideDefaultElevated': (t) =>
          t._reportsDefaultFilledBesideDefaultElevated(),
      'reportsButtonsInsideCollectionIf': (t) => t._reportsButtonsInsideCollectionIf(),
      'reportsStyleVariableWithDifferentFill': (t) => t._reportsStyleVariableWithDifferentFill(),
      'allowsOtherFileFillBesideDefault': (t) => t._allowsOtherFileFillBesideDefault(),
      'allowsTwoOtherFileStylesRedAndBlue': (t) => t._allowsTwoOtherFileStylesRedAndBlue(),
      'allowsStyleVariableWithoutFill': (t) => t._allowsStyleVariableWithoutFill(),
      'allowsThemeStyleBesideDefault': (t) => t._allowsThemeStyleBesideDefault(),
      'allowsStyleVariableWithEqualFill': (t) => t._allowsStyleVariableWithEqualFill(),
      'allowsUnreadableStyle': (t) => t._allowsUnreadableStyle(),
      'allowsOneColourWrittenTwoWays': (t) => t._allowsOneColourWrittenTwoWays(),
      'allowsEqualFillFromThemeFile': (t) => t._allowsEqualFillFromThemeFile(),
      'allowsEqualFillFromOtherFile': (t) => t._allowsEqualFillFromOtherFile(),
      'allowsEqualFillFromOtherPackage': (t) => t._allowsEqualFillFromOtherPackage(),
      'allowsOtherPackageFillBesideDefault': (t) => t._allowsOtherPackageFillBesideDefault(),
      'allowsResolveWithClosuresWithOtherParameterNames': (t) =>
          t._allowsResolveWithClosuresWithOtherParameterNames(),
      'allowsDefaultBesideColorSchemePrimary': (t) => t._allowsDefaultBesideColorSchemePrimary(),
      'allowsDefaultBesideSchemeVariablePrimary': (t) =>
          t._allowsDefaultBesideSchemeVariablePrimary(),
      'allowsDefaultBesideParameterPrimary': (t) => t._allowsDefaultBesideParameterPrimary(),
      'allowsFilledAndElevatedBothPrimary': (t) => t._allowsFilledAndElevatedBothPrimary(),
      'allowsDefaultElevatedBesidePrimary': (t) => t._allowsDefaultElevatedBesidePrimary(),
      'reportsLookalikePrimaryText': (t) => t._reportsLookalikePrimaryText(),
      'allowsEqualDefaultButtons': (t) => t._allowsEqualDefaultButtons(),
      'skipsGeneratedFiles': (t) => t._skipsGeneratedFiles(),
      'allowsSameExplicitColour': (t) => t._allowsSameExplicitColour(),
      'allowsDefaultFilledBesideDefaultTonal': (t) => t._allowsDefaultFilledBesideDefaultTonal(),
      'allowsFilledBesideOutlinedAndText': (t) => t._allowsFilledBesideOutlinedAndText(),
      'allowsSingleFilledButton': (t) => t._allowsSingleFilledButton(),
      'allowsButtonsInSeparateContainers': (t) => t._allowsButtonsInSeparateContainers(),
      'allowsColumn': (t) => t._allowsColumn(),
      'allowsLookalikeButton': (t) => t._allowsLookalikeButton(),
      'skipsTestFiles': (t) => t._skipsTestFiles(),
    },
  );
}

const _flutterLibrary = r'''
class Color {
  const Color(this.value);
  final int value;
}

class ColorScheme {
  const ColorScheme();
  Color get primary => const Color(1);
}

class ThemeData {
  const ThemeData();
  ColorScheme get colorScheme => const ColorScheme();
  FilledButtonThemeData get filledButtonTheme => const FilledButtonThemeData();
}

class FilledButtonThemeData {
  const FilledButtonThemeData();
  ButtonStyle? get style => null;
}

class Theme {
  static ThemeData of(Object context) => const ThemeData();
}

class Colors {
  static const Color green = Color(0xFF00AA00);
  static const Color brown = Color(0xFF884400);
}

abstract class Widget {
  const Widget();
}

abstract class WidgetStateProperty<T> {
  const WidgetStateProperty();
  static WidgetStateProperty<T> resolveWith<T>(T Function(Set<Object> states) callback) =>
      throw UnimplementedError();
  static WidgetStateProperty<T> all<T>(T value) => WidgetStatePropertyAll<T>(value);
}

class WidgetStatePropertyAll<T> extends WidgetStateProperty<T> {
  const WidgetStatePropertyAll(this.value);
  final T value;
}

class ButtonStyle {
  const ButtonStyle({this.backgroundColor, this.foregroundColor});
  final WidgetStateProperty<Color?>? backgroundColor;
  final WidgetStateProperty<Color?>? foregroundColor;
}

class FilledButton extends Widget {
  const FilledButton({required this.onPressed, this.style, this.child});
  const FilledButton.tonal({required this.onPressed, this.style, this.child});
  const FilledButton.icon({required this.onPressed, this.style, this.icon, this.label});
  final void Function()? onPressed;
  final ButtonStyle? style;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  static ButtonStyle styleFrom({Color? backgroundColor, Color? foregroundColor}) =>
      const ButtonStyle();
}

class ElevatedButton extends Widget {
  const ElevatedButton({required this.onPressed, this.style, this.child});
  const ElevatedButton.icon({required this.onPressed, this.style, this.icon, this.label});
  final void Function()? onPressed;
  final ButtonStyle? style;
  final Widget? child;
  final Widget? icon;
  final Widget? label;

  static ButtonStyle styleFrom({Color? backgroundColor, Color? foregroundColor}) =>
      const ButtonStyle();
}

class OutlinedButton extends Widget {
  const OutlinedButton({required this.onPressed, this.child});
  final void Function()? onPressed;
  final Widget? child;
}

class TextButton extends Widget {
  const TextButton({required this.onPressed, this.child});
  final void Function()? onPressed;
  final Widget? child;
}

class Text extends Widget {
  const Text(this.data);
  final String data;
}

class Expanded extends Widget {
  const Expanded({required this.child});
  final Widget child;
}

class Padding extends Widget {
  const Padding({required this.child});
  final Widget child;
}

class Row extends Widget {
  const Row({this.children = const <Widget>[]});
  final List<Widget> children;
}

class Wrap extends Widget {
  const Wrap({this.children = const <Widget>[]});
  final List<Widget> children;
}

class Column extends Widget {
  const Column({this.children = const <Widget>[]});
  final List<Widget> children;
}
''';

final class _AvoidConflictingFilledButtonsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/material.dart', _flutterLibrary);
    newPackage('other_pkg').addFile('lib/styles.dart', r"""
import 'package:flutter/material.dart';

final ButtonStyle foreignStyle = FilledButton.styleFrom(backgroundColor: Colors.green);
""");
    rule = AvoidConflictingFilledButtons();
    super.setUp();
  }

  Future<void> _reportsDifferentStyleFromColours() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Approve'),
    ),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Decline'),
    ),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsDifferentButtonStyleColours() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    ElevatedButton(
      onPressed: null,
      style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
      child: Text('Approve'),
    ),
    ElevatedButton(
      onPressed: null,
      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.brown)),
      child: Text('Decline'),
    ),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsExplicitColourBesideDefaultFill() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Approve')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Decline'),
    ),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsMixedFilledKindsInWrap() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Wrap(
  children: [
    FilledButton.icon(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      icon: Text('+'),
      label: Text('Approve'),
    ),
    ElevatedButton.icon(onPressed: null, icon: Text('-'), label: Text('Decline')),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Wrap('), 'Wrap'.length)]);
  }

  Future<void> _reportsButtonsInsideWrappers() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    Expanded(
      child: Padding(
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          child: Text('Approve'),
        ),
      ),
    ),
    Expanded(child: FilledButton(onPressed: null, child: Text('Decline'))),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsOnceForThreeButtons() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('One')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Two'),
    ),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Three'),
    ),
  ],
);
''';

    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsDefaultFilledBesideDefaultElevated() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    ElevatedButton(onPressed: null, child: Text('No')),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsButtonsInsideCollectionIf() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build(bool on) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    if (on)
      FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(backgroundColor: Colors.brown),
        child: Text('No'),
      ),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _reportsStyleVariableWithDifferentFill() async {
    const source = r"""
import 'package:flutter/material.dart';

abstract final class Styles {
  static final ButtonStyle danger = FilledButton.styleFrom(backgroundColor: Colors.brown);
}

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Yes'),
    ),
    FilledButton(onPressed: null, style: Styles.danger, child: Text('No')),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _allowsOtherFileFillBesideDefault() async {
    newFile('$testPackageLibPath/styles.dart', r"""
import 'package:flutter/material.dart';

final ButtonStyle dangerStyle = FilledButton.styleFrom(backgroundColor: Colors.brown);
""");
    const source = r"""
import 'package:flutter/material.dart';
import 'styles.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    FilledButton(onPressed: null, style: dangerStyle, child: Text('No')),
  ],
);
""";
    await assertNoDiagnostics(source);
  }

  Future<void> _allowsStyleVariableWithoutFill() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

abstract final class Styles {
  static final ButtonStyle rounded = FilledButton.styleFrom(foregroundColor: Colors.brown);
}

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    FilledButton(onPressed: null, style: Styles.rounded, child: Text('No')),
  ],
);
""");
  }

  Future<void> _allowsThemeStyleBesideDefault() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(Object context) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    FilledButton(
      onPressed: null,
      style: Theme.of(context).filledButtonTheme.style,
      child: Text('No'),
    ),
  ],
);
""");
  }

  Future<void> _allowsStyleVariableWithEqualFill() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

const ButtonStyle same = ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green));

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, style: same, child: Text('Yes')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('No'),
    ),
  ],
);
""");
  }

  Future<void> _allowsUnreadableStyle() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

ButtonStyle pick(bool on) => FilledButton.styleFrom(backgroundColor: on ? Colors.green : Colors.brown);

Widget build(bool on) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    FilledButton(onPressed: null, style: pick(on), child: Text('No')),
  ],
);
""");
  }

  Future<void> _allowsOneColourWrittenTwoWays() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

const Color kBrand = Color(7);

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: kBrand),
      child: Text('Yes'),
    ),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: const Color(7)),
      child: Text('No'),
    ),
  ],
);
""");
  }

  Future<void> _skipsGeneratedFiles() async {
    final path = '$testPackageLibPath/widget.g.dart';
    newFile(path, r"""
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('One')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Two'),
    ),
  ],
);
""");
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _assertForeignFill(String foreign, String inline) async {
    final source =
        """
import 'package:flutter/material.dart';
import '$foreign';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, style: foreignStyle, child: Text('A')),
    $inline
  ],
);
""";
    await assertNoDiagnostics(source);
  }

  static const _inlineBrand =
      "FilledButton(onPressed: null, style: FilledButton.styleFrom(backgroundColor: const Color(7)), child: Text('B')),";
  static const _inlineRed =
      "FilledButton(onPressed: null, style: FilledButton.styleFrom(backgroundColor: Colors.green), child: Text('B')),";

  Future<void> _allowsEqualFillFromThemeFile() async {
    newFile('$testPackageLibPath/theme.dart', r"""
import 'package:flutter/material.dart';

const Color kBrand = Color(7);
final ButtonStyle foreignStyle = FilledButton.styleFrom(backgroundColor: kBrand);
""");
    await _assertForeignFill('theme.dart', _inlineBrand);
  }

  Future<void> _allowsEqualFillFromOtherFile() async {
    newFile('$testPackageLibPath/styles.dart', r"""
import 'package:flutter/material.dart';

final ButtonStyle foreignStyle = FilledButton.styleFrom(backgroundColor: Colors.green);
""");
    await _assertForeignFill('styles.dart', _inlineRed);
  }

  Future<void> _allowsEqualFillFromOtherPackage() async {
    await _assertForeignFill('package:other_pkg/styles.dart', _inlineRed);
  }

  Future<void> _allowsOtherPackageFillBesideDefault() async {
    await _assertForeignFill(
      'package:other_pkg/styles.dart',
      "FilledButton(onPressed: null, child: Text('B')),",
    );
  }

  Future<void> _allowsTwoOtherFileStylesRedAndBlue() async {
    newFile('$testPackageLibPath/red.dart', r"""
import 'package:flutter/material.dart';

final ButtonStyle redStyle = FilledButton.styleFrom(backgroundColor: Colors.green);
""");
    newFile('$testPackageLibPath/blue.dart', r"""
import 'package:flutter/material.dart';

final ButtonStyle blueStyle = FilledButton.styleFrom(backgroundColor: Colors.brown);
""");
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';
import 'red.dart';
import 'blue.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, style: redStyle, child: Text('A')),
    FilledButton(onPressed: null, style: blueStyle, child: Text('B')),
  ],
);
""");
  }

  Future<void> _allowsResolveWithClosuresWithOtherParameterNames() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => Colors.green)),
      child: Text('A'),
    ),
    FilledButton(
      onPressed: null,
      style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((s) => Colors.green)),
      child: Text('B'),
    ),
  ],
);
""");
  }

  Future<void> _allowsDefaultBesideColorSchemePrimary() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(Object context) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('A')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
      child: Text('B'),
    ),
  ],
);
""");
  }

  Future<void> _allowsDefaultBesideSchemeVariablePrimary() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(Object context) {
  final scheme = Theme.of(context).colorScheme;
  return Row(
    children: [
      FilledButton(onPressed: null, child: Text('A')),
      FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(backgroundColor: scheme.primary),
        child: Text('B'),
      ),
    ],
  );
}
""");
  }

  Future<void> _allowsDefaultBesideParameterPrimary() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(ColorScheme cs) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('A')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: cs.primary),
      child: Text('B'),
    ),
  ],
);
""");
  }

  Future<void> _allowsFilledAndElevatedBothPrimary() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(ColorScheme cs) => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: cs.primary),
      child: Text('A'),
    ),
    ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
      child: Text('B'),
    ),
  ],
);
""");
  }

  Future<void> _allowsDefaultElevatedBesidePrimary() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(ColorScheme cs) => Row(
  children: [
    ElevatedButton(onPressed: null, child: Text('A')),
    ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
      child: Text('B'),
    ),
  ],
);
""");
  }

  Future<void> _reportsLookalikePrimaryText() async {
    const source = r"""
import 'package:flutter/material.dart';

class Palette {
  Color get primary => const Color(9);
}

Widget build(Palette colorScheme) => Row(
  children: [
    FilledButton(onPressed: null, child: Text('A')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
      child: Text('B'),
    ),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('Row('), 'Row'.length)]);
  }

  Future<void> _allowsEqualDefaultButtons() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    FilledButton(onPressed: null, child: Text('No')),
  ],
);
''');
  }

  Future<void> _allowsSameExplicitColour() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Yes'),
    ),
    FilledButton(
      onPressed: null,
      style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
      child: Text('Also yes'),
    ),
  ],
);
''');
  }

  Future<void> _allowsDefaultFilledBesideDefaultTonal() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Save')),
    FilledButton.tonal(onPressed: null, child: Text('Save draft')),
  ],
);
''');
  }

  Future<void> _allowsFilledBesideOutlinedAndText() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Approve'),
    ),
    OutlinedButton(onPressed: null, child: Text('Review')),
    TextButton(onPressed: null, child: Text('Decline')),
  ],
);
''');
  }

  Future<void> _allowsSingleFilledButton() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Approve'),
    ),
  ],
);
''');
  }

  Future<void> _allowsButtonsInSeparateContainers() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Column(
  children: [
    Row(
      children: [
        FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(backgroundColor: Colors.green),
          child: Text('Approve'),
        ),
      ],
    ),
    Row(
      children: [
        FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(backgroundColor: Colors.brown),
          child: Text('Decline'),
        ),
      ],
    ),
  ],
);
''');
  }

  Future<void> _allowsColumn() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Column(
  children: [
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.green),
      child: Text('Approve'),
    ),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Decline'),
    ),
  ],
);
''');
  }

  Future<void> _allowsLookalikeButton() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart' show Row, Widget, Color;

class FilledButton extends Widget {
  const FilledButton({this.color});
  final Color? color;
}

Widget build() => Row(
  children: [
    FilledButton(color: Color(1)),
    FilledButton(color: Color(2)),
  ],
);
''');
  }

  Future<void> _skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('One')),
    FilledButton(
      onPressed: null,
      style: FilledButton.styleFrom(backgroundColor: Colors.brown),
      child: Text('Two'),
    ),
  ],
);
''');

    await assertNoDiagnosticsInFile(path);
  }
}
