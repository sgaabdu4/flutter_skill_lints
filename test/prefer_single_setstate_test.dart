import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_single_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_setstate.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferSingleSetstateTest>(
    'PreferSingleSetstateTest',
    PreferSingleSetstateTest.new,
    {
      'reportsSecondSetState': (t) => t.reportsSecondSetState(),
      'acceptsSingleSetState': (t) => t.acceptsSingleSetState(),
      'acceptsSetStatesSeparatedByAwait': (t) => t.acceptsSetStatesSeparatedByAwait(),
      'acceptsSetStatesSeparatedByReturn': (t) => t.acceptsSetStatesSeparatedByReturn(),
      'acceptsSetStatesInSeparateClosures': (t) => t.acceptsSetStatesInSeparateClosures(),
      'acceptsClassesThatAreNotState': (t) => t.acceptsClassesThatAreNotState(),
      'mergesCallbacksIntoOne': (t) => t.mergesCallbacksIntoOne(),
      'mergesBlockBodies': (t) => t.mergesBlockBodies(),
    },
  );
}

final class PreferSingleSetstateTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferSingleSetstate();
    super.setUp();
  }

  static String _state(String body) =>
      '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  int count = 0;
  int other = 0;

  Future<void> run() async {
$body
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  static final _twice = _state('''
    setState(() => count++);
    setState(() => other++);''');

  Future<void> reportsSecondSetState() => assertDiagnostics(_twice, [
    lint(_twice.lastIndexOf('setState('), 'setState(() => other++)'.length),
  ]);

  Future<void> acceptsSingleSetState() => assertNoDiagnostics(
    _state('''
    setState(() => count++);
    other++;'''),
  );

  Future<void> acceptsSetStatesSeparatedByAwait() => assertNoDiagnostics(
    _state('''
    setState(() => count++);
    await Future<void>.value();
    setState(() => other++);'''),
  );

  Future<void> acceptsSetStatesSeparatedByReturn() => assertNoDiagnostics(
    _state('''
    if (count > 0) {
      setState(() => count++);
      return;
    }
    setState(() => other++);'''),
  );

  Future<void> acceptsSetStatesInSeparateClosures() => assertNoDiagnostics(
    _state('''
    Future<void>.value().then((_) {
      setState(() => count++);
    });
    Future<void>.value().then((_) {
      setState(() => other++);
    });'''),
  );

  Future<void> acceptsClassesThatAreNotState() => assertNoDiagnostics('''
class Plain {
  void setState(void Function() fn) {}

  void run() {
    setState(() {});
    setState(() {});
  }
}
''');

  Future<void> mergesCallbacksIntoOne() => expectFix(
    _twice,
    (context) => PreferSingleSetstateFix(context: context),
    expected: _state('''
    setState(() {
      count++;
      other++;
    });'''),
  );

  Future<void> mergesBlockBodies() => expectFix(
    _state('''
    setState(() {
      count++;
      count++;
    });
    setState(() {
      other++;
    });'''),
    (context) => PreferSingleSetstateFix(context: context),
    expected: _state('''
    setState(() {
      count++;
      count++;
      other++;
    });'''),
  );
}
