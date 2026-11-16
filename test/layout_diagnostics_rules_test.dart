import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/layout_diagnostics_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidPositionedOutsideStackTest>(
    'AvoidPositionedOutsideStackTest',
    _AvoidPositionedOutsideStackTest.new,
    _AvoidPositionedOutsideStackTest._allCases,
  );
  analysisRuleSuite<_AvoidUnboundedListInColumnTest>(
    'AvoidUnboundedListInColumnTest',
    _AvoidUnboundedListInColumnTest.new,
    _AvoidUnboundedListInColumnTest._allCases,
  );
  analysisRuleSuite<_AvoidUnboundedTextFieldInRowTest>(
    'AvoidUnboundedTextFieldInRowTest',
    _AvoidUnboundedTextFieldInRowTest.new,
    _AvoidUnboundedTextFieldInRowTest._allCases,
  );
  analysisRuleSuite<_AvoidListInSingleChildScrollViewTest>(
    'AvoidListInSingleChildScrollViewTest',
    _AvoidListInSingleChildScrollViewTest.new,
    _AvoidListInSingleChildScrollViewTest._allCases,
  );
  analysisRuleSuite<_AvoidOrientationLayoutTest>(
    'AvoidOrientationLayoutTest',
    _AvoidOrientationLayoutTest.new,
    _AvoidOrientationLayoutTest._allCases,
  );
  analysisRuleSuite<_AvoidClipRRectContainerTest>(
    'AvoidClipRRectContainerTest',
    _AvoidClipRRectContainerTest.new,
    _AvoidClipRRectContainerTest._allCases,
  );
}

abstract class _LayoutRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
enum Axis { horizontal, vertical }
enum Orientation { portrait, landscape }

class BuildContext {}
class Size {
  const Size(this.width, this.height);
  final double width;
  final double height;
}
class BoxConstraints {
  double get maxWidth => 0;
}
class BorderRadius {
  const BorderRadius.circular(double radius);
}
class BoxDecoration {
  const BoxDecoration({BorderRadius? borderRadius});
}

abstract class Widget {
  const Widget();
}
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}
abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget();
}
abstract class ProxyWidget extends Widget {
  const ProxyWidget({required this.child});
  final Widget child;
}
abstract class ParentDataWidget extends ProxyWidget {
  const ParentDataWidget({required super.child});
}

