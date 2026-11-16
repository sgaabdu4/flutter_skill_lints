import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/check_for_equals_in_render_object_setters.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/keep_state_below_its_widget.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_widget_private_members.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<KeepStateBelowItsWidgetTest>(
    'KeepStateBelowItsWidgetTest',
    KeepStateBelowItsWidgetTest.new,
    {
      'test_stateBeforeWidget_lint': (t) => t._stateBeforeWidgetLint(),
      'test_stateBelowWidget_noLint': (t) => t._stateBelowWidgetNoLint(),
      'test_stateWithoutSameFileWidget_noLint': (t) => t._stateWithoutSameFileWidgetNoLint(),
    },
  );
  analysisRuleSuite<PreferWidgetPrivateMembersTest>(
    'PreferWidgetPrivateMembersTest',
    PreferWidgetPrivateMembersTest.new,
    {
      'test_publicField_lint': (t) => t._publicFieldLint(),
      'test_constructorBackedFinalField_noLint': (t) => t._constructorBackedFinalFieldNoLint(),
      'test_constructorBackedDefaultFinalField_noLint': (t) =>
          t._constructorBackedDefaultFinalFieldNoLint(),
      'test_initializerListBackedFinalField_noLint': (t) =>
          t._initializerListBackedFinalFieldNoLint(),
      'test_constructorBackedMutableField_lint': (t) => t._constructorBackedMutableFieldLint(),
      'test_publicMethod_lint': (t) => t._publicMethodLint(),
      'test_privateAndFrameworkMembers_noLint': (t) => t._privateAndFrameworkMembersNoLint(),
    },
  );
  analysisRuleSuite<CheckForEqualsInRenderObjectSettersTest>(
    'CheckForEqualsInRenderObjectSettersTest',
    CheckForEqualsInRenderObjectSettersTest.new,
    {
      'test_setterWithoutEqualityGuard_lint': (t) => t._setterWithoutEqualityGuardLint(),
      'test_setterWithEqualityGuard_noLint': (t) => t._setterWithEqualityGuardNoLint(),
      'test_nonInvalidatingSetter_noLint': (t) => t._nonInvalidatingSetterNoLint(),
    },
  );
}

abstract class _FlutterStructureRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}

class Key {
  const Key();
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
  State<StatefulWidget> createState() => State<StatefulWidget>();
}

class State<T extends StatefulWidget> {
  T get widget => throw UnimplementedError();
}

class RenderObject {}

class RenderBox extends RenderObject {
  void markNeedsLayout() {}
  void markNeedsPaint() {}
}
''');
  }
}

final class KeepStateBelowItsWidgetTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = KeepStateBelowItsWidget();
    super.setUp();
  }

  Future<void> _stateBeforeWidgetLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class _CounterState extends State<Counter> {}

class Counter extends StatefulWidget {
  const Counter({super.key});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('_CounterState'), '_CounterState'.length),
    ]);
  }

  Future<void> _stateBelowWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});
}

class _CounterState extends State<Counter> {}
''');
  }

  Future<void> _stateWithoutSameFileWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _GenericState extends State<StatefulWidget> {}
''');
  }
}

final class PreferWidgetPrivateMembersTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = PreferWidgetPrivateMembers();
    super.setUp();
  }

  Future<void> _publicFieldLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  final int count = 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count'), 'count'.length)]);
  }

  Future<void> _constructorBackedFinalFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, required this.count});

  final int count;
}
''');
  }

  Future<void> _constructorBackedDefaultFinalFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, this.count = 0});

  final int count;
}
''');
  }

  Future<void> _initializerListBackedFinalFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, required int count}) : count = count;

  final int count;
}
''');
  }

  Future<void> _constructorBackedMutableFieldLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  Counter({super.key, required this.count});

  int count;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count;'), 'count'.length)]);
  }

  Future<void> _publicMethodLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});

  void reset() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('reset'), 'reset'.length)]);
  }

  Future<void> _privateAndFrameworkMembersNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  final int _count = 0;

  void _reset() {}

  @override
  Widget build(BuildContext context) => const Widget();
}
''');
  }
}

final class CheckForEqualsInRenderObjectSettersTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = CheckForEqualsInRenderObjectSetters();
    super.setUp();
  }

  Future<void> _setterWithoutEqualityGuardLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class RenderCounter extends RenderBox {
  int _count = 0;

  set count(int value) {
    _count = value;
    markNeedsLayout();
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count(int'), 'count'.length)]);
  }

  Future<void> _setterWithEqualityGuardNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class RenderCounter extends RenderBox {
  int _count = 0;

  set count(int value) {
    if (_count == value) return;
    _count = value;
    markNeedsLayout();
  }
}
''');
  }

  Future<void> _nonInvalidatingSetterNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class RenderCounter extends RenderBox {
  int _count = 0;

  set count(int value) {
    _count = value;
  }
}
''');
  }
}
