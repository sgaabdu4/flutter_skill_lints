import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_flexible_outside_flex.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_recursive_widget_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_undisposed_instances.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_stateful_widgets.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_setstate_synchronously.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidFlexibleOutsideFlexTest>(
    'AvoidFlexibleOutsideFlexTest',
    _AvoidFlexibleOutsideFlexTest.new,
    _AvoidFlexibleOutsideFlexTest._allCases,
  );
  analysisRuleSuite<_AvoidUndisposedInstancesTest>(
    'AvoidUndisposedInstancesTest',
    _AvoidUndisposedInstancesTest.new,
    _AvoidUndisposedInstancesTest._allCases,
  );
  analysisRuleSuite<_AvoidUndisposedDartUiPathTest>(
    'AvoidUndisposedDartUiPathTest',
    _AvoidUndisposedDartUiPathTest.new,
    _AvoidUndisposedDartUiPathTest._allCases,
  );
  analysisRuleSuite<_AvoidUnnecessaryStatefulWidgetsTest>(
    'AvoidUnnecessaryStatefulWidgetsTest',
    _AvoidUnnecessaryStatefulWidgetsTest.new,
    _AvoidUnnecessaryStatefulWidgetsTest._allCases,
  );
  analysisRuleSuite<_UseSetstateSynchronouslyTest>(
    'UseSetstateSynchronouslyTest',
    _UseSetstateSynchronouslyTest.new,
    _UseSetstateSynchronouslyTest._allCases,
  );
  analysisRuleSuite<_AvoidRecursiveWidgetCallsTest>(
    'AvoidRecursiveWidgetCallsTest',
    _AvoidRecursiveWidgetCallsTest.new,
    _AvoidRecursiveWidgetCallsTest._allCases,
  );
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
abstract class ScrollView extends StatelessWidget {
  const ScrollView();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class ListView extends ScrollView {
  const ListView({List<Widget> children = const []});
  const ListView.builder({required Widget Function(BuildContext, int) itemBuilder});
}
class SingleChildScrollView extends StatelessWidget {
  const SingleChildScrollView({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
''');
  }
}

final class _AvoidUndisposedInstancesTest extends _FlutterSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidUndisposedInstancesTest)> get _allCases =>
      caseSet<_AvoidUndisposedInstancesTest>(
        parent: const {},
        own: {
          'test_createdDisposableWithoutCleanup_lint': (t) =>
              t._createdDisposableWithoutCleanupLint(),
          'test_createdDisposableWithCleanup_noLint': (t) =>
              t._createdDisposableWithCleanupNoLint(),
          'test_createdCloseableWithoutCleanup_lint': (t) =>
              t._createdCloseableWithoutCleanupLint(),
          'test_userDefinedPathCloseStillRequiresCleanup_lint': (t) =>
              t._userDefinedPathCloseStillRequiresCleanupLint(),
          'test_createdCancelableWithoutCleanup_lint': (t) =>
              t._createdCancelableWithoutCleanupLint(),
          'test_createdDisposableRegisteredWithAddTearDown_noLint': (t) =>
              t._createdDisposableRegisteredWithAddTearDownNoLint(),
          'test_futureCompletionOwnsCleanup_noLint': (t) => t._futureCompletionOwnsCleanupNoLint(),
          'test_riverpodOnDisposeOwnsCleanup_noLint': (t) =>
              t._riverpodOnDisposeOwnsCleanupNoLint(),
          'test_unregisteredTearOffDoesNotOwnCleanup_lint': (t) =>
              t._unregisteredTearOffDoesNotOwnCleanupLint(),
          'test_unrelatedOnDisposeDoesNotOwnCleanup_lint': (t) =>
              t._unrelatedOnDisposeDoesNotOwnCleanupLint(),
          'test_returnedDisposable_noLint': (t) => t._returnedDisposableNoLint(),
          'test_nonDisposable_noLint': (t) => t._nonDisposableNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUndisposedInstances();
    newPackage('riverpod')
        .addFile('lib/riverpod.dart', 'class Ref { void onDispose(void Function() callback) {} }');
    super.setUp();
  }

  Future<void> _createdDisposableWithoutCleanupLint() async {
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

  Future<void> _createdDisposableWithCleanupNoLint() async {
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

  Future<void> _createdCloseableWithoutCleanupLint() async {
    const source = r'''
class Resource { void close() {} }
void buildResource() {
  final resource = Resource();
  print(resource);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('resource ='), 'resource'.length)]);
  }

