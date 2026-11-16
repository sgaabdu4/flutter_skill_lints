import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_commented_out_code.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_returning_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_class_destructuring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_explicit_function_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_widget_per_file.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_closest_build_context.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_sliver_prefix.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

part 'additional_lints_false_positive_test/use_existing_variable_cases.dart';

void main() {
  analysisRuleSuite<_PreferExplicitFunctionTypeFalsePositiveTest>(
    'PreferExplicitFunctionTypeFalsePositiveTest',
    _PreferExplicitFunctionTypeFalsePositiveTest.new,
    _PreferExplicitFunctionTypeFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_AvoidReturningWidgetsFalsePositiveTest>(
    'AvoidReturningWidgetsFalsePositiveTest',
    _AvoidReturningWidgetsFalsePositiveTest.new,
    _AvoidReturningWidgetsFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_PreferSingleSetstateFalsePositiveTest>(
    'PreferSingleSetstateFalsePositiveTest',
    _PreferSingleSetstateFalsePositiveTest.new,
    _PreferSingleSetstateFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_PreferSingleWidgetPerFileFalsePositiveTest>(
    'PreferSingleWidgetPerFileFalsePositiveTest',
    _PreferSingleWidgetPerFileFalsePositiveTest.new,
    _PreferSingleWidgetPerFileFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_UseClosestBuildContextFalsePositiveTest>(
    'UseClosestBuildContextFalsePositiveTest',
    _UseClosestBuildContextFalsePositiveTest.new,
    _UseClosestBuildContextFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_PreferClassDestructuringFalsePositiveTest>(
    'PreferClassDestructuringFalsePositiveTest',
    _PreferClassDestructuringFalsePositiveTest.new,
    _PreferClassDestructuringFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_UseSliverPrefixFalsePositiveTest>(
    'UseSliverPrefixFalsePositiveTest',
    _UseSliverPrefixFalsePositiveTest.new,
    _UseSliverPrefixFalsePositiveTest._allCases,
  );
  analysisRuleSuite<_AvoidCommentedOutCodeFalsePositiveTest>(
    'AvoidCommentedOutCodeFalsePositiveTest',
    _AvoidCommentedOutCodeFalsePositiveTest.new,
    _AvoidCommentedOutCodeFalsePositiveTest._allCases,
  );
  _defineUseExistingVariableCasesTests();
}

abstract class _AdditionalLintRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter')
      ..addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {
  const Key(String value);
}
class Widget {
  const Widget({Key? key});
}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => const Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}
class State<T extends StatefulWidget> {
  void setState(void Function() fn) => fn();
  Widget build(BuildContext context) => const Widget();
}
class SliverList extends Widget {
  const SliverList();
}
class Icon extends Widget {
  const Icon();
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
}

final class _PreferExplicitFunctionTypeFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_PreferExplicitFunctionTypeFalsePositiveTest)>
  get _allCases => caseSet<_PreferExplicitFunctionTypeFalsePositiveTest>(
    parent: const {},
    own: {
      'test_reportsPlainFunctionField': (t) => t._reportsPlainFunctionField(),
      'test_allowsSdkCompatibleOverrideParameter': (t) => t._allowsSdkCompatibleOverrideParameter(),
    },
  );

  @override
  void setUp() {
    rule = PreferExplicitFunctionType();
    super.setUp();
  }

  Future<void> _reportsPlainFunctionField() async {
    const source = '''
class Controller {
  final Function? onTap;
  const Controller(this.onTap);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Function'), 'Function?'.length)]);
  }

  Future<void> _allowsSdkCompatibleOverrideParameter() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

abstract class FakeStream extends Stream<List<int>> {
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw 'not implemented';
  }
}
''');
  }
}

final class _AvoidReturningWidgetsFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_AvoidReturningWidgetsFalsePositiveTest)>
  get _allCases => caseSet<_AvoidReturningWidgetsFalsePositiveTest>(
    parent: const {},
    own: {
      'test_severityIsError': (t) => t._severityIsError(),
      'test_reportsHelperReturningWidget': (t) => t._reportsHelperReturningWidget(),
      'test_allowsResolvedPreviewFunction': (t) => t._allowsResolvedPreviewFunction(),
      'test_reportsFunctionUnderLookalikePreviewAnnotation': (t) =>
          t._reportsFunctionUnderLookalikePreviewAnnotation(),
      'test_reportsHelperReturningWidgetList': (t) => t._reportsHelperReturningWidgetList(),
      'test_allowsWidgetListExtensionReturningWidgetList': (t) =>
          t._allowsWidgetListExtensionReturningWidgetList(),
      'test_reportsWidgetExtensionsOutsideCollectionUtilities': (t) =>
          t._reportsWidgetExtensionsOutsideCollectionUtilities(),
      'test_severity_error': (t) async => t._severityError(),
      'test_reportsPrivateMethodReturningWidgetList': (t) =>
          t._reportsPrivateMethodReturningWidgetList(),
      'test_allowsTestHelperReturningWidget': (t) => t._allowsTestHelperReturningWidget(),
      'test_allowsFrameworkBuilderOverride': (t) => t._allowsFrameworkBuilderOverride(),
      'test_allowsFrameworkBuilderCallbackMethod': (t) => t._allowsFrameworkBuilderCallbackMethod(),
    },
  );

  @override
  void setUp() {
    rule = AvoidReturningWidgets();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(AvoidReturningWidgets.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _reportsHelperReturningWidget() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget tile() => const Widget();
''';

    await assertDiagnostics(source, [lint(source.indexOf('tile'), 'tile'.length)]);
  }

  Future<void> _allowsResolvedPreviewFunction() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

@Preview(name: 'Tile')
Widget tilePreview() => const Widget();

final class TilePreviews {
  @Preview(name: 'Tile static')
  static Widget tileStaticPreview() => const Widget();
}
''');
  }

  Future<void> _reportsFunctionUnderLookalikePreviewAnnotation() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Preview {
  const Preview({String? name});
}

@Preview(name: 'Tile')
Widget tilePreview() => const Widget();
''';

    await assertDiagnostics(source, [lint(source.indexOf('tilePreview'), 'tilePreview'.length)]);
  }

  Future<void> _reportsHelperReturningWidgetList() async {
    const source = r'''
import 'package:flutter/widgets.dart';

List<Widget> headerChildren() => const <Widget>[];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('headerChildren'), 'headerChildren'.length),
    ]);
  }

  // collections-helpers.md: the skill's WidgetListX.separatedBy utility.
  Future<void> _allowsWidgetListExtensionReturningWidgetList() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension WidgetListX on List<Widget> {
  List<Widget> separatedBy(Widget separator) {
    return [
      for (final child in this) ...[
        if (!identical(child, first)) separator,
        child,
      ],
    ];
  }
}

