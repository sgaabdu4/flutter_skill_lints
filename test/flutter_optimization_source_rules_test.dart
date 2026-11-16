import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/flutter_optimization_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_FlutterKeyCreatedInBuildTest>(
    'FlutterKeyCreatedInBuildTest',
    _FlutterKeyCreatedInBuildTest.new,
    _FlutterKeyCreatedInBuildTest._allCases,
  );
  analysisRuleSuite<_FlutterUniqueOrGlobalKeyTest>(
    'FlutterUniqueOrGlobalKeyTest',
    _FlutterUniqueOrGlobalKeyTest.new,
    _FlutterUniqueOrGlobalKeyTest._allCases,
  );
  analysisRuleSuite<_FlutterOpacityWidgetTest>(
    'FlutterOpacityWidgetTest',
    _FlutterOpacityWidgetTest.new,
    _FlutterOpacityWidgetTest._allCases,
  );
  analysisRuleSuite<_FlutterSaveLayerFilterTest>(
    'FlutterSaveLayerFilterTest',
    _FlutterSaveLayerFilterTest.new,
    _FlutterSaveLayerFilterTest._allCases,
  );
  analysisRuleSuite<_FlutterClipSaveLayerTest>(
    'FlutterClipSaveLayerTest',
    _FlutterClipSaveLayerTest.new,
    _FlutterClipSaveLayerTest._allCases,
  );
  analysisRuleSuite<_FlutterIntrinsicLayoutTest>(
    'FlutterIntrinsicLayoutTest',
    _FlutterIntrinsicLayoutTest.new,
    _FlutterIntrinsicLayoutTest._allCases,
  );
  analysisRuleSuite<_FlutterAnimatedBuilderChildTest>(
    'FlutterAnimatedBuilderChildTest',
    _FlutterAnimatedBuilderChildTest.new,
    _FlutterAnimatedBuilderChildTest._allCases,
  );
  analysisRuleSuite<_FlutterWidgetOperatorEqualsTest>(
    'FlutterWidgetOperatorEqualsTest',
    _FlutterWidgetOperatorEqualsTest.new,
    _FlutterWidgetOperatorEqualsTest._allCases,
  );
}

abstract class _FlutterOptimizationRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    for (final name in const ['undefined_unqualified_name_read_not_found'])
      errorCodeByUniqueName(name)!,
  ];

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

final class _FlutterKeyCreatedInBuildTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterKeyCreatedInBuildTest)> get _allCases =>
      caseSet<_FlutterKeyCreatedInBuildTest>(
        parent: const {},
        own: {
          'test_allowsStableFieldKey': (t) => t._allowsStableFieldKey(),
          'test_reportsKeyLocalInBuild': (t) => t._reportsKeyLocalInBuild(),
        },
      );

  @override
  String get ruleName => 'flutter_key_created_in_build';

  Future<void> _allowsStableFieldKey() async {
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

  Future<void> _reportsKeyLocalInBuild() async {
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

final class _FlutterUniqueOrGlobalKeyTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterUniqueOrGlobalKeyTest)> get _allCases =>
      caseSet<_FlutterUniqueOrGlobalKeyTest>(
        parent: const {},
        own: {
          'test_allowsValueKey': (t) => t._allowsValueKey(),
          'test_reportsGlobalKey': (t) => t._reportsGlobalKey(),
          'test_allowsGlobalKeyInKeyRegistry': (t) => t._allowsGlobalKeyInKeyRegistry(),
          'test_allowsTypedStateAccessGlobalKey': (t) => t._allowsTypedStateAccessGlobalKey(),
          'test_allowsRepaintBoundaryCaptureGlobalKey': (t) =>
              t._allowsRepaintBoundaryCaptureGlobalKey(),
          'test_allowsGlobalKeyInTests': (t) => t._allowsGlobalKeyInTests(),
          'test_reportsUniqueKey': (t) => t._reportsUniqueKey(),
        },
      );

  @override
  String get ruleName => 'flutter_unique_or_global_key';

  Future<void> _allowsValueKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final rowKey = ValueKey('row');
''');
  }

  Future<void> _reportsGlobalKey() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final rowKey = GlobalKey();
''', 'GlobalKey');
  }

  Future<void> _allowsGlobalKeyInKeyRegistry() async {
    await assertAllowsInFile('$testPackageLibPath/core/navigation/app_widget_keys.dart', r'''
import 'package:flutter/widgets.dart';

abstract final class AppWidgetKeys {
  static final homeHeader = GlobalKey();
}
''');
  }

  Future<void> _allowsTypedStateAccessGlobalKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

