// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_flexible_outside_flex.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_recursive_widget_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_undisposed_instances.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_stateful_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_setstate_synchronously.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFlexibleOutsideFlexTest);
    defineReflectiveTests(AvoidUndisposedInstancesTest);
    defineReflectiveTests(AvoidUnnecessaryStatefulWidgetsTest);
    defineReflectiveTests(UseSetstateSynchronouslyTest);
    defineReflectiveTests(AvoidRecursiveWidgetCallsTest);
  });
}

abstract class _FlutterSafetyRuleTest extends AnalysisRuleTest {
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

class BuildContext {
  bool get mounted => true;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();

  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();

  bool get mounted => true;

  void setState(void Function() fn) => fn();
  void initState() {}
  void dispose() {}
}

abstract class RenderObjectWidget extends Widget {}
class Flex extends RenderObjectWidget {
  Flex({required List<Widget> children});
}
class Row extends Flex {
  Row({required super.children});
}
class Padding extends RenderObjectWidget {
  Padding({required Widget child});
}
class Container extends StatelessWidget {
  const Container({required this.child, Object? padding, double? width});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
class Flexible extends Widget {
  Flexible({required Widget child});
}
class Expanded extends Flexible {
  Expanded({required super.child});
}
class SizedBox extends Widget {
  const SizedBox();
}
''');
  }
}

@reflectiveTest
final class AvoidUndisposedInstancesTest extends _FlutterSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidUndisposedInstances();
    newPackage('riverpod')
        .addFile('lib/riverpod.dart', 'class Ref { void onDispose(void Function() callback) {} }');
    super.setUp();
  }

  Future<void> test_createdDisposableWithoutCleanup_lint() async {
    const source = r'''
class Resource {
  void dispose() {}
}

void buildResource() {
  final resource = Resource();
  print(resource);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('resource = Resource'), 'resource'.length),
    ]);
  }

  Future<void> test_createdDisposableWithCleanup_noLint() async {
    await assertNoDiagnostics(r'''
class Resource {
  void dispose() {}
}

void buildResource() {
  final resource = Resource();
  resource.dispose();
}
''');
  }

  Future<void> test_createdDisposableRegisteredWithAddTearDown_noLint() async {
    await assertNoDiagnostics(r'''
class Resource {
  void dispose() {}
}

void addTearDown(void Function() callback) {}

void buildResource() {
  final resource = Resource();
  addTearDown(resource.dispose);
}
''');
  }

  Future<void> test_futureCompletionOwnsCleanup_noLint() async {
    await assertNoDiagnostics(r'''
class Resource { void dispose() {} }
Future<void> useResource(Future<void> work) {
  final resource = Resource();
  return work.whenComplete(resource.dispose);
}
''');
  }

  Future<void> test_riverpodOnDisposeOwnsCleanup_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class Resource { void dispose() {} }
void useResource(Ref ref) {
  final resource = Resource();
  ref.onDispose(resource.dispose);
}
''');
  }

  Future<void> test_unregisteredTearOffDoesNotOwnCleanup_lint() async {
    const source = r'''
class Resource { void dispose() {} }
void useResource() {
  final resource = Resource();
  print(resource.dispose);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('resource ='), 8)]);
  }

  Future<void> test_unrelatedOnDisposeDoesNotOwnCleanup_lint() async {
    const source = r'''
class Resource { void dispose() {} }
class Ref { void onDispose(void Function() callback) {} }
void useResource(Ref ref) {
  final resource = Resource();
  ref.onDispose(resource.dispose);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('resource ='), 8)]);
  }

  Future<void> test_returnedDisposable_noLint() async {
    await assertNoDiagnostics(r'''
class Resource {
  void dispose() {}
}

Resource createResource() {
  final resource = Resource();
  return resource;
}
''');
  }

  Future<void> test_nonDisposable_noLint() async {
    await assertNoDiagnostics(r'''
class Resource {}

void buildResource() {
  final resource = Resource();
  print(resource);
}
''');
  }
}

@reflectiveTest
final class UseSetstateSynchronouslyTest extends _FlutterSafetyRuleTest {
  @override
  void setUp() {
    rule = UseSetstateSynchronously();
    super.setUp();
  }

  Future<void> test_setStateAfterAwait_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  var count = 0;

  Future<void> update() async {
    await Future<void>.value();
    setState(() {
      count += 1;
    });
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('setState'), 'setState'.length)]);
  }

  Future<void> test_setStateAfterMountedGuard_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  var count = 0;

  Future<void> update() async {
    await Future<void>.value();
    if (!context.mounted) return;
    setState(() {
      count += 1;
    });
  }
}
''');
  }

  Future<void> test_setStateInAsyncCallbackAfterAwait_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  var count = 0;

  void update() {
    run(() async {
      await Future<void>.value();
      setState(() {
        count += 1;
      });
    });
  }
}

