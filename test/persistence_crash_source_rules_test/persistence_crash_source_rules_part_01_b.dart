part of '../persistence_crash_source_rules_test.dart';

final class _FireAndForgetMissingCatchTest extends _PersistenceCrashRuleTest {
  static Map<String, Future<void> Function(_FireAndForgetMissingCatchTest)> get _allCases =>
      caseSet<_FireAndForgetMissingCatchTest>(
        parent: const {},
        own: {
          'test_reportsInlineAsyncMissingCatch': (t) => t._reportsInlineAsyncMissingCatch(),
          'test_inlineAsyncWithCatch_noDiagnostic': (t) => t._inlineAsyncWithCatchNoDiagnostic(),
          'test_calleeThatCatchesInternally_noDiagnostic': (t) =>
              t._calleeThatCatchesInternallyNoDiagnostic(),
          'test_reportsCalleeWithoutCatch': (t) => t._reportsCalleeWithoutCatch(),
          'test_resolvesCalleesInImportedLibraries': (t) => t._resolvesCalleesInImportedLibraries(),
          'test_emptyCalleeBody_noDiagnostic': (t) => t._emptyCalleeBodyNoDiagnostic(),
          'test_mutationRunCallee_noDiagnostic': (t) => t._mutationRunCalleeNoDiagnostic(),
          'test_reportsLocalMutationLookalike': (t) => t._reportsLocalMutationLookalike(),
          'test_navigationCallee_noDiagnostic': (t) => t._navigationCalleeNoDiagnostic(),
          'test_maybePopCallee_noDiagnostic': (t) => t._maybePopCalleeNoDiagnostic(),
          'test_reportsNavigationThenUncaughtRemoteWork': (t) =>
              t._reportsNavigationThenUncaughtRemoteWork(),
          'test_calleeDelegatingToCatchingMethod_noDiagnostic': (t) =>
              t._calleeDelegatingToCatchingMethodNoDiagnostic(),
          'test_importedNotifierDelegatingToCatchingMethod_noDiagnostic': (t) =>
              t._importedNotifierDelegatingToCatchingMethodNoDiagnostic(),
          'test_reportsImportedNotifierDelegatingToUncaughtMethod': (t) =>
              t._reportsImportedNotifierDelegatingToUncaughtMethod(),
          'test_reportsCalleeThrowingBeforeCaughtWork': (t) =>
              t._reportsCalleeThrowingBeforeCaughtWork(),
          'test_guardedHelper_noDiagnostic': (t) => t._guardedHelperNoDiagnostic(),
        },
      );

  @override
  String get ruleName => 'fire_and_forget_missing_catch';

  @override
  void setUp() {
    _riverpodPackage();
    _navigationPackages();
    super.setUp();
  }

  Future<void> _reportsInlineAsyncMissingCatch() async {
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

  Future<void> _inlineAsyncWithCatchNoDiagnostic() async {
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

  Future<void> _calleeThatCatchesInternallyNoDiagnostic() async {
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

  Future<void> _reportsCalleeWithoutCatch() async {
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

  Future<void> _resolvesCalleesInImportedLibraries() async {
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

  Future<void> _emptyCalleeBodyNoDiagnostic() async {
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
  Future<void> _mutationRunCalleeNoDiagnostic() async {
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

  Future<void> _reportsLocalMutationLookalike() async {
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

  // modals-navigation.md: route futures complete with the popped result, not an error.
  Future<void> _navigationCalleeNoDiagnostic() async {
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

  // routing-app-shell.md: `maybePop` completes with whether a route was popped, not an error.
  Future<void> _maybePopCalleeNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'package:flutter/material.dart';

class ShellScreen {
  Future<void> _createWorkout(BuildContext sheetContext) async {
    await Navigator.of(sheetContext).maybePop();
    if (!sheetContext.mounted) return;
  }

  void onCreateWorkout(BuildContext sheetContext) => unawaited(_createWorkout(sheetContext));
}
''');
  }

  Future<void> _reportsNavigationThenUncaughtRemoteWork() async {
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

  // lists-forms-workflows.md: `loadMore` delegates to `_loadPage`, which catches.
  Future<void> _calleeDelegatingToCatchingMethodNoDiagnostic() async {
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

  // lists-forms-workflows.md:40-84: an imported notifier's loadMore awaits `_loadPage`, which catches.
  Future<void> _importedNotifierDelegatingToCatchingMethodNoDiagnostic() async {
    newFile('$testPackageLibPath/paginated_notifier.dart', _paginatedNotifier);
    await assertRuleNoDiagnostics(r'''
import 'dart:async';

import 'paginated_notifier.dart';

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadMore());
  unawaited(notifier.refresh());
}
''');
  }

  Future<void> _reportsImportedNotifierDelegatingToUncaughtMethod() async {
    newFile('$testPackageLibPath/paginated_notifier.dart', _paginatedNotifier);
    await assertRuleDiagnostic(r'''
import 'dart:async';

import 'paginated_notifier.dart';

void onScroll(PaginatedNotifier notifier) {
  unawaited(notifier.loadNext());
}
''', 'unawaited(notifier.loadNext');
  }

  static const _paginatedNotifier = r'''
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

  Future<void> _fetchUncaught(int page) async {
    await repository.fetchPage(page);
  }

  Future<void> loadMore() async {
    if (isLoading) return;
    await _loadPage(1);
  }

  Future<void> refresh() async => _loadPage(0);

  Future<void> loadNext() async {
    await this._fetchUncaught(2);
  }
}
''';

  Future<void> _reportsCalleeThrowingBeforeCaughtWork() async {
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

  Future<void> _guardedHelperNoDiagnostic() async {
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
class NavigatorState {
  Future<bool> maybePop<T>([T? result]) async => _popDisposition();
  Future<bool> _popDisposition() async => throw StateError('no route');
}
class Navigator {
  static NavigatorState of(BuildContext context) => NavigatorState();
}
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

void _definePersistenceCrashSourceRulesPart01BTests() {
  analysisRuleSuite<_FireAndForgetMissingCatchTest>(
    'FireAndForgetMissingCatchTest',
    _FireAndForgetMissingCatchTest.new,
    _FireAndForgetMissingCatchTest._allCases,
  );
}
