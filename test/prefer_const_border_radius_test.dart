import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_const_border_radius_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_const_border_radius.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferConstBorderRadiusTest>(
    'PreferConstBorderRadiusTest',
    PreferConstBorderRadiusTest.new,
    {
      'reportsCircularConstructor': (t) => t.reportsCircularConstructor(),
      'acceptsAllConstructor': (t) => t.acceptsAllConstructor(),
      'ignoresRadiusCircular': (t) => t.ignoresRadiusCircular(),
      'ignoresOtherClassesWithCircular': (t) => t.ignoresOtherClassesWithCircular(),
      'rewritesToBorderRadiusAll': (t) => t.rewritesToBorderRadiusAll(),
    },
  );
}

final class PreferConstBorderRadiusTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferConstBorderRadius();
    super.setUp();
  }

  static const _circular = '''
import 'package:flutter/widgets.dart';

BorderRadius f() => BorderRadius.circular(8);
''';

  Future<void> reportsCircularConstructor() => assertDiagnostics(_circular, [
    lint(_circular.indexOf('BorderRadius.circular'), 'BorderRadius.circular(8)'.length),
  ]);

  Future<void> acceptsAllConstructor() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

BorderRadius f() => BorderRadius.all(Radius.circular(8));
''');

  Future<void> ignoresRadiusCircular() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Radius f() => Radius.circular(8);
''');

  Future<void> ignoresOtherClassesWithCircular() => assertNoDiagnostics('''
class BorderRadius {
  const BorderRadius.circular(double radius);
}

BorderRadius f() => BorderRadius.circular(8);
''');

  Future<void> rewritesToBorderRadiusAll() => expectFix(
    _circular,
    (context) => PreferConstBorderRadiusFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

BorderRadius f() => BorderRadius.all(Radius.circular(8));
''',
  );
}
