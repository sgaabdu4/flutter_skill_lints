import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_correct_edge_insets_constructor_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_correct_edge_insets_constructor.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferCorrectEdgeInsetsConstructorTest>(
    'PreferCorrectEdgeInsetsConstructorTest',
    _PreferCorrectEdgeInsetsConstructorTest.new,
    {
      'reportsEqualSidesInFromLtrb': (t) => t._reportsEqualSidesInFromLtrb(),
      'acceptsDistinctSidesInFromLtrb': (t) => t._acceptsDistinctSidesInFromLtrb(),
      'reportsOnlyWithEqualSides': (t) => t._reportsOnlyWithEqualSides(),
      'reportsSymmetricWithoutArguments': (t) => t._reportsSymmetricWithoutArguments(),
      'rewritesFromLtrbToAll': (t) => t._rewritesFromLtrbToAll(),
      'rewritesFromLtrbToSymmetric': (t) => t._rewritesFromLtrbToSymmetric(),
      'rewritesFromLtrbToOnly': (t) => t._rewritesFromLtrbToOnly(),
      'rewritesFromLtrbToZero': (t) => t._rewritesFromLtrbToZero(),
      'rewritesOnlyToAll': (t) => t._rewritesOnlyToAll(),
      'ignoresEdgeInsetsAllWithValue': (t) => t._ignoresEdgeInsetsAllWithValue(),
    },
  );
}

final class _PreferCorrectEdgeInsetsConstructorTest extends FixRuleTest {
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

  Future<void> _reportsEqualSidesInFromLtrb() async {
    final source = _source('EdgeInsets.fromLTRB(4, 4, 4, 4)');
    const expression = 'EdgeInsets.fromLTRB(4, 4, 4, 4)';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _acceptsDistinctSidesInFromLtrb() =>
      assertNoDiagnostics(_source('EdgeInsets.fromLTRB(1, 2, 3, 4)'));

  Future<void> _reportsOnlyWithEqualSides() async {
    final source = _source('EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)');
    const expression = 'EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _reportsSymmetricWithoutArguments() async {
    final source = _source('EdgeInsets.symmetric()');
    const expression = 'EdgeInsets.symmetric()';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _rewritesFromLtrbToAll() =>
      _expectRewrite('EdgeInsets.fromLTRB(4, 4, 4, 4)', 'EdgeInsets.all(4)');

  Future<void> _rewritesFromLtrbToSymmetric() async {
    await _expectRewrite(
      'EdgeInsets.fromLTRB(4, 8, 4, 8)',
      'EdgeInsets.symmetric(horizontal: 4, vertical: 8)',
    );
  }

  Future<void> _rewritesFromLtrbToOnly() =>
      _expectRewrite('EdgeInsets.fromLTRB(1, 0, 3, 0)', 'EdgeInsets.only(left: 1, right: 3)');

  Future<void> _rewritesFromLtrbToZero() =>
      _expectRewrite('EdgeInsets.fromLTRB(0, 0, 0, 0)', 'EdgeInsets.zero');

  Future<void> _rewritesOnlyToAll() =>
      _expectRewrite('EdgeInsets.only(left: 2, top: 2, right: 2, bottom: 2)', 'EdgeInsets.all(2)');

  Future<void> _ignoresEdgeInsetsAllWithValue() =>
      assertNoDiagnostics(_source('EdgeInsets.all(4)'));
}
