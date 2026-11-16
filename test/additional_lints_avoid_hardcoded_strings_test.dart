import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_hardcoded_strings.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidHardcodedStringsTest>(
    'AvoidHardcodedStringsTest',
    _AvoidHardcodedStringsTest.new,
    _AvoidHardcodedStringsTest._allCases,
  );
}

final class _AvoidHardcodedStringsTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidHardcodedStringsTest)> get _allCases =>
      caseSet<_AvoidHardcodedStringsTest>(
        parent: const {},
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_textPositionalLiteral_lint': (t) => t._textPositionalLiteralLint(),
          'test_sampleTextInsideResolvedPreview_noLint': (t) =>
              t._sampleTextInsideResolvedPreviewNoLint(),
          'test_textUnderLookalikePreviewAnnotation_lint': (t) =>
              t._textUnderLookalikePreviewAnnotationLint(),
          'test_textFromStringsConstantsClass_lint': (t) => t._textFromStringsConstantsClassLint(),
          'test_labelFromTopLevelConstant_lint': (t) => t._labelFromTopLevelConstantLint(),
          'test_textFromLocalizationsGetter_noLint': (t) => t._textFromLocalizationsGetterNoLint(),
          'test_constantWithoutLetters_noLint': (t) => t._constantWithoutLettersNoLint(),
          'test_stringsFileWidget_lint': (t) => t._stringsFileWidgetLint(),
          'test_textFromVariable_noLint': (t) => t._textFromVariableNoLint(),
          'test_emptyText_noLint': (t) => t._emptyTextNoLint(),
          'test_numericText_noLint': (t) => t._numericTextNoLint(),
          'test_namedLabelLiteral_lint': (t) => t._namedLabelLiteralLint(),
          'test_namedHintTextLiteral_lint': (t) => t._namedHintTextLiteralLint(),
          'test_namedSemanticLabelLiteral_lint': (t) => t._namedSemanticLabelLiteralLint(),
          'test_namedLabelFromVariable_noLint': (t) => t._namedLabelFromVariableNoLint(),
          'test_interpolationWithLiteralText_lint': (t) => t._interpolationWithLiteralTextLint(),
          'test_interpolationWithoutLiteralText_noLint': (t) =>
              t._interpolationWithoutLiteralTextNoLint(),
          'test_callbackProseInState_lint': (t) => t._callbackProseInStateLint(),
          'test_callbackProseInStatelessWidget_lint': (t) =>
              t._callbackProseInStatelessWidgetLint(),
          'test_callbackIdentifiersKeysAndProtocolStrings_noLint': (t) =>
              t._callbackIdentifiersKeysAndProtocolStringsNoLint(),
          'test_declaredMethodAndFunctionProse_noLint': (t) =>
              t._declaredMethodAndFunctionProseNoLint(),
          'test_callbackProseOutsideWidgetClass_noLint': (t) =>
              t._callbackProseOutsideWidgetClassNoLint(),
          'test_callbackProseInsideResolvedPreview_noLint': (t) =>
              t._callbackProseInsideResolvedPreviewNoLint(),
          'test_globalFunctionVariableProseInWidget_noLint': (t) =>
              t._globalFunctionVariableProseInWidgetNoLint(),
          'test_titleLiteralPassedToFunction_lint': (t) => t._titleLiteralPassedToFunctionLint(),
          'test_hintTextInDotShorthandConstructor_lint': (t) =>
              t._hintTextInDotShorthandConstructorLint(),
          'test_titleInDotShorthandStaticMethod_lint': (t) =>
              t._titleInDotShorthandStaticMethodLint(),
          'test_titleInEnumConstantArguments_lint': (t) => t._titleInEnumConstantArgumentsLint(),
          'test_titleInSuperConstructorCall_lint': (t) => t._titleInSuperConstructorCallLint(),
          'test_titleInRedirectingConstructorCall_lint': (t) =>
              t._titleInRedirectingConstructorCallLint(),
          'test_titleInFunctionTypedValueCall_lint': (t) => t._titleInFunctionTypedValueCallLint(),
          'test_labelInBinEntrypoint_lint': (t) => t._labelInBinEntrypointLint(),
          'test_labelInRepositoryDebugCall_noLint': (t) => t._labelInRepositoryDebugCallNoLint(),
          'test_labelInAnalyticsCall_noLint': (t) => t._labelInAnalyticsCallNoLint(),
          'test_titleToPlainNonUiFunction_noLint': (t) => t._titleToPlainNonUiFunctionNoLint(),
          'test_titleLiteralPassedToMethod_lint': (t) => t._titleLiteralPassedToMethodLint(),
          'test_labelLiteralAfterPositionalArgument_lint': (t) =>
              t._labelLiteralAfterPositionalArgumentLint(),
          'test_titleFromVariablePassedToFunction_noLint': (t) =>
              t._titleFromVariablePassedToFunctionNoLint(),
          'test_unrelatedNamedLiteralPassedToFunction_noLint': (t) =>
              t._unrelatedNamedLiteralPassedToFunctionNoLint(),
          'test_titleLiteralWithoutLettersPassedToFunction_noLint': (t) =>
              t._titleLiteralWithoutLettersPassedToFunctionNoLint(),
        },
      );

  @override
  void setUp() {
    _addFlutterPackage();
    rule = AvoidHardcodedStrings();
    super.setUp();
  }

  Future<void> _severityIsError() async {
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
      ..addFile('lib/foundation.dart', r'''
void debugPrintStack({StackTrace? stackTrace, String? label}) {}
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

  Future<void> _textPositionalLiteralLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Save');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> _sampleTextInsideResolvedPreviewNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

@Preview(name: 'Button')
Widget buttonPreview() => const AppButton(label: 'Suture Kit');
''');
  }

  Future<void> _textUnderLookalikePreviewAnnotationLint() async {
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

  Future<void> _textFromStringsConstantsClassLint() async {
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

  Future<void> _labelFromTopLevelConstantLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

const saveLabel = 'Save';

Widget build() => const AppButton(label: saveLabel);
''';

    await assertDiagnostics(source, [lint(source.indexOf('saveLabel);'), 'saveLabel'.length)]);
  }

  Future<void> _textFromLocalizationsGetterNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class AppLocalizations {
  String get welcome => 'Welcome back';
}

Widget build(AppLocalizations l10n) => Text(l10n.welcome);
''');
  }

  Future<void> _constantWithoutLettersNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract final class Separators {
  static const dash = ' - ';
}

