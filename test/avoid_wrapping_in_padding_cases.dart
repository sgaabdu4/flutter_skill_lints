import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_wrapping_in_padding_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_wrapping_in_padding.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidWrappingInPaddingTest>(
    'AvoidWrappingInPaddingTest',
    _AvoidWrappingInPaddingTest.new,
    {
      'reportsPaddingAroundWidgetWithPaddingParameter': (t) =>
          t._reportsPaddingAroundWidgetWithPaddingParameter(),
      'ignoresChildWithoutPaddingParameter': (t) => t._ignoresChildWithoutPaddingParameter(),
      'ignoresChildThatAlreadyHasPadding': (t) => t._ignoresChildThatAlreadyHasPadding(),
      'ignoresChildThatIsNotAWidgetCall': (t) => t._ignoresChildThatIsNotAWidgetCall(),
      'movesPaddingIntoChild': (t) => t._movesPaddingIntoChild(),
      'carriesPaddingKeyToChild': (t) => t._carriesPaddingKeyToChild(),
    },
  );
}

final class _AvoidWrappingInPaddingTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidWrappingInPadding();
    super.setUp();
  }

  static const _wrapped = '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  padding: EdgeInsets.all(8),
  child: Container(color: Color(1)),
);
''';

  Future<void> _reportsPaddingAroundWidgetWithPaddingParameter() =>
      assertDiagnostics(_wrapped, [lint(_wrapped.indexOf('Padding('), 'Padding'.length)]);

  Future<void> _ignoresChildWithoutPaddingParameter() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Padding(padding: EdgeInsets.all(8), child: Text('a'));
''');

  Future<void> _ignoresChildThatAlreadyHasPadding() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  padding: EdgeInsets.all(8),
  child: Container(padding: EdgeInsets.all(2)),
);
''');

  Future<void> _ignoresChildThatIsNotAWidgetCall() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build(Container other) => Padding(padding: EdgeInsets.all(8), child: other);
''');

  Future<void> _movesPaddingIntoChild() => expectFix(
    _wrapped,
    (context) => AvoidWrappingInPaddingFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Container(color: Color(1), padding: EdgeInsets.all(8));
''',
  );

  Future<void> _carriesPaddingKeyToChild() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(
  key: Key('k'),
  padding: EdgeInsets.all(8),
  child: Container(color: Color(1)),
);
''',
    (context) => AvoidWrappingInPaddingFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Container(key: Key('k'), color: Color(1), padding: EdgeInsets.all(8));
''',
  );
}
