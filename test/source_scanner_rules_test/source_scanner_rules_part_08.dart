part of '../source_scanner_rules_test.dart';

final class BareStateMountedForbiddenTest extends _StateRuleTest {
  @override
  String get ruleName => 'bare_state_mounted_forbidden';
  @override
  String get needle => 'mounted) return';
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/screens/todo_screen.dart';
  @override
  String get source => r'''
class ScreenState {
  void onFrame() {
    if (!mounted) return;
  }
}
''';

  Future<void> _reportsThisMounted() async {
    final analyzedSource = _analyzedSource(r'''
class ScreenState {
  void onFrame() {
    if (!this.mounted) return;
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'mounted) return', ruleName)]);
  }

  Future<void> _allowsContextAndRefMounted() async {
    await assertAllows(r'''
class ScreenState {
  void onFrame(context, ref) {
    if (!context.mounted) return;
    if (!ref.mounted) return;
  }
}
''', path: path);
  }

  Future<void> _allowsNonWidgetMountedMember() async {
    await assertAllows(r'''
class LifecycleHandle {
  bool mounted = true;

  void close() {
    if (!mounted) return;
  }
}
''', path: '$testPackageLibPath/core/services/lifecycle_handle.dart');
  }
}

abstract class _RouterRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => routerSourceRules;
}

final class RouterStringNavTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_string_nav';
  @override
  String get needle => "context.go('/home')";
  @override
  String get source => r'''
void navigate(context) {
  context.go('/home');
}
''';

  Future<void> _allowsTestHostStringRoutes() async {
    await assertAllows(r'''
void navigate(context) {
  context.go('/host');
}
''', path: '$testPackageRootPath/test/features/home/home_screen_test.dart');
  }

  Future<void> _reportsRouterStringInsideCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  void go(String location) {}
}

final class RouterBridge {
  RouterBridge(this._router);
  final GoRouter _router;

  void showHome() {
    _router.go('/home');
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/app_router.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "_router.go('/home')", ruleName),
    ]);
  }

  Future<void> _reportsRouterPushNamedInsideCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  Future<T?> pushNamed<T>(String name) async => null;
}

final class RouterBridge {
  RouterBridge(this._router);
  final GoRouter _router;

  Future<T?> showDetail<T>() {
    return _router.pushNamed<T>('detail');
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/app_router.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, '_router.pushNamed', ruleName),
    ]);
  }

  Future<void> _reportsCamelCaseRouterVariableInsideCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  void go(String location) {}
}

void open(GoRouter appRouter) {
  appRouter.go('/home');
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/app_router.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "appRouter.go('/home')", ruleName),
    ]);
  }

  Future<void> _reportsRawInitialLocationInsideCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  GoRouter({required String initialLocation});
}

GoRouter router() {
  return GoRouter(initialLocation: '/home');
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/app_router.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, "initialLocation: '/home'", ruleName),
    ]);
  }

  Future<void> _allowsTypedLocationsForStringNavRule() async {
    await assertAllows(r'''
class GoRouter {
  GoRouter({required String initialLocation});
  void go(String location) {}
  Future<T?> push<T>(String location) async => null;
}

class HomeRoute {
  const HomeRoute();
  String get location => '/home';
}

class ProductDetailRoute {
  const ProductDetailRoute({required this.id});
  final String id;
  String get location => '/products/$id';
}

final class RouterBridge {
  RouterBridge(this._router);
  final GoRouter _router;

  void showHome() {
    _router.go(const HomeRoute().location);
  }

  Future<T?> pushProduct<T>(String id) {
    return _router.push<T>(ProductDetailRoute(id: id).location);
  }
}

GoRouter router() {
  return GoRouter(initialLocation: const HomeRoute().location);
}
''', path: '$testPackageLibPath/core/router/app_router.dart');
  }

  Future<void> _allowsTypedRouteDefinitions() async {
    await assertAllows(r'''
class TypedGoRoute<T> {
  const TypedGoRoute({required String path, List<Object> routes = const []});
}

class GoRouteData {}

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<ProductRoute>(path: 'products'),
  ],
)
class HomeRoute extends GoRouteData {}

class ProductRoute extends GoRouteData {}
''', path: '$testPackageLibPath/core/router/app_routes.dart');
  }
}

final class RouterPopThenPushTest extends _RouterRuleTest {
  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'router_pop_then_push';
  @override
  String get needle => 'context.pop()';
  @override
  String get source => r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  context.pop();
  context.push('/next');
}
''';

