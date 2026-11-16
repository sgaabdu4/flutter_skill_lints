import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_shrink_wrap_in_lists.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidShrinkWrapInListsTest>(
    'AvoidShrinkWrapInListsTest',
    _AvoidShrinkWrapInListsTest.new,
    {
      'reportsShrinkWrapTrue': (t) => t._reportsShrinkWrapTrue(),
      'acceptsShrinkWrapFalse': (t) => t._acceptsShrinkWrapFalse(),
      'acceptsNonLiteralValue': (t) => t._acceptsNonLiteralValue(),
      'ignoresOtherWidgets': (t) => t._ignoresOtherWidgets(),
    },
  );
}

final class _AvoidShrinkWrapInListsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidShrinkWrapInLists();
    super.setUp();
  }

  Future<void> _reportsShrinkWrapTrue() async {
    const source = '''
import 'package:flutter/widgets.dart';

Widget build() => ListView(shrinkWrap: true);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('shrinkWrap: true'), 'shrinkWrap: true'.length),
    ]);
  }

  Future<void> _acceptsShrinkWrapFalse() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => ListView(shrinkWrap: false);
''');

  Future<void> _acceptsNonLiteralValue() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build(bool wrap) => ListView(shrinkWrap: wrap);
''');

  Future<void> _ignoresOtherWidgets() => assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

Widget build() => Column();
''');
}
