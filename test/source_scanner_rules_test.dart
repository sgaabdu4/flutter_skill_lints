import 'dart:math' as math;

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/architecture_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/data_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/dialog_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/hive_persistence_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/presentation_widget_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/runtime_bug_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_mixins_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:flutter_skill_lints/src/rules/state_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/test_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/value_object_source_rules.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_01.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_02.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_03.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_04.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_05.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_06.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_07.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_08.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_09.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_10.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_11.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_12.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_13.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_14.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_15.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_16.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_17.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_18.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_19.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_20.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_21.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_22.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_23.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_24.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_crash.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_network.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_riverpod_select.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_architecture.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_crash_registry.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_01_registry.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_02_registry.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_14_registry.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_15_registry.dart';
part 'source_scanner_rules_test/source_scanner_rules_part_12_registry.dart';

void main() {
  _defineSourceScannerRulesPart10Tests();
  _defineSourceScannerRulesPart06Tests();
  _defineSourceScannerRulesPartNetworkTests();
  _defineSourceScannerRulesPartCrashTests();
  _defineSourceScannerRulesPart07Tests();
  _defineSourceScannerRulesPart11Tests();
  _defineSourceScannerRulesPart20Tests();
  _defineSourceScannerRulesPart16Tests();
  _defineSourceScannerRulesPart01Tests();
  _defineSourceScannerRulesPart17Tests();
  _defineSourceScannerRulesPart21Tests();
  _defineSourceScannerRulesPart18Tests();
  _defineSourceScannerRulesPart22Tests();
  _defineSourceScannerRulesPart02Tests();
  _defineSourceScannerRulesPart14Tests();
  _defineSourceScannerRulesPart15Tests();
  _defineSourceScannerRulesPart03Tests();
  _defineSourceScannerRulesPart23Tests();
  _defineSourceScannerRulesPart19Tests();
  _defineSourceScannerRulesPart04Tests();
  _defineSourceScannerRulesPart12Tests();
  _defineSourceScannerRulesPart08Tests();
  _defineSourceScannerRulesPartRiverpodSelectTests();
  _defineSourceScannerRulesPart24Tests();
  _defineSourceScannerRulesPartArchitectureTests();
  _defineSourceScannerRulesPart09Tests();
  _defineSourceScannerRulesPart13Tests();
  _defineSourceScannerRulesPart05Tests();
}

abstract class _SourceRuleTest extends AnalysisRuleTest {
  List<ScannerRule> get rules;
  String get ruleName;
  String get source;
  String get needle;
  String? get path => null;
  bool get lineStart => false;
  bool get addIgnorePrefix => true;

  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    ...super.ignoredDiagnosticCodes,
    for (final name in const [
      'undefined_instance_member_read_not_found',
      'undefined_instance_member_write_not_found',
      'undefined_static_member_read_not_found',
      'undefined_unqualified_name_read_not_found',
      'undefined_unqualified_name_write_not_found',
    ])
      errorCodeByUniqueName(name)!,
  ];

  @override
  void setUp() {
    rule = rules.singleWhere((rule) => rule.name == ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> _reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    final filePath = path;
    if (filePath == null) {
      await assertDiagnostics(analyzedSource, [
        compatLint(analyzedSource, needle, ruleName, lineStart: lineStart),
      ]);
      return;
    }

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, needle, ruleName, lineStart: lineStart),
    ]);
  }

  Future<void> assertAllows(String source, {String? path, bool addIgnorePrefix = true}) async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    if (path == null) {
      await assertNoDiagnostics(analyzedSource);
      return;
    }

    newFile(path, analyzedSource);
    await assertNoDiagnosticsInFile(path);
  }

  String _analyzedSource(String source, {required bool addIgnorePrefix}) {
    if (!addIgnorePrefix) return source;
    return '''
// ignore_for_file: extends_non_class, final_not_initialized, implements_non_class, undefined_function, undefined_identifier, undefined_method, unused_import
// ignore_for_file: non_type_as_type_argument, unchecked_use_of_nullable_value, undefined_class, undefined_getter, undefined_setter
$source''';
  }

  T compatLint<T>(String source, String needle, String name, {bool lineStart = false}) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name) as T;
  }

  void _addFlutterPackage() {
    // Keep foundation stubs a test registered before super.setUp().
    final foundation = getFile(convertPath('/package/flutter/lib/foundation.dart'));
    final existingFoundation = foundation.exists ? foundation.readAsStringSync() : '';
    newPackage('flutter')
      ..addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {}
abstract class StatefulWidget extends Widget {}
abstract class State<T extends StatefulWidget> {}
''')
      ..addFile('lib/widget_previews.dart', r'''
base class Preview {
  const Preview({String? name});
}

abstract base class MultiPreview {
  const MultiPreview();
}
''')
      // Flutter declares debugPrint as a function-typed top-level variable.
      ..addFile(
        'lib/foundation.dart',
        '$existingFoundation'
            r'''
typedef DebugPrintCallback = void Function(String? message, {int? wrapWidth});
DebugPrintCallback debugPrint = (String? message, {int? wrapWidth}) {};
''',
      );
  }

  /// Opt-in stubs for rules that resolve Flutter, flutter_test, mocktail, riverpod and go_router elements.
  void _addTestingNavigationPackages() {
    newPackage('flutter')
      ..addFile('lib/foundation.dart', r'''
abstract class Key {
  const factory Key(String value) = ValueKey<String>;
  const Key.empty();
}
class ValueKey<T> extends Key {
  const ValueKey(this.value) : super.empty();
  final T value;
}
''')
      ..addFile('lib/material.dart', r'''
export 'foundation.dart';
export 'widgets.dart';
import 'widgets.dart';
class RouteSettings {
  const RouteSettings({this.name});
  final String? name;
}
class NavigatorState {
  bool canPop() => true;
  void pop<T extends Object?>([T? result]) {}
  Future<bool> maybePop<T extends Object?>([T? result]) async => true;
  Future<T?> push<T extends Object?>(Object route) async => null;
}
class Navigator {
  static NavigatorState of(BuildContext context, {bool rootNavigator = false}) => NavigatorState();
  static NavigatorState? maybeOf(BuildContext context, {bool rootNavigator = false}) => null;
  static void pop<T extends Object?>(BuildContext context, [T? result]) {}
}
class GlobalKey<T extends Object> {
  GlobalKey();
  BuildContext? get currentContext => null;
  T? get currentState => null;
}
Future<T?> showDialog<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool barrierDismissible = true,
  RouteSettings? routeSettings,
}) async => null;
Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  RouteSettings? routeSettings,
}) async => null;
''');
    newPackage('flutter_test').addFile('lib/flutter_test.dart', r'''
