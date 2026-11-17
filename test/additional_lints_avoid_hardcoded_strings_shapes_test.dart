import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_hardcoded_strings.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_ui_stub.dart';

void main() {
  analysisRuleSuite<_AvoidHardcodedStringsShapesTest>(
    'AvoidHardcodedStringsShapesTest',
    _AvoidHardcodedStringsShapesTest.new,
    _AvoidHardcodedStringsShapesTest._allCases,
  );
}

final class _AvoidHardcodedStringsShapesTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidHardcodedStringsShapesTest)> get _allCases =>
      caseSet<_AvoidHardcodedStringsShapesTest>(
        parent: const {},
        own: {
          'test_conditionalInText_lint': (t) => t._conditionalInTextLint(),
          'test_conditionalWithoutLiterals_noLint': (t) => t._conditionalWithoutLiteralsNoLint(),
          'test_switchExpressionInText_lint': (t) => t._switchExpressionInTextLint(),
          'test_conditionalInLabelArgument_lint': (t) => t._conditionalInLabelArgumentLint(),
          'test_interpolationInLabelArgument_lint': (t) => t._interpolationInLabelArgumentLint(),
          'test_compoundLabelNameLiteral_lint': (t) => t._compoundLabelNameLiteralLint(),
          'test_constructorDefaultLabel_lint': (t) => t._constructorDefaultLabelLint(),
          'test_constructorInitializerAndFieldLabel_lint': (t) =>
              t._constructorInitializerAndFieldLabelLint(),
          'test_widgetDefaultLabelOutsideWidget_noLint': (t) =>
              t._widgetDefaultLabelOutsideWidgetNoLint(),
          'test_constantListLookupInText_lint': (t) => t._constantListLookupInTextLint(),
          'test_constantListWithoutLettersLookup_noLint': (t) =>
              t._constantListWithoutLettersLookupNoLint(),
          'test_enumGetterLabelInFlutterFile_lint': (t) => t._enumGetterLabelInFlutterFileLint(),
          'test_extensionGetterLabelInFlutterFile_lint': (t) =>
              t._extensionGetterLabelInFlutterFileLint(),
          'test_enumGetterLabelWithoutFlutterImport_noLint': (t) =>
              t._enumGetterLabelWithoutFlutterImportNoLint(),
          'test_methodAndUnrelatedGetterInFlutterFile_noLint': (t) =>
              t._methodAndUnrelatedGetterInFlutterFileNoLint(),
          'test_literalPassedToModelConstructor_noLint': (t) =>
              t._literalPassedToModelConstructorNoLint(),
          'test_literalStoredByCopyWith_noLint': (t) => t._literalStoredByCopyWithNoLint(),
          'test_literalPassedToNonUiService_noLint': (t) => t._literalPassedToNonUiServiceNoLint(),
        },
      );

  @override
  void setUp() {
    addFlutterUiPackages(this);
    rule = AvoidHardcodedStrings();
    super.setUp();
  }

  Future<void> _conditionalInTextLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(bool on, String name) => Text(on ? 'Enabled' : name);

