// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/material_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WidgetMaterialBoundaryTest);
    defineReflectiveTests(AtomWidgetLayerDependencyTest);
  });
}

@reflectiveTest
final class WidgetMaterialBoundaryTest extends AnalysisRuleTest {
  static const _ruleName = 'widget_material_boundary';

  @override
  void setUp() {
    rule = materialSourceRules.singleWhere((rule) => rule.name == _ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> test_reportsCoreOrganismMaterialSurface() async {
    final filePath = '$testPackageLibPath/core/widgets/organisms/dashboard/empty_workout_card.dart';
    final source = _withFlutterImport(r'''
class EmptyWorkoutCardSurface extends StatelessWidget {
  const EmptyWorkoutCardSurface();

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Ink(child: InkWell(child: const Widget())),
    );
  }
}
''');

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      _lintFor(source, 'Material('),
      _lintFor(source, 'Ink('),
      _lintFor(source, 'InkWell('),
    ]);
  }

  Future<void> test_reportsCoreOrganismInkWellSurface() async {
    final filePath = '$testPackageLibPath/core/widgets/organisms/dashboard/empty_workout_card.dart';
    final source = _withFlutterImport(r'''
class EmptyWorkoutCardSurface extends StatelessWidget {
  const EmptyWorkoutCardSurface();

  @override
  Widget build(BuildContext context) {
    return InkWell(child: const Widget());
  }
}
''');

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [_lintFor(source, 'InkWell(')]);
  }

  Future<void> test_reportsCoreMoleculeInkSurface() async {
    final filePath = '$testPackageLibPath/core/widgets/molecules/mode_chip.dart';
    final source = _withFlutterImport(r'''
class ModeChip extends StatelessWidget {
  const ModeChip();

  @override
  Widget build(BuildContext context) => Ink(child: const Widget());
}
''');

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [_lintFor(source, 'Ink(')]);
  }

  Future<void> test_reportsFeatureWidgetMaterialSurface() async {
    final filePath = '$testPackageLibPath/features/exercises/presentation/widgets/workout_row.dart';
    final source = _withFlutterImport(r'''
class WorkoutRow extends StatelessWidget {
  const WorkoutRow();

  @override
  Widget build(BuildContext context) {
    return Material(child: Ink(child: InkWell(child: const Widget())));
  }
}
''');

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      _lintFor(source, 'Material('),
      _lintFor(source, 'Ink('),
      _lintFor(source, 'InkWell('),
    ]);
  }

  Future<void> test_allowsAtomMaterialOwner() async {
    final filePath = '$testPackageLibPath/core/widgets/atoms/bento_card_widget.dart';
    final source = _withFlutterImport(r'''
class BentoCard extends StatelessWidget {
  const BentoCard();

  @override
  Widget build(BuildContext context) {
    return Material(child: Ink(child: InkWell(child: const Widget())));
  }
}
''');

    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsAppShellMaterialOwner() async {
    final filePath = '$testPackageLibPath/app.dart';
    final source = _withFlutterImport(r'''
class App extends StatelessWidget {
  const App();

  @override
  Widget build(BuildContext context) => Material(child: const Widget());
}
''');

    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsTests() async {
    const filePath = 'test/core/widgets/organisms/empty_workout_card_test.dart';
    final source = _withFlutterImport(r'''
void main() {
  final widget = Material(child: const Widget());
  expect(widget, isNotNull);
}
''');

    newFile('$testPackageRootPath/$filePath', source);

    await assertNoDiagnosticsInFile('$testPackageRootPath/$filePath');
  }

  T _lintFor<T>(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) throw StateError('Needle not found: $needle');
    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: _ruleName) as T;
  }

  String _withFlutterImport(String source) => '''
// ignore_for_file: const_initialized_with_non_constant_value, extends_non_class, final_not_initialized, override_on_non_overriding_member, undefined_function, undefined_identifier, unused_local_variable
import 'package:flutter/material.dart';

$source''';

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/material.dart', r'''
class BuildContext {}

class Widget {
  const Widget();
}

class StatelessWidget extends Widget {
  const StatelessWidget();

  Widget build(BuildContext context) => const Widget();
}

class Material extends Widget {
  const Material({Widget? child});
}

class Ink extends Widget {
  const Ink({Widget? child});
}

class InkWell extends Widget {
  const InkWell({Widget? child});
}
''');
  }
}

@reflectiveTest
final class AtomWidgetLayerDependencyTest extends AnalysisRuleTest {
  static const _ruleName = 'atom_widget_layer_dependency';

  @override
  void setUp() {
    rule = materialSourceRules.singleWhere((rule) => rule.name == _ruleName);
    super.setUp();
  }

  Future<void> test_reportsAtomImportingFeaturePresentationWidget() async {
    final importedPath =
        '$testPackageLibPath/features/exercises/presentation/widgets/workout_row.dart';
    newFile(importedPath, 'class WorkoutRow {}');

    final filePath = '$testPackageLibPath/core/widgets/atoms/workout_row_surface.dart';
    const source = r'''
import '../../../features/exercises/presentation/widgets/workout_row.dart';

class WorkoutRowSurface {
  WorkoutRowSurface(WorkoutRow row);
}
''';

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      _lintFor(source, "import '../../../features", _ruleName),
    ]);
  }

  Future<void> test_reportsAtomImportingMolecule() async {
    final importedPath = '$testPackageLibPath/core/widgets/molecules/mode_chip.dart';
    newFile(importedPath, 'class ModeChip {}');

    final filePath = '$testPackageLibPath/core/widgets/atoms/mode_chip_surface.dart';
    const source = r'''
import '../molecules/mode_chip.dart';

class ModeChipSurface {
  ModeChipSurface(ModeChip chip);
}
''';

    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [_lintFor(source, "import '../molecules", _ruleName)]);
  }

  Future<void> test_allowsAtomImportingAtom() async {
    final importedPath = '$testPackageLibPath/core/widgets/atoms/app_text.dart';
    newFile(importedPath, 'class AppText {}');

    final filePath = '$testPackageLibPath/core/widgets/atoms/active_routine_chip.dart';
    const source = r'''
import 'app_text.dart';

class ActiveRoutineChip {
  ActiveRoutineChip(AppText text);
}
''';

    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }

  T _lintFor<T>(String source, String needle, String ruleName) {
    final offset = source.indexOf(needle);
    if (offset < 0) throw StateError('Needle not found: $needle');
    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: ruleName) as T;
  }
}
