import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_contradictory_expressions.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidContradictoryExpressionsTest>(
    'AvoidContradictoryExpressionsTest',
    AvoidContradictoryExpressionsTest.new,
    {
      'reportsEqualAndNotEqual': (t) => t.reportsEqualAndNotEqual(),
      'reportsLessAndGreater': (t) => t.reportsLessAndGreater(),
      'reportsEqualAndLess': (t) => t.reportsEqualAndLess(),
      'reportsSwappedOperands': (t) => t.reportsSwappedOperands(),
      'reportsDifferentIntegerLiterals': (t) => t.reportsDifferentIntegerLiterals(),
      'reportsDifferentStringLiterals': (t) => t.reportsDifferentStringLiterals(),
      'reportsDifferentBooleanLiterals': (t) => t.reportsDifferentBooleanLiterals(),
      'reportsDifferentDoubleLiterals': (t) => t.reportsDifferentDoubleLiterals(),
      'reportsContradictionInLongerChain': (t) => t.reportsContradictionInLongerChain(),
      'reportsPropertyAccessPairs': (t) => t.reportsPropertyAccessPairs(),
      'reportsPrefixedIdentifierPairs': (t) => t.reportsPrefixedIdentifierPairs(),
      'reportsOncePerChain': (t) => t.reportsOncePerChain(),
      'acceptsCompatibleComparisons': (t) => t.acceptsCompatibleComparisons(),
      'acceptsDifferentVariables': (t) => t.acceptsDifferentVariables(),
      'acceptsSameLiteralTwice': (t) => t.acceptsSameLiteralTwice(),
      'acceptsDisjunctions': (t) => t.acceptsDisjunctions(),
      'acceptsSingleComparison': (t) => t.acceptsSingleComparison(),
    },
  );
}

final class AvoidContradictoryExpressionsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidContradictoryExpressions();
    super.setUp();
  }

  Future<void> _expectReported(String expression, {String params = 'int x'}) async {
    final source = 'bool f($params) => $expression;\n';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> reportsEqualAndNotEqual() => _expectReported('x == 1 && x != 1');

  Future<void> reportsLessAndGreater() => _expectReported('x < 5 && x > 5');

  Future<void> reportsEqualAndLess() => _expectReported('x == 5 && x < 5');

  Future<void> reportsSwappedOperands() => _expectReported('x < 5 && 5 < x');

  Future<void> reportsDifferentIntegerLiterals() => _expectReported('x == 1 && x == 2');

  Future<void> reportsDifferentStringLiterals() =>
      _expectReported("s == 'a' && s == 'b'", params: 'String s');

  Future<void> reportsDifferentBooleanLiterals() =>
      _expectReported('b == true && b == false', params: 'bool b');

  Future<void> reportsDifferentDoubleLiterals() =>
      _expectReported('d == 1.5 && d == 2.5', params: 'double d');

  Future<void> reportsContradictionInLongerChain() =>
      _expectReported('y > 0 && x == 1 && y < 10 && x != 1', params: 'int x, int y');

  Future<void> reportsPropertyAccessPairs() async {
    const source = '''
class P {
  int v = 0;
}

bool f(P p) => p.v == 1 && p.v != 1;
''';
    const expression = 'p.v == 1 && p.v != 1';
    await assertDiagnostics(source, [lint(source.indexOf(expression), expression.length)]);
  }

  Future<void> reportsPrefixedIdentifierPairs() async {
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

  Future<void> reportsOncePerChain() => _expectReported('x == 1 && x != 1 && x == 3');

  Future<void> acceptsCompatibleComparisons() => assertNoDiagnostics('''
bool f(int x) => x > 1 && x < 5 && x != 3;
''');

  Future<void> acceptsDifferentVariables() => assertNoDiagnostics('''
bool f(int x, int y) => x == 1 && y != 1;
''');

  Future<void> acceptsSameLiteralTwice() => assertNoDiagnostics('''
bool f(int x) => x == 1 && x == 1;
''');

  Future<void> acceptsDisjunctions() => assertNoDiagnostics('''
bool f(int x) => x == 1 || x != 1;
''');

  Future<void> acceptsSingleComparison() => assertNoDiagnostics('''
bool f(int x, bool b) => x == 1 && b;
''');
}
