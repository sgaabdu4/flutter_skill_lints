// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_for_loop_in_children.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_spacing.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferSpacingLayoutTest);
    defineReflectiveTests(PreferForLoopWidgetListTest);
  });
}

abstract class _FlutterWidgetRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
enum Axis { horizontal, vertical }
enum MainAxisAlignment { start, center, end, spaceBetween, spaceAround, spaceEvenly }

class Widget {
  const Widget();
}

class Text extends Widget {
  const Text(String value);
}

class SizedBox extends Widget {
  const SizedBox({Object? key, double? width, double? height, Widget? child});
}

class Row extends Widget {
  const Row({
    double spacing = 0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    List<Widget> children = const [],
  });
}

class Column extends Widget {
  const Column({
    double spacing = 0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    List<Widget> children = const [],
  });
}

class Flex extends Widget {
  const Flex({
    required Axis direction,
    double spacing = 0,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    List<Widget> children = const [],
  });
}
''');
    super.setUp();
  }
}

@reflectiveTest
final class PreferSpacingLayoutTest extends _FlutterWidgetRuleTest {
  @override
  void setUp() {
    rule = PreferSpacing();
    super.setUp();
  }

  Future<void> test_uniformInteriorSeparators_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Row(children: [
  Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c'),
]);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(width: 8)'), 'SizedBox(width: 8)'.length),
      lint(source.lastIndexOf('SizedBox(width: 8)'), 'SizedBox(width: 8)'.length),
    ]);
  }

  Future<void> test_verticalInteriorSeparator_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Column(children: [Text('a'), SizedBox(height: 8), Text('b'), SizedBox(height: 8), Text('c')]);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
      lint(source.lastIndexOf('SizedBox(height: 8)'), 'SizedBox(height: 8)'.length),
    ]);
  }

  Future<void> test_skillSingleGapAndSpaceBetweenGaps_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

abstract final class Spacing {
  static const double s8 = 8;
}

Widget statusRow() => const Row(children: [Text('icon'), SizedBox(width: Spacing.s8), Text('message')]);
Widget spaced() => const Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
''');
  }

  Future<void> test_constantTokenWithCenterAlignment_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

const double gap = 8;
Widget build() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [Text('a'), SizedBox(width: gap), Text('b'), SizedBox(width: gap), Text('c')],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('SizedBox(width: gap)'), 'SizedBox(width: gap)'.length),
      lint(source.lastIndexOf('SizedBox(width: gap)'), 'SizedBox(width: gap)'.length),
    ]);
  }

  Future<void> test_dotShorthandAndConstAlias_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

