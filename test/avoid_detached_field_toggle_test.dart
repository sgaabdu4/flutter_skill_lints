import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_detached_field_toggle.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidDetachedFieldToggleTest>(
    'AvoidDetachedFieldToggleTest',
    _AvoidDetachedFieldToggleTest.new,
    {
      'reportsTextButtonBesideField': (t) => t._reportsTextButtonBesideField(),
      'reportsIconButtonBesideFormField': (t) => t._reportsIconButtonBesideFormField(),
      'reportsToggleThatWritesTheObscureState': (t) => t._reportsToggleThatWritesTheObscureState(),
      'reportsToggleInsideExpandedSibling': (t) => t._reportsToggleInsideExpandedSibling(),
      'reportsTextLabelAsSuffix': (t) => t._reportsTextLabelAsSuffix(),
      'reportsShowPasswordCheckbox': (t) => t._reportsShowPasswordCheckbox(),
      'reportsEyeButtonInStack': (t) => t._reportsEyeButtonInStack(),
      'reportsToggleMethodTearOff': (t) => t._reportsToggleMethodTearOff(),
      'allowsPreviewButtonWithEyeIcon': (t) => t._allowsPreviewButtonWithEyeIcon(),
      'allowsIconNamedLikeAnEye': (t) => t._allowsIconNamedLikeAnEye(),
      'reportsOutlinedEyeIconButton': (t) => t._reportsOutlinedEyeIconButton(),
      'reportsLabelledEyeButtonThatSetsTheFlag': (t) =>
          t._reportsLabelledEyeButtonThatSetsTheFlag(),
      'reportsCupertinoEyeSolid': (t) => t._reportsCupertinoEyeSolid(),
      'allowsSwitchNamedVisibility': (t) => t._allowsSwitchNamedVisibility(),
      'reportsIconDataFromAnotherIconClass': (t) => t._reportsIconDataFromAnotherIconClass(),
      'allowsShowMoreButton': (t) => t._allowsShowMoreButton(),
      'allowsHelpText': (t) => t._allowsHelpText(),
      'allowsDecorativeIcon': (t) => t._allowsDecorativeIcon(),
      'allowsSubmitThatOnlyReadsTheFlag': (t) => t._allowsSubmitThatOnlyReadsTheFlag(),
      'allowsControlThatReadsTheFlagOutsideAClosure': (t) =>
          t._allowsControlThatReadsTheFlagOutsideAClosure(),
      'allowsSecondFieldWithOwnSuffixToggle': (t) => t._allowsSecondFieldWithOwnSuffixToggle(),
      'skipsGeneratedFiles': (t) => t._skipsGeneratedFiles(),
      'allowsSuffixIconButton': (t) => t._allowsSuffixIconButton(),
      'allowsFieldWithoutToggle': (t) => t._allowsFieldWithoutToggle(),
      'allowsUnrelatedButtonInRow': (t) => t._allowsUnrelatedButtonInRow(),
      'allowsFieldThatIsNotObscured': (t) => t._allowsFieldThatIsNotObscured(),
      'allowsLookalikeField': (t) => t._allowsLookalikeField(),
      'skipsTestFiles': (t) => t._skipsTestFiles(),
    },
  );
}

