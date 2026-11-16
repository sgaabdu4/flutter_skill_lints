import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_on_reorder_item_index_semantics.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<UseOnReorderItemIndexSemanticsTest>(
    'UseOnReorderItemIndexSemanticsTest',
    UseOnReorderItemIndexSemanticsTest.new,
    {
      'test_frameworkOnReorder_lint': (t) => t._frameworkOnReorderLint(),
      'test_customOnReorder_noLint': (t) => t._customOnReorderNoLint(),
      'test_onReorderItemInverseAdapter_lint': (t) => t._onReorderItemInverseAdapterLint(),
      'test_onReorderItemPassThrough_noLint': (t) => t._onReorderItemPassThroughNoLint(),
      'test_downstreamReorderLegacyAdjustment_lint': (t) =>
          t._downstreamReorderLegacyAdjustmentLint(),
      'test_downstreamReorderDirectInsert_noLint': (t) => t._downstreamReorderDirectInsertNoLint(),
      'test_nonReorderFunctionWithSameParams_noLint': (t) =>
          t._nonReorderFunctionWithSameParamsNoLint(),
    },
  );
}

class UseOnReorderItemIndexSemanticsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseOnReorderItemIndexSemantics();
    super.setUp();
  }

  T lintFor<T>(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length) as T;
  }

  Future<void> _frameworkOnReorderLint() async {
    const source = r'''
typedef ReorderCallback = void Function(int oldIndex, int newIndex);
class ReorderableListView {
  ReorderableListView.builder({required int itemCount, ReorderCallback? onReorder});
}
void f() {
  ReorderableListView.builder(itemCount: 1, onReorder: (oldIndex, newIndex) {});
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('onReorder:'), 'onReorder'.length)]);
  }

  Future<void> _customOnReorderNoLint() async {
    await assertNoDiagnostics(r'''
typedef ReorderCallback = void Function(int oldIndex, int newIndex);
class BentoReorderableList {
  BentoReorderableList({ReorderCallback? onReorder});
}
void f() {
  BentoReorderableList(onReorder: (oldIndex, newIndex) {});
}
''');
  }

  Future<void> _onReorderItemInverseAdapterLint() async {
    const source = r'''
typedef ReorderCallback = void Function(int oldIndex, int newIndex);
class SliverReorderableList {
  SliverReorderableList({ReorderCallback? onReorderItem});
}
void save(int oldIndex, int newIndex) {}
void f() {
  SliverReorderableList(
    onReorderItem: (oldIndex, newIndex) =>
        save(oldIndex, newIndex > oldIndex ? newIndex + 1 : newIndex),
  );
}
''';

    await assertDiagnostics(source, [
      lintFor(source, 'newIndex > oldIndex ? newIndex + 1 : newIndex'),
    ]);
  }

  Future<void> _onReorderItemPassThroughNoLint() async {
    await assertNoDiagnostics(r'''
typedef ReorderCallback = void Function(int oldIndex, int newIndex);
class SliverReorderableList {
  SliverReorderableList({ReorderCallback? onReorderItem});
}
void save(int oldIndex, int newIndex) {}
void f() {
  SliverReorderableList(onReorderItem: (oldIndex, newIndex) => save(oldIndex, newIndex));
}
''');
  }

  Future<void> _downstreamReorderLegacyAdjustmentLint() async {
    const source = r'''
void reorderSelectedExercises(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) newIndex -= 1;
  _sink(newIndex);
}
void _sink(Object? value) {}
''';

    await assertDiagnostics(source, [lintFor(source, 'if (oldIndex < newIndex) newIndex -= 1;')]);
  }

  Future<void> _downstreamReorderDirectInsertNoLint() async {
    await assertNoDiagnostics(r'''
void reorderSelectedExercises(int oldIndex, int newIndex) {
  _sink(newIndex);
}
void _sink(Object? value) {}
''');
  }

  Future<void> _nonReorderFunctionWithSameParamsNoLint() async {
    await assertNoDiagnostics(r'''
void compareIndexes(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) newIndex -= 1;
  print(newIndex);
}
''');
  }
}
