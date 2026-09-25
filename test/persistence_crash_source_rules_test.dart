// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/persistence_crash_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

part 'persistence_crash_source_rules_test/persistence_crash_source_rules_part_01.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CrashDirectFirebaseCallTest);
    defineReflectiveTests(CrashInitBeforeRunAppTest);
    defineReflectiveTests(FireAndForgetMissingCatchTest);
    defineReflectiveTests(HiveDuplicateFieldIdTest);
    defineReflectiveTests(HiveDuplicateTypeIdTest);
    defineReflectiveTests(HiveReservedTypeIdsMissingTest);
    defineReflectiveTests(HiveTestCloseMissingTest);
    defineReflectiveTests(HiveTypeOnFreezedClassTest);
    defineReflectiveTests(HiveAdapterSpecDomainTypeTest);
    defineReflectiveTests(NotifierHiveAccessTest);
  });
}

abstract class _PersistenceCrashRuleTest extends AnalysisRuleTest {
  String get ruleName;

  @override
  void setUp() {
    rule = persistenceCrashSourceRules.singleWhere((rule) => rule.name == ruleName);
    super.setUp();
  }

  Future<void> assertRuleDiagnostic(String source, String needle, {String? path}) async {
    final analyzedSource = _withIgnorePrefix(source);
    final filePath = path ?? '$testPackageLibPath/source.dart';
    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [_lintFor(analyzedSource, needle, ruleName)]);
  }

  Future<void> assertRuleNoDiagnostics(String source, {String? path}) async {
    final filePath = path ?? '$testPackageLibPath/source.dart';
    newFile(filePath, _withIgnorePrefix(source));
    await assertNoDiagnosticsInFile(filePath);
  }

  T _lintFor<T>(String source, String needle, String name) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name) as T;
  }

  String _withIgnorePrefix(String source) => '''
// ignore_for_file: avoid_void_async, discarded_futures, final_not_initialized, undefined_getter, unused_element, unused_import
$source''';
}

@reflectiveTest
final class CrashDirectFirebaseCallTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_direct_firebase_call';

  Future<void> test_reportsOutsideBackend() async {
    await assertRuleDiagnostic(
      r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}
Future<void> submit() async {
  await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
}
''',
      'FirebaseCrashlytics.instance.recordError',
      path: '$testPackageLibPath/features/checkout/checkout_notifier.dart',
    );
  }

  Future<void> test_crashService_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}
abstract final class Crash {
  static Future<void> init() async {
    await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
  }
}
''', path: '$testPackageLibPath/core/services/crash_service.dart');
  }

  Future<void> test_reportsOtherCoreCrashFiles() async {
    await assertRuleDiagnostic(
      r'''
class FirebaseCrashlytics {
  static final instance = FirebaseCrashlytics();
  Future<void> recordError(Object error, StackTrace stack) async {}
}
Future<void> installHandlers() async {
  await FirebaseCrashlytics.instance.recordError(Exception('x'), StackTrace.current);
}
''',
      'FirebaseCrashlytics.instance.recordError',
      path: '$testPackageLibPath/core/crash/crash_handlers.dart',
    );
  }
}

