import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_spacing.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_PreferSpacingTest>('PreferSpacingTest', _PreferSpacingTest.new, {
    'reportsUniformColumnSpacers': (t) => t._reportsUniformColumnSpacers(),
    'reportsUniformRowSpacers': (t) => t._reportsUniformRowSpacers(),
    'ignoresWrongAxisSpacers': (t) => t._ignoresWrongAxisSpacers(),
    'ignoresDifferentSpacerSizes': (t) => t._ignoresDifferentSpacerSizes(),
    'ignoresShortChildLists': (t) => t._ignoresShortChildLists(),
    'ignoresWhenSpacingAlreadySet': (t) => t._ignoresWhenSpacingAlreadySet(),
    'ignoresSpaceBetweenDistribution': (t) => t._ignoresSpaceBetweenDistribution(),
    'reportsCenterDistribution': (t) => t._reportsCenterDistribution(),
    'usesFlexDirectionLiteral': (t) => t._usesFlexDirectionLiteral(),
    'ignoresSpacerWithChildOrKey': (t) => t._ignoresSpacerWithChildOrKey(),
    'ignoresNonConstantExtent': (t) => t._ignoresNonConstantExtent(),
    'reportsSeparatedBy': (t) => t._reportsSeparatedBy(),
    'ignoresSeparatedByOutsideChildren': (t) => t._ignoresSeparatedByOutsideChildren(),
    'reportsExpandYieldingSizedBox': (t) => t._reportsExpandYieldingSizedBox(),
    'ignoresExpandWithoutSizedBox': (t) => t._ignoresExpandWithoutSizedBox(),
  });
}

final class _PreferSpacingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferSpacing();
    super.setUp();
  }

  static const _import = "import 'package:flutter/widgets.dart';\n";

  Future<void> _reportsUniformColumnSpacers() async {
    const source =
        '''
${_import}Widget build() => Column(
  children: [
    Text('a'),
    SizedBox(height: 8),
    Text('b'),
    SizedBox(height: 8),
    Text('c'),
  ],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
      lint(source.lastIndexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
    ]);
  }

  Future<void> _reportsUniformRowSpacers() async {
    const source =
        '''
${_import}Widget build() => Row(
  children: [
    Text('a'),
    SizedBox(width: 4),
    Text('b'),
    SizedBox(width: 4),
    Text('c'),
  ],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(width: 4)'), 'SizedBox(width: 4)'.length),
      lint(source.lastIndexOf('SizedBox(width: 4)'), 'SizedBox(width: 4)'.length),
    ]);
  }

  Future<void> _ignoresWrongAxisSpacers() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  children: [
    Text('a'),
    SizedBox(width: 8),
    Text('b'),
    SizedBox(width: 8),
    Text('c'),
  ],
);
''');

  Future<void> _ignoresDifferentSpacerSizes() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  children: [
    Text('a'),
    SizedBox(height: 8),
    Text('b'),
    SizedBox(height: 16),
    Text('c'),
  ],
);
''');

  Future<void> _ignoresShortChildLists() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  children: [Text('a'), SizedBox(height: 8), Text('b')],
);
''');

  Future<void> _ignoresWhenSpacingAlreadySet() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  spacing: 2,
  children: [
    Text('a'),
    SizedBox(height: 8),
    Text('b'),
    SizedBox(height: 8),
    Text('c'),
  ],
);
''');

  Future<void> _ignoresSpaceBetweenDistribution() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('a'),
    SizedBox(height: 8),
    Text('b'),
    SizedBox(height: 8),
    Text('c'),
  ],
);
''');

  Future<void> _reportsCenterDistribution() async {
    const source =
        '''
${_import}Widget build() => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('a'),
    SizedBox(height: 8),
    Text('b'),
    SizedBox(height: 8),
    Text('c'),
  ],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
      lint(source.lastIndexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
    ]);
  }

  Future<void> _usesFlexDirectionLiteral() async {
    const source =
        '''
${_import}Widget build() => Flex(
  direction: Axis.horizontal,
  children: [
    Text('a'),
    SizedBox(width: 8),
    Text('b'),
    SizedBox(width: 8),
    Text('c'),
  ],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(width: 8)'), 'SizedBox(width: 8)'.length),
      lint(source.lastIndexOf('SizedBox(width: 8)'), 'SizedBox(width: 8)'.length),
    ]);
  }

  Future<void> _ignoresSpacerWithChildOrKey() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  children: [
    Text('a'),
    SizedBox(height: 8, child: Text('x')),
    Text('b'),
    SizedBox(height: 8, child: Text('x')),
    Text('c'),
  ],
);
''');

  Future<void> _ignoresNonConstantExtent() => assertNoDiagnostics('''
${_import}Widget build(double gap) => Column(
  children: [
    Text('a'),
    SizedBox(height: gap),
    Text('b'),
    SizedBox(height: gap),
    Text('c'),
  ],
);
''');

  Future<void> _reportsSeparatedBy() async {
    const source =
        '''
${_import}Widget build() => Column(
  children: [Text('a'), Text('b')].separatedBy(SizedBox(height: 8)),
);
''';
    const call = "[Text('a'), Text('b')].separatedBy(SizedBox(height: 8))";
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> _ignoresSeparatedByOutsideChildren() => assertNoDiagnostics('''
${_import}List<Widget> build() => [Text('a')].separatedBy(SizedBox(height: 8));
''');

  Future<void> _reportsExpandYieldingSizedBox() async {
    const source =
        '''
${_import}Widget build(List<Widget> items) => Column(
  children: items.expand((w) sync* {
    yield SizedBox(height: 8);
    yield w;
  }).toList(),
);
''';
    const call = '''items.expand((w) sync* {
    yield SizedBox(height: 8);
    yield w;
  })''';
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> _ignoresExpandWithoutSizedBox() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> items) => Column(
  children: items.expand((w) sync* {
    yield w;
    yield w;
  }).toList(),
);
''');
}
