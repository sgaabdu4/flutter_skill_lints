// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RouterDirectRouteCallTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_direct_route_call';
  @override
  String get needle => 'context.go';
  @override
  String get source => r'''
void open(context, String id) {
  context.go(ProductDetailRoute(id: id).location);
}
''';

  Future<void> test_allowsGeneratedTypedRouteGo() async {
    await assertAllows(r'''
class ProductDetailRoute {
  ProductDetailRoute({required String id});
  void go(Object context) {}
}

void open(context, String id) {
  ProductDetailRoute(id: id).go(context);
}
''');
  }

  Future<void> test_allowsConstTypedRoutePush() async {
    await assertAllows(r'''
class ProductCreateRoute {
  const ProductCreateRoute();
  Future<T?> push<T>(Object context) async => null;
}

void open(context) {
  const ProductCreateRoute().push<void>(context);
}
''');
  }

  Future<void> test_reportsContextGoWithTypedLocation() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, String id) {
  context.go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'context.go', ruleName)]);
  }

  Future<void> test_reportsInjectedRouterGo() async {
    final analyzedSource = _analyzedSource(r'''
void open(router, String id) {
  router.go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'router.go', ruleName)]);
  }

  Future<void> test_reportsCamelCaseInjectedRouterGo() async {
    final analyzedSource = _analyzedSource(r'''
void open(appRouter, String id) {
  appRouter.go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'appRouter.go', ruleName)]);
  }

  Future<void> test_reportsRouterConvenienceGoHome() async {
    final analyzedSource = _analyzedSource(r'''
void open(router) {
  router.goHome();
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router.goHome', ruleName),
    ]);
  }

  Future<void> test_reportsCamelCaseRouterConveniencePush() async {
    final analyzedSource = _analyzedSource(r'''
void open(appRouter, String itemId) {
  appRouter.pushItem(itemId);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'appRouter.pushItem', ruleName),
    ]);
  }

  Future<void> test_reportsContextConvenienceGoHome() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  context.goHome();
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'context.goHome', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineContextGo() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, String id) {
  context
      .go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'context\n      .go', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineInjectedRouterGo() async {
    final analyzedSource = _analyzedSource(r'''
void open(router, String id) {
  router
      .go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router\n      .go', ruleName),
    ]);
  }

  Future<void> test_allowsContextPopHelperCall() async {
    await assertAllows(r'''
void close(context) {
  context.popIfCan();
  context.popWithFallback(const HomeRoute());
}

class HomeRoute {
  const HomeRoute();
}
''');
  }

  Future<void> test_allowsNavigatorMaybePopForLocalDismissal() async {
    await assertAllows(r'''
void close(context) {
  Navigator.of(context).maybePop().then((_) {});
}
''');
  }

  Future<void> test_allowsShellGoBranch() async {
    await assertAllows(r'''
void selectTab(navigationShell) {
  navigationShell.goBranch(1);
}
''');
  }

  Future<void> test_allowsLocalModalApi() async {
    await assertAllows(r'''
void confirm(context) {
  showDialog<bool>(context: context, builder: (_) => null);
}
''');
  }

  Future<void> test_reportsPublicStaticCoordinatorCallOutsideCoreNavigation() async {
    final analyzedSource = _analyzedSource(r'''
void close(context) {
  FeatureNavigationCoordinator.popIfCan(context);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'FeatureNavigationCoordinator.popIfCan', ruleName),
    ]);
  }

  Future<void> test_reportsRouterGoEvenInCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  void go(String location) {}
}

class ProductDetailRoute {
  ProductDetailRoute({required String id});
  String get location => '';
}

final class RouterBridge {
  RouterBridge(this._router);
  final GoRouter _router;

  void showProduct(String id) {
    _router.go(ProductDetailRoute(id: id).location);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/router_provider.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '_router.go', ruleName)]);
  }

  Future<void> test_allowsFallbackRouteGoHelper() async {
    await assertAllows(r'''
final class FeatureNavigation {
  void popWithFallback(fallbackRoute) {
    fallbackRoute.go(this);
  }
}
''');
  }

  Future<void> test_reportsTestFileRawNavigation() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, String id) {
  context.pushNamed('detail');
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageRootPath/test/navigation_test.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'context.pushNamed', ruleName),
    ]);
  }

  Future<void> test_scansPartFileSourceInsteadOfDefiningLibrary() async {
    final libraryPath = '$testPackageLibPath/core/widgets/organisms/next_up_card.dart';
    final partPath = '$testPackageLibPath/core/widgets/organisms/start_button.dart';
    final librarySource = _analyzedSource(r'''
part 'start_button.dart';

void open(context) {
  context.go(ProductDetailRoute().location);
}
''', addIgnorePrefix: addIgnorePrefix);
    final partSource = _analyzedSource(r'''
part of 'next_up_card.dart';

class StartButton {
  void build() {}
}
''', addIgnorePrefix: addIgnorePrefix);

    newFile(libraryPath, librarySource);
    newFile(partPath, partSource);

    await assertDiagnosticsInFile(libraryPath, [compatLint(librarySource, 'context.go', ruleName)]);
    await assertNoDiagnosticsInFile(partPath);
  }
}