extension WidgetIterableX on Iterable<Widget> {
  Iterable<Widget> spaced(Widget gap) => expand((child) => [child, gap]);
}
''');
  }

  Future<void> _reportsWidgetExtensionsOutsideCollectionUtilities() async {
    const source = r'''
import 'package:flutter/widgets.dart';

extension WidgetListX on List<Widget> {
  Widget first2() => first;
}

extension ContextX on BuildContext {
  List<Widget> headerChildren() => const <Widget>[];
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('first2'), 'first2'.length),
      lint(source.indexOf('headerChildren'), 'headerChildren'.length),
    ]);
  }

  void _severityError() {
    expect(AvoidReturningWidgets.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _reportsPrivateMethodReturningWidgetList() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class BentoSheet extends StatelessWidget {
  const BentoSheet();

  @override
  Widget build(BuildContext context) => const Widget();

  List<Widget> _headerChildren() => const <Widget>[];
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_headerChildren'), '_headerChildren'.length),
    ]);
  }

  Future<void> _allowsTestHelperReturningWidget() async {
    final filePath = '$testPackageRootPath/test/core/widgets/app_dialog_test.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';

Widget _testApp(Widget child) => child;
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsFrameworkBuilderOverride() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: override_on_non_overriding_member
import 'package:flutter/widgets.dart';

class MainShellRoute {
  @override
  Widget builder(
    BuildContext context,
    Object state,
    Object navigationShell,
  ) => const Widget();
}
''');
  }

  Future<void> _allowsFrameworkBuilderCallbackMethod() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static Icon _errorBuilder(BuildContext context, Object error, StackTrace? stackTrace) =>
      const Icon();
}
''');
  }
}

