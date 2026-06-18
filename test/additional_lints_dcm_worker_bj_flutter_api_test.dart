// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/consistent_update_render_object.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_dedicated_media_query_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sliver_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDedicatedMediaQueryMethodsTest);
    defineReflectiveTests(PreferSliverPrefixTest);
    defineReflectiveTests(ConsistentUpdateRenderObjectTest);
  });
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

@reflectiveTest
final class PreferDedicatedMediaQueryMethodsTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferDedicatedMediaQueryMethods();
    super.setUp();
  }

  Future<void> test_sizePaddingAndViewInsets_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.of(context).size;
  MediaQuery.of(context).padding;
  MediaQuery.of(context).viewInsets;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('size'), 'size'.length),
      lint(source.indexOf('padding'), 'padding'.length),
      lint(source.indexOf('viewInsets'), 'viewInsets'.length),
    ]);
  }

  Future<void> test_dedicatedMethods_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.sizeOf(context);
  MediaQuery.paddingOf(context);
  MediaQuery.viewInsetsOf(context);
}
''');
  }

  Future<void> test_otherMediaQueryProperty_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void build(BuildContext context) {
  MediaQuery.of(context).hashCode;
}
''');
  }
}

@reflectiveTest
final class PreferSliverPrefixTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = PreferSliverPrefix();
    super.setUp();
  }

  Future<void> test_statelessWidgetReturningSliverWithoutPrefix_lint() async {
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

  Future<void> test_sliverNameOnlyInsideClassName_lint() async {
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

  Future<void> test_prefixedStatelessWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class SliverFeedList extends StatelessWidget {
  const SliverFeedList();

  @override
  Widget build(BuildContext context) => const SliverList();
}
''');
  }

  Future<void> test_statefulWidgetReturningSliver_lint() async {
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

  Future<void> test_boxWidgetReturn_noLint() async {
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

@reflectiveTest
final class ConsistentUpdateRenderObjectTest extends _FlutterRuleTest {
  @override
  void setUp() {
    rule = ConsistentUpdateRenderObject();
    super.setUp();
  }

  Future<void> test_constructorFieldMissingFromUpdateRenderObject_lint() async {
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

  Future<void> test_allConstructorFieldsAssigned_noLint() async {
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

  Future<void> test_nonConstructorField_noLint() async {
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
