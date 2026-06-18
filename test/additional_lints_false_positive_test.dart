// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_returning_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_class_destructuring.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_explicit_function_type.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_widget_per_file.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_closest_build_context.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_existing_variable.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_sliver_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExplicitFunctionTypeFalsePositiveTest);
    defineReflectiveTests(AvoidReturningWidgetsFalsePositiveTest);
    defineReflectiveTests(PreferSingleSetstateFalsePositiveTest);
    defineReflectiveTests(PreferSingleWidgetPerFileFalsePositiveTest);
    defineReflectiveTests(UseClosestBuildContextFalsePositiveTest);
    defineReflectiveTests(UseExistingVariableFalsePositiveTest);
    defineReflectiveTests(PreferClassDestructuringFalsePositiveTest);
    defineReflectiveTests(UseSliverPrefixFalsePositiveTest);
  });
}

abstract class _AdditionalLintRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
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
''');
  }
}

@reflectiveTest
final class PreferExplicitFunctionTypeFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = PreferExplicitFunctionType();
    super.setUp();
  }

  Future<void> test_reportsPlainFunctionField() async {
    const source = '''
class Controller {
  final Function? onTap;
  const Controller(this.onTap);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('Function'), 'Function?'.length)]);
  }

  Future<void> test_allowsSdkCompatibleOverrideParameter() async {
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

@reflectiveTest
final class AvoidReturningWidgetsFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = AvoidReturningWidgets();
    super.setUp();
  }

  Future<void> test_reportsHelperReturningWidget() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget tile() => const Widget();
''';

    await assertDiagnostics(source, [lint(source.indexOf('tile'), 'tile'.length)]);
  }

  Future<void> test_reportsHelperReturningWidgetList() async {
    const source = r'''
import 'package:flutter/widgets.dart';

List<Widget> headerChildren() => const <Widget>[];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('headerChildren'), 'headerChildren'.length),
    ]);
  }

  Future<void> test_reportsPrivateMethodReturningWidgetList() async {
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

  Future<void> test_allowsTestHelperReturningWidget() async {
    final filePath = '$testPackageRootPath/test/core/widgets/app_dialog_test.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';

Widget _testApp(Widget child) => child;
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsFrameworkBuilderOverride() async {
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

  Future<void> test_allowsFrameworkBuilderCallbackMethod() async {
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

@reflectiveTest
final class PreferSingleSetstateFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = PreferSingleSetstate();
    super.setUp();
  }

  Future<void> test_reportsSequentialSetStateCalls() async {
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

  Future<void> test_allowsSetStateSeparatedByAwait() async {
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

  Future<void> test_allowsMutuallyExclusiveSetStateBranches() async {
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

@reflectiveTest
final class PreferSingleWidgetPerFileFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = PreferSingleWidgetPerFile();
    super.setUp();
  }

  Future<void> test_reportsSecondPublicWidget() async {
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

  Future<void> test_reportsPrivateWidgetCompanion() async {
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

  Future<void> test_allowsVisibleForTestingWidgetCompanion() async {
    const filePath = '/home/test/package/lib/primary_widget.dart';
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

  Future<void> test_reportsPrivateVisibleForTestingWidgetCompanion() async {
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

  Future<void> test_allowsPrivateWidgetCompanionInTestFile() async {
    const filePath = '/home/test/package/test/primary_widget_test.dart';
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

  Future<void> test_reportsVisibleForTestingWidgetCompanionInTestFile() async {
    const filePath = '/home/test/package/test/primary_widget_test.dart';
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

@reflectiveTest
final class UseClosestBuildContextFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = UseClosestBuildContext();
    super.setUp();
  }

  Future<void> test_reportsOuterContextWhenInnerContextNamed() async {
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

  Future<void> test_allowsWildcardBuilderContextWhenOuterContextIsIntentionallyPassed() async {
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

@reflectiveTest
final class UseExistingVariableFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = UseExistingVariable();
    super.setUp();
  }

  Future<void> test_reportsDuplicateExpressionWithoutInterveningSideEffect() async {
    const source = r'''
class Container {
  Object read(Object provider) => Object();
}

final provider = Object();

void run(Container container) {
  final initial = container.read(provider);
  final duplicate = container.read(provider);
  print(initial);
  print(duplicate);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('container.read(provider)', source.indexOf('duplicate')), 24),
    ]);
  }

  Future<void> test_allowsDuplicateExpressionAfterMutation() async {
    await assertNoDiagnostics(r'''
class Container {
  Object read(Object provider) => Object();
}

class Notifier {
  void updateSet(Object value) {}
}

final provider = Object();

void run(Container container, Notifier notifier) {
  final initial = container.read(provider);
  notifier.updateSet(initial);
  final afterUpdate = container.read(provider);
  print(afterUpdate);
}
''');
  }

  Future<void> test_allowsFreshCollectionRecorders() async {
    await assertNoDiagnostics(r'''
void run() {
  final deletedIds = <String>[];
  final createdRows = <Map<String, Object?>>[];
  final permissions = <List<String>>[];
  deletedIds.add('one');
  createdRows.add({'id': 'row-1'});
  permissions.add(['read']);
}
''');
  }
}

@reflectiveTest
final class PreferClassDestructuringFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = PreferClassDestructuring();
    super.setUp();
  }

  Future<void> test_allowsPropertyAssertionsInTests() async {
    const filePath = '/home/test/package/test/workout_test.dart';
    newFile(filePath, r'''
class Workout {
  String get routineId => 'routine-1';
  int get orderIndex => 2;
  String get updatedAt => '2024-01-01';
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

  Future<void> test_allowsL10nLocalBinding() async {
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

  Future<void> test_allowsAppLocalizationsVariableWithDifferentName() async {
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

@reflectiveTest
final class UseSliverPrefixFalsePositiveTest extends _AdditionalLintRuleTest {
  @override
  void setUp() {
    rule = UseSliverPrefix();
    super.setUp();
  }

  Future<void> test_reportsSliverReturningWidgetWithoutSliverName() async {
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

  Future<void> test_allowsPublicNameContainingSliver() async {
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
