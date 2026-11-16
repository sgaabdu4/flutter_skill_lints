import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_correct_edge_insets_constructor_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_edge_insets_constructor.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<PreferCorrectEdgeInsetsConstructorTest>(
    'PreferCorrectEdgeInsetsConstructorTest',
    PreferCorrectEdgeInsetsConstructorTest.new,
    {
      'reportsEqualSidesInFromLtrb': (t) => t.reportsEqualSidesInFromLtrb(),
      'acceptsDistinctSidesInFromLtrb': (t) => t.acceptsDistinctSidesInFromLtrb(),
      'reportsOnlyWithEqualSides': (t) => t.reportsOnlyWithEqualSides(),
      'reportsSymmetricWithoutArguments': (t) => t.reportsSymmetricWithoutArguments(),
      'rewritesFromLtrbToAll': (t) => t.rewritesFromLtrbToAll(),
      'rewritesFromLtrbToSymmetric': (t) => t.rewritesFromLtrbToSymmetric(),
      'rewritesFromLtrbToOnly': (t) => t.rewritesFromLtrbToOnly(),
      'rewritesFromLtrbToZero': (t) => t.rewritesFromLtrbToZero(),
      'rewritesOnlyToAll': (t) => t.rewritesOnlyToAll(),
      'ignoresEdgeInsetsAllWithValue': (t) => t.ignoresEdgeInsetsAllWithValue(),
    },
  );
}

final class PreferCorrectEdgeInsetsConstructorTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferCorrectEdgeInsetsConstructor();
    super.setUp();
  }

  static String _source(String expression) =>
      '''
import 'package:flutter/widgets.dart';

EdgeInsets f() => $expression;
''';

  Future<void> _expectRewrite(String expression, String expected) => expectFix(
    _source(expression),
    (context) => PreferCorrectEdgeInsetsConstructorFix(context: context),
    expected: _source(expected),
  );

  Future<void> reportsEqualSidesInFromLtrb() async {
    final source = _source('EdgeInsets.fromLTRB(4, 4, 4, 4)');
    const expression = 'EdgeInsets.fromLTRB(4, 4, 4, 4)';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> acceptsDistinctSidesInFromLtrb() =>
      assertNoDiagnostics(_source('EdgeInsets.fromLTRB(1, 2, 3, 4)'));

  Future<void> reportsOnlyWithEqualSides() async {
    final source = _source('EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)');
    const expression = 'EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> reportsSymmetricWithoutArguments() async {
    final source = _source('EdgeInsets.symmetric()');
    const expression = 'EdgeInsets.symmetric()';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> rewritesFromLtrbToAll() =>
      _expectRewrite('EdgeInsets.fromLTRB(4, 4, 4, 4)', 'EdgeInsets.all(4)');

  Future<void> rewritesFromLtrbToSymmetric() async {
    await _expectRewrite(
      'EdgeInsets.fromLTRB(4, 8, 4, 8)',
      'EdgeInsets.symmetric(horizontal: 4, vertical: 8)',
    );
  }

  Future<void> rewritesFromLtrbToOnly() =>
      _expectRewrite('EdgeInsets.fromLTRB(1, 0, 3, 0)', 'EdgeInsets.only(left: 1, right: 3)');

  Future<void> rewritesFromLtrbToZero() =>
      _expectRewrite('EdgeInsets.fromLTRB(0, 0, 0, 0)', 'EdgeInsets.zero');

  Future<void> rewritesOnlyToAll() =>
      _expectRewrite('EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)', 'EdgeInsets.all(2)');

  Future<void> ignoresEdgeInsetsAllWithValue() => assertNoDiagnostics(_source('EdgeInsets.all(4)'));
}
