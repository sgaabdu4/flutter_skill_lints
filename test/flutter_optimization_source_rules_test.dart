// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/flutter_optimization_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterKeyCreatedInBuildTest);
    defineReflectiveTests(FlutterUniqueOrGlobalKeyTest);
    defineReflectiveTests(FlutterOpacityWidgetTest);
    defineReflectiveTests(FlutterSaveLayerFilterTest);
    defineReflectiveTests(FlutterClipSaveLayerTest);
    defineReflectiveTests(FlutterIntrinsicLayoutTest);
    defineReflectiveTests(FlutterAnimatedBuilderChildTest);
    defineReflectiveTests(FlutterWidgetOperatorEqualsTest);
  });
}

abstract class _FlutterOptimizationRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  void setUp() {
    rule = flutterOptimizationSourceRules.singleWhere((rule) => rule.name == ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> assertReports(String source, String needle, {bool lineStart = false}) async {
    final analyzedSource = _withIgnorePrefix(source);
    await assertDiagnostics(analyzedSource, [
      lintFor(analyzedSource, needle, lineStart: lineStart),
    ]);
  }

  Future<void> assertAllows(String source) async {
    await assertNoDiagnostics(_withIgnorePrefix(source));
  }

  Future<void> assertAllowsInFile(String filePath, String source) async {
    newFile(filePath, _withIgnorePrefix(source));
    await assertNoDiagnosticsInFile(filePath);
  }

  T lintFor<T>(String source, String needle, {bool lineStart = false}) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: ruleName) as T;
  }

  String _withIgnorePrefix(String source) => '''
// ignore_for_file: const_initialized_with_non_constant_value, equal_elements_in_set, extends_non_class, hash_and_equals, invalid_override, missing_override_of_must_be_overridden, non_abstract_class_inherits_abstract_member, undefined_class, undefined_function, undefined_identifier, undefined_method, unused_element, unused_import
$source''';

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Key {
  const Key(String value);
}
class LocalKey extends Key {
  const LocalKey(String value) : super(value);
}
class ValueKey<T> extends LocalKey {
  const ValueKey(T value) : super('');
}
class ObjectKey extends LocalKey {
  const ObjectKey(Object? value) : super('');
}
class UniqueKey extends LocalKey {
  UniqueKey() : super('');
}
class GlobalKey<T> extends Key {
  GlobalKey({String? debugLabel}) : super('');
}
class Widget {
  const Widget({Key? key});
}
class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => const Widget();
}
class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}
class Animation<T> {}
class AnimatedBuilder extends Widget {
  const AnimatedBuilder({Object? animation, Object? builder, Widget? child});
}
class FadeTransition extends Widget {
  const FadeTransition({Object? opacity, Widget? child});
}
class Opacity extends Widget {
  const Opacity({double? opacity, Widget? child});
}
class ShaderMask extends Widget {
  const ShaderMask({Object? shaderCallback, Widget? child});
}
class ColorFiltered extends Widget {
  const ColorFiltered({Object? colorFilter, Widget? child});
}
class ColorFilter {
  const ColorFilter.mode(Object color, Object blendMode);
}
class Clip {
  static const antiAliasWithSaveLayer = Clip();
  static const antiAlias = Clip();
  const Clip();
}
class ClipRRect extends Widget {
  const ClipRRect({Clip? clipBehavior, Widget? child});
}
class IntrinsicWidth extends Widget {
  const IntrinsicWidth({Widget? child});
}
class IntrinsicHeight extends Widget {
  const IntrinsicHeight({Widget? child});
}
class SizedBox extends Widget {
  const SizedBox({double? height, Widget? child});
}
class ScaffoldMessengerState {}
class RepaintBoundary extends Widget {
  const RepaintBoundary({Key? key, Widget? child}) : super(key: key);
}
''');
  }
}

@reflectiveTest
final class FlutterKeyCreatedInBuildTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_key_created_in_build';

  Future<void> test_allowsStableFieldKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final rowKey = ValueKey('row');

class Tile extends StatelessWidget {
  const Tile({super.key});

  @override
  Widget build(BuildContext context) {
    return Widget(key: rowKey);
  }
}
''');
  }

  Future<void> test_reportsKeyLocalInBuild() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile({super.key});

  @override
  Widget build(BuildContext context) {
    final rowKey = ValueKey('row');
    return Widget(key: rowKey);
  }
}
''', 'ValueKey');
  }
}

@reflectiveTest
final class FlutterUniqueOrGlobalKeyTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_unique_or_global_key';

  Future<void> test_allowsValueKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final rowKey = ValueKey('row');
''');
  }

  Future<void> test_reportsGlobalKey() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final rowKey = GlobalKey();