const _flutterLibrary = r'''
abstract class Widget {
  const Widget();
}

class IconData {
  const IconData(this.code);
  final int code;
}

class Icons {
  static const IconData visibility = IconData(1);
  static const IconData visibilityOff = IconData(2);
  static const IconData lock = IconData(3);
  static const IconData visibilityNote = IconData(4);
  static const IconData visibilityOffOutlined = IconData(5);
}

class Symbols {
  static const IconData visibility = IconData(7);
}

class CupertinoIcons {
  static const IconData eye_solid = IconData(6);
}

class Switch extends Widget {
  const Switch({required this.value, required this.onChanged});
  final bool value;
  final void Function(bool)? onChanged;
}

class Icon extends Widget {
  const Icon(this.icon);
  final Object icon;
}

class Text extends Widget {
  const Text(this.data);
  final String data;
}

class IconButton extends Widget {
  const IconButton({required this.onPressed, required this.icon, this.tooltip});
  final void Function()? onPressed;
  final Widget icon;
  final String? tooltip;
}

class FilledButton extends Widget {
  const FilledButton({required this.onPressed, required this.child});
  final void Function()? onPressed;
  final Widget child;
}

class TextButton extends Widget {
  const TextButton({required this.onPressed, required this.child});
  final void Function()? onPressed;
  final Widget child;
}

class InputDecoration {
  const InputDecoration({this.suffixIcon, this.suffix, this.labelText});
  final Widget? suffixIcon;
  final Widget? suffix;
  final String? labelText;
}

class TextField extends Widget {
  const TextField({this.obscureText = false, this.decoration});
  final bool obscureText;
  final InputDecoration? decoration;
}

class TextFormField extends Widget {
  const TextFormField({this.obscureText = false, this.decoration});
  final bool obscureText;
  final InputDecoration? decoration;
}

class Checkbox extends Widget {
  const Checkbox({required this.value, required this.onChanged});
  final bool value;
  final void Function(bool?)? onChanged;
}

class Column extends Widget {
  const Column({this.children = const <Widget>[]});
  final List<Widget> children;
}

class Stack extends Widget {
  const Stack({this.children = const <Widget>[]});
  final List<Widget> children;
}

class Expanded extends Widget {
  const Expanded({required this.child});
  final Widget child;
}

class Row extends Widget {
  const Row({this.children = const <Widget>[]});
  final List<Widget> children;
}
''';

final class _AvoidDetachedFieldToggleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/material.dart', _flutterLibrary);
    rule = AvoidDetachedFieldToggle();
    super.setUp();
  }

  Future<void> _reportsTextButtonBesideField() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build(bool hidden, void Function() flip) => Row(
  children: [
    Expanded(child: TextField(obscureText: hidden)),
    TextButton(onPressed: flip, child: Text('Show')),
  ],
);
''';
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsIconButtonBesideFormField() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build(bool hidden, void Function() flip) => Row(
  children: [
    TextFormField(obscureText: true),
    IconButton(onPressed: flip, icon: Icon(Icons.visibilityOff)),
  ],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('TextFormField'), 'TextFormField'.length),
    ]);
  }

  Future<void> _reportsToggleThatWritesTheObscureState() async {
    const source = r'''
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  Widget build() => Row(
    children: [
      TextField(obscureText: hidden),
      TextButton(onPressed: () => hidden = !hidden, child: Text('Toggle')),
    ],
  );
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsToggleInsideExpandedSibling() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    Expanded(child: TextButton(onPressed: flip, child: Text('Hide'))),
  ],
);
''';
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsTextLabelAsSuffix() async {
    const source = r'''
import 'package:flutter/material.dart';

