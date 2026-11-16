import 'package:flutter_skill_lints/src/additional_lints/fixes/prefer_iterable_of_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_iterable_of.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';

void main() {
  analysisRuleSuite<PreferIterableOfFixTest>(
    'PreferIterableOfFixTest',
    PreferIterableOfFixTest.new,
    {
      'replacesFromInConstructor': (t) => t.replacesFromInConstructor(),
      'replacesFromInStaticCall': (t) => t.replacesFromInStaticCall(),
    },
  );
}

final class PreferIterableOfFixTest extends FixRuleTest {
  @override
  void setUp() {
    rule = PreferIterableOf();
    super.setUp();
  }

  Future<void> replacesFromInConstructor() => expectFix(
    'final a = List<int>.from(<int>[1]);\n',
    (context) => PreferIterableOfFix(context: context),
    expected: 'final a = List<int>.of(<int>[1]);\n',
  );

  Future<void> replacesFromInStaticCall() => expectFix(
    'final a = Set<int>.from(<int>[1]);\n',
    (context) => PreferIterableOfFix(context: context),
    expected: 'final a = Set<int>.of(<int>[1]);\n',
  );
}
