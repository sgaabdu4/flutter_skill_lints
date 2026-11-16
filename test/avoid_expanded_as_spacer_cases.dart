import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_expanded_as_spacer_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_expanded_as_spacer.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidExpandedAsSpacerTest>(
    'AvoidExpandedAsSpacerTest',
    _AvoidExpandedAsSpacerTest.new,
    {
      'reportsExpandedAroundEmptySizedBox': (t) => t._reportsExpandedAroundEmptySizedBox(),
      'reportsExpandedAroundEmptyContainer': (t) => t._reportsExpandedAroundEmptyContainer(),
      'ignoresChildWithArguments': (t) => t._ignoresChildWithArguments(),
      'ignoresOtherChildren': (t) => t._ignoresOtherChildren(),
      'ignoresExpandedWithoutChild': (t) => t._ignoresExpandedWithoutChild(),
      'ignoresSizedBoxWithDimension': (t) => t._ignoresSizedBoxWithDimension(),
      'replacesWithSpacer': (t) => t._replacesWithSpacer(),
      'keepsFlexAndKeyAndConst': (t) => t._keepsFlexAndKeyAndConst(),
    },
  );
}

final class _AvoidExpandedAsSpacerTest extends FixRuleTest {
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

  Future<void> _reportsExpandedAroundEmptySizedBox() =>
      assertDiagnostics(_expanded, [lint(_expanded.indexOf('Expanded('), 'Expanded'.length)]);

  Future<void> _reportsExpandedAroundEmptyContainer() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: Container(key: Key('a')));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Expanded('), 'Expanded'.length)]);
  }

  Future<void> _ignoresChildWithArguments() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: SizedBox(height: 4));
''');

  Future<void> _ignoresOtherChildren() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: Text('a'));
''');

  Future<void> _ignoresExpandedWithoutChild() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded();
''');

  Future<void> _ignoresSizedBoxWithDimension() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Expanded(child: SizedBox.square(dimension: 2));
''');

  Future<void> _replacesWithSpacer() => expectFix(
    _expanded,
    (context) => AvoidExpandedAsSpacerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Spacer();
''',
  );

  Future<void> _keepsFlexAndKeyAndConst() => expectFix(
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