class Flex extends RenderObjectWidget {
  const Flex({Axis direction = Axis.horizontal, List<Widget> children = const []});
}
class Row extends Flex {
  const Row({super.children});
}
class Column extends Flex {
  const Column({super.children});
}
class Stack extends RenderObjectWidget {
  const Stack({List<Widget> children = const []});
}
class Positioned extends ParentDataWidget {
  const Positioned({double? top, required super.child});
}
class Expanded extends ParentDataWidget {
  const Expanded({required super.child});
}
class Padding extends RenderObjectWidget {
  const Padding({Object? padding, required Widget child});
}
class SizedBox extends RenderObjectWidget {
  const SizedBox({double? width, double? height, Widget? child});
}
class Container extends StatelessWidget {
  const Container({Object? color, BoxDecoration? decoration, Widget? child});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class Text extends StatelessWidget {
  const Text(String data);
  @override
  Widget build(BuildContext context) => const SizedBox();
}

abstract class ScrollView extends StatelessWidget {
  const ScrollView({Axis scrollDirection = Axis.vertical, bool shrinkWrap = false});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
abstract class BoxScrollView extends ScrollView {
  const BoxScrollView({super.scrollDirection, super.shrinkWrap});
}
class ListView extends BoxScrollView {
  const ListView({super.scrollDirection, super.shrinkWrap, List<Widget> children = const []});
  const ListView.builder({required Widget Function(BuildContext, int) itemBuilder});
}
class GridView extends BoxScrollView {
  const GridView.count({required int crossAxisCount, List<Widget> children = const []});
}
class CustomScrollView extends ScrollView {
  const CustomScrollView({List<Widget> slivers = const []});
}
class SingleChildScrollView extends StatelessWidget {
  const SingleChildScrollView({Axis scrollDirection = Axis.vertical, required Widget child});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class TextField extends StatelessWidget {
  const TextField();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class TextFormField extends StatelessWidget {
  const TextFormField();
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class ClipRRect extends RenderObjectWidget {
  const ClipRRect({BorderRadius? borderRadius, Widget? child});
}

class MediaQueryData {
  Size get size => const Size(0, 0);
  Orientation get orientation => Orientation.portrait;
}
class MediaQuery {
  static MediaQueryData of(BuildContext context) => MediaQueryData();
  static Size sizeOf(BuildContext context) => const Size(0, 0);
  static Orientation orientationOf(BuildContext context) => Orientation.portrait;
}
class OrientationBuilder extends StatelessWidget {
  const OrientationBuilder({required Widget Function(BuildContext, Orientation) builder});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class LayoutBuilder extends StatelessWidget {
  const LayoutBuilder({required Widget Function(BuildContext, BoxConstraints) builder});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
    super.setUp();
  }
}

final class _AvoidPositionedOutsideStackTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidPositionedOutsideStackTest)> get _allCases =>
      caseSet<_AvoidPositionedOutsideStackTest>(
        parent: const {},
        own: {
          'test_positionedUnderColumnPaddingOrList_lint': (t) =>
              t._positionedUnderColumnPaddingOrListLint(),
          'test_positionedInStackOrUnprovenParent_noLint': (t) =>
              t._positionedInStackOrUnprovenParentNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidPositionedOutsideStack();
    super.setUp();
  }

  Future<void> _positionedUnderColumnPaddingOrListLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget column() => const Column(children: [Positioned(top: 0, child: SizedBox())]);
Widget padded() => const Padding(child: Positioned(child: SizedBox()));
Widget list() => const ListView(children: [Positioned(child: SizedBox())]);
''';
    await assertDiagnostics(source, [
      for (final match in 'Positioned'.allMatches(source)) lint(match.start, 'Positioned'.length),
    ]);
  }

  Future<void> _positionedInStackOrUnprovenParentNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget stack() => const Stack(children: [SizedBox(), Positioned(top: 0, child: SizedBox())]);
class Badge extends StatelessWidget {
  const Badge();
  @override
  Widget build(BuildContext context) => const Positioned(child: SizedBox());
}
Widget extracted() => const Stack(children: [Badge()]);
Widget builder() => ListView.builder(itemBuilder: (context, index) => const Positioned(child: SizedBox()));
''');
  }
}

final class _AvoidUnboundedListInColumnTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidUnboundedListInColumnTest)> get _allCases =>
      caseSet<_AvoidUnboundedListInColumnTest>(
        parent: const {},
        own: {
          'test_verticalListDirectlyInColumn_lint': (t) => t._verticalListDirectlyInColumnLint(),
          'test_constrainedOrOtherAxisLists_noLint': (t) => t._constrainedOrOtherAxisListsNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnboundedListInColumn();
    super.setUp();
  }

  Future<void> _verticalListDirectlyInColumnLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget list() => Column(children: [const Text('Header'), ListView.builder(itemBuilder: (context, index) => const SizedBox())]);
Widget grid() => const Column(children: [GridView.count(crossAxisCount: 2)]);
Widget flex(bool show) => Flex(direction: Axis.vertical, children: [if (show) const ListView(shrinkWrap: false)]);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('ListView.builder'), 'ListView.builder'.length),
      lint(source.indexOf('GridView.count'), 'GridView.count'.length),
      lint(source.indexOf('ListView(shrinkWrap'), 'ListView'.length),
    ]);
  }

  Future<void> _constrainedOrOtherAxisListsNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget panel() => Column(children: [
  const Text('Header'),
  Expanded(child: ListView.builder(itemBuilder: (context, index) => const SizedBox())),
]);
Widget fixed() => const Column(children: [SizedBox(height: 200, child: ListView())]);
Widget horizontal() => const Column(children: [ListView(scrollDirection: Axis.horizontal)]);
Widget row() => const Row(children: [ListView()]);
Widget shrinkWrapped() => const Column(children: [ListView(shrinkWrap: true)]);
Widget dynamicDirection(Axis axis) => Flex(direction: axis, children: const [ListView()]);
''');
  }
}

final class _AvoidUnboundedTextFieldInRowTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidUnboundedTextFieldInRowTest)> get _allCases =>
      caseSet<_AvoidUnboundedTextFieldInRowTest>(
        parent: const {},
        own: {
          'test_textFieldDirectlyInRow_lint': (t) => t._textFieldDirectlyInRowLint(),
          'test_constrainedOrVerticalTextField_noLint': (t) =>
              t._constrainedOrVerticalTextFieldNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnboundedTextFieldInRow();
    super.setUp();
  }

  Future<void> _textFieldDirectlyInRowLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget search() => const Row(children: [Text('icon'), TextField()]);
Widget form() => const Flex(direction: Axis.horizontal, children: [TextFormField()]);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('TextField()'), 'TextField'.length),
      lint(source.indexOf('TextFormField'), 'TextFormField'.length),
    ]);
  }

  Future<void> _constrainedOrVerticalTextFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget searchBar() => const Row(children: [
  Text('icon'),
  SizedBox(width: 8),
  Expanded(child: TextField()),
]);
Widget fixed() => const Row(children: [SizedBox(width: 200, child: TextField())]);
Widget column() => const Column(children: [TextField()]);
''');
  }
}

final class _AvoidListInSingleChildScrollViewTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidListInSingleChildScrollViewTest)> get _allCases =>
      caseSet<_AvoidListInSingleChildScrollViewTest>(
        parent: const {},
        own: {
          'test_sameAxisListInScrollView_lint': (t) => t._sameAxisListInScrollViewLint(),
          'test_slivers_crossAxis_andUnprovenNesting_noLint': (t) =>
              t._sliversCrossAxisAndUnprovenNestingNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidListInSingleChildScrollView();
    super.setUp();
  }

  Future<void> _sameAxisListInScrollViewLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget direct() => const SingleChildScrollView(child: ListView(shrinkWrap: true));
Widget nested() => const SingleChildScrollView(
  child: Column(children: [Text('Header'), Padding(child: ListView())]),
);
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('ListView('), 'ListView'.length),
      lint(source.lastIndexOf('ListView('), 'ListView'.length),
    ]);
  }

  Future<void> _sliversCrossAxisAndUnprovenNestingNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget slivers() => const CustomScrollView(slivers: [SizedBox()]);
Widget carousel() => const SingleChildScrollView(
  child: Column(children: [
    SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal)),
  ]),
);
class Section extends StatelessWidget {
  const Section({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
Widget composed() => const SingleChildScrollView(child: Section(child: ListView()));
Widget standalone() => const ListView();
''');
  }
}

final class _AvoidOrientationLayoutTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidOrientationLayoutTest)> get _allCases =>
      caseSet<_AvoidOrientationLayoutTest>(
        parent: const {},
        own: {
          'test_orientationLayoutBranches_lint': (t) => t._orientationLayoutBranchesLint(),
          'test_availableSpaceAndLookalikes_noLint': (t) => t._availableSpaceAndLookalikesNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidOrientationLayout();
    super.setUp();
  }

  Future<void> _orientationLayoutBranchesLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
bool landscape(BuildContext context) => MediaQuery.orientationOf(context) == Orientation.landscape;
Orientation fromData(BuildContext context) => MediaQuery.of(context).orientation;
Orientation fromLocal(MediaQueryData data) => data.orientation;
Widget builder() => OrientationBuilder(builder: (context, orientation) => const SizedBox());
''';
    await assertDiagnostics(source, [
      lint(
        source.indexOf('MediaQuery.orientationOf(context)'),
        'MediaQuery.orientationOf(context)'.length,
      ),
      lint(
        source.indexOf('MediaQuery.of(context).orientation'),
        'MediaQuery.of(context).orientation'.length,
      ),
      lint(source.indexOf('data.orientation'), 'data.orientation'.length),
      lint(source.indexOf('OrientationBuilder('), 'OrientationBuilder'.length),
    ]);
  }

  Future<void> _availableSpaceAndLookalikesNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget layout() => LayoutBuilder(
  builder: (context, constraints) => constraints.maxWidth >= 840 ? const Text('wide') : const Text('compact'),
);
bool wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;
class Photo {
  int get orientation => 0;
}
int photoOrientation(Photo photo) => photo.orientation;
''');
  }
}

final class _AvoidClipRRectContainerTest extends _LayoutRuleTest {
  static Map<String, Future<void> Function(_AvoidClipRRectContainerTest)> get _allCases =>
      caseSet<_AvoidClipRRectContainerTest>(
        parent: const {},
        own: {
          'test_clipRRectAroundContainer_lint': (t) => t._clipRRectAroundContainerLint(),
          'test_containerRadiusOrOtherClippedChild_noLint': (t) =>
              t._containerRadiusOrOtherClippedChildNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidClipRRectContainer();
    super.setUp();
  }

  Future<void> _clipRRectAroundContainerLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
Widget card() => const ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: 0));
''';
    await assertDiagnostics(source, [lint(source.indexOf('ClipRRect('), 'ClipRRect'.length)]);
  }

  Future<void> _containerRadiusOrOtherClippedChildNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget card() => const Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)));
Widget image() => const ClipRRect(borderRadius: BorderRadius.circular(12), child: Text('image'));
''');
  }
}
