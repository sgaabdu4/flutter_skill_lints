import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_border_all.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidBorderAllTest>('AvoidBorderAllTest', AvoidBorderAllTest.new, {
    'reportsBorderAll': (t) => t.reportsBorderAll(),
    'acceptsFromBorderSide': (t) => t.acceptsFromBorderSide(),
    'ignoresOtherClassesWithAll': (t) => t.ignoresOtherClassesWithAll(),
  });
}

final class AvoidBorderAllTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidBorderAll();
    super.setUp();
  }

  Future<void> reportsBorderAll() async {
    const source = '''
import 'package:flutter/widgets.dart';

Border f() => Border.all(width: 2);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('Border.all'), 'Border.all(width: 2)'.length),
    ]);
  }

  Future<void> acceptsFromBorderSide() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Border f() => Border.fromBorderSide(BorderSide(width: 2));
''');

  Future<void> ignoresOtherClassesWithAll() => assertNoDiagnostics('''
class Border {
  const Border.all();
}

Border f() => Border.all();
''');
}
