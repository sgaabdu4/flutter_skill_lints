import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/consistent_update_render_object.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sliver_prefix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_dedicated_media_query_methods.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_UseDedicatedMediaQueryMethodsTest>(
    'UseDedicatedMediaQueryMethodsTest',
    _UseDedicatedMediaQueryMethodsTest.new,
    _UseDedicatedMediaQueryMethodsTest._allCases,
  );
  analysisRuleSuite<_PreferSliverPrefixTest>(
    'PreferSliverPrefixTest',
    _PreferSliverPrefixTest.new,
    _PreferSliverPrefixTest._allCases,
  );
  analysisRuleSuite<_ConsistentUpdateRenderObjectTest>(
    'ConsistentUpdateRenderObjectTest',
    _ConsistentUpdateRenderObjectTest.new,
    _ConsistentUpdateRenderObjectTest._allCases,
  );
}

abstract class _FlutterRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}

class Widget {
  const Widget();
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
  State createState();
}

abstract class State<T extends StatefulWidget> {
  T get widget => throw UnimplementedError();
  Widget build(BuildContext context);
}

class SliverList extends Widget {
  const SliverList();
}

class BoxWidget extends Widget {
  const BoxWidget();
}

class Size {
  const Size();
}

class EdgeInsets {
  const EdgeInsets();
}

class MediaQueryData {
  const MediaQueryData();

  Size get size => const Size();
  EdgeInsets get padding => const EdgeInsets();
  EdgeInsets get viewInsets => const EdgeInsets();
}

class MediaQuery {
  static MediaQueryData of(BuildContext context) => const MediaQueryData();
  static Size sizeOf(BuildContext context) => const Size();
  static EdgeInsets paddingOf(BuildContext context) => const EdgeInsets();
  static EdgeInsets viewInsetsOf(BuildContext context) => const EdgeInsets();
}

class RenderObject {}

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget();
}

abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget();

  RenderObject createRenderObject(BuildContext context);

  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {}
}
''');
  }
}

final class _UseDedicatedMediaQueryMethodsTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_UseDedicatedMediaQueryMethodsTest)> get _allCases =>
      caseSet<_UseDedicatedMediaQueryMethodsTest>(
        parent: const {},
        own: {
          'test_sizePaddingAndViewInsets_lint': (t) => t._sizePaddingAndViewInsetsLint(),
          'test_dedicatedMethods_noLint': (t) => t._dedicatedMethodsNoLint(),
          'test_otherMediaQueryProperty_noLint': (t) => t._otherMediaQueryPropertyNoLint(),
        },
      );

  @override
  void setUp() {
    rule = UseDedicatedMediaQueryMethods();
    super.setUp();
  }

  Future<void> _sizePaddingAndViewInsetsLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.of(context).size;
  MediaQuery.of(context).padding;
  MediaQuery.of(context).viewInsets;
}
''';

    await assertDiagnostics(source, [
      for (final read in [
        'MediaQuery.of(context).size',
        'MediaQuery.of(context).padding',
        'MediaQuery.of(context).viewInsets',
      ])
        lint(source.indexOf(read), read.length),
    ]);
  }

  Future<void> _dedicatedMethodsNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.sizeOf(context);
  MediaQuery.paddingOf(context);
  MediaQuery.viewInsetsOf(context);
}
''');
  }

  Future<void> _otherMediaQueryPropertyNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.of(context).hashCode;
}
''');
  }
}