  Future<void> _allowsSkillSafePopAfterEarlierPushReplacement() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginRoute extends GoRouteData {
  const LoginRoute();
  void pushReplacement(BuildContext context) {}
}

class ProductListRoute extends GoRouteData {
  const ProductListRoute();
}

void navigate(BuildContext context, bool result) {
  const LoginRoute().pushReplacement(context);

  if (context.canPop()) {
    context.pop(result);
  } else {
    const ProductListRoute().go(context);
  }
}
''');
  }

  Future<void> _reportsNavigatorPopThenTypedRoutePush() async {
    const source = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateExerciseRoute extends GoRouteData {
  const CreateExerciseRoute();
}

Future<void> onCreateTapped(BuildContext context) async {
  Navigator.of(context).pop();
  await const CreateExerciseRoute().push<String>(context);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).pop();', ruleName),
    ]);
  }

  Future<void> _allowsSkillPopWithResultThenCallerPush() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CreateChoice { exercise }

class CreateExerciseRoute extends GoRouteData {
  const CreateExerciseRoute();
}

Future<void> onCreateTapped(BuildContext context) async {
  Navigator.of(context).pop(CreateChoice.exercise);
}

Future<void> openCreateSheet(BuildContext context, Future<CreateChoice?> sheet) async {
  final choice = await sheet;
  if (choice != CreateChoice.exercise) return;
  await const CreateExerciseRoute().push<String>(context);
}
''');
  }
}

final class PopFallbackHelperMustCheckNavigatorStackTest extends _RouterRuleTest {
  @override
  String get ruleName => 'pop_fallback_helper_must_check_navigator_stack';
  @override
  String get needle => 'bool popIfCan<T>([T? result]) {';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class BuildContext {}

extension ContextNavigationX on BuildContext {
  bool canPop() => false;
  void pop<T>([T? result]) {}

  bool popIfCan<T>([T? result]) {
    if (!canPop()) return false;
    pop<T>(result);
    return true;
  }
}
''';

  Future<void> _allowsNavigatorStackChecks() async {
    await assertAllows(r'''
class BuildContext {}
class NavigatorState {
  bool canPop() => false;
  void pop<T>([T? result]) {}
}
class Navigator {
  static NavigatorState? maybeOf(BuildContext context, {bool rootNavigator = false}) => null;
}
class GoRouteData {
  void go(BuildContext context) {}
}

extension ContextNavigationX on BuildContext {
  bool get mounted => true;
  bool canPop() => false;
  void pop<T>([T? result]) {}

  bool popIfCan<T extends Object?>([T? result]) {
    if (!mounted) return false;
    final rootNavigator = Navigator.maybeOf(this, rootNavigator: true);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop<T>(result);
      return true;
    }

    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      navigator.pop<T>(result);
      return true;
    }

    if (!canPop()) return false;
    pop<T>(result);
    return true;
  }

  void popOrGo<T extends Object?>(GoRouteData fallbackRoute, [T? result]) {
    if (popIfCan<T>(result)) return;
    fallbackRoute.go(this);
  }
}
''');
  }

  Future<void> _reportsMissingMountedGuard() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}
class NavigatorState {
  bool canPop() => false;
  void pop<T>([T? result]) {}
}
class Navigator {
  static NavigatorState? maybeOf(BuildContext context, {bool rootNavigator = false}) => null;
}

extension ContextNavigationX on BuildContext {
  bool canPop() => false;
  void pop<T>([T? result]) {}

  bool popIfCan<T>([T? result]) {
    final rootNavigator = Navigator.maybeOf(this, rootNavigator: true);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop<T>(result);
      return true;
    }
    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      navigator.pop<T>(result);
      return true;
    }
    if (!canPop()) return false;
    pop<T>(result);
    return true;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '  bool popIfCan<T>([T? result]) {', ruleName),
    ]);
  }

  Future<void> _reportsMissingLocalNavigatorCheck() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}
class NavigatorState {
  bool canPop() => false;
  void pop<T>([T? result]) {}
}
class Navigator {
  static NavigatorState? maybeOf(BuildContext context, {bool rootNavigator = false}) => null;
}

extension ContextNavigationX on BuildContext {
  bool get mounted => true;
  bool canPop() => false;
  void pop<T>([T? result]) {}

  bool popIfCan<T>([T? result]) {
    if (!mounted) return false;
    final rootNavigator = Navigator.maybeOf(this, rootNavigator: true);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop<T>(result);
      return true;
    }
    if (!canPop()) return false;
    pop<T>(result);
    return true;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '  bool popIfCan<T>([T? result]) {', ruleName),
    ]);
  }

  Future<void> _reportsMissingRootNavigatorCheck() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}
class NavigatorState {
  bool canPop() => false;
  void pop<T>([T? result]) {}
}
class Navigator {
  static NavigatorState? maybeOf(BuildContext context, {bool rootNavigator = false}) => null;
}

extension ContextNavigationX on BuildContext {
  bool get mounted => true;
  bool canPop() => false;
  void pop<T>([T? result]) {}

  bool popIfCan<T>([T? result]) {
    if (!mounted) return false;
    final navigator = Navigator.maybeOf(this);
    if (navigator != null && navigator.canPop()) {
      navigator.pop<T>(result);
      return true;
    }
    if (!canPop()) return false;
    pop<T>(result);
    return true;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '  bool popIfCan<T>([T? result]) {', ruleName),
    ]);
  }

  Future<void> _allowsNonFallbackHelper() async {
    await assertAllows(r'''
