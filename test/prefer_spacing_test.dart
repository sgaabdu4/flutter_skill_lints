import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_spacing.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_widgets_stub.dart';

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

void main() {
  analysisRuleSuite<PreferSpacingTest>('PreferSpacingTest', PreferSpacingTest.new, {
    'reportsUniformColumnSpacers': (t) => t.reportsUniformColumnSpacers(),
    'reportsUniformRowSpacers': (t) => t.reportsUniformRowSpacers(),
    'ignoresWrongAxisSpacers': (t) => t.ignoresWrongAxisSpacers(),
    'ignoresDifferentSpacerSizes': (t) => t.ignoresDifferentSpacerSizes(),
    'ignoresShortChildLists': (t) => t.ignoresShortChildLists(),
    'ignoresWhenSpacingAlreadySet': (t) => t.ignoresWhenSpacingAlreadySet(),
    'ignoresSpaceBetweenDistribution': (t) => t.ignoresSpaceBetweenDistribution(),
    'reportsCenterDistribution': (t) => t.reportsCenterDistribution(),
    'usesFlexDirectionLiteral': (t) => t.usesFlexDirectionLiteral(),
    'ignoresSpacerWithChildOrKey': (t) => t.ignoresSpacerWithChildOrKey(),
    'ignoresNonConstantExtent': (t) => t.ignoresNonConstantExtent(),
    'reportsSeparatedBy': (t) => t.reportsSeparatedBy(),
    'ignoresSeparatedByOutsideChildren': (t) => t.ignoresSeparatedByOutsideChildren(),
    'reportsExpandYieldingSizedBox': (t) => t.reportsExpandYieldingSizedBox(),
    'ignoresExpandWithoutSizedBox': (t) => t.ignoresExpandWithoutSizedBox(),
  });
}

final class PreferSpacingTest extends AnalysisRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = PreferSpacing();
    super.setUp();
  }

  static const _import = "import 'package:flutter/widgets.dart';\n";

  Future<void> reportsUniformColumnSpacers() async {
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

  Future<void> reportsUniformRowSpacers() async {
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

  Future<void> ignoresWrongAxisSpacers() => assertNoDiagnostics('''
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

  Future<void> ignoresDifferentSpacerSizes() => assertNoDiagnostics('''
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

  Future<void> ignoresShortChildLists() => assertNoDiagnostics('''
${_import}Widget build() => Column(
  children: [Text('a'), SizedBox(height: 8), Text('b')],
);
''');

  Future<void> ignoresWhenSpacingAlreadySet() => assertNoDiagnostics('''
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

  Future<void> ignoresSpaceBetweenDistribution() => assertNoDiagnostics('''
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

  Future<void> reportsCenterDistribution() async {
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

  Future<void> usesFlexDirectionLiteral() async {
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

  Future<void> ignoresSpacerWithChildOrKey() => assertNoDiagnostics('''
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

  Future<void> ignoresNonConstantExtent() => assertNoDiagnostics('''
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

  Future<void> reportsSeparatedBy() async {
    const source =
        '''
${_import}Widget build() => Column(
  children: [Text('a'), Text('b')].separatedBy(SizedBox(height: 8)),
);
''';
    const call = "[Text('a'), Text('b')].separatedBy(SizedBox(height: 8))";
    await assertDiagnostics(source, [lint(source.indexOf(call), call.length)]);
  }

  Future<void> ignoresSeparatedByOutsideChildren() => assertNoDiagnostics('''
${_import}List<Widget> build() => [Text('a')].separatedBy(SizedBox(height: 8));
''');

  Future<void> reportsExpandYieldingSizedBox() async {
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

  Future<void> ignoresExpandWithoutSizedBox() => assertNoDiagnostics('''
${_import}Widget build(List<Widget> items) => Column(
  children: items.expand((w) sync* {
    yield w;
    yield w;
  }).toList(),
);
''');
}
