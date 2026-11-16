import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_empty_setstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_inherited_widget_in_initstate.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_stateless_widget_initialized_fields.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidEmptySetstateTest>(
    'AvoidEmptySetstateTest',
    _AvoidEmptySetstateTest.new,
    _AvoidEmptySetstateTest._allCases,
  );
  analysisRuleSuite<_AvoidInheritedWidgetInInitstateTest>(
    'AvoidInheritedWidgetInInitstateTest',
    _AvoidInheritedWidgetInInitstateTest.new,
    _AvoidInheritedWidgetInInitstateTest._allCases,
  );
  analysisRuleSuite<_AvoidStatelessWidgetInitializedFieldsTest>(
    'AvoidStatelessWidgetInitializedFieldsTest',
    _AvoidStatelessWidgetInitializedFieldsTest.new,
    _AvoidStatelessWidgetInitializedFieldsTest._allCases,
  );
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

final class _AvoidEmptySetstateTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_AvoidEmptySetstateTest)> get _allCases =>
      caseSet<_AvoidEmptySetstateTest>(
        parent: const {},
        own: {
          'test_emptySetState_lint': (t) => t._emptySetStateLint(),
          'test_setStateWithMutation_noLint': (t) => t._setStateWithMutationNoLint(),
          'test_emptyCallbackOutsideState_noLint': (t) => t._emptyCallbackOutsideStateNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidEmptySetstate();
    super.setUp();
  }

  Future<void> _emptySetStateLint() async {
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

  Future<void> _setStateWithMutationNoLint() async {
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

  Future<void> _emptyCallbackOutsideStateNoLint() async {
    await assertNoDiagnostics(r'''
void setState(void Function() fn) => fn();

void update() {
  setState(() {});
}
''');
  }
}

final class _AvoidInheritedWidgetInInitstateTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_AvoidInheritedWidgetInInitstateTest)> get _allCases =>
      caseSet<_AvoidInheritedWidgetInInitstateTest>(
        parent: const {},
        own: {
          'test_dependOnInheritedWidgetInInitState_lint': (t) =>
              t._dependOnInheritedWidgetInInitStateLint(),
          'test_dependOnInheritedWidgetInDidChangeDependencies_noLint': (t) =>
              t._dependOnInheritedWidgetInDidChangeDependenciesNoLint(),
          'test_unrelatedMethodNamedContext_noLint': (t) => t._unrelatedMethodNamedContextNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidInheritedWidgetInInitstate();
    super.setUp();
  }

  Future<void> _dependOnInheritedWidgetInInitStateLint() async {
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

  Future<void> _dependOnInheritedWidgetInDidChangeDependenciesNoLint() async {
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

  Future<void> _unrelatedMethodNamedContextNoLint() async {
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

final class _AvoidStatelessWidgetInitializedFieldsTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_AvoidStatelessWidgetInitializedFieldsTest)>
  get _allCases => caseSet<_AvoidStatelessWidgetInitializedFieldsTest>(
    parent: const {},
    own: {
      'test_initializedInstanceField_lint': (t) => t._initializedInstanceFieldLint(),
      'test_constructorInitializedField_noLint': (t) => t._constructorInitializedFieldNoLint(),
      'test_staticInitializedField_noLint': (t) => t._staticInitializedFieldNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidStatelessWidgetInitializedFields();
    super.setUp();
  }

  Future<void> _initializedInstanceFieldLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  final label = 'Inbox';
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('label'), 'label'.length)]);
  }

  Future<void> _constructorInitializedFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile(this.label);

  final String label;
}
''');
  }

  Future<void> _staticInitializedFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  static const label = 'Inbox';
}
''');
  }
}
