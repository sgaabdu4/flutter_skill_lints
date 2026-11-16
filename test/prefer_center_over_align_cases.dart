import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_center_over_align_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_center_over_align.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferCenterOverAlignTest>(
    'PreferCenterOverAlignTest',
    PreferCenterOverAlignTest.new,
    {
      'reportsAlignWithoutAlignment': (t) => t.reportsAlignWithoutAlignment(),
      'reportsAlignWithCenterConstant': (t) => t.reportsAlignWithCenterConstant(),
      'reportsAlignWithZeroZero': (t) => t.reportsAlignWithZeroZero(),
      'acceptsOtherAlignment': (t) => t.acceptsOtherAlignment(),
      'replacesAlignWithCenter': (t) => t.replacesAlignWithCenter(),
      'dropsCenterAlignmentArgument': (t) => t.dropsCenterAlignmentArgument(),
    },
  );
}

final class PreferCenterOverAlignTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferCenterOverAlign();
    super.setUp();
  }

  Future<void> reportsAlignWithoutAlignment() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> reportsAlignWithCenterConstant() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment.center, child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> reportsAlignWithZeroZero() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment(0, 0), child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> acceptsOtherAlignment() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment(1, 0), child: Text('a'));
''');

  Future<void> replacesAlignWithCenter() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => Align(child: Text('a'));
''',
    (context) => PreferCenterOverAlignFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Center(child: Text('a'));
''',
  );

  Future<void> dropsCenterAlignmentArgument() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment.center, child: Text('a'));
''',
    (context) => PreferCenterOverAlignFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Center(child: Text('a'));
''',
  );
}
