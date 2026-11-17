import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

void addFlutterUiPackages(AnalysisRuleTest test) {
  test
      .newPackage('material_ui')
      .addFile('lib/material_ui.dart', "export 'package:flutter/widgets.dart';\n");
  test
      .newPackage('cupertino_ui')
      .addFile('lib/cupertino_ui.dart', "export 'package:flutter/widgets.dart';\n");
  test.newPackage('flutter')
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

class BuildContext {}

class InputDecoration {
const InputDecoration({this.hintText});
final String? hintText;
}

class Field extends Widget {
const Field({this.decoration});
final InputDecoration? decoration;
}

class Toast extends Widget {
const Toast();
static Toast make({String? title}) => const Toast();
}

class Panel extends Widget {
const Panel();
void announce({String? title}) {}
}

class Parent extends Widget {
const Parent({this.title});
final String? title;
}

typedef ValueChanged<T> = void Function(T value);

typedef DebugPrintCallback = void Function(String? message);

DebugPrintCallback debugPrint = (_) {};

abstract class StatelessWidget extends Widget {
const StatelessWidget();
Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
const StatefulWidget();
State createState();
}

abstract class State<T extends StatefulWidget> {
T get widget => throw UnimplementedError();
Widget build(BuildContext context);
}
''')
    ..addFile('lib/foundation.dart', "export 'src/foundation/print.dart';\n")
    ..addFile('lib/src/foundation/print.dart', r'''
void debugPrintStack({StackTrace? stackTrace, String? label}) {}
''')
    ..addFile('lib/services.dart', "export 'src/services/announce.dart';\n")
    ..addFile('lib/src/services/announce.dart', r'''
void announce({String? label}) {}
''')
    ..addFile('lib/scheduler.dart', "export 'src/scheduler/schedule.dart';\n")
    ..addFile('lib/src/scheduler/schedule.dart', r'''
void schedule({String? label}) {}
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
