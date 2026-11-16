import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_any_or_every_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_any_or_every.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_PreferAnyOrEveryTest>('PreferAnyOrEveryTest', _PreferAnyOrEveryTest.new, {
    'rewritesWhereIsNotEmptyToAny': (t) => t._rewritesWhereIsNotEmptyToAny(),
    'rewritesWhereIsEmptyToEvery': (t) => t._rewritesWhereIsEmptyToEvery(),
    'negatesSimpleIdentifierBodies': (t) => t._negatesSimpleIdentifierBodies(),
    'removesDoubleNegation': (t) => t._removesDoubleNegation(),
    'wrapsBinaryBodiesInParentheses': (t) => t._wrapsBinaryBodiesInParentheses(),
    'negatesMethodCallBodies': (t) => t._negatesMethodCallBodies(),
    'usesSingleReturnBlockBody': (t) => t._usesSingleReturnBlockBody(),
    'refusesEveryForNamedPredicates': (t) => t._refusesEveryForNamedPredicates(),
  });
}

final class _PreferAnyOrEveryTest extends FixRuleTest {
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

  Future<void> _rewritesWhereIsNotEmptyToAny() =>
      _expectRewrite('l.where((e) => e > 1).isNotEmpty', 'l.any((e) => e > 1)');

  Future<void> _rewritesWhereIsEmptyToEvery() =>
      _expectRewrite('l.where((e) => e > 1).isEmpty', 'l.every((e) => !(e > 1))');

  Future<void> _negatesSimpleIdentifierBodies() =>
      _expectRewrite('l.where((e) => e.isEven).isEmpty', 'l.every((e) => !e.isEven)');

  Future<void> _removesDoubleNegation() =>
      _expectRewrite('l.where((e) => !e.isEven).isEmpty', 'l.every((e) => e.isEven)');

  Future<void> _wrapsBinaryBodiesInParentheses() =>
      _expectRewrite('l.where((e) => e > 1 && e < 5).isEmpty', 'l.every((e) => !(e > 1 && e < 5))');

  Future<void> _negatesMethodCallBodies() =>
      _expectRewrite('l.where((e) => l.contains(e)).isEmpty', 'l.every((e) => !l.contains(e))');

  Future<void> _usesSingleReturnBlockBody() =>
      _expectRewrite('l.where((e) { return e.isOdd; }).isEmpty', 'l.every((e) => !e.isOdd)');

  Future<void> _refusesEveryForNamedPredicates() => expectNoFix(
    'bool f(List<int> l, bool Function(int) p) => l.where(p).isEmpty;\n',
    (context) => PreferAnyOrEveryFix(context: context),
  );
}
