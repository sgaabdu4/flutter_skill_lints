import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test/test.dart';

void analysisRuleSuite<T extends AnalysisRuleTest>(
  String name,
  T Function() create,
  Map<String, Future<void> Function(T)> cases,
) {
  group(name, () {
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final fixture = create()..setUp();
        try {
          await entry.value(fixture);
        } finally {
          await fixture.tearDown();
        }
      });
    }
  });
}
