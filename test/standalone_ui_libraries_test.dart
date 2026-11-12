import 'dart:math' as math;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_throw.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_sliver_prefix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_sliver_prefix.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/rules/avoid_flutter_host_driver_imports.dart';
import 'package:flutter_skill_lints/src/rules/dialog_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterUiLibraryUriTest', () {
    test('test_acceptsFrameworkAndStandalonePackages', () {
      for (final uri in const [
        'package:flutter/widgets.dart',
        'package:material_ui/material_ui.dart',
        'package:material_ui/src/button.dart',
        'package:cupertino_ui/cupertino_ui.dart',
      ]) {
        expect(isFlutterUiLibraryUri(uri), isTrue, reason: uri);
      }
    });

    test('test_rejectsLookalikePackages', () {
      for (final uri in const [
        'package:flutter_riverpod/flutter_riverpod.dart',
        'package:material_ui_kit/kit.dart',
        'package:cupertino_ui2/x.dart',
        'package:my_app/material_ui/x.dart',
        'dart:ui',
      ]) {
        expect(isFlutterUiLibraryUri(uri), isFalse, reason: uri);
      }
    });
  });

  _suite<FireAndForgetModalStandaloneTest>(
    'FireAndForgetModalStandaloneTest',
    FireAndForgetModalStandaloneTest.new,
    {
      'test_materialModalIsTrusted_frameworkImport': (t) =>
          t.materialModalIsTrustedFrameworkImport(),
      'test_materialModalIsTrusted_standaloneImport': (t) =>
          t.materialModalIsTrustedStandaloneImport(),
      'test_cupertinoModalIsTrusted_frameworkImport': (t) =>
          t.cupertinoModalIsTrustedFrameworkImport(),
      'test_cupertinoModalIsTrusted_standaloneImport': (t) =>
          t.cupertinoModalIsTrustedStandaloneImport(),
      'test_appModalLookalikeStillReports_frameworkImport': (t) =>
          t.appModalLookalikeStillReportsFrameworkImport(),
      'test_appModalLookalikeStillReports_standaloneImport': (t) =>
          t.appModalLookalikeStillReportsStandaloneImport(),
    },
  );

  _suite<ModalRouteSettingsStandaloneTest>(
    'ModalRouteSettingsStandaloneTest',
    ModalRouteSettingsStandaloneTest.new,
    {
      'test_reportsMaterialModal_frameworkImport': (t) => t.reportsMaterialModalFrameworkImport(),
      'test_reportsMaterialModal_standaloneImport': (t) => t.reportsMaterialModalStandaloneImport(),
      'test_reportsCupertinoModal_frameworkImport': (t) => t.reportsCupertinoModalFrameworkImport(),
      'test_reportsCupertinoModal_standaloneImport': (t) =>
          t.reportsCupertinoModalStandaloneImport(),
      'test_allowsModalWithRouteSettings_frameworkImport': (t) =>
          t.allowsModalWithRouteSettingsFrameworkImport(),
      'test_allowsModalWithRouteSettings_standaloneImport': (t) =>
          t.allowsModalWithRouteSettingsStandaloneImport(),
    },
  );

  _suite<StyleRawTokenStandaloneTest>(
    'StyleRawTokenStandaloneTest',
    StyleRawTokenStandaloneTest.new,
    {
      'test_reportsRawIconButtonSize_frameworkImport': (t) =>
          t.reportsRawIconButtonSizeFrameworkImport(),
      'test_reportsRawIconButtonSize_standaloneImport': (t) =>
          t.reportsRawIconButtonSizeStandaloneImport(),
      'test_reportsRawMaterialColor_frameworkImport': (t) =>
          t.reportsRawMaterialColorFrameworkImport(),
      'test_reportsRawMaterialColor_standaloneImport': (t) =>
          t.reportsRawMaterialColorStandaloneImport(),
      'test_reportsRawCupertinoColor_frameworkImport': (t) =>
          t.reportsRawCupertinoColorFrameworkImport(),
      'test_reportsRawCupertinoColor_standaloneImport': (t) =>
          t.reportsRawCupertinoColorStandaloneImport(),
    },
  );

  _suite<WatchIntoFrameworkWidgetStandaloneTest>(
    'WatchIntoFrameworkWidgetStandaloneTest',
    WatchIntoFrameworkWidgetStandaloneTest.new,
    {
      'test_allowsWholeValueIntoMaterialApp_frameworkImport': (t) =>
          t.allowsWholeValueIntoMaterialAppFrameworkImport(),
      'test_allowsWholeValueIntoMaterialApp_standaloneImport': (t) =>
          t.allowsWholeValueIntoMaterialAppStandaloneImport(),
      'test_reportsWholeValueIntoAppWidget_frameworkImport': (t) =>
          t.reportsWholeValueIntoAppWidgetFrameworkImport(),
      'test_reportsWholeValueIntoAppWidget_standaloneImport': (t) =>
          t.reportsWholeValueIntoAppWidgetStandaloneImport(),
    },
  );

  _suite<AvoidThrowModalBuilderStandaloneTest>(
    'AvoidThrowModalBuilderStandaloneTest',
    AvoidThrowModalBuilderStandaloneTest.new,
    {
      'test_reportsThrowInModalBuilder_frameworkImport': (t) =>
          t.reportsThrowInModalBuilderFrameworkImport(),
      'test_reportsThrowInModalBuilder_standaloneImport': (t) =>
          t.reportsThrowInModalBuilderStandaloneImport(),
    },
  );

  _suite<UseSliverPrefixStandaloneTest>(
    'UseSliverPrefixStandaloneTest',
    UseSliverPrefixStandaloneTest.new,
    {
      'test_reportsSliverAppBarWithoutPrefix_frameworkImport': (t) =>
          t.reportsSliverAppBarWithoutPrefixFrameworkImport(),
      'test_reportsSliverAppBarWithoutPrefix_standaloneImport': (t) =>
          t.reportsSliverAppBarWithoutPrefixStandaloneImport(),
    },
  );

  _suite<PreferSliverPrefixStandaloneTest>(
    'PreferSliverPrefixStandaloneTest',
    PreferSliverPrefixStandaloneTest.new,
    {
      'test_reportsSliverAppBarWithoutPrefix_frameworkImport': (t) =>
          t.reportsSliverAppBarWithoutPrefixFrameworkImport(),
      'test_reportsSliverAppBarWithoutPrefix_standaloneImport': (t) =>
          t.reportsSliverAppBarWithoutPrefixStandaloneImport(),
    },
  );

  _suite<HostDriverImportsStandaloneTest>(
    'HostDriverImportsStandaloneTest',
    HostDriverImportsStandaloneTest.new,
    {
      'test_reportsMaterialImport_frameworkImport': (t) => t.reportsMaterialImportFrameworkImport(),
      'test_reportsMaterialImport_standaloneImport': (t) =>
          t.reportsMaterialImportStandaloneImport(),
      'test_reportsCupertinoImport_standaloneImport': (t) =>
          t.reportsCupertinoImportStandaloneImport(),
    },
  );
}

