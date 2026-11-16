import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_setstate.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessarySetstateTest>(
    'AvoidUnnecessarySetstateTest',
    AvoidUnnecessarySetstateTest.new,
    {
      'reportsSetStateInInitState': (t) => t.reportsSetStateInInitState(),
      'reportsSetStateInDidUpdateWidget': (t) => t.reportsSetStateInDidUpdateWidget(),
      'reportsSetStateDirectlyInBuild': (t) => t.reportsSetStateDirectlyInBuild(),
      'acceptsSetStateInEventHandler': (t) => t.acceptsSetStateInEventHandler(),
      'acceptsSetStateInOtherMethods': (t) => t.acceptsSetStateInOtherMethods(),
      'acceptsSetStateInsideClosureInInitState': (t) => t.acceptsSetStateInsideClosureInInitState(),
      'acceptsSetStateOutsideState': (t) => t.acceptsSetStateOutsideState(),
      'inlinesExpressionBody': (t) => t.inlinesExpressionBody(),
      'inlinesBlockBody': (t) => t.inlinesBlockBody(),
      'removesEmptyCallback': (t) => t.removesEmptyCallback(),
      'keepsCallbackReferences': (t) => t.keepsCallbackReferences(),
    },
  );
}

final class AvoidUnnecessarySetstateTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidUnnecessarySetstate();
    super.setUp();
  }

  static String _state(String members) =>
      '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  int count = 0;

$members
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  static final _initWithExpression = _state('''
  @override
  void initState() {
    super.initState();
    setState(() => count = 1);
  }
''');

  Future<void> reportsSetStateInInitState() => assertDiagnostics(_initWithExpression, [
    lint(_initWithExpression.indexOf('setState('), 'setState(() => count = 1)'.length),
  ]);

  Future<void> reportsSetStateInDidUpdateWidget() async {
    final source = _state('''
  @override
  void didUpdateWidget(W oldWidget) {
    setState(() {});
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('setState('), 'setState(() {})'.length)]);
  }

  Future<void> reportsSetStateDirectlyInBuild() async {
    const source = '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  Widget build(BuildContext context) {
    setState(() {});
    return Text('a');
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('setState('), 'setState(() {})'.length)]);
  }

  Future<void> acceptsSetStateInEventHandler() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() {}),
    child: Text('a'),
  );
}
''');

  Future<void> acceptsSetStateInOtherMethods() => assertNoDiagnostics(
    _state('''
  void bump() {
    setState(() => count++);
  }
'''),
  );

  Future<void> acceptsSetStateInsideClosureInInitState() => assertNoDiagnostics(
    _state('''
  @override
  void initState() {
    Future<void>.value().then((_) {
      setState(() {});
    });
  }
'''),
  );

  Future<void> acceptsSetStateOutsideState() => assertNoDiagnostics('''
class Plain {
  void setState(void Function() fn) {}

  void initState() {
    setState(() {});
  }
}
''');

  Future<void> inlinesExpressionBody() => expectFix(
    _initWithExpression,
    (context) => AvoidUnnecessarySetstateFix(context: context),
    expected: _state('''
  @override
  void initState() {
    super.initState();
    count = 1;
  }
'''),
  );

  Future<void> inlinesBlockBody() => expectFix(
    _state('''
  @override
  void initState() {
    setState(() {
      count = 1;
      count = 2;
    });
  }
'''),
    (context) => AvoidUnnecessarySetstateFix(context: context),
    expected: _state('''
  @override
  void initState() {
    count = 1;
    count = 2;
  }
'''),
  );

  Future<void> removesEmptyCallback() => expectFix(
    _state('''
  @override
  void initState() {
    setState(() {});
  }
'''),
    (context) => AvoidUnnecessarySetstateFix(context: context),
    expected: _state('''
  @override
  void initState() {
    
  }
'''),
  );

  Future<void> keepsCallbackReferences() => expectNoFix(
    _state('''
  void _apply() {}

  @override
  void initState() {
    setState(_apply);
  }
'''),
    (context) => AvoidUnnecessarySetstateFix(context: context),
  );
}
