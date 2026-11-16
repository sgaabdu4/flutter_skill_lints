import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_padding_over_container_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_padding_over_container.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferPaddingOverContainerTest>(
    'PreferPaddingOverContainerTest',
    _PreferPaddingOverContainerTest.new,
    {
      'reportsContainerWithOnlyPadding': (t) => t._reportsContainerWithOnlyPadding(),
      'reportsContainerWithOnlyMargin': (t) => t._reportsContainerWithOnlyMargin(),
      'acceptsContainerWithOtherArguments': (t) => t._acceptsContainerWithOtherArguments(),
      'acceptsContainerWithBothPaddingAndMargin': (t) =>
          t._acceptsContainerWithBothPaddingAndMargin(),
      'acceptsNullPaddingLiteral': (t) => t._acceptsNullPaddingLiteral(),
      'acceptsNullablePadding': (t) => t._acceptsNullablePadding(),
      'keepsPaddingArgument': (t) => t._keepsPaddingArgument(),
      'renamesMarginToPadding': (t) => t._renamesMarginToPadding(),
    },
  );
}

final class _PreferPaddingOverContainerTest extends FixRuleTest {
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

  Future<void> _reportsContainerWithOnlyPadding() =>
      assertDiagnostics(_padded, [lint(_padded.indexOf('Container('), 'Container'.length)]);

  Future<void> _reportsContainerWithOnlyMargin() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => Container(margin: EdgeInsets.all(4), child: Text('a'));
''';
    await assertDiagnostics(source, [lint(source.indexOf('Container('), 'Container'.length)]);
  }

  Future<void> _acceptsContainerWithOtherArguments() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(4), color: Color(1));
''');

  Future<void> _acceptsContainerWithBothPaddingAndMargin() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: EdgeInsets.all(4), margin: EdgeInsets.all(2));
''');

  Future<void> _acceptsNullPaddingLiteral() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Container(padding: null, child: Text('a'));
''');

  Future<void> _acceptsNullablePadding() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build(EdgeInsets? inset) => Container(padding: inset, child: Text('a'));
''');

  Future<void> _keepsPaddingArgument() => expectFix(
    _padded,
    (context) => PreferPaddingOverContainerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => Padding(padding: EdgeInsets.all(4), child: Text('a'));
''',
  );

  Future<void> _renamesMarginToPadding() => expectFix(
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
