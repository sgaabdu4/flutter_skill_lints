import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_commented_out_code_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_commented_out_code.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidCommentedOutCodeTest>(
    'AvoidCommentedOutCodeTest',
    AvoidCommentedOutCodeTest.new,
    {
      'removesCommentedOutCallLine': (t) => t.removesCommentedOutCallLine(),
      'removesWholeCommentGroup': (t) => t.removesWholeCommentGroup(),
    },
  );
}

final class AvoidCommentedOutCodeTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidCommentedOutCode();
    super.setUp();
  }

  Future<void> removesCommentedOutCallLine() => expectFix(
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

  Future<void> removesWholeCommentGroup() => expectFix(
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
