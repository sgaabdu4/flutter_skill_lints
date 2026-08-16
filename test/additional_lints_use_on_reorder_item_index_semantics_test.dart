// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_on_reorder_item_index_semantics.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() => defineReflectiveTests(UseOnReorderItemIndexSemanticsTest));
}

@reflectiveTest
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

  Future<void> test_frameworkOnReorder_lint() async {
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

  Future<void> test_customOnReorder_noLint() async {
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

  Future<void> test_onReorderItemInverseAdapter_lint() async {
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

  Future<void> test_onReorderItemPassThrough_noLint() async {
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

  Future<void> test_downstreamReorderLegacyAdjustment_lint() async {
    const source = r'''
void reorderSelectedExercises(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) newIndex -= 1;
  _sink(newIndex);
}
void _sink(Object? value) {}
''';

    await assertDiagnostics(source, [lintFor(source, 'if (oldIndex < newIndex) newIndex -= 1;')]);
  }

  Future<void> test_downstreamReorderDirectInsert_noLint() async {
    await assertNoDiagnostics(r'''
void reorderSelectedExercises(int oldIndex, int newIndex) {
  _sink(newIndex);
}
void _sink(Object? value) {}
''');
  }

  Future<void> test_nonReorderFunctionWithSameParams_noLint() async {
    await assertNoDiagnostics(r'''
void compareIndexes(int oldIndex, int newIndex) {
  if (oldIndex < newIndex) newIndex -= 1;
  print(newIndex);
}
''');
  }
}
