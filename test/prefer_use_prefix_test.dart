// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_use_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(PreferUsePrefixTest));
}

@reflectiveTest
final class PreferUsePrefixTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferUsePrefix();
    super.setUp();
  }

  Future<void> test_reportsFunctionCallingHookWithoutUsePrefix() async {
    const source = r'''
Object useState(Object value) => value;

Object buildCounter() {
  return useState(0);
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('buildCounter'), 'buildCounter'.length)]);
  }

  Future<void> test_allowsTestEntrypointCallingUsePrefixedHelpers() async {
    await assertNoDiagnostics(r'''
void useNarrowViewport() {}
void useLargeTextScale() {}

void main() {
  useNarrowViewport();
  useLargeTextScale();
}
''');
  }
}