''', 'GlobalKey');
  }

  Future<void> test_allowsGlobalKeyInKeyRegistry() async {
    await assertAllowsInFile('$testPackageLibPath/core/navigation/app_widget_keys.dart', r'''
import 'package:flutter/widgets.dart';

abstract final class AppWidgetKeys {
  static final homeHeader = GlobalKey();
}
''');
  }

  Future<void> test_allowsTypedStateAccessGlobalKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

abstract final class SnackBarUtils {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}
''');
  }

  Future<void> test_allowsRepaintBoundaryCaptureGlobalKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

class SharePreviewSheet {
  SharePreviewSheet() : _shareableCardKey = GlobalKey();

  final GlobalKey _shareableCardKey;
}
''');
  }

  Future<void> test_allowsGlobalKeyInTests() async {
    final filePath = '$testPackageRootPath/test/core/mixins/lifecycle_mixin_test.dart';
    newFile(
      filePath,
      _withIgnorePrefix(r'''
import 'package:flutter/widgets.dart';

final firstKey = GlobalKey(debugLabel: 'first-target');
final missingKey = GlobalKey(debugLabel: 'missing-target');
'''),
    );

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsUniqueKey() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final rowKey = UniqueKey();
''', 'UniqueKey');
  }
}

@reflectiveTest
final class FlutterOpacityWidgetTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_opacity_widget';

  Future<void> test_allowsFadeTransition() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = FadeTransition(opacity: animation, child: child);
''');
  }

  Future<void> test_reportsOpacity() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = Opacity(opacity: 0.5, child: child);
''', 'Opacity');
  }
}

@reflectiveTest
final class FlutterSaveLayerFilterTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_save_layer_filter';

  Future<void> test_allowsContainerWithoutFilter() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = Widget();
''');
  }

  Future<void> test_reportsColorFiltered() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ColorFiltered(colorFilter: filter, child: child);
''', 'ColorFiltered');
  }

  Future<void> test_reportsShaderMask() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ShaderMask(shaderCallback: shader, child: child);
''', 'ShaderMask');
  }
}

@reflectiveTest
final class FlutterClipSaveLayerTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_clip_save_layer';

  Future<void> test_allowsAntiAliasClip() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = ClipRRect(clipBehavior: Clip.antiAlias, child: child);
''');
  }

  Future<void> test_reportsAntiAliasWithSaveLayer() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ClipRRect(
  clipBehavior: Clip.antiAliasWithSaveLayer,
  child: child,
);
''', 'Clip.antiAliasWithSaveLayer');
  }
}

@reflectiveTest
final class FlutterIntrinsicLayoutTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_intrinsic_layout';

  Future<void> test_allowsSizedBox() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = SizedBox(height: 72, child: child);
''');
  }

  Future<void> test_reportsIntrinsicHeight() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = IntrinsicHeight(child: child);
''', 'IntrinsicHeight');
  }

  Future<void> test_reportsIntrinsicWidth() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = IntrinsicWidth(child: child);
''', 'IntrinsicWidth');
  }
}

@reflectiveTest
final class FlutterAnimatedBuilderChildTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_animated_builder_child';

  Future<void> test_allowsChildParameter() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = AnimatedBuilder(
  animation: animation,
  child: child,
  builder: builder,
);
''');
  }

  Future<void> test_reportsMissingChildParameter() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = AnimatedBuilder(
  animation: animation,
  builder: builder,
);
''', 'AnimatedBuilder');
  }
}

@reflectiveTest
final class FlutterWidgetOperatorEqualsTest extends _FlutterOptimizationRuleTest {
  @override
  String get ruleName => 'flutter_widget_operator_equals';

  Future<void> test_allowsNonWidgetEquality() async {
    await assertAllows(r'''
class Model {
  @override
  bool operator ==(Object other) => identical(this, other);
}
''');
  }

  Future<void> test_reportsStatelessWidgetEquality() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

class Tile extends StatelessWidget {
  const Tile({super.key});

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  Widget build(BuildContext context) => const Widget();
}
''', 'operator ==');
  }
}