class BuildContext {}

extension ContextNavigationX on BuildContext {
  bool popIfCan<T>([T? result]) => false;
}
''');
  }
}

final class RouterRedirectWatchTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_watch';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    ref.watch(provider);
    return null;
  },
);
''';
}

final class RouterRedirectLoadingBounceTest extends _RouterRuleTest {
  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'router_redirect_loading_bounce';
  @override
  String get needle => "return '/loading';";
  @override
  String get source => r'''
enum AuthStatus { loading, signedIn }

String? redirectFor(AuthStatus status) {
  if (status == AuthStatus.loading) return '/loading';
  return null;
}
''';

  Future<void> _reportsLoadingSwitchCaseReturningTypedLocation() async {
    const source = '''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

String? resolveBadRedirect({required String location, required SetupStatus setupStatus}) {
  switch (setupStatus) {
    case SetupStatus.loading:
      return const SplashRoute().location;
    case SetupStatus.unauthenticated:
      return location == const LoginRoute().location ? null : const LoginRoute().location;
    case SetupStatus.setupComplete:
      return null;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'return const SplashRoute().location;', ruleName),
    ]);
  }

  Future<void> _reportsFallThroughLoadingCase() async {
    const source = '''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

String? resolve(SetupStatus setupStatus) {
  switch (setupStatus) {
    case SetupStatus.loading:
    case SetupStatus.unauthenticated:
      return '/splash';
    case SetupStatus.setupComplete:
      return null;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "return '/splash';", ruleName),
    ]);
  }

  Future<void> _reportsLoadingSwitchExpressionCase() async {
    const source = '''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

String? resolve(SetupStatus setupStatus) => switch (setupStatus) {
  SetupStatus.loading => const SplashRoute().location,
  SetupStatus.unauthenticated => const LoginRoute().location,
  SetupStatus.setupComplete => null,
};
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'const SplashRoute().location,', ruleName),
    ]);
  }

  Future<void> _reportsIsLoadingBranchInRedirectClosure() async {
    const source = '''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

final class AuthState {
  bool get isLoading => false;
}

String? Function() redirectFor(AuthState auth) => () {
  if (auth.isLoading) {
    return '/splash';
  }
  return null;
};
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "return '/splash';", ruleName),
    ]);
  }

  Future<void> _allowsSkillResolverThatStaysPutWhileLoading() async {
    await assertAllows('''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

String? resolveAppRedirect({required String location, required SetupStatus setupStatus}) {
  switch (setupStatus) {
    case SetupStatus.loading:
      return null;
    case SetupStatus.unauthenticated:
      return location == const LoginRoute().location ? null : const LoginRoute().location;
    case SetupStatus.setupComplete:
      return location == const LoginRoute().location ? '/home' : null;
  }
}
''');
  }

  Future<void> _allowsNegatedLoadingBranch() async {
    await assertAllows('''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

String? resolve(SetupStatus setupStatus, String location) {
  if (setupStatus != SetupStatus.loading && location == '/splash') return '/home';
  return null;
}
''');
  }

  Future<void> _allowsNonEnumLoadingConstant() async {
    await assertAllows('''
import 'package:go_router/go_router.dart';

enum SetupStatus { loading, unauthenticated, setupComplete }

class SplashRoute extends GoRouteData {
  const SplashRoute();
}

class LoginRoute extends GoRouteData {
  const LoginRoute();
}

abstract final class Steps {
  static const loading = 0;
}

String? resolve(int step) {
  if (step == Steps.loading) return '/intro';
  return null;
}
''');
  }

  Future<void> _allowsLoadingComparisonInsideOtherCase() async {
    await assertAllows(r'''
enum SetupStatus { loading, unauthenticated }

String? resolve(SetupStatus setupStatus, SetupStatus previous) {
  switch (setupStatus) {
    case SetupStatus.unauthenticated:
      if (previous != SetupStatus.loading) return '/login';
      return null;
    case SetupStatus.loading:
      return null;
  }
}
''');
  }
}

final class RouterSplashWaitsForInitialSyncTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_splash_waits_for_initial_sync';
  @override
  String get needle => 'InitialSyncStatus.syncing';
  @override
  String get source => r'''
String? resolveAppRedirect({
  required String currentPath,
  required AuthState authState,
  required InitialSyncStatus syncStatus,
}) {
  if (_shouldStayOnSplash(currentPath, authState, syncStatus)) return null;
  return null;
}

bool _shouldStayOnSplash(String currentPath, AuthState authState, InitialSyncStatus syncStatus) {
  if (currentPath != '/splash') return false;
  final awaitingInitialSync = authState.isAuthenticated && syncStatus == InitialSyncStatus.syncing;
  return authState.isLoading || awaitingInitialSync;
}
''';

  Future<void> _allowsAuthLoadingSplashGate() async {
    await assertAllows(r'''
String? resolveAppRedirect({
  required String currentPath,
  required AuthState authState,
}) {
  if (currentPath == '/splash' && authState.isLoading) return null;
  return currentPath == '/splash' ? '/home' : null;
}
''');
  }

  Future<void> _allowsInitialSyncStatusOutsideSplashRedirect() async {
    await assertAllows(r'''
void logSyncStatus(InitialSyncStatus status) {
  if (status == InitialSyncStatus.syncing) {
    print('syncing');
  }
}
''');
  }
}

final class RouterComplexExtraTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_complex_extra';
  @override
  String get needle => r'this.$extra';
  @override
  String get source => r'''
class Item {}

class ActiveItemRoute extends GoRouteData {
  const ActiveItemRoute({this.$extra});

  final Item? $extra;
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, r'$extra});', ruleName),
      compatLint(analyzedSource, r'$extra;', ruleName),
    ]);
  }

  Future<void> _reportsTypedRouteExtraCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(item) {
  ActiveItemRoute($extra: item);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, r'$extra:', ruleName)]);
  }

  Future<void> _reportsGoRouterStateExtraRead() async {
    final analyzedSource = _analyzedSource(r'''
class Item {}

void build(context) {
  final routeItem = GoRouterState.of(context).extra as Item?;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouterState.of(context).extra', ruleName),
    ]);
  }

  Future<void> _reportsContextNavigationExtraArgument() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, item) {
  context.push('/active_item', extra: item);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'extra: item', ruleName)]);
  }

  Future<void> _allowsTypedRouteWithoutExtra() async {
    await assertAllows(r'''
class ActiveItemRoute extends GoRouteData {
  const ActiveItemRoute();
}

void open(context) {
  const ActiveItemRoute().push<void>(context);
}
''');
  }

  Future<void> _allowsTestFixtureExtraRead() async {
    await assertAllows(r'''
void build(state) {
  final text = state.extra == null ? 'active:no-extra' : 'active:has-extra';
}
''', path: '$testPackageRootPath/test/features/home/home_screen_auto_resume_test.dart');
  }

  Future<void> _allowsUnrelatedNamedExtraArgument() async {
    await assertAllows(r'''
class DetailPanel {
  const DetailPanel({required this.extra});

  final Object extra;
}

void build(value) {
  DetailPanel(extra: value);
}
''');
  }
}

