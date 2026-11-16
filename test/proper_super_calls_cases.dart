import 'package:flutter_skill_lints/src/additional_lints/fixes/proper_super_calls_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/proper_super_calls.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<ProperSuperCallsTest>('ProperSuperCallsTest', ProperSuperCallsTest.new, {
    'reportsInitStateSuperNotFirst': (t) => t.reportsInitStateSuperNotFirst(),
    'reportsDisposeSuperNotLast': (t) => t.reportsDisposeSuperNotLast(),
    'acceptsCorrectOrder': (t) => t.acceptsCorrectOrder(),
    'ignoresMissingSuperCall': (t) => t.ignoresMissingSuperCall(),
    'ignoresClassesThatAreNotState': (t) => t.ignoresClassesThatAreNotState(),
    'ignoresExpressionBodies': (t) => t.ignoresExpressionBodies(),
    'movesSuperToStart': (t) => t.movesSuperToStart(),
    'movesSuperToEnd': (t) => t.movesSuperToEnd(),
  });
}

final class ProperSuperCallsTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = ProperSuperCalls();
    super.setUp();
  }

  static const _wrongInit = '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void initState() {
    final a = 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  static const _wrongDispose = '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void dispose() {
    super.dispose();
    final a = 1;
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> reportsInitStateSuperNotFirst() => assertDiagnostics(_wrongInit, [
    lint(_wrongInit.indexOf('super.initState()'), 'super.initState()'.length),
  ]);

  Future<void> reportsDisposeSuperNotLast() => assertDiagnostics(_wrongDispose, [
    lint(_wrongDispose.indexOf('super.dispose()'), 'super.dispose()'.length),
  ]);

  Future<void> acceptsCorrectOrder() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void initState() {
    super.initState();
    final a = 1;
  }

  @override
  void dispose() {
    final a = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''');

  Future<void> ignoresMissingSuperCall() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void initState() {
    final a = 1;
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''');

  Future<void> ignoresClassesThatAreNotState() => assertNoDiagnostics('''
class Base {
  void initState() {}
}

class Other extends Base {
  @override
  void initState() {
    final a = 1;
    super.initState();
  }
}
''');

  Future<void> ignoresExpressionBodies() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void initState() => super.initState();

  @override
  Widget build(BuildContext context) => Text('a');
}
''');

  Future<void> movesSuperToStart() => expectFix(
    _wrongInit,
    (context) => ProperSuperCallsFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void initState() {
    super.initState();
    final a = 1;
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''',
  );

  Future<void> movesSuperToEnd() => expectFix(
    _wrongDispose,
    (context) => ProperSuperCallsFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  void dispose() {
    final a = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''',
  );
}
