import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_text_rich_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_text_rich.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferTextRichTest>('PreferTextRichTest', PreferTextRichTest.new, {
    'reportsRichText': (t) => t.reportsRichText(),
    'ignoresPlainText': (t) => t.ignoresPlainText(),
    'rewritesToTextRich': (t) => t.rewritesToTextRich(),
    'keepsOtherArguments': (t) => t.keepsOtherArguments(),
  });
}

final class PreferTextRichTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferTextRich();
    super.setUp();
  }

  static const _rich = '''
import 'package:flutter/widgets.dart';

Widget build() => RichText(text: TextSpan(text: 'a'));
''';

  Future<void> reportsRichText() =>
      assertDiagnostics(_rich, [lint(_rich.indexOf('RichText('), 'RichText'.length)]);

  Future<void> ignoresPlainText() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Text('a');
''');

  Future<void> rewritesToTextRich() => expectFix(
    _rich,
    (context) => PreferTextRichFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Text.rich(TextSpan(text: 'a'));
''',
  );

  Future<void> keepsOtherArguments() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => RichText(maxLines: 2, text: TextSpan(text: 'a'));
''',
    (context) => PreferTextRichFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Text.rich(TextSpan(text: 'a'), maxLines: 2);
''',
  );
}
