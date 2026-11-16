import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mounted_in_setstate.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidMountedInSetstateTest>(
    'AvoidMountedInSetstateTest',
    AvoidMountedInSetstateTest.new,
    {
      'reportsBareMounted': (t) => t.reportsBareMounted(),
      'reportsContextMounted': (t) => t.reportsContextMounted(),
      'reportsThisMounted': (t) => t.reportsThisMounted(),
      'reportsMountedInNestedClosure': (t) => t.reportsMountedInNestedClosure(),
      'acceptsMountedBeforeSetState': (t) => t.acceptsMountedBeforeSetState(),
      'acceptsMethodReferenceCallback': (t) => t.acceptsMethodReferenceCallback(),
      'acceptsSetStateOutsideState': (t) => t.acceptsSetStateOutsideState(),
      'acceptsCallbackWithoutMounted': (t) => t.acceptsCallbackWithoutMounted(),
    },
  );
}

final class AvoidMountedInSetstateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidMountedInSetstate();
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

  void run() {
$body
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> _expectReported(String body, String reported) async {
    final source = _state(body);
    await assertDiagnostics(source, [lint(source.indexOf(reported), reported.length)]);
  }

  Future<void> reportsBareMounted() =>
      _expectReported('    setState(() { if (mounted) count++; });', 'mounted');

  Future<void> reportsContextMounted() =>
      _expectReported('    setState(() { if (context.mounted) count++; });', 'context.mounted');

  Future<void> reportsThisMounted() =>
      _expectReported('    setState(() { if (this.mounted) count++; });', 'this.mounted');

  Future<void> reportsMountedInNestedClosure() => _expectReported('''
    setState(() {
      [1].forEach((_) {
        if (mounted) count++;
      });
    });''', 'mounted');

  Future<void> acceptsMountedBeforeSetState() => assertNoDiagnostics(
    _state('''
    if (!mounted) return;
    setState(() => count++);'''),
  );

  Future<void> acceptsMethodReferenceCallback() => assertNoDiagnostics(
    _state('''
    setState(run);'''),
  );

  Future<void> acceptsCallbackWithoutMounted() => assertNoDiagnostics(
    _state('''
    setState(() => count++);'''),
  );

  Future<void> acceptsSetStateOutsideState() => assertNoDiagnostics('''
class Plain {
  bool get mounted => true;

  void setState(void Function() fn) {}

  void run() {
    setState(() {
      if (mounted) return;
    });
  }
}
''');
}
