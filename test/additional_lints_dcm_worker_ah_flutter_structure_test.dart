// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/check_for_equals_in_render_object_setters.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/keep_state_below_its_widget.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_widget_private_members.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(KeepStateBelowItsWidgetTest);
    defineReflectiveTests(PreferWidgetPrivateMembersTest);
    defineReflectiveTests(CheckForEqualsInRenderObjectSettersTest);
  });
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

@reflectiveTest
final class KeepStateBelowItsWidgetTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = KeepStateBelowItsWidget();
    super.setUp();
  }

  Future<void> test_stateBeforeWidget_lint() async {
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

  Future<void> test_stateBelowWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});
}

class _CounterState extends State<Counter> {}
''');
  }

  Future<void> test_stateWithoutSameFileWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class _GenericState extends State<StatefulWidget> {}
''');
  }
}

@reflectiveTest
final class PreferWidgetPrivateMembersTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = PreferWidgetPrivateMembers();
    super.setUp();
  }

  Future<void> test_publicField_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key});

  final int count = 0;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count'), 'count'.length)]);
  }

  Future<void> test_constructorBackedFinalField_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, required this.count});

  final int count;
}
''');
  }

  Future<void> test_constructorBackedDefaultFinalField_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, this.count = 0});

  final int count;
}
''');
  }

  Future<void> test_initializerListBackedFinalField_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  const Counter({super.key, required int count}) : count = count;

  final int count;
}
''');
  }

  Future<void> test_constructorBackedMutableField_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatelessWidget {
  Counter({super.key, required this.count});

  int count;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count;'), 'count'.length)]);
  }

  Future<void> test_publicMethod_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Counter extends StatefulWidget {
  const Counter({super.key});

  void reset() {}
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('reset'), 'reset'.length)]);
  }

  Future<void> test_privateAndFrameworkMembers_noLint() async {
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

@reflectiveTest
final class CheckForEqualsInRenderObjectSettersTest extends _FlutterStructureRuleTest {
  @override
  void setUp() {
    rule = CheckForEqualsInRenderObjectSetters();
    super.setUp();
  }

  Future<void> test_setterWithoutEqualityGuard_lint() async {
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

  Future<void> test_setterWithEqualityGuard_noLint() async {
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

  Future<void> test_nonInvalidatingSetter_noLint() async {
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
