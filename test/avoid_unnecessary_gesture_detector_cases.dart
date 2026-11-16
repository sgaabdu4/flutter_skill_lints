import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_unnecessary_gesture_detector_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_gesture_detector.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryGestureDetectorTest>(
    'AvoidUnnecessaryGestureDetectorTest',
    _AvoidUnnecessaryGestureDetectorTest.new,
    {
      'reportsDetectorWithoutHandlers': (t) => t._reportsDetectorWithoutHandlers(),
      'acceptsDetectorWithHandler': (t) => t._acceptsDetectorWithHandler(),
      'replacesDetectorWithItsChild': (t) => t._replacesDetectorWithItsChild(),
      'ignoresDetectorWithoutChild': (t) => t._ignoresDetectorWithoutChild(),
    },
  );
}

final class _AvoidUnnecessaryGestureDetectorTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidUnnecessaryGestureDetector();
    super.setUp();
  }

  static const _useless = '''
import 'package:flutter/widgets.dart';

Widget build() => GestureDetector(child: Text('a'));
''';

  Future<void> _reportsDetectorWithoutHandlers() => assertDiagnostics(_useless, [
    lint(_useless.indexOf('GestureDetector('), 'GestureDetector'.length),
  ]);

  Future<void> _acceptsDetectorWithHandler() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => GestureDetector(onTap: () {}, child: Text('a'));
''');

  Future<void> _replacesDetectorWithItsChild() => expectFix(
    _useless,
    (context) => AvoidUnnecessaryGestureDetectorFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Text('a');
''',
  );

  Future<void> _ignoresDetectorWithoutChild() => expectNoFix('''
import 'package:flutter/widgets.dart';

Widget build() => GestureDetector();
''', (context) => AvoidUnnecessaryGestureDetectorFix(context: context));
}