  Future<void> _userDefinedPathCloseStillRequiresCleanupLint() async {
    const source = r'''
class Path { void close() {} }
void createPath() {
  final path = Path();
  print(path);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('path ='), 'path'.length)]);
  }

  Future<void> _createdCancelableWithoutCleanupLint() async {
    const source = r'''
class Task { void cancel() {} }
void startTask() {
  final task = Task();
  print(task);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('task ='), 'task'.length)]);
  }

  Future<void> _createdDisposableRegisteredWithAddTearDownNoLint() async {
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

  Future<void> _futureCompletionOwnsCleanupNoLint() async {
    await assertNoDiagnostics(r'''
class Resource { void dispose() {} }
Future<void> useResource(Future<void> work) {
  final resource = Resource();
  return work.whenComplete(resource.dispose);
}
''');
  }

  Future<void> _riverpodOnDisposeOwnsCleanupNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';
class Resource { void dispose() {} }
void useResource(Ref ref) {
  final resource = Resource();
  ref.onDispose(resource.dispose);
}
''');
  }

  Future<void> _unregisteredTearOffDoesNotOwnCleanupLint() async {
    const source = r'''
class Resource { void dispose() {} }
void useResource() {
  final resource = Resource();
  print(resource.dispose);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('resource ='), 8)]);
  }

  Future<void> _unrelatedOnDisposeDoesNotOwnCleanupLint() async {
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

  Future<void> _returnedDisposableNoLint() async {
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

  Future<void> _nonDisposableNoLint() async {
    await assertNoDiagnostics(r'''
class Resource {}

void buildResource() {
  final resource = Resource();
  print(resource);
}
''');
  }
}

final class _UseSetstateSynchronouslyTest extends _FlutterSafetyRuleTest {
  static Map<String, Future<void> Function(_UseSetstateSynchronouslyTest)> get _allCases =>
      caseSet<_UseSetstateSynchronouslyTest>(
        parent: const {},
        own: {
          'test_setStateAfterAwait_lint': (t) => t._setStateAfterAwaitLint(),
          'test_setStateAfterMountedGuard_noLint': (t) => t._setStateAfterMountedGuardNoLint(),
          'test_setStateInAsyncCallbackAfterAwait_lint': (t) =>
              t._setStateInAsyncCallbackAfterAwaitLint(),
          'test_nonStateSetState_noLint': (t) => t._nonStateSetStateNoLint(),
        },
      );

  @override
  void setUp() {
    rule = UseSetstateSynchronously();
    super.setUp();
  }

  Future<void> _setStateAfterAwaitLint() async {
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

  Future<void> _setStateAfterMountedGuardNoLint() async {
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

  Future<void> _setStateInAsyncCallbackAfterAwaitLint() async {
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

  Future<void> _nonStateSetStateNoLint() async {
    await assertNoDiagnostics(r'''
void setState(void Function() fn) => fn();

Future<void> update() async {
  await Future<void>.value();
  setState(() {});
}
''');
  }
}

final class _AvoidRecursiveWidgetCallsTest extends _FlutterSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidRecursiveWidgetCallsTest)> get _allCases =>
      caseSet<_AvoidRecursiveWidgetCallsTest>(
        parent: const {},
        own: {
          'test_recursiveWidgetFunction_lint': (t) => t._recursiveWidgetFunctionLint(),
          'test_recursiveBuildMethod_lint': (t) => t._recursiveBuildMethodLint(),
          'test_nonRecursiveWidgetFunction_noLint': (t) => t._nonRecursiveWidgetFunctionNoLint(),
          'test_recursiveNonWidgetFunction_noLint': (t) => t._recursiveNonWidgetFunctionNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidRecursiveWidgetCalls();
    super.setUp();
  }

  Future<void> _recursiveWidgetFunctionLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget helper() {
  return helper();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('helper() {'), 'helper'.length)]);
  }

  Future<void> _recursiveBuildMethodLint() async {
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

  Future<void> _nonRecursiveWidgetFunctionNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget helper() {
  return const SizedBox();
}
''');
  }

  Future<void> _recursiveNonWidgetFunctionNoLint() async {
    await assertNoDiagnostics(r'''
int countDown(int value) {
  if (value == 0) return 0;
  return countDown(value - 1);
}
''');
  }
}

final class _AvoidUnnecessaryStatefulWidgetsTest extends _FlutterSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryStatefulWidgetsTest)> get _allCases =>
      caseSet<_AvoidUnnecessaryStatefulWidgetsTest>(
        parent: const {},
        own: {
          'test_mixinLifecycle_noLint': (t) => t._mixinLifecycleNoLint(),
          'test_mixinMutableState_noLint': (t) => t._mixinMutableStateNoLint(),
          'test_superclassLifecycle_noLint': (t) => t._superclassLifecycleNoLint(),
          'test_lifecycleInterface_lint': (t) => t._lifecycleInterfaceLint(),
          'test_emptyMixin_lint': (t) => t._emptyMixinLint(),
          'test_finalMixinField_lint': (t) => t._finalMixinFieldLint(),
          'test_ownLifecycle_noLint': (t) => t._ownLifecycleNoLint(),
          'test_plainState_lint': (t) => t._plainStateLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnnecessaryStatefulWidgets();
    super.setUp();
  }

  Future<void> _mixinLifecycleNoLint() async {
    await assertNoDiagnostics(
      _source('''
mixin Lifecycle<T extends StatefulWidget> on State<T> {
  @override
  void dispose() { super.dispose(); }
}
''', 'with Lifecycle<Demo>'),
    );
  }

  Future<void> _mixinMutableStateNoLint() async {
    await assertNoDiagnostics(_source('mixin Counter { int count = 0; }', 'with Counter'));
  }

  Future<void> _superclassLifecycleNoLint() async {
    final source = _source('''
abstract class Base<T extends StatefulWidget> extends State<T> {
  @override
  void initState() { super.initState(); }
}
''', '').replaceFirst('extends State<Demo>', 'extends Base<Demo>');
    await assertNoDiagnostics(source);
  }

  Future<void> _lifecycleInterfaceLint() async {
    final source = _source(
      'abstract interface class Lifecycle { void dispose(); }',
      'implements Lifecycle',
    );
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> _emptyMixinLint() async {
    final source = _source('mixin Empty {}', 'with Empty');
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> _finalMixinFieldLint() async {
    final source = _source('mixin Label { final label = "label"; }', 'with Label');
    await assertDiagnostics(source, [lint(source.indexOf('Demo extends'), 4)]);
  }

  Future<void> _ownLifecycleNoLint() async {
    await assertNoDiagnostics(_source('', '', '@override void dispose() {}'));
  }

  Future<void> _plainStateLint() async {
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

final class _AvoidFlexibleOutsideFlexTest extends _FlutterSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidFlexibleOutsideFlexTest)> get _allCases =>
      caseSet<_AvoidFlexibleOutsideFlexTest>(
        parent: const {},
        own: {
          'test_containerWithPadding_lint': (t) => t._containerWithPaddingLint(),
          'test_containerWithWidth_lint': (t) => t._containerWithWidthLint(),
          'test_transparentContainerBelowPadding_lint': (t) =>
              t._transparentContainerBelowPaddingLint(),
          'test_nullAndUnknownContainerProperties_noLint': (t) =>
              t._nullAndUnknownContainerPropertiesNoLint(),
          'test_nonNullableGenericContainerProperty_lint': (t) =>
              t._nonNullableGenericContainerPropertyLint(),
          'test_transparentContainer_noLint': (t) => t._transparentContainerNoLint(),
          'test_nullableContainerPaddingIsNotProvenInvalid_noLint': (t) =>
              t._nullableContainerPaddingIsNotProvenInvalidNoLint(),
          'test_expandedUnderScrollViews_lint': (t) => t._expandedUnderScrollViewsLint(),
          'test_expandedInListBuilderOrAroundList_noLint': (t) =>
              t._expandedInListBuilderOrAroundListNoLint(),
          'test_extractedExpandedWidget_noLint': (t) => t._extractedExpandedWidgetNoLint(),
          'test_composedFlexParent_noLint': (t) => t._composedFlexParentNoLint(),
          'test_directFlexParent_noLint': (t) => t._directFlexParentNoLint(),
          'test_incompatibleRenderObjectParent_lint': (t) =>
              t._incompatibleRenderObjectParentLint(),
        },
      );

  Future<void> _containerWithPaddingLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Container(padding: Object(), child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }

  Future<void> _containerWithWidthLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Container(width: 20, child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }

  Future<void> _transparentContainerBelowPaddingLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Padding(child: Container(child: Expanded(child: const SizedBox())));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> _nullAndUnknownContainerPropertiesNoLint() async {
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

  Future<void> _nonNullableGenericContainerPropertyLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build<T extends Object>(T padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> _transparentContainerNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Container(child: Expanded(child: const SizedBox()))]);
''');
  }

  Future<void> _nullableContainerPaddingIsNotProvenInvalidNoLint() async {
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

  Future<void> _expandedUnderScrollViewsLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget list() => ListView(children: [const SizedBox(), Expanded(child: const SizedBox())]);
Widget scroll() => SingleChildScrollView(child: Expanded(child: const SizedBox()));
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('Expanded('), 'Expanded'.length),
      lint(source.lastIndexOf('Expanded('), 'Expanded'.length),
    ]);
  }

  Future<void> _expandedInListBuilderOrAroundListNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget builder() => ListView.builder(itemBuilder: (context, index) => Expanded(child: const SizedBox()));
