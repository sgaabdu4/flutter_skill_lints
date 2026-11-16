import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_sized_box_square_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sized_box_square.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferSizedBoxSquareTest>(
    'PreferSizedBoxSquareTest',
    PreferSizedBoxSquareTest.new,
    {
      'reportsEqualWidthAndHeight': (t) => t.reportsEqualWidthAndHeight(),
      'acceptsDifferentDimensions': (t) => t.acceptsDifferentDimensions(),
      'acceptsOnlyOneDimension': (t) => t.acceptsOnlyOneDimension(),
      'ignoresNamedConstructors': (t) => t.ignoresNamedConstructors(),
      'rewritesToSquare': (t) => t.rewritesToSquare(),
      'keepsConstAndOtherArguments': (t) => t.keepsConstAndOtherArguments(),
    },
  );
}

final class PreferSizedBoxSquareTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferSizedBoxSquare();
    super.setUp();
  }

  static const _equal = '''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(width: 8, height: 8);
''';

  Future<void> reportsEqualWidthAndHeight() =>
      assertDiagnostics(_equal, [lint(_equal.indexOf('SizedBox('), 'SizedBox'.length)]);

  Future<void> acceptsDifferentDimensions() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(width: 8, height: 9);
''');

  Future<void> acceptsOnlyOneDimension() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(width: 8);
''');

  Future<void> ignoresNamedConstructors() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox.square(dimension: 8);
''');

  Future<void> rewritesToSquare() => expectFix(
    _equal,
    (context) => PreferSizedBoxSquareFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox.square(dimension: 8);
''',
  );

  Future<void> keepsConstAndOtherArguments() => expectFix(
    '''
import 'package:flutter/widgets.dart';

Widget build() => const SizedBox(key: Key('k'), width: 8, height: 8, child: Text('a'));
''',
    (context) => PreferSizedBoxSquareFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => const SizedBox.square(key: Key('k'), child: Text('a'), dimension: 8);
''',
  );
}