final class _PreferSingleSetstateFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_PreferSingleSetstateFalsePositiveTest)> get _allCases =>
      caseSet<_PreferSingleSetstateFalsePositiveTest>(
        parent: const {},
        own: {
          'test_reportsSequentialSetStateCalls': (t) => t._reportsSequentialSetStateCalls(),
          'test_allowsSetStateSeparatedByAwait': (t) => t._allowsSetStateSeparatedByAwait(),
          'test_allowsMutuallyExclusiveSetStateBranches': (t) =>
              t._allowsMutuallyExclusiveSetStateBranches(),
        },
      );

  @override
  void setUp() {
    rule = PreferSingleSetstate();
    super.setUp();
  }

  Future<void> _reportsSequentialSetStateCalls() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  void update() {
    setState(() {});
    setState(() {});
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('setState'), 'setState(() {})'.length),
    ]);
  }

  Future<void> _allowsSetStateSeparatedByAwait() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

Future<bool> save() async => false;

class DemoState extends State<Demo> {
  Future<void> submit() async {
    setState(() {});
    final success = await save();
    if (success) {
      return;
    }
    setState(() {});
  }
}
''');
  }

  Future<void> _allowsMutuallyExclusiveSetStateBranches() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  bool isMuted = true;

  void toggleMute() {
    if (isMuted) {
      setState(() => isMuted = false);
    } else {
      setState(() => isMuted = true);
    }
  }
}
''');
  }
}

final class _PreferSingleWidgetPerFileFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_PreferSingleWidgetPerFileFalsePositiveTest)>
  get _allCases => caseSet<_PreferSingleWidgetPerFileFalsePositiveTest>(
    parent: const {},
    own: {
      'test_reportsSecondPublicWidget': (t) => t._reportsSecondPublicWidget(),
      'test_reportsPrivateWidgetCompanion': (t) => t._reportsPrivateWidgetCompanion(),
      'test_allowsVisibleForTestingWidgetCompanion': (t) =>
          t._allowsVisibleForTestingWidgetCompanion(),
      'test_reportsPrivateVisibleForTestingWidgetCompanion': (t) =>
          t._reportsPrivateVisibleForTestingWidgetCompanion(),
      'test_allowsPrivateWidgetCompanionInTestFile': (t) =>
          t._allowsPrivateWidgetCompanionInTestFile(),
      'test_reportsVisibleForTestingWidgetCompanionInTestFile': (t) =>
          t._reportsVisibleForTestingWidgetCompanionInTestFile(),
    },
  );

  @override
  void setUp() {
    rule = PreferSingleWidgetPerFile();
    super.setUp();
  }

  Future<void> _reportsSecondPublicWidget() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class PrimaryWidget extends StatelessWidget {
  const PrimaryWidget({super.key});
}