void _suite<T extends AnalysisRuleTest>(
  String name,
  T Function() create,
  Map<String, Future<void> Function(T)> cases,
) {
  group(name, () {
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final fixture = create()..setUp();
        try {
          await entry.value(fixture);
        } finally {
          await fixture.tearDown();
        }
      });
    }
  });
}

const _flutterMaterial = "import 'package:flutter/material.dart';";
const _materialUi = "import 'package:material_ui/material_ui.dart';";
const _flutterCupertino = "import 'package:flutter/cupertino.dart';";
const _cupertinoUi = "import 'package:cupertino_ui/cupertino_ui.dart';";

abstract class _StandaloneUiTest extends AnalysisRuleTest {
  AnalysisRule createRule();

  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    for (final name in const [
      'undefined_instance_member_read_not_found',
      'undefined_static_member_read_not_found',
      'undefined_unqualified_name_read_not_found',
      'unused_import',
    ])
      errorCodeByUniqueName(name)!,
  ];

  @override
  void setUp() {
    rule = createRule();
    addUiPackages();
    super.setUp();
  }

  void addUiPackages() {
    newPackage('flutter')
      ..addFile('lib/widgets.dart', _widgetsApi)
      ..addFile('lib/material.dart', _materialApi)
      ..addFile('lib/cupertino.dart', _cupertinoApi);
    newPackage('material_ui').addFile('lib/material_ui.dart', _materialApi);
    newPackage('cupertino_ui').addFile('lib/cupertino_ui.dart', _cupertinoApi);
  }

  T lintAt<T>(String source, String needle, {bool lineStart = false}) {
    var offset = source.indexOf(needle);
    if (offset < 0) throw StateError('Needle not found: $needle');
    if (lineStart) offset = source.lastIndexOf('\n', offset) + 1;
    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: rule.name) as T;
  }
}

