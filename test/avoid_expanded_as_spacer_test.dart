import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_expanded_as_spacer.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidExpandedAsSpacerTest>(
    'AvoidExpandedAsSpacerTest',
    AvoidExpandedAsSpacerTest.new,
    {
      'reportsExpandedAroundEmptySizedBox': (t) => t.reportsExpandedAroundEmptySizedBox(),
      'reportsExpandedAroundEmptyContainer': (t) => t.reportsExpandedAroundEmptyContainer(),
      'ignoresChildWithArguments': (t) => t.ignoresChildWithArguments(),
      'ignoresOtherChildren': (t) => t.ignoresOtherChildren(),
      'ignoresExpandedWithoutChild': (t) => t.ignoresExpandedWithoutChild(),
      'ignoresSizedBoxWithDimension': (t) => t.ignoresSizedBoxWithDimension(),
      'replacesWithSpacer': (t) => t.replacesWithSpacer(),
      'keepsFlexAndKeyAndConst': (t) => t.keepsFlexAndKeyAndConst(),
    },
  );
}

final class AvoidExpandedAsSpacerTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidExpandedAsSpacer();
    super.setUp();
  }

  static const _expanded = '''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: SizedBox());
''';

  Future<void> reportsExpandedAroundEmptySizedBox() =>
      assertDiagnostics(_expanded, [lint(_expanded.indexOf('Expanded('), 'Expanded'.length)]);

  Future<void> reportsExpandedAroundEmptyContainer() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: Container(key: Key('a')));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> ignoresChildWithArguments() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: SizedBox(height: 4));
''');

  Future<void> ignoresOtherChildren() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: Text('a'));
''');

  Future<void> ignoresExpandedWithoutChild() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded();
''');

  Future<void> ignoresSizedBoxWithDimension() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: SizedBox.square(dimension: 2));
''');

  Future<void> replacesWithSpacer() => expectFix(
    _expanded,
    (context) => AvoidExpandedAsSpacerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Spacer();
''',
  );

  Future<void> keepsFlexAndKeyAndConst() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => const Expanded(key: Key('k'), flex: 2, child: SizedBox());
''',
    (context) => AvoidExpandedAsSpacerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => const Spacer(key: Key('k'), flex: 2);
''',
  );
}
