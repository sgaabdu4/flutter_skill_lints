// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inherited_widget_in_initstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_stateless_widget_initialized_fields.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEmptySetstateTest);
    defineReflectiveTests(AvoidInheritedWidgetInInitstateTest);
    defineReflectiveTests(AvoidStatelessWidgetInitializedFieldsTest);
  });
}

abstract class _FlutterLifecycleRuleTest extends AnalysisRuleTest {
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
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) => null;

  InheritedElement? dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) => null;
}

class InheritedElement {}

abstract class InheritedWidget extends Widget {
  const InheritedWidget({required this.child});

  final Widget child;
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();

  void initState() {}

  void didChangeDependencies() {}

  void setState(void Function() fn) => fn();
}
''');
  }
}

@reflectiveTest
final class AvoidEmptySetstateTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = AvoidEmptySetstate();
    super.setUp();
  }

  Future<void> test_emptySetState_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  void update() {
    setState(() {});
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('setState'), 'setState(() {})'.length)]);
  }

  Future<void> test_setStateWithMutation_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class DemoState extends State<Demo> {
  var count = 0;

  void update() {
    setState(() {
      count += 1;
    });
  }
}
''');
  }

  Future<void> test_emptyCallbackOutsideState_noLint() async {
    await assertNoDiagnostics(r'''
void setState(void Function() fn) => fn();

void update() {
  setState(() {});
}
''');
  }
}

@reflectiveTest
final class AvoidInheritedWidgetInInitstateTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = AvoidInheritedWidgetInInitstate();
    super.setUp();
  }

  Future<void> test_dependOnInheritedWidgetInInitState_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class Scope extends InheritedWidget {
  const Scope({required super.child});
}

class DemoState extends State<Demo> {
  @override
  void initState() {
    super.initState();
    context.dependOnInheritedWidgetOfExactType<Scope>();
  }
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('context.dependOnInheritedWidgetOfExactType'),
        'context.dependOnInheritedWidgetOfExactType<Scope>()'.length,
      ),
    ]);
  }

  Future<void> test_dependOnInheritedWidgetInDidChangeDependencies_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {}

class Scope extends InheritedWidget {
  const Scope({required super.child});
}

class DemoState extends State<Demo> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.dependOnInheritedWidgetOfExactType<Scope>();
  }
}
''');
  }

  Future<void> test_unrelatedMethodNamedContext_noLint() async {
    await assertNoDiagnostics(r'''
class Context {
  void dependOnInheritedWidgetOfExactType<T>() {}
}

class Host {
  final context = Context();

  void initState() {
    context.dependOnInheritedWidgetOfExactType<int>();
  }
}
''');
  }
}

@reflectiveTest
final class AvoidStatelessWidgetInitializedFieldsTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = AvoidStatelessWidgetInitializedFields();
    super.setUp();
  }

  Future<void> test_initializedInstanceField_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  final label = 'Inbox';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('label'), 'label'.length)]);
  }

  Future<void> test_constructorInitializedField_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile(this.label);

  final String label;
}
''');
  }

  Future<void> test_staticInitializedField_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  static const label = 'Inbox';
}
''');
  }
}