Widget around() => Row(children: [Expanded(child: ListView(children: [const SizedBox()]))]);
''');
  }

  Future<void> _extractedExpandedWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Section extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(child: const SizedBox());
}
Widget build() => Row(children: [Section()]);
''');
  }

  Future<void> _composedFlexParentNoLint() async {
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

  Future<void> _directFlexParentNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Expanded(child: const SizedBox())]);
''');
  }

  Future<void> _incompatibleRenderObjectParentLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget build() => Row(children: [Padding(child: Expanded(child: const SizedBox()))]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded'), 8)]);
  }
}

final class _AvoidUndisposedDartUiPathTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidUndisposedDartUiPathTest)> get _allCases =>
      caseSet<_AvoidUndisposedDartUiPathTest>(
        parent: const {},
        own: {
          'test_geometricPathCloseIsNotDisposal_noLint': (t) =>
              t._geometricPathCloseIsNotDisposalNoLint(),
        },
      );

  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = AvoidUndisposedInstances();
    super.setUp();
    newFile('$packagesRootPath/ui/lib/ui.dart', r'''
library dart.ui;

class Path {
  Path();
  void moveTo(double x, double y) {}
  void lineTo(double x, double y) {}
  void close() {}
}
class Paint {}
class Canvas {
  void drawPath(Path path, Paint paint) {}
}
''');
  }

  Future<void> _geometricPathCloseIsNotDisposalNoLint() async {
    await assertNoDiagnostics(r'''
import 'dart:ui';

void paintLine(Canvas canvas, Paint paint) {
  final path = Path();
  path.moveTo(0, 0);
  path.lineTo(1, 1);
  canvas.drawPath(path, paint);
}
''');
  }
}