@reflectiveTest
final class CrashInitBeforeRunAppTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'crash_init_before_run_app';

  Future<void> test_reportsMissingInit() async {
    await assertRuleDiagnostic(
      r'''
void runApp(Object app) {}
Future<void> main() async {
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_initBeforeRunApp_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init() async {}
}
void runApp(Object app) {}
Future<void> main() async {
  await Crash.init();
  runApp(Object());
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_crashAppRunner_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async {
  await Crash.init(appRunner: () => runApp(Object()));
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_awaitedTopLevelAppRunnerAfterMain_noDiagnostic() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
''');
    await assertRuleNoDiagnostics(r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async { await Crash.init(appRunner: () { runApp(Object()); }); }
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_forwardedTopLevelAppRunnerBeforeMain_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
void ensureInitialized() {}
Future<void> runAppRoot() async {
  ensureInitialized();
  await Crash.init(appRunner: () { runApp(Object()); });
}
Future<void> forwardStartup() async { await runAppRoot(); }
Future<void> main() => forwardStartup();
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_unawaitedTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { runAppRoot(); }
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(false); }
Future<void> runAppRoot(bool enabled) async {
  if (!enabled) return;
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unreachableTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await unrelated(); }
Future<void> unrelated() async {}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalCallToTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) await runAppRoot();
}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_callCycleDoesNotReachTopLevelAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> main() async { await first(); }
Future<void> first() async { await second(); }
Future<void> second() async { await first(); }
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_topLevelAppRunnerAfterDirectRunApp_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) async { appRunner(); }
}
void runApp(Object app) {}
Future<void> runAppRoot() async {
  await Crash.init(appRunner: () { runApp(Object()); });
}
Future<void> main() async {
  runApp(Object());
  await runAppRoot();
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_runAppBeforeCrashInitInHelper_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init() async {} }
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async {
  runApp(Object());
  await Crash.init();
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_returnBeforeCrashAppRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init({required void Function() appRunner}) async { appRunner(); } }
void runApp(Object app) {}
Future<void> main() async { await runAppRoot(); }
Future<void> runAppRoot() async {
  return;
  // ignore: dead_code
  await Crash.init(appRunner: () { runApp(Object()); });
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_throwBeforeAwaitedRunner_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init({required void Function() appRunner}) async { appRunner(); } }
void runApp(Object app) {}
Future<void> main() async {
  throw 0;
  // ignore: dead_code
  await runAppRoot();
}
Future<void> runAppRoot() async { await Crash.init(appRunner: () { runApp(Object()); }); }
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_awaitedResolvedInitializer_noDiagnostic() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash {
  static Future<void> init() async {}
}
class CrashReporter {
  Future<void> initialize() => Crash.init();
}
''');
    await assertRuleNoDiagnostics(r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''', path: '$testPackageLibPath/main.dart');
  }

  Future<void> test_shadowedCrashParameterInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class Other { Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize(Other Crash) => Crash.init();
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize(Other());
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_shadowedCrashLocalInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class Other { Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize() {
    final Crash = Other();
    return Crash.init();
  }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unrelatedAwaitedInitializer_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
class CrashReporter {
  Future<void> initialize() async {}
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_initializerInDifferentFunction_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter { Future<void> initialize() => Crash.init(); }
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> other() async { await CrashReporter().initialize(); }
Future<void> main() async { runApp(Object()); }
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalCrashInitInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize(bool enabled) async {
    if (enabled) await Crash.init();
  }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize(false);
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_unawaitedCrashInitInWrapper_stillReports() async {
    newFile('$testPackageLibPath/crash.dart', r'''
abstract final class Crash { static Future<void> init() async {} }
class CrashReporter {
  Future<void> initialize() async { Crash.init(); }
}
''');
    await assertRuleDiagnostic(
      r'''
import 'crash.dart';
void runApp(Object app) {}
Future<void> main() async {
  await CrashReporter().initialize();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }

  Future<void> test_conditionalDirectCrashInit_stillReports() async {
    await assertRuleDiagnostic(
      r'''
abstract final class Crash { static Future<void> init() async {} }
void runApp(Object app) {}
bool shouldInitialize() => false;
Future<void> main() async {
  if (shouldInitialize()) await Crash.init();
  runApp(Object());
}
''',
      'runApp(Object())',
      path: '$testPackageLibPath/main.dart',
    );
  }
}

@reflectiveTest
final class FireAndForgetMissingCatchTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'fire_and_forget_missing_catch';

  @override
  void setUp() {
    _riverpodPackage();
    _navigationPackages();
    super.setUp();
  }

  Future<void> test_reportsInlineAsyncMissingCatch() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';
abstract interface class Client {
  Future<void> sync();
}
void mirror(Client client) {
  unawaited(() async {
    await client.sync();
  }());
}
''', 'unawaited(() async');
  }

  Future<void> test_inlineAsyncWithCatch_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';
class Client {
  Future<void> sync() async {}
}

void mirror(Client client) {
  unawaited(() async {
    try {
      await client.sync();
    } on Exception {
      // handled
    }
  }());
}
''');
  }

  Future<void> test_calleeThatCatchesInternally_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

class RemoteMirror {
  Future<void> sync() async {
    try {
      await Future<void>.value();
    } on Exception {
      // handled
    }
  }
}

void mirror(RemoteMirror remoteMirror) {
  unawaited(remoteMirror.sync());
}
''');
  }

  Future<void> test_reportsCalleeWithoutCatch() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

Future<void> trackUncaught(String name) async {
  await Future<void>.value();
}

void track() {
  unawaited(trackUncaught('x'));
}
''', 'unawaited(trackUncaught');
  }

  Future<void> test_resolvesCalleesInImportedLibraries() async {
    newFile('$testPackageLibPath/analytics.dart', r'''
Future<void> trackEvent(String name) async {
  try {
    await Future<void>.value();
  } on Exception {
    // handled
  }
}

Future<void> trackUncaught(String name) async {
  await Future<void>.value();
}
''');
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'analytics.dart';

void track() {
  unawaited(trackEvent('sign_in'));
  unawaited(trackUncaught('x'));
}
''', 'unawaited(trackUncaught');
  }

  Future<void> test_emptyCalleeBody_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

