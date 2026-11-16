import 'package:flutter_skill_lints/src/additional_lints/fixes/proper_super_calls_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/proper_super_calls.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_ProperSuperCallsTest>('ProperSuperCallsTest', _ProperSuperCallsTest.new, {
    'reportsInitStateSuperNotFirst': (t) => t._reportsInitStateSuperNotFirst(),
    'reportsDisposeSuperNotLast': (t) => t._reportsDisposeSuperNotLast(),
    'acceptsCorrectOrder': (t) => t._acceptsCorrectOrder(),
    'ignoresMissingSuperCall': (t) => t._ignoresMissingSuperCall(),
    'ignoresClassesThatAreNotState': (t) => t._ignoresClassesThatAreNotState(),
    'ignoresExpressionBodies': (t) => t._ignoresExpressionBodies(),
    'movesSuperToStart': (t) => t._movesSuperToStart(),
    'movesSuperToEnd': (t) => t._movesSuperToEnd(),
  });
}

final class _ProperSuperCallsTest extends FixRuleTest {
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

  Future<void> _reportsInitStateSuperNotFirst() => assertDiagnostics(_wrongInit, [
    lint(_wrongInit.indexOf('super.initState()'), 'super.initState()'.length),
  ]);

  Future<void> _reportsDisposeSuperNotLast() => assertDiagnostics(_wrongDispose, [
    lint(_wrongDispose.indexOf('super.dispose()'), 'super.dispose()'.length),
  ]);

  Future<void> _acceptsCorrectOrder() => assertNoDiagnostics('''
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

  Future<void> _ignoresMissingSuperCall() => assertNoDiagnostics('''
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

  Future<void> _ignoresClassesThatAreNotState() => assertNoDiagnostics('''
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

  Future<void> _ignoresExpressionBodies() => assertNoDiagnostics('''
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

  Future<void> _movesSuperToStart() => expectFix(
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

  Future<void> _movesSuperToEnd() => expectFix(
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