abstract class _ScannerStandaloneUiTest extends _StandaloneUiTest {
  List<ScannerRule> get rules;
  String get ruleName;

  @override
  AnalysisRule createRule() => rules.singleWhere((rule) => rule.name == ruleName);
}

const _widgetsApi = r'''
class BuildContext {}
class Key {
  const Key(String value);
}
class Widget {
  const Widget({Key? key});
}
abstract class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context);
}
class SizedBox extends Widget {
  const SizedBox();
}
class Icon extends Widget {
  const Icon(Object? icon, {double? size});
}
class RouteSettings {
  const RouteSettings({this.name});
  final String? name;
}
typedef WidgetBuilder = Widget Function(BuildContext context);
''';

const _materialApi = r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';

Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
}) async {
  throw StateError('stand-in');
}

Future<T?> showDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
}) async {
  throw StateError('stand-in');
}

class IconButton extends Widget {
  const IconButton({double? iconSize});
}

class SliverAppBar extends Widget {
  const SliverAppBar();
}

class MaterialApp extends Widget {
  MaterialApp.router({Object? routerConfig});
}

class Colors {
  static const Object red = Object();
}
''';

const _cupertinoApi = r'''
import 'package:flutter/widgets.dart';
export 'package:flutter/widgets.dart';

Future<T?> showCupertinoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
}) async {
  throw StateError('stand-in');
}

class CupertinoColors {
  static const Object systemBlue = Object();
}
''';

final class FireAndForgetModalStandaloneTest extends _ScannerStandaloneUiTest {
  @override
  List<ScannerRule> get rules => persistenceCrashSourceRules;
  @override
  String get ruleName => 'fire_and_forget_missing_catch';

  Future<void> _assertModalTrusted(String import, String call) => assertNoDiagnostics('''
import 'dart:async';
$import

void open(BuildContext context) {
  unawaited($call(context: context, builder: (_) => const SizedBox()));
}
''');

  Future<void> materialModalIsTrustedFrameworkImport() =>
      _assertModalTrusted(_flutterMaterial, 'showModalBottomSheet<void>');

  Future<void> materialModalIsTrustedStandaloneImport() =>
      _assertModalTrusted(_materialUi, 'showModalBottomSheet<void>');

  Future<void> cupertinoModalIsTrustedFrameworkImport() =>
      _assertModalTrusted(_flutterCupertino, 'showCupertinoDialog<void>');

  Future<void> cupertinoModalIsTrustedStandaloneImport() =>
      _assertModalTrusted(_cupertinoUi, 'showCupertinoDialog<void>');

  Future<void> _assertAppLookalikeReports(String import) {
    final source =
        '''
import 'dart:async';
$import

Future<void> showModalBottomSheet<T>({required BuildContext context}) async {
  throw StateError('app code');
}

