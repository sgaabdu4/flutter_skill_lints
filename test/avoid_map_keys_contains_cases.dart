import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_map_keys_contains_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_map_keys_contains.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidMapKeysContainsTest>(
    'AvoidMapKeysContainsTest',
    _AvoidMapKeysContainsTest.new,
    {
      'rewritesPrefixedKeysContains': (t) => t._rewritesPrefixedKeysContains(),
      'rewritesPropertyAccessKeysContains': (t) => t._rewritesPropertyAccessKeysContains(),
    },
  );
}

final class _AvoidMapKeysContainsTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidMapKeysContains();
    super.setUp();
  }

  Future<void> _rewritesPrefixedKeysContains() => expectFix(
    '''
bool f(Map<String, int> m) => m.keys.contains('a');
''',
    (context) => AvoidMapKeysContainsFix(context: context),
    expected: '''
bool f(Map<String, int> m) => m.containsKey('a');
''',
  );

  Future<void> _rewritesPropertyAccessKeysContains() => expectFix(
    '''
class Holder {
  final Map<String, int> m = {};
}

bool f(Holder h) => h.m.keys.contains('a');
''',
    (context) => AvoidMapKeysContainsFix(context: context),
    expected: '''
class Holder {
  final Map<String, int> m = {};
}

bool f(Holder h) => h.m.containsKey('a');
''',
  );
}
