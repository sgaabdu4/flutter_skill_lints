import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_sized_box_square_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sized_box_square.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferSizedBoxSquareTest>(
    'PreferSizedBoxSquareTest',
    _PreferSizedBoxSquareTest.new,
    {
      'reportsEqualWidthAndHeight': (t) => t._reportsEqualWidthAndHeight(),
      'acceptsDifferentDimensions': (t) => t._acceptsDifferentDimensions(),
      'acceptsOnlyOneDimension': (t) => t._acceptsOnlyOneDimension(),
      'ignoresNamedConstructors': (t) => t._ignoresNamedConstructors(),
      'rewritesToSquare': (t) => t._rewritesToSquare(),
      'keepsConstAndOtherArguments': (t) => t._keepsConstAndOtherArguments(),
    },
  );
}

final class _PreferSizedBoxSquareTest extends FixRuleTest {
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

  Future<void> _reportsEqualWidthAndHeight() =>
      assertDiagnostics(_equal, [lint(_equal.indexOf('SizedBox('), 'SizedBox'.length)]);

  Future<void> _acceptsDifferentDimensions() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(width: 8, height: 9);
''');

  Future<void> _acceptsOnlyOneDimension() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox(width: 8);
''');

  Future<void> _ignoresNamedConstructors() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox.square(dimension: 8);
''');

  Future<void> _rewritesToSquare() => expectFix(
    _equal,
    (context) => PreferSizedBoxSquareFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

Widget build() => SizedBox.square(dimension: 8);
''',
  );

  Future<void> _keepsConstAndOtherArguments() => expectFix(
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