void run(Future<void> Function() callback) {}
''';

    await assertDiagnostics(source, [lint(source.indexOf('setState'), 'setState'.length)]);
  }

  Future<void> test_nonStateSetState_noLint() async {
    await assertNoDiagnostics(r'''
void setState(void Function() fn) => fn();

Future<void> update() async {
  await Future<void>.value();
  setState(() {});
}
''');
  }
}

@reflectiveTest
final class AvoidRecursiveWidgetCallsTest extends _FlutterSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidRecursiveWidgetCalls();
    super.setUp();
  }

  Future<void> test_recursiveWidgetFunction_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget helper() {
  return helper();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('helper() {'), 'helper'.length)]);
  }

  Future<void> test_recursiveBuildMethod_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatelessWidget {
  const Demo();

  @override
  Widget build(BuildContext context) {
    return build(context);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('build(BuildContext'), 'build'.length)]);
  }

  Future<void> test_nonRecursiveWidgetFunction_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget helper() {
  return const SizedBox();
}
''');
  }

  Future<void> test_recursiveNonWidgetFunction_noLint() async {
    await assertNoDiagnostics(r'''
int countDown(int value) {
  if (value == 0) return 0;
  return countDown(value - 1);
}
''');
  }
}

@reflectiveTest
final class AvoidUnnecessaryStatefulWidgetsTest extends _FlutterSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryStatefulWidgets();
    super.setUp();
  }

  Future<void> test_mixinLifecycle_noLint() async {
    await assertNoDiagnostics(
      _source('''
mixin Lifecycle<T extends StatefulWidget> on State<T> {
  @override
  void dispose() { super.dispose(); }
}
''', 'with Lifecycle<Demo>'),
    );
  }

  Future<void> test_mixinMutableState_noLint() async {
    await assertNoDiagnostics(_source('mixin Counter { int count = 0; }', 'with Counter'));
  }

  Future<void> test_superclassLifecycle_noLint() async {
    final source = _source('''
abstract class Base<T extends StatefulWidget> extends State<T> {
  @override
  void initState() { super.initState(); }
}
''', '').replaceFirst('extends State<Demo>', 'extends Base<Demo>');
    await assertNoDiagnostics(source);
  }

  Future<void> test_lifecycleInterface_lint() async {
    final source = _source(
      'abstract interface class Lifecycle { void dispose(); }',
      'implements Lifecycle',
    );
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> test_emptyMixin_lint() async {
    final source = _source('mixin Empty {}', 'with Empty');
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> test_finalMixinField_lint() async {
    final source = _source('mixin Label { final label = "label"; }', 'with Label');
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> test_ownLifecycle_noLint() async {
    await assertNoDiagnostics(_source('', '', '@override void dispose() {}'));
  }

  Future<void> test_plainState_lint() async {
    final source = _source('', '');
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  String _source(String mixin, String clause, [String body = '']) =>
      '''
import 'package:flutter/widgets.dart';
$mixin
class Demo extends StatefulWidget {}
class DemoState extends State<Demo> $clause {
  $body
  Widget build(BuildContext context) => const Widget();
}
''';
}

@reflectiveTest
final class AvoidFlexibleOutsideFlexTest extends _FlutterSafetyRuleTest {
  Future<void> test_containerWithPadding_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Container(padding: Object(), child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }

  Future<void> test_containerWithWidth_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Container(width: 20, child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }

  Future<void> test_transparentContainerBelowPadding_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Padding(child: Container(child: Expanded(child: const SizedBox())));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> test_nullAndUnknownContainerProperties_noLint() async {
    for (final (index, declaration) in [
      'Widget build() => Container(padding: null,',
      'Widget build(dynamic padding) => Container(padding: padding,',
      'Widget build<T>(T padding) => Container(padding: padding,',
    ].indexed) {
      final path = '$testPackageLibPath/nullability_$index.dart';
      newFile(path, '''
import 'package:flutter/widgets.dart';
$declaration child: Expanded(child: const SizedBox()));
''');
      await assertNoDiagnosticsInFile(path);
    }
  }

  Future<void> test_nonNullableGenericContainerProperty_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build<T extends Object>(T padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> test_transparentContainer_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Container(child: Expanded(child: const SizedBox()))]);
''');
  }

  Future<void> test_nullableContainerPaddingIsNotProvenInvalid_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget build(Object? padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
''');
  }

  @override
  void setUp() {
    rule = AvoidFlexibleOutsideFlex();
    super.setUp();
  }

  Future<void> test_extractedExpandedWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Section extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(child: const SizedBox());
}
Widget build() => Row(children: [Section()]);
''');
  }

  Future<void> test_composedFlexParent_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Panel extends StatelessWidget {
  const Panel(this.children);
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Row(children: children);
}
Widget build() => Panel([Expanded(child: const SizedBox())]);
''');
  }

  Future<void> test_directFlexParent_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Expanded(child: const SizedBox())]);
''');
  }

  Future<void> test_incompatibleRenderObjectParent_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Padding(child: Expanded(child: const SizedBox()))]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }
}
