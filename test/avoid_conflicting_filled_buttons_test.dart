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
      'allowsEqualDefaultButtons': (t) => t._allowsEqualDefaultButtons(),
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

class Colors {
  static const Color green = Color(0xFF00AA00);
  static const Color brown = Color(0xFF884400);
}

abstract class Widget {
  const Widget();
}

abstract class WidgetStateProperty<T> {
  const WidgetStateProperty();
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

  Future<void> _allowsEqualDefaultButtons() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    FilledButton(onPressed: null, child: Text('Yes')),
    ElevatedButton(onPressed: null, child: Text('No')),
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