void open(BuildContext context) {
  unawaited(showModalBottomSheet<void>(context: context));
}
''';
    return assertDiagnostics(source, [lintAt(source, 'unawaited(showModalBottomSheet')]);
  }

  Future<void> appModalLookalikeStillReportsFrameworkImport() =>
      _assertAppLookalikeReports(_flutterMaterial);

  Future<void> appModalLookalikeStillReportsStandaloneImport() =>
      _assertAppLookalikeReports(_materialUi);
}

final class ModalRouteSettingsStandaloneTest extends _ScannerStandaloneUiTest {
  @override
  List<ScannerRule> get rules => dialogSourceRules;
  @override
  String get ruleName => 'modal_helper_requires_route_settings';

  Future<void> _assertReports(String import, String call) {
    final source =
        '''
$import

Future<void> open(BuildContext context) =>
    $call(context: context, builder: (_) => const SizedBox());
''';
    return assertDiagnostics(source, [lintAt(source, '$call(')]);
  }

  Future<void> reportsMaterialModalFrameworkImport() =>
      _assertReports(_flutterMaterial, 'showDialog<void>');

  Future<void> reportsMaterialModalStandaloneImport() =>
      _assertReports(_materialUi, 'showDialog<void>');

  Future<void> reportsCupertinoModalFrameworkImport() =>
      _assertReports(_flutterCupertino, 'showCupertinoDialog<void>');

  Future<void> reportsCupertinoModalStandaloneImport() =>
      _assertReports(_cupertinoUi, 'showCupertinoDialog<void>');

  Future<void> _assertAllowsRouteSettings(String import) => assertNoDiagnostics('''
$import

Future<void> open(BuildContext context) => showDialog<void>(
  context: context,
  routeSettings: const RouteSettings(name: 'confirm'),
  builder: (_) => const SizedBox(),
);
''');

  Future<void> allowsModalWithRouteSettingsFrameworkImport() =>
      _assertAllowsRouteSettings(_flutterMaterial);

  Future<void> allowsModalWithRouteSettingsStandaloneImport() =>
      _assertAllowsRouteSettings(_materialUi);
}

final class StyleRawTokenStandaloneTest extends _ScannerStandaloneUiTest {
  @override
  List<ScannerRule> get rules => uiSourceRules;
  @override
  String get ruleName => 'style_raw_token';

  Future<void> _assertReports(String import, String declaration) {
    final source =
        '''
$import

