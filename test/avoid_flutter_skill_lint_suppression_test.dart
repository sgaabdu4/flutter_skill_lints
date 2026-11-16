import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_flutter_skill_lint_suppression.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidFlutterSkillLintSuppressionTest>(
    'AvoidFlutterSkillLintSuppressionTest',
    _AvoidFlutterSkillLintSuppressionTest.new,
    _AvoidFlutterSkillLintSuppressionTest._allCases,
  );
}

final class _AvoidFlutterSkillLintSuppressionTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_AvoidFlutterSkillLintSuppressionTest)> get _allCases =>
      caseSet<_AvoidFlutterSkillLintSuppressionTest>(
        parent: const {},
        own: {
          'test_reportsFileIgnoreForMagicLiterals': (t) => t._reportsFileIgnoreForMagicLiterals(),
          'test_reportsLineIgnoreForContractKeys': (t) => t._reportsLineIgnoreForContractKeys(),
          'test_allowsAnalyzerIgnores': (t) => t._allowsAnalyzerIgnores(),
        },
      );

  @override
  void setUp() {
    rule = AvoidFlutterSkillLintSuppression();
    super.setUp();
  }

  Future<void> _reportsFileIgnoreForMagicLiterals() async {
    const source = r'''
// ignore_for_file: avoid_magic_literals
Object? read(Map<String, Object?> data) => data['active-workout'];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('// ignore_for_file'), '// ignore_for_file: avoid_magic_literals'.length),
    ]);
  }

  Future<void> _reportsLineIgnoreForContractKeys() async {
    const source = r'''
// ignore: avoid_local_contract_key_constants
class ActiveWorkoutNotifier {
  static const _draftKeys = <String>{};
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('// ignore:'), '// ignore: avoid_local_contract_key_constants'.length),
    ]);
  }

  Future<void> _allowsAnalyzerIgnores() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: implementation_imports, non_constant_identifier_names
void main() {}
''');
  }
}