final class _PreferSliverPrefixTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_PreferSliverPrefixTest)> get _allCases =>
      caseSet<_PreferSliverPrefixTest>(
        parent: const {},
        own: {
          'test_statelessWidgetReturningSliverWithoutPrefix_lint': (t) =>
              t._statelessWidgetReturningSliverWithoutPrefixLint(),
          'test_sliverNameOnlyInsideClassName_lint': (t) => t._sliverNameOnlyInsideClassNameLint(),
          'test_prefixedStatelessWidget_noLint': (t) => t._prefixedStatelessWidgetNoLint(),
          'test_statefulWidgetReturningSliver_lint': (t) => t._statefulWidgetReturningSliverLint(),
          'test_boxWidgetReturn_noLint': (t) => t._boxWidgetReturnNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PreferSliverPrefix();
    super.setUp();
  }

  Future<void> _statelessWidgetReturningSliverWithoutPrefixLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class FeedList extends StatelessWidget {
  const FeedList();

  @override
  Widget build(BuildContext context) => const SliverList();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('FeedList'), 'FeedList'.length)]);
  }

  Future<void> _sliverNameOnlyInsideClassNameLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class FeedSliverList extends StatelessWidget {
  const FeedSliverList();

  @override
  Widget build(BuildContext context) => const SliverList();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FeedSliverList'), 'FeedSliverList'.length),
    ]);
  }

  Future<void> _prefixedStatelessWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SliverFeedList extends StatelessWidget {
  const SliverFeedList();

  @override
  Widget build(BuildContext context) => const SliverList();
}
''');
  }

  Future<void> _statefulWidgetReturningSliverLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class FeedSection extends StatefulWidget {
  const FeedSection();

  @override
  State<FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<FeedSection> {
  @override
  Widget build(BuildContext context) => const SliverList();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('FeedSection'), 'FeedSection'.length)]);
  }

  Future<void> _boxWidgetReturnNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class FeedBox extends StatelessWidget {
  const FeedBox();

  @override
  Widget build(BuildContext context) => const BoxWidget();
}
''');
  }
}

final class _ConsistentUpdateRenderObjectTest extends _FlutterRuleTest {
  static Map<String, Future<void> Function(_ConsistentUpdateRenderObjectTest)> get _allCases =>
      caseSet<_ConsistentUpdateRenderObjectTest>(
        parent: const {},
        own: {
          'test_constructorFieldMissingFromUpdateRenderObject_lint': (t) =>
              t._constructorFieldMissingFromUpdateRenderObjectLint(),
          'test_allConstructorFieldsAssigned_noLint': (t) =>
              t._allConstructorFieldsAssignedNoLint(),
          'test_nonConstructorField_noLint': (t) => t._nonConstructorFieldNoLint(),
        },
      );

  @override
  void setUp() {
    rule = ConsistentUpdateRenderObject();
    super.setUp();
  }

  Future<void> _constructorFieldMissingFromUpdateRenderObjectLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class CounterRenderObject extends RenderObject {
  int count = 0;
  int step = 0;
}

class CounterWidget extends LeafRenderObjectWidget {
  const CounterWidget({required this.count, required this.step});

  final int count;
  final int step;

  @override
  CounterRenderObject createRenderObject(BuildContext context) => CounterRenderObject();

  @override
  void updateRenderObject(BuildContext context, CounterRenderObject renderObject) {
    renderObject.count = count;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('step;'), 'step'.length)]);
  }

  Future<void> _allConstructorFieldsAssignedNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class CounterRenderObject extends RenderObject {
  int count = 0;
  int step = 0;
}

class CounterWidget extends LeafRenderObjectWidget {
  const CounterWidget({required this.count, required this.step});

  final int count;
  final int step;

  @override
  CounterRenderObject createRenderObject(BuildContext context) => CounterRenderObject()
    ..count = count
    ..step = step;

  @override
  void updateRenderObject(BuildContext context, CounterRenderObject renderObject) {
    renderObject.count = count;
    renderObject.step = step;
  }
}
''');
  }

  Future<void> _nonConstructorFieldNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class CounterRenderObject extends RenderObject {
  int count = 0;
}

class CounterWidget extends LeafRenderObjectWidget {
  const CounterWidget({required this.count});

  final int count;
  final int derived = 0;

  @override
  CounterRenderObject createRenderObject(BuildContext context) => CounterRenderObject();

  @override
  void updateRenderObject(BuildContext context, CounterRenderObject renderObject) {
    renderObject.count = count;
  }
}
''');
  }
}