const chosenAlignment = MainAxisAlignment.end;
Widget row() => const Row(
  mainAxisAlignment: .center,
  children: [Text('a'), SizedBox(width: 4 + 4), Text('b'), SizedBox(width: 4 + 4), Text('c')],
);
Widget aliased() => const Row(
  mainAxisAlignment: chosenAlignment,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget flex() => const Flex(
  direction: .horizontal,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
''';
    await assertDiagnostics(source, [
      for (final gap in RegExp(r'SizedBox\(width: (?:4 \+ 4|8)\)').allMatches(source))
        lint(gap.start, gap.end - gap.start),
    ]);
  }

  Future<void> test_missingLeadingTrailingOrInteriorSeparator_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget leading() => const Row(children: [SizedBox(width: 8), Text('a'), Text('b')]);
Widget trailing() => const Row(children: [Text('a'), Text('b'), SizedBox(width: 8)]);
Widget missing() => const Row(children: [Text('a'), SizedBox(width: 8), Text('b'), Text('c')]);
Widget extra() => const Row(children: [Text('a'), SizedBox(width: 8), SizedBox(width: 8), Text('b')]);
Widget keyed() => const Row(children: [Text('a'), SizedBox(key: 'identity', width: 8), Text('b')]);
Widget mixed() => const Row(children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 12), Text('c')]);
''');
  }

  Future<void> test_axisAndConditionalChildren_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget wrongAxis() => const Column(children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')]);
Widget dynamicAxis(Axis direction) => Flex(
  direction: direction,
  children: const [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget wrongFlexAxis() => const Flex(
  direction: Axis.vertical,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget conditional(bool show) => Row(children: [
  const Text('a'), const SizedBox(width: 8), if (show) const Text('b'), const Text('c'),
]);
Widget loop(List<String> labels) => Row(children: [
  const Text('a'), const SizedBox(width: 8), for (final label in labels) Text(label),
]);
''');
  }

  Future<void> test_distributedEdgesAndEvaluatedGapExpressions_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

double nextGap() => 8;
class Gap {
  double get value => 8;
}

Widget around() => const Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget evenly() => const Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget dynamicAlignment(MainAxisAlignment alignment) => Row(
  mainAxisAlignment: alignment,
  children: const [Text('a'), SizedBox(width: 8), Text('b'), SizedBox(width: 8), Text('c')],
);
Widget calledGap() => Row(children: [
  const Text('a'), SizedBox(width: nextGap()), const Text('b'),
  SizedBox(width: nextGap()), const Text('c'),
]);
Widget getterGap(Gap gap) => Row(children: [
  const Text('a'), SizedBox(width: gap.value), const Text('b'),
  SizedBox(width: gap.value), const Text('c'),
]);
''');
  }

  Future<void> test_realFlutterSizedBoxAndLiteralFlexAxis_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart' as f;

f.Widget build() => const f.Flex(
  direction: f.Axis.horizontal,
  children: [f.Text('a'), f.SizedBox(width: 8), f.Text('b'), f.SizedBox(width: 8), f.Text('c')],
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('f.SizedBox(width: 8)'), 'f.SizedBox(width: 8)'.length),
      lint(source.lastIndexOf('f.SizedBox(width: 8)'), 'f.SizedBox(width: 8)'.length),
    ]);
  }

  Future<void> test_localSizedBoxLookalike_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

class SizedBox extends f.Widget {
  const SizedBox({double? width});
}

f.Widget build() => const f.Row(children: [f.Text('a'), SizedBox(width: 8), f.Text('b'), SizedBox(width: 8), f.Text('c')]);
''');
  }

  Future<void> test_axisGetterLookalike_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

class AxisHolder {
  f.Axis get horizontal => f.Axis.horizontal;
}

f.Widget build(AxisHolder holder) => f.Flex(
  direction: holder.horizontal,
  children: const [f.Text('a'), f.SizedBox(width: 8), f.Text('b'), f.SizedBox(width: 8), f.Text('c')],
);
''');
  }
}

@reflectiveTest
final class PreferForLoopWidgetListTest extends _FlutterWidgetRuleTest {
  @override
  void setUp() {
    rule = PreferForLoopInChildren();
    super.setUp();
  }

  Future<void> test_numericDataTransforms_noLint() async {
    await assertNoDiagnostics(r'''
List<int> mapped(List<int> values) => values.map((value) => value * 2).toList();
List<int> folded(List<int> values) => values.fold<List<int>>(
  <int>[], (items, value) => items..add(value),
);
List<int> generated() => List.generate(3, (index) => index * 2);
List<int> typedGenerated() => List<int>.generate(3, (index) => index * 2);
List<int> spread(List<int> values) => <int>[...values.map((value) => value * 2)];
''');
  }

