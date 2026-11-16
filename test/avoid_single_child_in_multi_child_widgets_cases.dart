import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_child_in_multi_child_widgets.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AvoidSingleChildInMultiChildWidgetsTest>(
    'AvoidSingleChildInMultiChildWidgetsTest',
    AvoidSingleChildInMultiChildWidgetsTest.new,
    {
      'reportsColumnWithOneChild': (t) => t.reportsColumnWithOneChild(),
      'reportsWrapWithOneChild': (t) => t.reportsWrapWithOneChild(),
      'acceptsTwoChildren': (t) => t.acceptsTwoChildren(),
      'acceptsSpreadChild': (t) => t.acceptsSpreadChild(),
      'acceptsForElementChild': (t) => t.acceptsForElementChild(),
      'reportsConditionalSingleChild': (t) => t.reportsConditionalSingleChild(),
      'acceptsConditionalWithSpread': (t) => t.acceptsConditionalWithSpread(),
      'acceptsNonLiteralChildren': (t) => t.acceptsNonLiteralChildren(),
      'ignoresUnlistedWidgets': (t) => t.ignoresUnlistedWidgets(),
      'acceptsColumnWithoutChildren': (t) => t.acceptsColumnWithoutChildren(),
    },
  );
}

final class AvoidSingleChildInMultiChildWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidSingleChildInMultiChildWidgets();
    super.setUp();
  }

  static const _import = "import 'package:flutter/widgets.dart';\n";

  Future<void> reportsColumnWithOneChild() async {
    const source =
        '''
${_import}Widget build() => Column(children: [Text('a')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> reportsWrapWithOneChild() async {
    const source =
        '''
${_import}Widget build() => Wrap(children: [Text('a')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Wrap'), 'Wrap'.length)]);
  }

  Future<void> acceptsTwoChildren() => assertNoDiagnostics('''
${_import}Widget build() => Row(children: [Text('a'), Text('b')]);
''');

  Future<void> acceptsSpreadChild() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> all) => Column(children: [...all]);
''');

  Future<void> acceptsForElementChild() => assertNoDiagnostics('''
${_import}Widget build(List<int> all) => Column(children: [for (final a in all) Text('a')]);
''');

  Future<void> reportsConditionalSingleChild() async {
    const source =
        '''
${_import}Widget build(bool on) => Column(children: [if (on) Text('a') else Text('b')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> acceptsConditionalWithSpread() => assertNoDiagnostics('''
${_import}Widget build(bool on, List<Widget> all) => Column(children: [if (on) ...all]);
''');

  Future<void> acceptsNonLiteralChildren() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> all) => Column(children: all);
''');

  Future<void> ignoresUnlistedWidgets() => assertNoDiagnostics('''
${_import}Widget build() => Padding(padding: EdgeInsets.all(1), child: Text('a'));
''');

  Future<void> acceptsColumnWithoutChildren() => assertNoDiagnostics('''
${_import}Widget build() => Column();
''');
}
