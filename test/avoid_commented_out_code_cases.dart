import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_commented_out_code_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_commented_out_code.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<_AvoidCommentedOutCodeTest>(
    'AvoidCommentedOutCodeTest',
    _AvoidCommentedOutCodeTest.new,
    {
      'removesCommentedOutCallLine': (t) => t._removesCommentedOutCallLine(),
      'removesWholeCommentGroup': (t) => t._removesWholeCommentGroup(),
    },
  );
}

final class _AvoidCommentedOutCodeTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

  Future<void> _removesCommentedOutCallLine() => expectFix(
    '''
void f() {
  // print(1);
  print(2);
}
''',
    (context) => AvoidCommentedOutCodeFix(context: context),
    expected: '''
void f() {
  print(2);
}
''',
  );

  Future<void> _removesWholeCommentGroup() => expectFix(
    '''
void f() {
  // final a = 1;
  // print(a);
  print(2);
}
''',
    (context) => AvoidCommentedOutCodeFix(context: context),
    expected: '''
void f() {
  print(2);
}
''',
  );
}