$declaration
''';
    return assertDiagnostics(source, [lintAt(source, declaration, lineStart: true)]);
  }

  Future<void> reportsRawIconButtonSizeFrameworkImport() =>
      _assertReports(_flutterMaterial, 'Widget button() => const IconButton(iconSize: 24);');

  Future<void> reportsRawIconButtonSizeStandaloneImport() =>
      _assertReports(_materialUi, 'Widget button() => const IconButton(iconSize: 24);');

  Future<void> reportsRawMaterialColorFrameworkImport() =>
      _assertReports(_flutterMaterial, 'final accent = Colors.red;');

  Future<void> reportsRawMaterialColorStandaloneImport() =>
      _assertReports(_materialUi, 'final accent = Colors.red;');

  Future<void> reportsRawCupertinoColorFrameworkImport() =>
      _assertReports(_flutterCupertino, 'final accent = CupertinoColors.systemBlue;');

  Future<void> reportsRawCupertinoColorStandaloneImport() =>
      _assertReports(_cupertinoUi, 'final accent = CupertinoColors.systemBlue;');
}

final class WatchIntoFrameworkWidgetStandaloneTest extends _ScannerStandaloneUiTest {
  @override
  List<ScannerRule> get rules => riverpodSourceRules;
  @override
  String get ruleName => 'riverpod_watch_no_select';

  @override
  void addUiPackages() {
    super.addUiPackages();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class ProviderListenable<T> {}
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:riverpod/riverpod.dart';
export 'package:riverpod/riverpod.dart';
class WidgetRef {
  T watch<T>(ProviderListenable<T> provider) => throw StateError('synthetic');
}
''');
  }

  static const _shellConfig = r'''
class Source<T> implements ProviderListenable<T> {}
class ShellConfig {
  const ShellConfig(this.initialLocation, this.debugLogDiagnostics);
  final String initialLocation;
  final bool debugLogDiagnostics;
}
final shellConfigProvider = Source<ShellConfig>();
''';

  Future<void> _assertFrameworkWidgetAllowed(String import) => assertNoDiagnostics('''
import 'package:flutter_riverpod/flutter_riverpod.dart';
$import

$_shellConfig
class MyApp {
  Widget build(WidgetRef ref) {
    final config = ref.watch(shellConfigProvider);
    return MaterialApp.router(routerConfig: config);
  }
}
''');

  Future<void> allowsWholeValueIntoMaterialAppFrameworkImport() =>
      _assertFrameworkWidgetAllowed(_flutterMaterial);

  Future<void> allowsWholeValueIntoMaterialAppStandaloneImport() =>
      _assertFrameworkWidgetAllowed(_materialUi);

  Future<void> _assertAppWidgetReports(String import) {
    final source =
        '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
$import

$_shellConfig
class ShellView extends Widget {
  const ShellView({required this.config});
  final ShellConfig config;
}
class MyApp {
  Widget build(WidgetRef ref) => ShellView(config: ref.watch(shellConfigProvider));
}
''';
    return assertDiagnostics(source, [lintAt(source, 'ref.watch(shellConfigProvider)')]);
  }

  Future<void> reportsWholeValueIntoAppWidgetFrameworkImport() =>
      _assertAppWidgetReports(_flutterMaterial);

  Future<void> reportsWholeValueIntoAppWidgetStandaloneImport() =>
      _assertAppWidgetReports(_materialUi);
}

final class AvoidThrowModalBuilderStandaloneTest extends _StandaloneUiTest {
  @override
  AnalysisRule createRule() => AvoidThrow();

  Future<void> _assertReports(String import) {
    final source =
        '''
$import

Widget _build(BuildContext context) {
  throw Exception('x');
}

void open(BuildContext context) {
  showDialog<void>(context: context, builder: _build);
}
''';
    return assertDiagnostics(source, [
      lint(source.indexOf("throw Exception('x')"), "throw Exception('x')".length),
    ]);
  }

  Future<void> reportsThrowInModalBuilderFrameworkImport() => _assertReports(_flutterMaterial);

  Future<void> reportsThrowInModalBuilderStandaloneImport() => _assertReports(_materialUi);
}

abstract class _SliverPrefixStandaloneTest extends _StandaloneUiTest {
  Future<void> _assertReports(String import) {
    final source =
        '''
$import

class FeedHeader extends StatelessWidget {
  const FeedHeader({super.key});

  @override
  Widget build(BuildContext context) => const SliverAppBar();
}
''';
    return assertDiagnostics(source, [lint(source.indexOf('FeedHeader'), 'FeedHeader'.length)]);
  }

  Future<void> reportsSliverAppBarWithoutPrefixFrameworkImport() =>
      _assertReports(_flutterMaterial);

  Future<void> reportsSliverAppBarWithoutPrefixStandaloneImport() => _assertReports(_materialUi);
}

final class UseSliverPrefixStandaloneTest extends _SliverPrefixStandaloneTest {
  @override
  AnalysisRule createRule() => UseSliverPrefix();
}

final class PreferSliverPrefixStandaloneTest extends _SliverPrefixStandaloneTest {
  @override
  AnalysisRule createRule() => PreferSliverPrefix();
}

final class HostDriverImportsStandaloneTest extends _StandaloneUiTest {
  @override
  AnalysisRule createRule() => AvoidFlutterHostDriverImports();

  Future<void> _assertReports(String uri) {
    final source = "import '$uri';\n";
    final path = '$testPackageRootPath/test_driver/app_test.dart';
    newFile(path, source);
    return assertDiagnosticsInFile(path, [lint(source.indexOf("'$uri'"), "'$uri'".length)]);
  }

  Future<void> reportsMaterialImportFrameworkImport() =>
      _assertReports('package:flutter/material.dart');

  Future<void> reportsMaterialImportStandaloneImport() =>
      _assertReports('package:material_ui/material_ui.dart');

  Future<void> reportsCupertinoImportStandaloneImport() =>
      _assertReports('package:cupertino_ui/cupertino_ui.dart');
}
