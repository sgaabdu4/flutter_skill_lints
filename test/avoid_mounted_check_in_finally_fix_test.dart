import 'package:flutter_skill_lints/src/additional_lints/fixes/avoid_mounted_check_in_finally_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mounted_check_in_finally.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<AvoidMountedCheckInFinallyFixTest>(
    'AvoidMountedCheckInFinallyFixTest',
    AvoidMountedCheckInFinallyFixTest.new,
    {
      'wrapsTrailingStatementInPositiveGuard': (t) => t.wrapsTrailingStatementInPositiveGuard(),
      'wrapsEveryTrailingStatement': (t) => t.wrapsEveryTrailingStatement(),
      'keepsGuardStatementsBeforeTheCheck': (t) => t.keepsGuardStatementsBeforeTheCheck(),
      'keepsTheTargetOfTheMountedCheck': (t) => t.keepsTheTargetOfTheMountedCheck(),
      'offersNoFixWithoutTrailingStatements': (t) => t.offersNoFixWithoutTrailingStatements(),
    },
  );
}

final class AvoidMountedCheckInFinallyFixTest extends FixRuleTest {
  @override
  void setUp() {
    rule = AvoidMountedCheckInFinally();
    super.setUp();
  }

  static String _source(String finallyBody) =>
      '''
class Ref {
  bool get mounted => true;
}

void use(Object value) {}

Future<void> f(Ref ref) async {
  try {
    await Future<void>.value();
  } finally {
$finallyBody
  }
}
''';

  Future<void> _expectRewrite(String before, String after) => expectFix(
    _source(before),
    (context) => AvoidMountedCheckInFinallyFix(context: context),
    expected: _source(after),
  );

  Future<void> wrapsTrailingStatementInPositiveGuard() => _expectRewrite(
    '''
    if (!ref.mounted) return;
    use(1);''',
    '''
    if (ref.mounted) {
      use(1);
    }''',
  );

  Future<void> wrapsEveryTrailingStatement() => _expectRewrite(
    '''
    if (!ref.mounted) return;
    use(1);
    use(2);''',
    '''
    if (ref.mounted) {
      use(1);
      use(2);
    }''',
  );

  Future<void> keepsGuardStatementsBeforeTheCheck() => _expectRewrite(
    '''
    use(0);
    if (!ref.mounted) return;
    use(1);''',
    '''
    use(0);
    if (ref.mounted) {
      use(1);
    }''',
  );

  Future<void> keepsTheTargetOfTheMountedCheck() => expectFix(
    '''
class Ctx {
  bool get mounted => true;
}

void use(Object value) {}

Future<void> f(Ctx context) async {
  try {
    await Future<void>.value();
  } finally {
    if (!context.mounted) return;
    use(1);
  }
}
''',
    (context) => AvoidMountedCheckInFinallyFix(context: context),
    expected: '''
class Ctx {
  bool get mounted => true;
}

void use(Object value) {}

Future<void> f(Ctx context) async {
  try {
    await Future<void>.value();
  } finally {
    if (context.mounted) {
      use(1);
    }
  }
}
''',
  );

  Future<void> offersNoFixWithoutTrailingStatements() => expectNoFix(
    _source('    if (!ref.mounted) return;'),
    (context) => AvoidMountedCheckInFinallyFix(context: context),
  );
}