  Future<void> test_flutterWidgetTransforms_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> mapped(List<int> values) => values.map((value) => f.Text('$value')).toList();
List<f.Widget> folded(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) {
    items.add(f.Text('$value'));
    return items;
  },
);
List<f.Widget> generated() => List.generate(3, (index) => f.Text('$index'));
List<f.Widget> typedGenerated() => List<f.Widget>.generate(3, (index) => f.Text('$index'));
List<f.Widget> spread(List<int> values) => <f.Widget>[...values.map((value) => f.Text('$value'))];
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('values.map'), 48),
      lint(
        source.indexOf('values.fold'),
        source.indexOf(');\nList<f.Widget> generated') - source.indexOf('values.fold') + 1,
      ),
      lint(
        source.indexOf('List.generate'),
        "List.generate(3, (index) => f.Text('\$index'))".length,
      ),
      lint(
        source.indexOf('List<f.Widget>.generate'),
        "List<f.Widget>.generate(3, (index) => f.Text('\$index'))".length,
      ),
      lint(source.indexOf('...values.map'), "...values.map((value) => f.Text('\$value'))".length),
    ]);
  }

  Future<void> test_localWidgetLookalike_noLint() async {
    await assertNoDiagnostics(r'''
class Widget {
  const Widget();
}
List<Widget> build(List<int> values) => values.map((value) => const Widget()).toList();
''');
  }

  Future<void> test_filteredReorderedAndAccumulatorDependentFolds_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> filtered(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) {
    if (value.isEven) items.add(f.Text('$value'));
    return items;
  },
);
List<f.Widget> reordered(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) => <f.Widget>[f.Text('$value'), ...items],
);
List<f.Widget> accumulated(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) {
    items.add(f.Text('${items.length}'));
    return items;
  },
);
''');
  }

  Future<void> test_immutableFoldAndFixedLengthCollections_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> immutableFold(List<int> values) => values.fold<List<f.Widget>>(
  const <f.Widget>[], (items, value) => items..add(f.Text('$value')),
);
List<f.Widget> fixedMap(List<int> values) =>
  values.map((value) => f.Text('$value')).toList(growable: false);
List<f.Widget> dynamicMap(List<int> values, bool growable) =>
  values.map((value) => f.Text('$value')).toList(growable: growable);
List<f.Widget> fixedGenerate() =>
  List.generate(3, (index) => f.Text('$index'), growable: false);
List<f.Widget> dynamicGenerate(bool growable) =>
  List.generate(3, (index) => f.Text('$index'), growable: growable);
List<f.Widget> fixedTypedGenerate() =>
  List<f.Widget>.generate(3, (index) => f.Text('$index'), growable: false);
List<f.Widget> dynamicTypedGenerate(bool growable) =>
  List<f.Widget>.generate(3, (index) => f.Text('$index'), growable: growable);
''');
  }

  Future<void> test_explicitGrowableCollections_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> mapped(List<int> values) =>
  values.map((value) => f.Text('$value')).toList(growable: true);
List<f.Widget> generated() =>
  List.generate(3, (index) => f.Text('$index'), growable: true);
List<f.Widget> typedGenerated() =>
  List<f.Widget>.generate(3, (index) => f.Text('$index'), growable: true);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('values.map'), 62),
      lint(source.indexOf('List.generate'), 61),
      lint(source.indexOf('List<f.Widget>.generate'), 71),
    ]);
  }

  Future<void> test_cascadeAppendOnceFold_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> build(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) => items..add(f.Text('$value')),
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('values.fold'), source.indexOf(');') - source.indexOf('values.fold') + 1),
    ]);
  }

  Future<void> test_blockReturnCascadeAppendOnceFold_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart' as f;

List<f.Widget> build(List<int> values) => values.fold<List<f.Widget>>(
  <f.Widget>[], (items, value) {
    return items..add(f.Text('$value'));
  },
);
''';
    await assertDiagnostics(source, [
      lint(
        source.indexOf('values.fold'),
        source.lastIndexOf(');') - source.indexOf('values.fold') + 1,
      ),
    ]);
  }

  Future<void> test_customMapMethodReturningFlutterWidgets_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

class Values {
  List<f.Widget> map(f.Widget Function(int) convert) => [convert(1)];
}

List<f.Widget> build(Values values) => values.map((value) => f.Text('$value')).toList();
''');
  }

  Future<void> test_customListGenerateReturningFlutterWidgets_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart' as f;

class List<T> {
  List();
  factory List.generate(int count, T Function(int) build) => List<T>();
}

List<f.Widget> build() => List<f.Widget>.generate(2, (index) => f.Text('$index'));
''');
  }
}