final class PushTokenRefresh {
  PushTokenRefresh._();

  static final PushTokenRefresh instance = PushTokenRefresh._();

  Future<void> refresh() async {}
}

void onResume() {
  unawaited(PushTokenRefresh.instance.refresh());
}
''');
  }

  // riverpod-codegen.md Mutations: `run` records failures in the mutation state.
  Future<void> test_mutationRunCallee_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>();

class AddTodoScreen {
  Future<void> _addTodo(Object ref) => addTodoMutation.run(ref, (tsx) async {
    await Future<void>.value();
  });

  void onPressed(Object ref) => unawaited(_addTodo(ref));
  void retry(Object ref) => unawaited(addTodoMutation.run(ref, (tsx) async {}));
}
''');
  }

  Future<void> test_reportsLocalMutationLookalike() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

class Mutation<T> {
  Future<T> run(Object target, Future<T> Function(Object tsx) cb) => cb(target);
}

final addTodoMutation = Mutation<void>();

Future<void> _addTodo(Object ref) => addTodoMutation.run(ref, (tsx) async {});

void onPressed(Object ref) {
  unawaited(_addTodo(ref));
}
''', 'unawaited(_addTodo');
  }

  // modals-navigation.md Dismiss Modal -> Push Route: route futures complete with
  // the popped result, so a callee that only awaits navigation has nothing to catch.
  Future<void> test_navigationCallee_noDiagnostic() async {
    newFile('$testPackageLibPath/core/extensions/context_extensions.dart', r'''
import 'package:flutter/material.dart';

extension ModalContextX on BuildContext {
  Future<T?> showAppSheet<T>({required String routeName, required WidgetBuilder builder}) {
    return showModalBottomSheet<T>(
      context: this,
      routeSettings: RouteSettings(name: routeName),
      builder: builder,
    );
  }
}
''');
    newFile('$testPackageLibPath/routes.dart', r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

mixin $CreateExerciseRoute on GoRouteData {
  String get location => '/create';
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);
}

class CreateExerciseRoute extends GoRouteData with $CreateExerciseRoute {
  const CreateExerciseRoute();
}

class StubRoute {
  const StubRoute();
  Future<T?> push<T>(BuildContext context) async => null;
}
''');
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:flutter/material.dart';

import 'core/extensions/context_extensions.dart';
import 'routes.dart';

enum CreateChoice { exercise }

