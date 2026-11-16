import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_map_keys_contains_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_map_keys_contains.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidMapKeysContainsTest>(
    'AvoidMapKeysContainsTest',
    AvoidMapKeysContainsTest.new,
    {
      'rewritesPrefixedKeysContains': (t) => t.rewritesPrefixedKeysContains(),
      'rewritesPropertyAccessKeysContains': (t) => t.rewritesPropertyAccessKeysContains(),
    },
  );
}

final class AvoidMapKeysContainsTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidMapKeysContains();
    super.setUp();
  }

  Future<void> rewritesPrefixedKeysContains() => expectFix(
    '''
bool f(Map<String, int> m) => m.keys.contains('a');
''',
    (context) => AvoidMapKeysContainsFix(context: context),
    expected: '''
bool f(Map<String, int> m) => m.containsKey('a');
''',
  );

  Future<void> rewritesPropertyAccessKeysContains() => expectFix(
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
