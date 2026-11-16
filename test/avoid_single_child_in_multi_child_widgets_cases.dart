import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_single_child_in_multi_child_widgets.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_AvoidSingleChildInMultiChildWidgetsTest>(
    'AvoidSingleChildInMultiChildWidgetsTest',
    _AvoidSingleChildInMultiChildWidgetsTest.new,
    {
      'reportsColumnWithOneChild': (t) => t._reportsColumnWithOneChild(),
      'reportsWrapWithOneChild': (t) => t._reportsWrapWithOneChild(),
      'acceptsTwoChildren': (t) => t._acceptsTwoChildren(),
      'acceptsSpreadChild': (t) => t._acceptsSpreadChild(),
      'acceptsForElementChild': (t) => t._acceptsForElementChild(),
      'reportsConditionalSingleChild': (t) => t._reportsConditionalSingleChild(),
      'acceptsConditionalWithSpread': (t) => t._acceptsConditionalWithSpread(),
      'acceptsNonLiteralChildren': (t) => t._acceptsNonLiteralChildren(),
      'ignoresUnlistedWidgets': (t) => t._ignoresUnlistedWidgets(),
      'acceptsColumnWithoutChildren': (t) => t._acceptsColumnWithoutChildren(),
    },
  );
}

final class _AvoidSingleChildInMultiChildWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AvoidSingleChildInMultiChildWidgets();
    super.setUp();
  }

  static const _import = "import 'package:flutter/widgets.dart';\n";

  Future<void> _reportsColumnWithOneChild() async {
    const source =
        '''
${_import}Widget build() => Column(children: [Text('a')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> _reportsWrapWithOneChild() async {
    const source =
        '''
${_import}Widget build() => Wrap(children: [Text('a')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Wrap'), 'Wrap'.length)]);
  }

  Future<void> _acceptsTwoChildren() => assertNoDiagnostics('''
${_import}Widget build() => Row(children: [Text('a'), Text('b')]);
''');

  Future<void> _acceptsSpreadChild() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> all) => Column(children: [...all]);
''');

  Future<void> _acceptsForElementChild() => assertNoDiagnostics('''
${_import}Widget build(List<int> all) => Column(children: [for (final a in all) Text('a')]);
''');

  Future<void> _reportsConditionalSingleChild() async {
    const source =
        '''
${_import}Widget build(bool on) => Column(children: [if (on) Text('a') else Text('b')]);
''';
    await assertDiagnostics(source, [lint(source.indexOf('Column'), 'Column'.length)]);
  }

  Future<void> _acceptsConditionalWithSpread() => assertNoDiagnostics('''
${_import}Widget build(bool on, List<Widget> all) => Column(children: [if (on) ...all]);
''');

  Future<void> _acceptsNonLiteralChildren() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> all) => Column(children: all);
''');

  Future<void> _ignoresUnlistedWidgets() => assertNoDiagnostics('''
${_import}Widget build() => Padding(padding: EdgeInsets.all(1), child: Text('a'));
''');

  Future<void> _acceptsColumnWithoutChildren() => assertNoDiagnostics('''
${_import}Widget build() => Column();
''');
}