Widget build() => const Text(Separators.dash);
''');
  }

  Future<void> _stringsFileWidgetLint() async {
    final filePath = '$testPackageLibPath/core/constants/app_strings.dart';
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Save');
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> _textFromVariableNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(String label) => Text(label);
''');
  }

  Future<void> _emptyTextNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('');
''');
  }

  Future<void> _numericTextNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('5');
''');
  }

  Future<void> _namedLabelLiteralLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const AppButton(label: 'Save');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> _namedHintTextLiteralLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const InputField(hintText: 'Email');
''';

    await assertDiagnostics(source, [lint(source.indexOf("'Email'"), "'Email'".length)]);
  }

  Future<void> _namedSemanticLabelLiteralLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Icon(semanticLabel: 'Add exercise');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Add exercise'"), "'Add exercise'".length),
    ]);
  }

  Future<void> _namedLabelFromVariableNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(String label) => AppButton(label: label);
''');
  }

  Future<void> _interpolationWithLiteralTextLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(String name) => Text('Hello $name');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf(r"'Hello $name'"), r"'Hello $name'".length),
    ]);
  }

  Future<void> _interpolationWithoutLiteralTextNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build(int count) => Text('$count');
''');
  }

  static const _formWidget = r'''
import 'package:flutter/widgets.dart';

class ScheduleForm extends StatefulWidget {
  const ScheduleForm({required this.onError, required this.onSelected});
  final ValueChanged<String> onError;
  final ValueChanged<String> onSelected;

  @override
  State<ScheduleForm> createState() => _ScheduleFormState();
}
''';

  Future<void> _callbackProseInStateLint() async {
    const source =
        '''
$_formWidget
class _ScheduleFormState extends State<ScheduleForm> {
  void _submit() {
    widget.onError('Please choose a time first');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Please choose"), "'Please choose a time first'".length),
    ]);
  }

  Future<void> _callbackProseInStatelessWidgetLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

const _savedCopy = 'Draft saved.';

class SavePanel extends StatelessWidget {
  const SavePanel({required this.onSaved, this.onError, required this.onNotice});
  final void Function(String message) onSaved;
  final ValueChanged<String>? onError;
  final void Function({required String message}) onNotice;