abstract final class SnackBarUtils {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}
''');
  }

  Future<void> _allowsRepaintBoundaryCaptureGlobalKey() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

class SharePreviewSheet {
  SharePreviewSheet() : _shareableCardKey = GlobalKey();

  final GlobalKey _shareableCardKey;
}
''');
  }

  Future<void> _allowsGlobalKeyInTests() async {
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

  Future<void> _reportsUniqueKey() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final rowKey = UniqueKey();
''', 'UniqueKey');
  }
}

final class _FlutterOpacityWidgetTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterOpacityWidgetTest)> get _allCases =>
      caseSet<_FlutterOpacityWidgetTest>(
        parent: const {},
        own: {
          'test_allowsFadeTransition': (t) => t._allowsFadeTransition(),
          'test_reportsOpacity': (t) => t._reportsOpacity(),
        },
      );

  @override
  String get ruleName => 'flutter_opacity_widget';

  Future<void> _allowsFadeTransition() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = FadeTransition(opacity: animation, child: child);
''');
  }

  Future<void> _reportsOpacity() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = Opacity(opacity: 0.5, child: child);
''', 'Opacity');
  }
}

final class _FlutterSaveLayerFilterTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterSaveLayerFilterTest)> get _allCases =>
      caseSet<_FlutterSaveLayerFilterTest>(
        parent: const {},
        own: {
          'test_allowsContainerWithoutFilter': (t) => t._allowsContainerWithoutFilter(),
          'test_reportsColorFiltered': (t) => t._reportsColorFiltered(),
          'test_reportsShaderMask': (t) => t._reportsShaderMask(),
        },
      );

  @override
  String get ruleName => 'flutter_save_layer_filter';

  Future<void> _allowsContainerWithoutFilter() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = Widget();
''');
  }

  Future<void> _reportsColorFiltered() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ColorFiltered(colorFilter: filter, child: child);
''', 'ColorFiltered');
  }

  Future<void> _reportsShaderMask() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ShaderMask(shaderCallback: shader, child: child);
''', 'ShaderMask');
  }
}

final class _FlutterClipSaveLayerTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterClipSaveLayerTest)> get _allCases =>
      caseSet<_FlutterClipSaveLayerTest>(
        parent: const {},
        own: {
          'test_allowsAntiAliasClip': (t) => t._allowsAntiAliasClip(),
          'test_reportsAntiAliasWithSaveLayer': (t) => t._reportsAntiAliasWithSaveLayer(),
        },
      );

  @override
  String get ruleName => 'flutter_clip_save_layer';

  Future<void> _allowsAntiAliasClip() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = ClipRRect(clipBehavior: Clip.antiAlias, child: child);
''');
  }

  Future<void> _reportsAntiAliasWithSaveLayer() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = ClipRRect(
  clipBehavior: Clip.antiAliasWithSaveLayer,
  child: child,
);
''', 'Clip.antiAliasWithSaveLayer');
  }
}

final class _FlutterIntrinsicLayoutTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterIntrinsicLayoutTest)> get _allCases =>
      caseSet<_FlutterIntrinsicLayoutTest>(
        parent: const {},
        own: {
          'test_allowsSizedBox': (t) => t._allowsSizedBox(),
          'test_reportsIntrinsicHeight': (t) => t._reportsIntrinsicHeight(),
          'test_reportsIntrinsicWidth': (t) => t._reportsIntrinsicWidth(),
        },
      );

  @override
  String get ruleName => 'flutter_intrinsic_layout';

  Future<void> _allowsSizedBox() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = SizedBox(height: 72, child: child);
''');
  }

  Future<void> _reportsIntrinsicHeight() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = IntrinsicHeight(child: child);
''', 'IntrinsicHeight');
  }

  Future<void> _reportsIntrinsicWidth() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = IntrinsicWidth(child: child);
''', 'IntrinsicWidth');
  }
}

final class _FlutterAnimatedBuilderChildTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterAnimatedBuilderChildTest)> get _allCases =>
      caseSet<_FlutterAnimatedBuilderChildTest>(
        parent: const {},
        own: {
          'test_allowsChildParameter': (t) => t._allowsChildParameter(),
          'test_reportsMissingChildParameter': (t) => t._reportsMissingChildParameter(),
        },
      );

  @override
  String get ruleName => 'flutter_animated_builder_child';

  Future<void> _allowsChildParameter() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

final widget = AnimatedBuilder(
  animation: animation,
  child: child,
  builder: builder,
);
''');
  }

  Future<void> _reportsMissingChildParameter() async {
    await assertReports(r'''
import 'package:flutter/widgets.dart';

final widget = AnimatedBuilder(
  animation: animation,
  builder: builder,
);
''', 'AnimatedBuilder');
  }
}

final class _FlutterWidgetOperatorEqualsTest extends _FlutterOptimizationRuleTest {
  static Map<String, Future<void> Function(_FlutterWidgetOperatorEqualsTest)> get _allCases =>
      caseSet<_FlutterWidgetOperatorEqualsTest>(
        parent: const {},
        own: {
          'test_allowsNonWidgetEquality': (t) => t._allowsNonWidgetEquality(),
          'test_reportsStatelessWidgetEquality': (t) => t._reportsStatelessWidgetEquality(),
        },
      );

  @override
  String get ruleName => 'flutter_widget_operator_equals';

  Future<void> _allowsNonWidgetEquality() async {
    await assertAllows(r'''
class Model {
  @override
  bool operator ==(Object other) => identical(this, other);
}
''');
  }

  Future<void> _reportsStatelessWidgetEquality() async {
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
