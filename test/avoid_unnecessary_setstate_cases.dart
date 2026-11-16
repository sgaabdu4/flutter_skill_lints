import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_setstate.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessarySetstateTest>(
    'AvoidUnnecessarySetstateTest',
    _AvoidUnnecessarySetstateTest.new,
    {
      'reportsSetStateInInitState': (t) => t._reportsSetStateInInitState(),
      'reportsSetStateInDidUpdateWidget': (t) => t._reportsSetStateInDidUpdateWidget(),
      'reportsSetStateDirectlyInBuild': (t) => t._reportsSetStateDirectlyInBuild(),
      'acceptsSetStateInEventHandler': (t) => t._acceptsSetStateInEventHandler(),
      'acceptsSetStateInOtherMethods': (t) => t._acceptsSetStateInOtherMethods(),
      'acceptsSetStateInsideClosureInInitState': (t) =>
          t._acceptsSetStateInsideClosureInInitState(),
      'acceptsSetStateOutsideState': (t) => t._acceptsSetStateOutsideState(),
      'inlinesExpressionBody': (t) => t._inlinesExpressionBody(),
      'inlinesBlockBody': (t) => t._inlinesBlockBody(),
      'removesEmptyCallback': (t) => t._removesEmptyCallback(),
      'keepsCallbackReferences': (t) => t._keepsCallbackReferences(),
    },
  );
}

final class _AvoidUnnecessarySetstateTest extends FixRuleTest {
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

  Future<void> _reportsSetStateInInitState() => assertDiagnostics(_initWithExpression, [
    lint(_initWithExpression.indexOf('setState('), 'setState(() => count = 1)'.length),
  ]);

  Future<void> _reportsSetStateInDidUpdateWidget() async {
    final source = _state('''
  @override
  void didUpdateWidget(W oldWidget) {
    setState(() {});
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('setState('), 'setState(() {})'.length)]);
  }

  Future<void> _reportsSetStateDirectlyInBuild() async {
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

  Future<void> _acceptsSetStateInEventHandler() => assertNoDiagnostics('''
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

  Future<void> _acceptsSetStateInOtherMethods() => assertNoDiagnostics(
    _state('''
  void bump() {
    setState(() => count++);
  }
'''),
  );

  Future<void> _acceptsSetStateInsideClosureInInitState() => assertNoDiagnostics(
    _state('''
  @override
  void initState() {
    Future<void>.value().then((_) {
      setState(() {});
    });
  }
'''),
  );

  Future<void> _acceptsSetStateOutsideState() => assertNoDiagnostics('''
class Plain {
  void setState(void Function() fn) {}

  void initState() {
    setState(() {});
  }
}
''');

  Future<void> _inlinesExpressionBody() => expectFix(
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

  Future<void> _inlinesBlockBody() => expectFix(
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

  Future<void> _removesEmptyCallback() => expectFix(
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

  Future<void> _keepsCallbackReferences() => expectNoFix(
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