class SecondaryWidget extends StatelessWidget {
  const SecondaryWidget({super.key});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('SecondaryWidget'), 'SecondaryWidget'.length),
    ]);
  }

  Future<void> _reportsPrivateWidgetCompanion() async {
    const source = r'''
// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';

class PrimaryWidget extends StatelessWidget {
  const PrimaryWidget({super.key});
}

class _PrimaryWidgetContent extends StatelessWidget {
  const _PrimaryWidgetContent({super.key});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_PrimaryWidgetContent'), '_PrimaryWidgetContent'.length),
    ]);
  }

  Future<void> _allowsVisibleForTestingWidgetCompanion() async {
    final filePath = '$testPackageRootPath/lib/primary_widget.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';

const visibleForTesting = _VisibleForTesting();

class _VisibleForTesting {
  const _VisibleForTesting();
}

class PrimaryWidget extends StatelessWidget {
  const PrimaryWidget({super.key});
}

@visibleForTesting
class PrimaryWidgetContent extends StatelessWidget {
  const PrimaryWidgetContent({super.key});
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsPrivateVisibleForTestingWidgetCompanion() async {
    const source = r'''
// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';

const visibleForTesting = _VisibleForTesting();

class _VisibleForTesting {
  const _VisibleForTesting();
}

class PrimaryWidget extends StatelessWidget {
  const PrimaryWidget({super.key});
}

@visibleForTesting
class _PrimaryWidgetContent extends StatelessWidget {
  const _PrimaryWidgetContent({super.key});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_PrimaryWidgetContent'), '_PrimaryWidgetContent'.length),
    ]);
  }

  Future<void> _allowsPrivateWidgetCompanionInTestFile() async {
    final filePath = '$testPackageRootPath/test/primary_widget_test.dart';
    newFile(filePath, r'''
// ignore_for_file: unused_element_parameter
import 'package:flutter/widgets.dart';

class PrimaryWidgetHarness extends StatelessWidget {
  const PrimaryWidgetHarness({super.key});
}

class _PrimaryWidgetContent extends StatelessWidget {
  const _PrimaryWidgetContent({super.key});
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsVisibleForTestingWidgetCompanionInTestFile() async {
    final filePath = '$testPackageRootPath/test/primary_widget_test.dart';
    const source = r'''
import 'package:flutter/widgets.dart';

const visibleForTesting = _VisibleForTesting();

class _VisibleForTesting {
  const _VisibleForTesting();
}

class PrimaryWidgetHarness extends StatelessWidget {
  const PrimaryWidgetHarness({super.key});
}

@visibleForTesting
class PrimaryWidgetContent extends StatelessWidget {
  const PrimaryWidgetContent({super.key});
}
''';

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      lint(source.indexOf('PrimaryWidgetContent'), 'PrimaryWidgetContent'.length),
    ]);
  }
}

final class _UseClosestBuildContextFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_UseClosestBuildContextFalsePositiveTest)>
  get _allCases => caseSet<_UseClosestBuildContextFalsePositiveTest>(
    parent: const {},
    own: {
      'test_reportsOuterContextWhenInnerContextNamed': (t) =>
          t._reportsOuterContextWhenInnerContextNamed(),
      'test_allowsWildcardBuilderContextWhenOuterContextIsIntentionallyPassed': (t) =>
          t._allowsWildcardBuilderContextWhenOuterContextIsIntentionallyPassed(),
    },
  );

  @override
  void setUp() {
    rule = UseClosestBuildContext();
    super.setUp();
  }

  Future<void> _reportsOuterContextWhenInnerContextNamed() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  void show({required Widget Function(BuildContext context) builder}) {}
}

extension HostContext on BuildContext {
  void show({required Widget Function(BuildContext context) builder}) {}
}

class Child extends Widget {
  const Child({required BuildContext hostContext});
}

class Sheet {
  static void show(BuildContext context) => context.show(
    builder: (sheetContext) => Child(hostContext: context),
  );
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('context'), 'context'.length)]);
  }

  Future<void> _allowsWildcardBuilderContextWhenOuterContextIsIntentionallyPassed() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension HostContext on BuildContext {
  void show({required Widget Function(BuildContext context) builder}) {}
}

class Child extends Widget {
  const Child({required BuildContext hostContext});
}

class Sheet {
  static void show(BuildContext context) => context.show(
    builder: (_) => Child(hostContext: context),
  );
}
''');
  }
}