@reflectiveTest
final class RouterRawRouteDefinitionTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_raw_route_definition';
  @override
  String get needle => 'GoRoute(';
  @override
  String get source => r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''';

  Future<void> test_reportsRawGoRouteOutsideRouterBoundary() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/products/product_screen.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRoute(', ruleName)]);
  }

  Future<void> test_reportsRawGoRouteWithSeparatedCallParen() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRoute
      (path: '/detail', builder: (_, _) => null);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/products/product_screen.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRoute', ruleName)]);
  }

  Future<void> test_reportsRawShellRouteOutsideRouterBoundary() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  StatefulShellRoute.indexedStack(branches: const []);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/home/home_shell.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'StatefulShellRoute.indexedStack', ruleName),
    ]);
  }

  Future<void> test_reportsRawGoRouterOutsideRouterBoundary() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRouter(routes: const []);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/products/product_screen.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRouter(', ruleName)]);
  }

  Future<void> test_allowsRouterBoundary() async {
    await assertAllows(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', path: '$testPackageLibPath/core/router/app_routes.dart');
  }

  Future<void> test_reportsTestHarnessRouterOutsideHelper() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageRootPath/test/product_screen_test.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRoute(', ruleName)]);
  }

  Future<void> test_allowsSharedTestRouterHelper() async {
    await assertAllows(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', path: '$testPackageRootPath/test/helpers/router_test_utils.dart');
  }
}

@reflectiveTest
final class RouterModalLocalHelpersTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_modal_local_helpers';
  @override
  String get needle => 'featureNavigationCoordinatorProvider';
  @override
  String get source => r'''
void open(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).showScrollableBottomSheet<int>(
    context: context,
    builder: (_) => null,
  );
}
''';

  Future<void> test_reportsModalRouteAbstraction() async {
    final analyzedSource = _analyzedSource(r'''
abstract class ProductModalRoute<T> extends ModalRouteBase<T> {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ProductModalRoute', ruleName),
    ]);
  }

  Future<void> test_reportsProviderPresent() async {
    final analyzedSource = _analyzedSource(r'''
void open(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).present(
    context,
    NumberPickerModalRoute(value: 1),
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'featureNavigationCoordinatorProvider', ruleName),
      compatLint(analyzedSource, 'NumberPickerModalRoute', ruleName),
    ]);
  }

  Future<void> test_allowsLocalBottomSheetHelper() async {
    await assertAllows(r'''
void open(context) {
  context.showScrollableBottomSheet<int>(builder: (_) => null);
}
''');
  }

  Future<void> test_allowsThemedDialogHelper() async {
    await assertAllows(r'''
void open(context) {
  DialogTheme.showDialog<bool>(context: context, builder: (_) => null);
}
''');
  }
}

@reflectiveTest
final class RouterProviderScopeNavigationReadTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_container_navigation_escape';
  @override
  String get needle => 'ProviderScope.containerOf';
  @override
  String get source => r'''
void open(context) {
  final selected = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''';

  Future<void> test_reportsMultilineReadAfterContainerLookup() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ProviderScope.containerOf', ruleName),
    ]);
  }

  Future<void> test_reportsRouterDelegateNavigatorContext() async {
    final analyzedSource = _analyzedSource(r'''
class HomeRoute {
  const HomeRoute();
  void go(Object context) {}
}

void open(router) {
  final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
  if (navigatorContext == null) return;
  const HomeRoute().go(navigatorContext);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router.routerDelegate.navigatorKey.currentContext', ruleName),
    ]);
  }

  Future<void> test_reportsNavigatorKeyCurrentContext() async {
    final analyzedSource = _analyzedSource(r'''
class HomeRoute {
  const HomeRoute();
  void go(Object context) {}
}

void open(navigatorKey) {
  final navigatorContext = navigatorKey.currentContext;
  if (navigatorContext == null) return;
  const HomeRoute().go(navigatorContext);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'navigatorKey.currentContext', ruleName),
    ]);
  }

  Future<void> test_allowsUnrelatedProviderScopeRead() async {
    await assertAllows(r'''
void open(context) {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(itemRepositoryProvider);
}
''');
  }

  Future<void> test_allowsWidgetRefNavigationRead() async {
    await assertAllows(r'''
void open(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''');
  }
}

abstract class _NotifierRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => notifierSourceRules;
}

abstract class _NotifierFixtureTest extends _NotifierRuleTest {
  @override
  String get needle => 'void updateTodo';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Notifier<T> {
  Ref get ref => Ref();
}

class Ref {
  Object watch(Object provider) => Object();
}

class Repository {
  void save() {}
}

final provider = Object();

class TodosNotifier extends Notifier<int> {
  final Repository _repository = Repository();

  void updateTodo() {
    ref.watch(provider);
    _repository.save();
  }
}
''';
}