Widget build(void Function() flip) => TextField(
  obscureText: true,
  decoration: InputDecoration(
    suffixIcon: TextButton(onPressed: flip, child: Text('Show')),
  ),
);
''';
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsShowPasswordCheckbox() async {
    const source = r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  Widget build() => Column(
    children: [
      TextField(obscureText: hidden),
      Checkbox(value: !hidden, onChanged: (value) => hidden = !(value ?? false)),
    ],
  );
}
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsEyeButtonInStack() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Stack(
  children: [
    TextField(obscureText: true),
    IconButton(onPressed: flip, icon: Icon(Icons.visibilityOff)),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsToggleMethodTearOff() async {
    const source = r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  void toggle() {
    hidden = !hidden;
  }

  Widget build() => Row(
    children: [
      TextField(obscureText: hidden),
      TextButton(onPressed: toggle, child: Text('Switch')),
    ],
  );
}
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _allowsPreviewButtonWithEyeIcon() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(void Function() preview) => Row(
  children: [
    TextField(obscureText: true),
    TextButton(
      onPressed: preview,
      child: Row(children: [Icon(Icons.visibility), Text('Preview')]),
    ),
  ],
);
""");
  }

  Future<void> _allowsIconNamedLikeAnEye() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(void Function() open) => Row(
  children: [
    TextField(obscureText: true),
    IconButton(onPressed: open, icon: Icon(Icons.visibilityNote)),
  ],
);
""");
  }

  Future<void> _reportsOutlinedEyeIconButton() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    IconButton(onPressed: flip, icon: Icon(Icons.visibilityOffOutlined)),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsLabelledEyeButtonThatSetsTheFlag() async {
    const source = r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  Widget build() => Row(
    children: [
      TextField(obscureText: hidden),
      TextButton(
        onPressed: () => hidden = !hidden,
        child: Row(children: [Icon(Icons.visibility), Text('Preview')]),
      ),
    ],
  );
}
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _reportsCupertinoEyeSolid() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    IconButton(onPressed: flip, icon: Icon(CupertinoIcons.eye_solid)),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _allowsSwitchNamedVisibility() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(bool visibility, void Function(bool) set) => Row(
  children: [
    TextField(obscureText: true),
    Switch(value: visibility, onChanged: set),
  ],
);
""");
  }

  Future<void> _reportsIconDataFromAnotherIconClass() async {
    const source = r"""
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    IconButton(onPressed: flip, icon: Icon(Symbols.visibility)),
  ],
);
""";
    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> _allowsShowMoreButton() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build(void Function() more) => Row(
  children: [
    TextField(obscureText: true),
    TextButton(onPressed: more, child: Text('Show more options')),
  ],
);
""");
  }

  Future<void> _allowsHelpText() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build() => Column(
  children: [
    TextField(obscureText: true),
    Text('Show your ID at the desk'),
  ],
);
""");
  }

  Future<void> _allowsDecorativeIcon() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    Icon(Icons.visibilityOff),
    Expanded(child: TextField(obscureText: true)),
  ],
);
""");
  }

  Future<void> _allowsSubmitThatOnlyReadsTheFlag() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  Widget build(void Function(bool) send) => Column(
    children: [
      TextField(obscureText: hidden),
      FilledButton(onPressed: () => send(hidden), child: Text('Submit')),
    ],
  );
}
""");
  }

  Future<void> _allowsControlThatReadsTheFlagOutsideAClosure() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;

  Widget build(void Function(bool?) send) => Column(
    children: [
      TextField(obscureText: hidden),
      Text(hidden ? 'Hidden' : 'Visible'),
      Checkbox(value: hidden, onChanged: send),
    ],
  );
}
""");
  }

  Future<void> _allowsSecondFieldWithOwnSuffixToggle() async {
    await assertNoDiagnostics(r"""
import 'package:flutter/material.dart';

class Form1 {
  bool hidden = true;
  bool hiddenAgain = true;

  Widget build() => Column(
    children: [
      TextField(obscureText: hidden),
      TextField(obscureText: hiddenAgain, decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () => hiddenAgain = !hiddenAgain,
          tooltip: 'Show password',
          icon: Icon(Icons.visibility),
        ),
      )),
    ],
  );
}
""");
  }

  Future<void> _skipsGeneratedFiles() async {
    final path = '$testPackageLibPath/widget.g.dart';
    newFile(path, r"""
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    TextButton(onPressed: flip, child: Text('Show')),
  ],
);
""");
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> _allowsSuffixIconButton() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build(bool hidden, void Function() flip) => TextField(
  obscureText: hidden,
  decoration: InputDecoration(
    suffixIcon: IconButton(
      onPressed: flip,
      tooltip: 'Show password',
      icon: Icon(Icons.visibility),
    ),
  ),
);
''');
  }

  Future<void> _allowsFieldWithoutToggle() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build() => Row(
  children: [
    Expanded(child: TextField(obscureText: true)),
  ],
);
''');
  }

  Future<void> _allowsUnrelatedButtonInRow() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build(void Function() submit) => Row(
  children: [
    Expanded(child: TextField(obscureText: true)),
    TextButton(onPressed: submit, child: Text('Forgot password?')),
    IconButton(onPressed: submit, tooltip: 'Help', icon: Icon(Icons.lock)),
  ],
);
''');
  }

  Future<void> _allowsFieldThatIsNotObscured() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(),
    TextButton(onPressed: flip, child: Text('Show')),
  ],
);
''');
  }

  Future<void> _allowsLookalikeField() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/material.dart' show Row, Widget, TextButton, Text;

class TextField extends Widget {
  const TextField({this.obscureText = false});
  final bool obscureText;
}

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    TextButton(onPressed: flip, child: Text('Show')),
  ],
);
''');
  }

  Future<void> _skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/material.dart';

Widget build(void Function() flip) => Row(
  children: [
    TextField(obscureText: true),
    TextButton(onPressed: flip, child: Text('Show')),
  ],
);
''');
    await assertNoDiagnosticsInFile(path);
  }
}
