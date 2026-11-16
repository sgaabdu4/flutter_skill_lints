import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_single_setstate_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_single_setstate.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferSingleSetstateTest>(
    'PreferSingleSetstateTest',
    _PreferSingleSetstateTest.new,
    {
      'reportsSecondSetState': (t) => t._reportsSecondSetState(),
      'acceptsSingleSetState': (t) => t._acceptsSingleSetState(),
      'acceptsSetStatesSeparatedByAwait': (t) => t._acceptsSetStatesSeparatedByAwait(),
      'acceptsSetStatesSeparatedByReturn': (t) => t._acceptsSetStatesSeparatedByReturn(),
      'acceptsSetStatesInSeparateClosures': (t) => t._acceptsSetStatesInSeparateClosures(),
      'acceptsClassesThatAreNotState': (t) => t._acceptsClassesThatAreNotState(),
      'mergesCallbacksIntoOne': (t) => t._mergesCallbacksIntoOne(),
      'mergesBlockBodies': (t) => t._mergesBlockBodies(),
    },
  );
}

final class _PreferSingleSetstateTest extends FixRuleTest {
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

  Future<void> _reportsSecondSetState() => assertDiagnostics(_twice, [
    lint(_twice.lastIndexOf('setState('), 'setState(() => other++)'.length),
  ]);

  Future<void> _acceptsSingleSetState() => assertNoDiagnostics(
    _state('''
    setState(() => count++);
    other++;'''),
  );

  Future<void> _acceptsSetStatesSeparatedByAwait() => assertNoDiagnostics(
    _state('''
    setState(() => count++);
    await Future<void>.value();
    setState(() => other++);'''),
  );

  Future<void> _acceptsSetStatesSeparatedByReturn() => assertNoDiagnostics(
    _state('''
    if (count > 0) {
      setState(() => count++);
      return;
    }
    setState(() => other++);'''),
  );

  Future<void> _acceptsSetStatesInSeparateClosures() => assertNoDiagnostics(
    _state('''
    Future<void>.value().then((_) {
      setState(() => count++);
    });
    Future<void>.value().then((_) {
      setState(() => other++);
    });'''),
  );

  Future<void> _acceptsClassesThatAreNotState() => assertNoDiagnostics('''
class Plain {
  void setState(void Function() fn) {}

  void run() {
    setState(() {});
    setState(() {});
  }
}
''');

  Future<void> _mergesCallbacksIntoOne() => expectFix(
    _twice,
    (context) => PreferSingleSetstateFix(context: context),
    expected: _state('''
    setState(() {
      count++;
      other++;
    });'''),
  );

  Future<void> _mergesBlockBodies() => expectFix(
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