import 'package:flutter/foundation.dart';
class FinderBase<T> {
  FinderBase<T> get first => this;
}
class Finder extends FinderBase<Object> {}
class CommonFinders {
  const CommonFinders();
  Finder text(String text) => Finder();
  Finder textContaining(Pattern pattern) => Finder();
  Finder widgetWithText(Type widgetType, String text) => Finder();
  Finder byType(Type type) => Finder();
  Finder byKey(Key key) => Finder();
  Finder descendant({required Finder of, required Finder matching}) => Finder();
}
const find = CommonFinders();
class WidgetController {
  Future<void> tap(FinderBase<Object> finder) async {}
  Future<void> longPress(FinderBase<Object> finder) async {}
  Future<void> drag(FinderBase<Object> finder, Object offset) async {}
  Future<void> enterText(FinderBase<Object> finder, String text) async {}
}
class WidgetTester extends WidgetController {
  Future<void> pump([Duration? duration]) async {}
}
const Object findsOneWidget = Object();
void expect(Object? actual, Object? matcher) {}
void test(String description, Object? Function() body) {}
void testWidgets(String description, Future<void> Function(WidgetTester) callback) {}
''');
    newPackage('test_api').addFile('lib/fake.dart', 'abstract class Fake {}');
    newPackage('mocktail').addFile('lib/mocktail.dart', r'''
export 'package:test_api/fake.dart' show Fake;
class Mock {
  dynamic noSuchMethod(Invocation invocation) => null;
}
''');
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  void onDispose(void Function() callback) {}
}
class Override {}
abstract class AnyNotifier<StateT, ValueT> {
  Ref get ref => Ref();
}
abstract class Notifier<StateT> extends AnyNotifier<StateT, StateT> {
  StateT build();
}
abstract class AsyncNotifier<ValueT> extends AnyNotifier<Object?, ValueT> {
  Future<ValueT> build();
}
class NotifierProvider<NotifierT extends AnyNotifier<StateT, StateT>, StateT> {
  NotifierProvider(NotifierT Function() create);
  Override overrideWith(NotifierT Function() create) => Override();
  Override overrideWithBuild(StateT Function(Ref ref, NotifierT notifier) build) => Override();
  Override overrideWithValue(StateT value) => Override();
}
class NotifierProviderFamily<NotifierT extends AnyNotifier<StateT, StateT>, StateT, ArgT> {
  Override overrideWith2(NotifierT Function(ArgT arg) create) => Override();
}
class Provider<ValueT> {
  Provider(ValueT Function(Ref ref) create);
  Override overrideWith(ValueT Function(Ref ref) create) => Override();
  Override overrideWithValue(ValueT value) => Override();
}
''');
    newPackage('go_router').addFile('lib/go_router.dart', r'''
import 'package:flutter/widgets.dart';
class GoRouter {
  static GoRouter of(BuildContext context) => GoRouter();
  void go(String location, {Object? extra}) {}
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async => null;
}
abstract class GoRouteData {
  const GoRouteData();
  String get location => '';
  void go(BuildContext context) {}
  Future<T?> push<T>(BuildContext context) async => null;
}
class StatefulNavigationShell {
  int get currentIndex => 0;
  void goBranch(int index, {bool initialLocation = false}) {}
}
extension GoRouterHelper on BuildContext {
  bool canPop() => true;
  void pop<T extends Object?>([T? result]) {}
  void go(String location, {Object? extra}) {}
  Future<T?> push<T extends Object?>(String location, {Object? extra}) async => null;
}
''');
  }
}
