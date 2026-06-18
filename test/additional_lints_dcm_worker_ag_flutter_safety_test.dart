// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_recursive_widget_calls.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_undisposed_instances.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_setstate_synchronously.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUndisposedInstancesTest);
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
