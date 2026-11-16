import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_center_over_align_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_center_over_align.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferCenterOverAlignTest>(
    'PreferCenterOverAlignTest',
    _PreferCenterOverAlignTest.new,
    {
      'reportsAlignWithoutAlignment': (t) => t._reportsAlignWithoutAlignment(),
      'reportsAlignWithCenterConstant': (t) => t._reportsAlignWithCenterConstant(),
      'reportsAlignWithZeroZero': (t) => t._reportsAlignWithZeroZero(),
      'acceptsOtherAlignment': (t) => t._acceptsOtherAlignment(),
      'replacesAlignWithCenter': (t) => t._replacesAlignWithCenter(),
      'dropsCenterAlignmentArgument': (t) => t._dropsCenterAlignmentArgument(),
    },
  );
}

final class _PreferCenterOverAlignTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferCenterOverAlign();
    super.setUp();
  }

  Future<void> _reportsAlignWithoutAlignment() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> _reportsAlignWithCenterConstant() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment.center, child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> _reportsAlignWithZeroZero() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment(0, 0), child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Align('), 'Align'.length)]);
  }

  Future<void> _acceptsOtherAlignment() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Align(alignment: Alignment(1, 0), child: Text('a'));
''');

  Future<void> _replacesAlignWithCenter() => expectFix(
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

  Future<void> _dropsCenterAlignmentArgument() => expectFix(
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
