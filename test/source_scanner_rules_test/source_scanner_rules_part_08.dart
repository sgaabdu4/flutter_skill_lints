// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
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

  Future<void> test_reportsThisMounted() async {
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

  Future<void> test_allowsContextAndRefMounted() async {
    await assertAllows(r'''
class ScreenState {
  void onFrame(context, ref) {
    if (!context.mounted) return;
    if (!ref.mounted) return;
  }
}
''', path: path);
  }

  Future<void> test_allowsNonWidgetMountedMember() async {
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

@reflectiveTest
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

  Future<void> test_allowsTestHostStringRoutes() async {
    await assertAllows(r'''
void navigate(context) {
  context.go('/host');
}
''', path: '$testPackageRootPath/test/features/home/home_screen_test.dart');
  }

  Future<void> test_reportsRouterStringInsideCoreRouter() async {
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

  Future<void> test_reportsRouterPushNamedInsideCoreRouter() async {
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

  Future<void> test_reportsCamelCaseRouterVariableInsideCoreRouter() async {
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

  Future<void> test_reportsRawInitialLocationInsideCoreRouter() async {
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

  Future<void> test_allowsTypedLocationsForStringNavRule() async {
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

  Future<void> test_allowsTypedRouteDefinitions() async {
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

@reflectiveTest
final class RouterPopThenPushTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_pop_then_push';
  @override
  String get needle => 'context.pop()';
  @override
  String get source => r'''
void navigate(context) {
  context.pop();
  context.push('/next');
}
''';
}

@reflectiveTest
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

  Future<void> test_allowsNavigatorStackChecks() async {
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

  Future<void> test_reportsMissingMountedGuard() async {
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

  Future<void> test_reportsMissingLocalNavigatorCheck() async {
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

  Future<void> test_reportsMissingRootNavigatorCheck() async {
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

  Future<void> test_allowsNonFallbackHelper() async {
    await assertAllows(r'''
class BuildContext {}

extension ContextNavigationX on BuildContext {
  bool popIfCan<T>([T? result]) => false;
}
''');
  }
}

@reflectiveTest
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

@reflectiveTest
final class RouterRedirectLoadingBounceTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_loading_bounce';
  @override
  String get needle => "if (isLoading) return '/loading';";
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    if (isLoading) return '/loading';
    return null;
  },
);
''';
}

@reflectiveTest
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

  Future<void> test_allowsAuthLoadingSplashGate() async {
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

  Future<void> test_allowsInitialSyncStatusOutsideSplashRedirect() async {
    await assertAllows(r'''
void logSyncStatus(InitialSyncStatus status) {
  if (status == InitialSyncStatus.syncing) {
    print('syncing');
  }
}
''');
  }
}

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, r'$extra});', ruleName),
      compatLint(analyzedSource, r'$extra;', ruleName),
    ]);
  }

  Future<void> test_reportsTypedRouteExtraCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(item) {
  ActiveItemRoute($extra: item);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, r'$extra:', ruleName)]);
  }

  Future<void> test_reportsGoRouterStateExtraRead() async {
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

  Future<void> test_reportsContextNavigationExtraArgument() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, item) {
  context.push('/active_item', extra: item);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'extra: item', ruleName)]);
  }

  Future<void> test_allowsTypedRouteWithoutExtra() async {
    await assertAllows(r'''
class ActiveItemRoute extends GoRouteData {
  const ActiveItemRoute();
}

void open(context) {
  const ActiveItemRoute().push<void>(context);
}
''');
  }

  Future<void> test_allowsTestFixtureExtraRead() async {
    await assertAllows(r'''
void build(state) {
  final text = state.extra == null ? 'active:no-extra' : 'active:has-extra';
}
''', path: '$testPackageRootPath/test/features/home/home_screen_auto_resume_test.dart');
  }

  Future<void> test_allowsUnrelatedNamedExtraArgument() async {
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
