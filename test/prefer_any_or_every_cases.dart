import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_any_or_every_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_any_or_every.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferAnyOrEveryTest>('PreferAnyOrEveryTest', PreferAnyOrEveryTest.new, {
    'rewritesWhereIsNotEmptyToAny': (t) => t.rewritesWhereIsNotEmptyToAny(),
    'rewritesWhereIsEmptyToEvery': (t) => t.rewritesWhereIsEmptyToEvery(),
    'negatesSimpleIdentifierBodies': (t) => t.negatesSimpleIdentifierBodies(),
    'removesDoubleNegation': (t) => t.removesDoubleNegation(),
    'wrapsBinaryBodiesInParentheses': (t) => t.wrapsBinaryBodiesInParentheses(),
    'negatesMethodCallBodies': (t) => t.negatesMethodCallBodies(),
    'usesSingleReturnBlockBody': (t) => t.usesSingleReturnBlockBody(),
    'refusesEveryForNamedPredicates': (t) => t.refusesEveryForNamedPredicates(),
  });
}

final class PreferAnyOrEveryTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferAnyOrEvery();
    super.setUp();
  }

  Future<void> _expectRewrite(String expression, String expected) => expectFix(
    'bool f(List<int> l, bool Function(int) p) => $expression;\n',
    (context) => PreferAnyOrEveryFix(context: context),
    expected: 'bool f(List<int> l, bool Function(int) p) => $expected;\n',
  );

  Future<void> rewritesWhereIsNotEmptyToAny() =>
      _expectRewrite('l.where((e) => e > 1).isNotEmpty', 'l.any((e) => e > 1)');

  Future<void> rewritesWhereIsEmptyToEvery() =>
      _expectRewrite('l.where((e) => e > 1).isEmpty', 'l.every((e) => !(e > 1))');

  Future<void> negatesSimpleIdentifierBodies() =>
      _expectRewrite('l.where((e) => e.isEven).isEmpty', 'l.every((e) => !e.isEven)');

  Future<void> removesDoubleNegation() =>
      _expectRewrite('l.where((e) => !e.isEven).isEmpty', 'l.every((e) => e.isEven)');

  Future<void> wrapsBinaryBodiesInParentheses() =>
      _expectRewrite('l.where((e) => e > 1 && e < 5).isEmpty', 'l.every((e) => !(e > 1 && e < 5))');

  Future<void> negatesMethodCallBodies() =>
      _expectRewrite('l.where((e) => l.contains(e)).isEmpty', 'l.every((e) => !l.contains(e))');

  Future<void> usesSingleReturnBlockBody() =>
      _expectRewrite('l.where((e) { return e.isOdd; }).isEmpty', 'l.every((e) => !e.isOdd)');

  Future<void> refusesEveryForNamedPredicates() => expectNoFix(
    'bool f(List<int> l, bool Function(int) p) => l.where(p).isEmpty;\n',
    (context) => PreferAnyOrEveryFix(context: context),
  );
}
