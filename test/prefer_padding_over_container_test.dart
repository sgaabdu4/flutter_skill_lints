import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_padding_over_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_padding_over_container.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferPaddingOverContainerTest>(
    'PreferPaddingOverContainerTest',
    PreferPaddingOverContainerTest.new,
    {
      'reportsContainerWithOnlyPadding': (t) => t.reportsContainerWithOnlyPadding(),
      'reportsContainerWithOnlyMargin': (t) => t.reportsContainerWithOnlyMargin(),
      'acceptsContainerWithOtherArguments': (t) => t.acceptsContainerWithOtherArguments(),
      'acceptsContainerWithBothPaddingAndMargin': (t) =>
          t.acceptsContainerWithBothPaddingAndMargin(),
      'keepsPaddingArgument': (t) => t.keepsPaddingArgument(),
      'renamesMarginToPadding': (t) => t.renamesMarginToPadding(),
    },
  );
}

final class PreferPaddingOverContainerTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferPaddingOverContainer();
    super.setUp();
  }

  static const _padded = '''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(4), child: Text('a'));
''';

  Future<void> reportsContainerWithOnlyPadding() =>
      assertDiagnostics(_padded, [lint(_padded.indexOf('Container('), 'Container'.length)]);

  Future<void> reportsContainerWithOnlyMargin() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Container(margin: EdgeInsets.all(4), child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Container('), 'Container'.length)]);
  }

  Future<void> acceptsContainerWithOtherArguments() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(4), color: Color(1));
''');

  Future<void> acceptsContainerWithBothPaddingAndMargin() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(4), margin: EdgeInsets.all(2));
''');

  Future<void> keepsPaddingArgument() => expectFix(
    _padded,
    (context) => PreferPaddingOverContainerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(padding: EdgeInsets.all(4), child: Text('a'));
''',
  );

  Future<void> renamesMarginToPadding() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => Container(margin: EdgeInsets.all(4), child: Text('a'));
''',
    (context) => PreferPaddingOverContainerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(padding: EdgeInsets.all(4), child: Text('a'));
''',
  );
}