void _defineSourceScannerRulesPart08Tests() {
  analysisRuleSuite<BareStateMountedForbiddenTest>(
    'BareStateMountedForbiddenTest',
    BareStateMountedForbiddenTest.new,
    {
      'test_reportsThisMounted': (t) => t._reportsThisMounted(),
      'test_allowsContextAndRefMounted': (t) => t._allowsContextAndRefMounted(),
      'test_allowsNonWidgetMountedMember': (t) => t._allowsNonWidgetMountedMember(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RouterStringNavTest>('RouterStringNavTest', RouterStringNavTest.new, {
    'test_allowsTestHostStringRoutes': (t) => t._allowsTestHostStringRoutes(),
    'test_reportsRouterStringInsideCoreRouter': (t) => t._reportsRouterStringInsideCoreRouter(),
    'test_reportsRouterPushNamedInsideCoreRouter': (t) =>
        t._reportsRouterPushNamedInsideCoreRouter(),
    'test_reportsCamelCaseRouterVariableInsideCoreRouter': (t) =>
        t._reportsCamelCaseRouterVariableInsideCoreRouter(),
    'test_reportsRawInitialLocationInsideCoreRouter': (t) =>
        t._reportsRawInitialLocationInsideCoreRouter(),
    'test_allowsTypedLocationsForStringNavRule': (t) => t._allowsTypedLocationsForStringNavRule(),
    'test_allowsTypedRouteDefinitions': (t) => t._allowsTypedRouteDefinitions(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<RouterPopThenPushTest>('RouterPopThenPushTest', RouterPopThenPushTest.new, {
    'test_allowsSkillSafePopAfterEarlierPushReplacement': (t) =>
        t._allowsSkillSafePopAfterEarlierPushReplacement(),
    'test_reportsNavigatorPopThenTypedRoutePush': (t) => t._reportsNavigatorPopThenTypedRoutePush(),
    'test_allowsSkillPopWithResultThenCallerPush': (t) =>
        t._allowsSkillPopWithResultThenCallerPush(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<PopFallbackHelperMustCheckNavigatorStackTest>(
    'PopFallbackHelperMustCheckNavigatorStackTest',
    PopFallbackHelperMustCheckNavigatorStackTest.new,
    {
      'test_allowsNavigatorStackChecks': (t) => t._allowsNavigatorStackChecks(),
      'test_reportsMissingMountedGuard': (t) => t._reportsMissingMountedGuard(),
      'test_reportsMissingLocalNavigatorCheck': (t) => t._reportsMissingLocalNavigatorCheck(),
      'test_reportsMissingRootNavigatorCheck': (t) => t._reportsMissingRootNavigatorCheck(),
      'test_allowsNonFallbackHelper': (t) => t._allowsNonFallbackHelper(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RouterRedirectWatchTest>(
    'RouterRedirectWatchTest',
    RouterRedirectWatchTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<RouterRedirectLoadingBounceTest>(
    'RouterRedirectLoadingBounceTest',
    RouterRedirectLoadingBounceTest.new,
    {
      'test_reportsLoadingSwitchCaseReturningTypedLocation': (t) =>
          t._reportsLoadingSwitchCaseReturningTypedLocation(),
      'test_reportsFallThroughLoadingCase': (t) => t._reportsFallThroughLoadingCase(),
      'test_reportsLoadingSwitchExpressionCase': (t) => t._reportsLoadingSwitchExpressionCase(),
      'test_reportsIsLoadingBranchInRedirectClosure': (t) =>
          t._reportsIsLoadingBranchInRedirectClosure(),
      'test_allowsSkillResolverThatStaysPutWhileLoading': (t) =>
          t._allowsSkillResolverThatStaysPutWhileLoading(),
      'test_allowsNegatedLoadingBranch': (t) => t._allowsNegatedLoadingBranch(),
      'test_allowsNonEnumLoadingConstant': (t) => t._allowsNonEnumLoadingConstant(),
      'test_allowsLoadingComparisonInsideOtherCase': (t) =>
          t._allowsLoadingComparisonInsideOtherCase(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RouterSplashWaitsForInitialSyncTest>(
    'RouterSplashWaitsForInitialSyncTest',
    RouterSplashWaitsForInitialSyncTest.new,
    {
      'test_allowsAuthLoadingSplashGate': (t) => t._allowsAuthLoadingSplashGate(),
      'test_allowsInitialSyncStatusOutsideSplashRedirect': (t) =>
          t._allowsInitialSyncStatusOutsideSplashRedirect(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RouterComplexExtraTest>('RouterComplexExtraTest', RouterComplexExtraTest.new, {
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    'test_reportsTypedRouteExtraCall': (t) => t._reportsTypedRouteExtraCall(),
    'test_reportsGoRouterStateExtraRead': (t) => t._reportsGoRouterStateExtraRead(),
    'test_reportsContextNavigationExtraArgument': (t) => t._reportsContextNavigationExtraArgument(),
    'test_allowsTypedRouteWithoutExtra': (t) => t._allowsTypedRouteWithoutExtra(),
    'test_allowsTestFixtureExtraRead': (t) => t._allowsTestFixtureExtraRead(),
    'test_allowsUnrelatedNamedExtraArgument': (t) => t._allowsUnrelatedNamedExtraArgument(),
  });
}