  void _save(String name, void Function(String message) report) {
    onSaved('Saved!');
    onError?.call('Could not save $name');
    onNotice(message: _savedCopy);
    report('Name is required.');
    final void Function(String) announce = onSaved;
    announce('Saving draft');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Saved!'"), "'Saved!'".length),
      lint(source.indexOf(r"'Could not save $name'"), r"'Could not save $name'".length),
      lint(source.indexOf('_savedCopy);'), '_savedCopy'.length),
      lint(source.indexOf("'Name is required.'"), "'Name is required.'".length),
      lint(source.indexOf("'Saving draft'"), "'Saving draft'".length),
    ]);
  }

  Future<void> _callbackIdentifiersKeysAndProtocolStringsNoLint() async {
    await assertNoDiagnostics('''
$_formWidget
class _ScheduleFormState extends State<ScheduleForm> {
  void _select(Map<String, String> headers) {
    widget.onSelected('user_42');
    widget.onSelected('Authorization');
    widget.onSelected('https://example.com/v1.2/items');
    widget.onSelected('config.json');
    widget.onSelected('');
    widget.onSelected(headers['Authorization'] ?? '');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> _declaredMethodAndFunctionProseNoLint() async {
    await assertNoDiagnostics('''
$_formWidget
class TodoNotifier {
  void addTodo(String title) {}
}

void logEvent(String message) {}

class _ScheduleFormState extends State<ScheduleForm> {
  final notifier = TodoNotifier();

  void _add() {
    notifier.addTodo('New Todo');
    logEvent('Form submitted by user');
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> _callbackProseOutsideWidgetClassNoLint() async {
    await assertNoDiagnostics(r'''
class FormCallbacks {
  const FormCallbacks({required this.onError});
  final void Function(String) onError;
}

void notify(FormCallbacks callbacks) {
  callbacks.onError('Please choose a time first');
}
''');
  }

  Future<void> _callbackProseInsideResolvedPreviewNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

class SavePanel extends StatelessWidget {
  const SavePanel({required this.onSaved});
  final ValueChanged<String> onSaved;

  @Preview(name: 'Saved')
  static Widget preview() {
    final panel = SavePanel(onSaved: (_) {});
    panel.onSaved('Saved to drafts');
    return panel;
  }

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }

  Future<void> _titleLiteralPassedToFunctionLint() async {
    const source = '''
import 'package:flutter/widgets.dart';

void show(BuildContext context, {String? title}) {}

void open(BuildContext context) {
  show(context, title: 'Saved changes');
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf("'Saved changes'"), "'Saved changes'".length),
    ]);
  }

  Future<void> _titleLiteralPassedToMethodLint() async {
    const source = '''
import 'package:flutter/widgets.dart';

class Toaster {
  Widget show({String? tooltip}) => const Toast();
}

void open(Toaster toaster) {
  toaster.show(tooltip: 'Undo last change');
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf("'Undo last change'"), "'Undo last change'".length),
    ]);
  }

  Future<void> _labelLiteralAfterPositionalArgumentLint() async {
    const source = '''
import 'package:flutter/widgets.dart';

void showConfirmDialog(BuildContext context, {String? title}) {}

void open(BuildContext context) {
  showConfirmDialog(context, title: 'Delete item?');
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf("'Delete item?'"), "'Delete item?'".length),
    ]);
  }

  Future<void> _titleFromVariablePassedToFunctionNoLint() async {
    await assertNoDiagnostics('''
void show({String? title}) {}

void open(String heading) {
  show(title: heading);
}
''');
  }

  Future<void> _unrelatedNamedLiteralPassedToFunctionNoLint() async {
    await assertNoDiagnostics('''
void send({String? channel}) {}

void open() {
  send(channel: 'Order updates');
}
''');
  }

  Future<void> _titleLiteralWithoutLettersPassedToFunctionNoLint() async {
    await assertNoDiagnostics('''
void show({String? title}) {}

void open() {
  show(title: '123');
}
''');
  }

  Future<void> _hintTextInDotShorthandConstructorLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Field(decoration: .new(hintText: 'Search'));
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Search'"), "'Search'".length)]);
  }

  Future<void> _titleInDotShorthandStaticMethodLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Toast pick() => .make(title: 'Saved');
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Saved'"), "'Saved'".length)]);
  }

  Future<void> _titleInEnumConstantArgumentsLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget? tabContent;

enum Tab {
  home(title: 'Home');

  const Tab({required this.title});
  final String title;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Home'"), "'Home'".length)]);
  }

  Future<void> _titleInSuperConstructorCallLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Child extends Parent {
  const Child() : super(title: 'Home');
}
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Home'"), "'Home'".length)]);
  }

  Future<void> _titleInRedirectingConstructorCallLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Child extends Parent {
  const Child() : this.named(title: 'Home');
  const Child.named({super.title});
}
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Home'"), "'Home'".length)]);
  }

  Future<void> _titleInFunctionTypedValueCallLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Row extends StatelessWidget {
  const Row({required this.onShow});
  final void Function({String? title}) onShow;

  @override
  Widget build(BuildContext context) {
    onShow(title: 'Save');
    return const Text('');
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> _labelInBinEntrypointLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const AppButton(label: 'Save');
''';
    final path = '$testPackageRootPath/bin/main.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [lint(source.indexOf("'Save'"), "'Save'".length)]);
  }

  Future<void> _labelInRepositoryDebugCallNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';

class SyncRepository {
  void fail(StackTrace stack) {
    debugPrintStack(stackTrace: stack, label: 'Sync failed');
  }
}
''');
  }

  Future<void> _labelInAnalyticsCallNoLint() async {
    await assertNoDiagnostics(r'''
class Analytics {
  void track(String event, {String? label}) {}
}

void use(Analytics analytics) {
  analytics.track('button_tap', label: 'checkout_button');
}
''');
  }

  Future<void> _titleToPlainNonUiFunctionNoLint() async {
    await assertNoDiagnostics('''
void show({String? title}) {}

void open() {
  show(title: 'Saved changes');
}
''');
  }

  Future<void> _globalFunctionVariableProseInWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Hooks {
  static void Function(String message) onLog = (_) {};
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    debugPrint('Rebuilt $productId card');
    debugPrint.call('Rebuilt card again');
    Hooks.onLog('Product card built');
    return const Widget();
  }
}
''');
  }
}
