// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_flutter_skill_lint_suppression.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFlutterSkillLintSuppressionTest);
  });
}

@reflectiveTest
final class AvoidFlutterSkillLintSuppressionTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidFlutterSkillLintSuppression();
    super.setUp();
  }

  Future<void> test_reportsFileIgnoreForMagicLiterals() async {
    const source = r'''
// ignore_for_file: avoid_magic_literals
Object? read(Map<String, Object?> data) => data['active-workout'];
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('// ignore_for_file'), '// ignore_for_file: avoid_magic_literals'.length),
    ]);
  }

  Future<void> test_reportsLineIgnoreForContractKeys() async {
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

  Future<void> test_allowsAnalyzerIgnores() async {
    await assertNoDiagnostics(r'''
// ignore_for_file: implementation_imports, non_constant_identifier_names
void main() {}
''');
  }
}