class CreateScreen {
  Future<void> _openCreateSheet(BuildContext context) async {
    final choice = await context.showAppSheet<CreateChoice>(
      routeName: 'create-sheet',
      builder: (_) => const SizedBox(),
    );
    if (!context.mounted) return;
    if (choice != CreateChoice.exercise) return;
    await const CreateExerciseRoute().push<String>(context);
  }

  Future<void> _openStub(BuildContext context) async {
    await const StubRoute().push<String>(context);
  }

  void onPressed(BuildContext context) {
    unawaited(_openCreateSheet(context));
    unawaited(_openStub(context));
  }
}
''');
  }

  Future<void> test_reportsNavigationThenUncaughtRemoteWork() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'package:flutter/material.dart';

abstract interface class Remote {
  Future<void> sync();
}

class SyncScreen {
  SyncScreen(this.remote);
  final Remote remote;

  Future<void> _confirmAndSync(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(context: context, builder: (_) => const SizedBox());
    if (ok != true) return;
    await remote.sync();
  }

  void onPressed(BuildContext context) {
    unawaited(_confirmAndSync(context));
  }
}
''', 'unawaited(_confirmAndSync');
  }

  // lists-forms-workflows.md pagination: `loadMore` delegates to `_loadPage`,
  // which catches and writes error state.
  Future<void> test_calleeDelegatingToCatchingMethod_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

abstract interface class Repository {
  Future<List<int>> fetchPage(int page);
}

class PaginatedNotifier {
  PaginatedNotifier(this.repository);
  final Repository repository;
  bool isLoading = false;

  Future<void> _loadPage(int page) async {
    isLoading = true;
    try {
      await repository.fetchPage(page);
    } catch (e) {
      isLoading = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading) return;
    await _loadPage(1);
  }
}

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadMore());
}
''');
  }

  Future<void> test_reportsCalleeThrowingBeforeCaughtWork() async {
    await assertRuleDiagnostic(r'''
import 'dart:async';

Future<void> _safe() async {
  try {
    await Future<void>.value();
  } on Exception {
    // handled
  }
}

Future<void> checked(bool ready) async {
  if (!ready) throw Exception('not ready');
  await _safe();
}

void start() {
  unawaited(checked(false));
}
''', 'unawaited(checked');
  }

  Future<void> test_guardedHelper_noDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

class Client {
  Future<void> sync() async {}
}

void mirror(Client client) {
  unawaited(_send(() => client.sync(), 'Client.sync'));
}

Future<void> _send(Future<void> Function() operation, String operationName) async {
  try {
    await operation();
  } on Exception {
    // handled
  }
}
''');
  }

  void _riverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Mutation<ResultT> {
  factory Mutation() = _Mutation<ResultT>;
  Future<ResultT> run(Object target, Future<ResultT> Function(Object tsx) cb);
}

final class _Mutation<ResultT> implements Mutation<ResultT> {
  @override
  Future<ResultT> run(Object target, Future<ResultT> Function(Object tsx) cb) async {
    try {
      return await cb(target);
    } catch (error) {
      rethrow;
    }
  }
}
''');
  }

  void _navigationPackages() {
    newPackage('flutter').addFile('lib/material.dart', r'''
class BuildContext {
  bool get mounted => true;
}
abstract class Widget {
  const Widget();
}
class SizedBox extends Widget {
  const SizedBox();
}
typedef WidgetBuilder = Widget Function(BuildContext context);
class RouteSettings {
  const RouteSettings({String? name});
}
Future<T?> showModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? routeSettings,
}) async => null;
''');
    newPackage('go_router').addFile('lib/go_router.dart', r'''
import 'package:flutter/material.dart';
abstract class GoRouteData {
  const GoRouteData();
  Future<T?> push<T>(BuildContext context) => throw UnimplementedError();
}
extension GoRouterHelper on BuildContext {
  Future<T?> push<T>(String location) async => null;
}
''');
  }
}