final class _PreferClassDestructuringFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_PreferClassDestructuringFalsePositiveTest)>
  get _allCases => caseSet<_PreferClassDestructuringFalsePositiveTest>(
    parent: const {},
    own: {
      'test_allowsPropertyReadsPassedToConstructor': (t) =>
          t._allowsPropertyReadsPassedToConstructor(),
      'test_reportsPropertyReadsIntoLocals': (t) => t._reportsPropertyReadsIntoLocals(),
      'test_severity_error': (t) async => t._severityError(),
      'test_allowsPropertyAssertionsInTests': (t) => t._allowsPropertyAssertionsInTests(),
      'test_allowsL10nLocalBinding': (t) => t._allowsL10nLocalBinding(),
      'test_allowsAppLocalizationsVariableWithDifferentName': (t) =>
          t._allowsAppLocalizationsVariableWithDifferentName(),
    },
  );

  @override
  void setUp() {
    rule = PreferClassDestructuring();
    super.setUp();
  }

  // Row 19: the skill's DateTimeX.localDayStart (primitive-formatting.md).
  Future<void> _allowsPropertyReadsPassedToConstructor() async {
    await assertNoDiagnostics(r'''
class Day {
  const Day(this.year, this.month, {required this.day});
  final int year;
  final int month;
  final int day;
}

Day localDayStart(Day local) {
  return Day(local.year, local.month, day: local.day);
}
''');
  }

  Future<void> _reportsPropertyReadsIntoLocals() async {
    const source = r'''
class Span {
  int get inHours => 1;
  int get inMinutes => 2;
  int get inSeconds => 3;
}

int classAccess(Span d) {
  final a = d.inHours;
  final b = d.inMinutes;
  final c = d.inSeconds;
  return a + b + c;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('d.inHours'), 'd.inHours'.length)]);
  }

  void _severityError() {
    expect(PreferClassDestructuring.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsPropertyAssertionsInTests() async {
    final filePath = '$testPackageRootPath/test/workout_test.dart';
    newFile(filePath, r'''
class Workout {
  String get routineId => 'routine-1';
  int get orderIndex => 2;
  String get updatedAt => 'saved';
}

void expect(Object? actual, Object? matcher) {}
Object? equals(Object? value) => value;
const isNotNull = Object();

void main() {
  final workout = Workout();
  expect(workout.routineId, equals('routine-1'));
  expect(workout.orderIndex, equals(2));
  expect(workout.updatedAt, isNotNull);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsL10nLocalBinding() async {
    await assertNoDiagnostics(r'''
class AppLocalizations {
  const AppLocalizations();

  String get save => '';
  String get cancel => '';
  String get delete => '';
}

void build() {
  final l10n = const AppLocalizations();
  print(l10n.save);
  print(l10n.cancel);
  print(l10n.delete);
}
''');
  }

  Future<void> _allowsAppLocalizationsVariableWithDifferentName() async {
    await assertNoDiagnostics(r'''
class AppLocalizations {
  const AppLocalizations();

  String get save => '';
  String get cancel => '';
  String get delete => '';
}

void build() {
  final strings = const AppLocalizations();
  print(strings.save);
  print(strings.cancel);
  print(strings.delete);
}
''');
  }
}

final class _UseSliverPrefixFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_UseSliverPrefixFalsePositiveTest)> get _allCases =>
      caseSet<_UseSliverPrefixFalsePositiveTest>(
        parent: const {},
        own: {
          'test_reportsSliverReturningWidgetWithoutSliverName': (t) =>
              t._reportsSliverReturningWidgetWithoutSliverName(),
          'test_allowsPublicNameContainingSliver': (t) => t._allowsPublicNameContainingSliver(),
        },
      );

  @override
  void setUp() {
    rule = UseSliverPrefix();
    super.setUp();
  }

  Future<void> _reportsSliverReturningWidgetWithoutSliverName() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) => const SliverList();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('ItemList'), 'ItemList'.length)]);
  }

  Future<void> _allowsPublicNameContainingSliver() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class CatalogSliverList extends StatelessWidget {
  const CatalogSliverList({super.key});

  @override
  Widget build(BuildContext context) => const SliverList();
}
''');
  }
}

final class _AvoidCommentedOutCodeFalsePositiveTest extends _AdditionalLintRuleTest {
  static Map<String, Future<void> Function(_AvoidCommentedOutCodeFalsePositiveTest)>
  get _allCases => caseSet<_AvoidCommentedOutCodeFalsePositiveTest>(
    parent: const {},
    own: {
      'test_allowsParenthesizedHyphenatedDescription': (t) =>
          t._allowsParenthesizedHyphenatedDescription(),
      'test_allowsParenthesizedDescriptionThatWouldParseAsCall': (t) =>
          t._allowsParenthesizedDescriptionThatWouldParseAsCall(),
      'test_allowsUnspacedDescriptionThatDoesNotParse': (t) =>
          t._allowsUnspacedDescriptionThatDoesNotParse(),
      'test_doesNotGroupTrailingDescriptionsWithLaterCode': (t) =>
          t._doesNotGroupTrailingDescriptionsWithLaterCode(),
      'test_reportsCommentedOutCallStatement': (t) => t._reportsCommentedOutCallStatement(),
      'test_reportsCommentedOutCallWithoutSemicolon': (t) =>
          t._reportsCommentedOutCallWithoutSemicolon(),
      'test_reportsCommentedOutDeclaration': (t) => t._reportsCommentedOutDeclaration(),
      'test_reportsCommentedOutMultilineCall': (t) => t._reportsCommentedOutMultilineCall(),
      'test_allowsProseStartingWithTypeKeyword': (t) => t._allowsProseStartingWithTypeKeyword(),
      'test_allowsProseWithAssignmentLikeEquals': (t) => t._allowsProseWithAssignmentLikeEquals(),
      'test_reportsCommentedOutAssignmentWithoutSemicolon': (t) =>
          t._reportsCommentedOutAssignmentWithoutSemicolon(),
      'test_reportsCommentedOutMultilineDeclaration': (t) =>
          t._reportsCommentedOutMultilineDeclaration(),
      'test_reportsCommentedOutConstructorCallAfterProse': (t) =>
          t._reportsCommentedOutConstructorCallAfterProse(),
      'test_reportsCommentedOutBlock': (t) => t._reportsCommentedOutBlock(),
    },
  );

  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

  Future<void> _allowsParenthesizedHyphenatedDescription() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose (GOD-POD Method)
}
''');
  }

  Future<void> _allowsParenthesizedDescriptionThatWouldParseAsCall() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const ldl = '0-130'; // Cholesterol (total)
}
''');
  }

  Future<void> _allowsUnspacedDescriptionThatDoesNotParse() async {
    await assertNoDiagnostics(r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose(GOD-POD Method)
}
''');
  }

  Future<void> _doesNotGroupTrailingDescriptionsWithLaterCode() async {
    const source = r'''
abstract final class CommentProbe {
  static const fbs = '60-100'; // Glucose (GOD-POD Method)
  static const ldl = '0-130'; // Cholesterol (total)
}

void commentControls() {
  // foo(bar);
  // final x = 1;
}
''';
    final start = source.indexOf('// foo');
    final end = source.indexOf('// final x = 1;') + '// final x = 1;'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutCallStatement() async {
    const source = r'''
void run() {
  // foo(bar);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// foo'), '// foo(bar);'.length)]);
  }

  Future<void> _reportsCommentedOutCallWithoutSemicolon() async {
    const source = r'''
void run() {
  // foo(bar)
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// foo'), '// foo(bar)'.length)]);
  }

  Future<void> _reportsCommentedOutDeclaration() async {
    const source = r'''
void run() {
  // final x = 1;
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// final'), '// final x = 1;'.length)]);
  }

  Future<void> _reportsCommentedOutMultilineCall() async {
    const source = r'''
void run() {
  // save(
  //   item,
  // );
}
''';
    final start = source.indexOf('// save(');
    final end = source.indexOf('// );') + '// );'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _allowsProseStartingWithTypeKeyword() async {
    await assertNoDiagnostics(r'''
void run() {
  // Widget — use .select() on the computed getter
  print(1);
}
''');
  }

  Future<void> _allowsProseWithAssignmentLikeEquals() async {
    await assertNoDiagnostics(r'''
void run() {
  // ✅ DO — fixed sequence: persist → targeted sync → navigate.
  //    Reorder = UI flicker (stale parent) OR lost writes on dispose.
  print(1);
}
''');
  }

  Future<void> _reportsCommentedOutAssignmentWithoutSemicolon() async {
    const source = r'''
void run() {
  // count = 1
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('// count'), '// count = 1'.length)]);
  }

  Future<void> _reportsCommentedOutMultilineDeclaration() async {
    const source = r'''
void run() {
  // final items = watch(
  //   provider,
  // );
}
''';
    final start = source.indexOf('// final');
    final end = source.indexOf('// );') + '// );'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutConstructorCallAfterProse() async {
    const source = r'''
void run() {
  // inside UserModel.toEntity() or UserImportService — outside /domain/:
  //   User(email: Email(json['email'] as String))
}
''';
    final start = source.indexOf('// inside');
    final end = source.indexOf('String))') + 'String))'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }

  Future<void> _reportsCommentedOutBlock() async {
    const source = r'''
void run() {
  // if (ready) {
  //   doThing();
  // }
}
''';
    final start = source.indexOf('// if');
    final end = source.lastIndexOf('// }') + '// }'.length;
    await assertDiagnostics(source, [lint(start, end - start)]);
  }
}