Widget buildBoth(bool on) => Text(on ? 'Active now' : 'Paused');
''';
    await assertDiagnostics(source, [
      for (final text in ["'Enabled'", "'Active now'", "'Paused'"])
        lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _conditionalWithoutLiteralsNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class AppLocalizations {
  String get on => 'On';
  String get off => 'Off';
}

Widget build(bool on, AppLocalizations l10n, String name) =>
    Text(on ? l10n.on : (name.isEmpty ? l10n.off : name));
''');
  }

  Future<void> _switchExpressionInTextLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(int level) => Text(switch (level) {
  0 => 'Easy',
  1 => 'Normal',
  _ => 'Hard',
});
''';
    await assertDiagnostics(source, [
      for (final text in ["'Easy'", "'Normal'", "'Hard'"]) lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _conditionalInLabelArgumentLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(bool busy) => AppButton(label: busy ? 'Saving' : 'Save');
''';
    await assertDiagnostics(source, [
      for (final text in ["'Saving'", "'Save'"]) lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _interpolationInLabelArgumentLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build(int step) => AppButton(label: 'Step $step of 3');
''';
    await assertDiagnostics(source, [
      for (final text in [r"'Step $step of 3'"]) lint(source.indexOf(text), text.length),
    ]);
  }

  static const _bannerWidget = r'''
import 'package:flutter/widgets.dart';

class Banner extends Widget {
  const Banner({this.ctaLabel, this.emptyBody, this.routeName, this.ctaKey, this.context});
  final String? ctaLabel;
  final String? emptyBody;
  final String? routeName;
  final String? ctaKey;
  final String? context;
}
''';

  Future<void> _compoundLabelNameLiteralLint() async {
    const source =
        '''
$_bannerWidget
Widget build() => const Banner(
  ctaLabel: 'Start now',
  emptyBody: 'Nothing here yet',
  routeName: '/start',
  ctaKey: 'start_cta',
  context: 'home',
);
''';
    await assertDiagnostics(source, [
      for (final text in ["'Start now'", "'Nothing here yet'"])
        lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _constructorDefaultLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Banner extends Widget {
  const Banner({this.label = 'Learn more', String caption = 'Read the guide', this.routeName = '/x'})
    : text = caption;
  final String label;
  final String text;
  final String routeName;
}
''';
    await assertDiagnostics(source, [
      for (final text in ["'Learn more'", "'Read the guide'"])
        lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _constructorInitializerAndFieldLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Banner extends Widget {
  const Banner() : label = 'Learn more';
  final String label;
  final String title = 'Settings';
  final String id = 'settings_banner';
}
''';
    await assertDiagnostics(source, [
      for (final text in ["'Learn more'", "'Settings'"]) lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _widgetDefaultLabelOutsideWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

class Report {
  const Report({this.label = 'Weekly report'});
  final String label;
  final String title = 'Summary';
}
''');
  }

  Future<void> _constantListLookupInTextLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class DayName extends StatelessWidget {
  const DayName(this.index);
  final int index;
  static const _days = ['Mon', 'Tue', 'Wed'];
  static const _ids = ['101', '202'];

  @override
  Widget build(BuildContext context) => Column(Text(_days[index]), Text(_ids[index]));
}

class Column extends Widget {
  const Column(this.a, this.b);
  final Widget a;
  final Widget b;
}
''';
    await assertDiagnostics(source, [
      for (final text in ['_days[index]']) lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _constantListWithoutLettersLookupNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

const _digits = ['1', '2', '3'];

Widget build(int index) => Text(_digits[index]);
''');
  }

  Future<void> _enumGetterLabelInFlutterFileLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

enum Mode {
  easy,
  hard;

  String get label => switch (this) {
    Mode.easy => 'Easy',
    Mode.hard => 'Hard',
  };

  String get description {
    if (this == Mode.easy) return 'Gentle pace';
    return 'Full effort';
  }

  String get id => 'mode_$name';
}
''';
    await assertDiagnostics(source, [
      for (final text in ["'Easy'", "'Hard'", "'Gentle pace'", "'Full effort'"])
        lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _extensionGetterLabelInFlutterFileLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

extension CountCopy on int {
  String get shortLabel => this < 1 ? 'No items' : '$this items';
}
''';
    await assertDiagnostics(source, [
      for (final text in ["'No items'", r"'$this items'"]) lint(source.indexOf(text), text.length),
    ]);
  }

  Future<void> _enumGetterLabelWithoutFlutterImportNoLint() async {
    await assertNoDiagnostics(r'''
enum Mode {
  easy,
  hard;

  String get label => switch (this) {
    Mode.easy => 'Easy',
    Mode.hard => 'Hard',
  };
}
''');
  }

  Future<void> _methodAndUnrelatedGetterInFlutterFileNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

enum Mode {
  easy;

  String describe(int count) => 'Mode $count';
  String get storageKey => 'mode_easy';
  String get contextual => 'Easy mode';
}
''');
  }

  Future<void> _literalPassedToModelConstructorNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

class AuthError {
  const AuthError.validation(this.text);
  final String text;
}

AuthError check() => const AuthError.validation('Enter a name');
''');
  }

  Future<void> _literalStoredByCopyWithNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget? anchor;

class LoadState {
  const LoadState({this.failure});
  final String? failure;
  LoadState copyWith({String? failure}) => LoadState(failure: failure ?? this.failure);
}

LoadState fail(LoadState state) => state.copyWith(failure: 'Could not load');
''');
  }

  Future<void> _literalPassedToNonUiServiceNoLint() async {
    await assertNoDiagnostics(r'''
class Reminders {
  void show({String? title, String? body, String? ctaLabel}) {}
}

void remind(Reminders reminders) {
  reminders.show(title: 'Reminder', body: 'Time to train', ctaLabel: 'Open the app');
}
''');
  }
}
