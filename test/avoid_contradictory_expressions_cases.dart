import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_contradictory_expressions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidContradictoryExpressionsTest>(
    'AvoidContradictoryExpressionsTest',
    _AvoidContradictoryExpressionsTest.new,
    {
      'reportsEqualAndNotEqual': (t) => t._reportsEqualAndNotEqual(),
      'reportsLessAndGreater': (t) => t._reportsLessAndGreater(),
      'reportsEqualAndLess': (t) => t._reportsEqualAndLess(),
      'reportsSwappedOperands': (t) => t._reportsSwappedOperands(),
      'reportsDifferentIntegerLiterals': (t) => t._reportsDifferentIntegerLiterals(),
      'reportsDifferentStringLiterals': (t) => t._reportsDifferentStringLiterals(),
      'reportsDifferentBooleanLiterals': (t) => t._reportsDifferentBooleanLiterals(),
      'reportsDifferentDoubleLiterals': (t) => t._reportsDifferentDoubleLiterals(),
      'reportsContradictionInLongerChain': (t) => t._reportsContradictionInLongerChain(),
      'reportsPropertyAccessPairs': (t) => t._reportsPropertyAccessPairs(),
      'reportsPrefixedIdentifierPairs': (t) => t._reportsPrefixedIdentifierPairs(),
      'reportsOncePerChain': (t) => t._reportsOncePerChain(),
      'acceptsCompatibleComparisons': (t) => t._acceptsCompatibleComparisons(),
      'acceptsDifferentVariables': (t) => t._acceptsDifferentVariables(),
      'acceptsSameLiteralTwice': (t) => t._acceptsSameLiteralTwice(),
      'acceptsDisjunctions': (t) => t._acceptsDisjunctions(),
      'acceptsSingleComparison': (t) => t._acceptsSingleComparison(),
    },
  );
}

final class _AvoidContradictoryExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  Future<void> _expectReported(String expression, {String params = 'int x'}) async {
    final source = 'bool f($params) => $expression;\n';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _reportsEqualAndNotEqual() => _expectReported('x == 1 && x != 1');

  Future<void> _reportsLessAndGreater() => _expectReported('x < 5 && x > 5');

  Future<void> _reportsEqualAndLess() => _expectReported('x == 5 && x < 5');

  Future<void> _reportsSwappedOperands() => _expectReported('x < 5 && 5 < x');

  Future<void> _reportsDifferentIntegerLiterals() => _expectReported('x == 1 && x == 2');

  Future<void> _reportsDifferentStringLiterals() =>
      _expectReported("s == 'a' && s == 'b'", params: 'String s');

  Future<void> _reportsDifferentBooleanLiterals() =>
      _expectReported('b == true && b == false', params: 'bool b');

  Future<void> _reportsDifferentDoubleLiterals() =>
      _expectReported('d == 1.5 && d == 2.5', params: 'double d');

  Future<void> _reportsContradictionInLongerChain() =>
      _expectReported('y > 0 && x == 1 && y < 10 && x != 1', params: 'int x, int y');

  Future<void> _reportsPropertyAccessPairs() async {
    const source = '''
class P {
  int v = 0;
}

bool f(P p) => p.v == 1 && p.v != 1;
''';
    const expression = 'p.v == 1 && p.v != 1';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _reportsPrefixedIdentifierPairs() async {
    const source = '''
class P {
  int v = 0;
}

P get p => P();

bool f() => (p).v == 1 && (p).v == 2;
''';
    const expression = '(p).v == 1 && (p).v == 2';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> _reportsOncePerChain() => _expectReported('x == 1 && x != 1 && x == 3');

  Future<void> _acceptsCompatibleComparisons() => assertNoDiagnostics('''
bool f(int x) => x > 1 && x < 5 && x != 3;
''');

  Future<void> _acceptsDifferentVariables() => assertNoDiagnostics('''
bool f(int x, int y) => x == 1 && y != 1;
''');

  Future<void> _acceptsSameLiteralTwice() => assertNoDiagnostics('''
bool f(int x) => x == 1 && x == 1;
''');

  Future<void> _acceptsDisjunctions() => assertNoDiagnostics('''
bool f(int x) => x == 1 || x != 1;
''');

  Future<void> _acceptsSingleComparison() => assertNoDiagnostics('''
bool f(int x, bool b) => x == 1 && b;
''');
}
