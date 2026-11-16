part of '../source_scanner_rules_test.dart';

final class _RouterDirectRouteCallTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterDirectRouteCallTest)> get _allCases =>
      caseSet<_RouterDirectRouteCallTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsGeneratedTypedRouteGo': (t) => t._allowsGeneratedTypedRouteGo(),
          'test_allowsConstTypedRoutePush': (t) => t._allowsConstTypedRoutePush(),
          'test_reportsTypedLocationOnExplicitRouter': (t) =>
              t._reportsTypedLocationOnExplicitRouter(),
          'test_reportsRawLocationOnExplicitRouter': (t) => t._reportsRawLocationOnExplicitRouter(),
          'test_reportsContextGoWithTypedLocation': (t) => t._reportsContextGoWithTypedLocation(),
          'test_reportsInjectedRouterGo': (t) => t._reportsInjectedRouterGo(),
          'test_reportsCamelCaseInjectedRouterGo': (t) => t._reportsCamelCaseInjectedRouterGo(),
          'test_reportsRouterConvenienceGoHome': (t) => t._reportsRouterConvenienceGoHome(),
          'test_reportsCamelCaseRouterConveniencePush': (t) =>
              t._reportsCamelCaseRouterConveniencePush(),
          'test_reportsContextConvenienceGoHome': (t) => t._reportsContextConvenienceGoHome(),
          'test_reportsMultilineContextGo': (t) => t._reportsMultilineContextGo(),
          'test_reportsMultilineInjectedRouterGo': (t) => t._reportsMultilineInjectedRouterGo(),
          'test_allowsContextPopHelperCall': (t) => t._allowsContextPopHelperCall(),
          'test_allowsNavigatorMaybePopForLocalDismissal': (t) =>
              t._allowsNavigatorMaybePopForLocalDismissal(),
          'test_allowsShellGoBranch': (t) => t._allowsShellGoBranch(),
          'test_allowsLocalModalApi': (t) => t._allowsLocalModalApi(),
          'test_reportsPublicStaticCoordinatorCallOutsideCoreNavigation': (t) =>
              t._reportsPublicStaticCoordinatorCallOutsideCoreNavigation(),
          'test_reportsRouterGoEvenInCoreRouter': (t) => t._reportsRouterGoEvenInCoreRouter(),
          'test_allowsFallbackRouteGoHelper': (t) => t._allowsFallbackRouteGoHelper(),
          'test_reportsTestFileRawNavigation': (t) => t._reportsTestFileRawNavigation(),
          'test_scansPartFileSourceInsteadOfDefiningLibrary': (t) =>
              t._scansPartFileSourceInsteadOfDefiningLibrary(),
          'test_reportsInjectedRouterNavigation': (t) => t._reportsInjectedRouterNavigation(),
          'test_allowsTypedRouteNavigation': (t) => t._allowsTypedRouteNavigation(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

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

  Future<void> _allowsGeneratedTypedRouteGo() async {
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

  Future<void> _allowsConstTypedRoutePush() async {
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

  Future<void> _reportsTypedLocationOnExplicitRouter() async {
    const source = r'''
import 'package:go_router/go_router.dart';

class ItemRoute extends GoRouteData {
  const ItemRoute();
}
class RouterHolder {
  RouterHolder(this.rootRouter);
  final GoRouter rootRouter;
}
void open(GoRouter router, GoRouteData route, RouterHolder holder) {
  router.go(route.location);
  router.go(const ItemRoute().location);
  holder.rootRouter.go(route.location);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router.go(route.location)', ruleName),
      compatLint(analyzedSource, 'router.go(const ItemRoute()', ruleName),
      compatLint(analyzedSource, 'rootRouter.go', ruleName),
    ]);
  }

  Future<void> _reportsRawLocationOnExplicitRouter() async {
    const source = r'''
import 'package:go_router/go_router.dart';

void open(GoRouter router, String location) {
  router.go(location);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'router.go', ruleName)]);
  }

  Future<void> _reportsContextGoWithTypedLocation() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, String id) {
  context.go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'context.go', ruleName)]);
  }

  Future<void> _reportsInjectedRouterGo() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:go_router/go_router.dart';

void open(router, String id, GoRouter goodRouter, GoRouteData route, bool ok) {
  router.go(ProductDetailRoute(id: id).location);
  ok ? goodRouter.go(route.location) : router.go('/raw');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router.go', ruleName),
      compatLint(analyzedSource, 'goodRouter.go', ruleName),
    ]);
  }

  Future<void> _reportsCamelCaseInjectedRouterGo() async {
    final analyzedSource = _analyzedSource(r'''
void open(appRouter, String id) {
  appRouter.go(ProductDetailRoute(id: id).location);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'appRouter.go', ruleName)]);
  }

  Future<void> _reportsRouterConvenienceGoHome() async {
    final analyzedSource = _analyzedSource(r'''
void open(router) {
  router.goHome();
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'router.goHome', ruleName),
    ]);
  }

  Future<void> _reportsCamelCaseRouterConveniencePush() async {
    final analyzedSource = _analyzedSource(r'''
void open(appRouter, String itemId) {
  appRouter.pushItem(itemId);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'appRouter.pushItem', ruleName),
    ]);
  }

  Future<void> _reportsContextConvenienceGoHome() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  context.goHome();
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'context.goHome', ruleName),
    ]);
  }

  Future<void> _reportsMultilineContextGo() async {
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

  Future<void> _reportsMultilineInjectedRouterGo() async {
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

  Future<void> _allowsContextPopHelperCall() async {
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

  Future<void> _allowsNavigatorMaybePopForLocalDismissal() async {
    await assertAllows(r'''
void close(context) {
  Navigator.of(context).maybePop().then((_) {});
}
''');
  }

  Future<void> _allowsShellGoBranch() async {
    await assertAllows(r'''
void selectTab(navigationShell) {
  navigationShell.goBranch(1);
}
''');
  }

  Future<void> _allowsLocalModalApi() async {
    await assertAllows(r'''
void confirm(context) {
  showDialog<bool>(context: context, builder: (_) => null);
}
''');
  }

  Future<void> _reportsPublicStaticCoordinatorCallOutsideCoreNavigation() async {
    for (final (index, body) in [
      'FeatureNavigationCoordinator.popIfCan(context);',
      'ok ? router.go(route.location) : FeatureNavigationCoordinator.popIfCan(context);',
      'FeatureNavigationCoordinator.open(router).go(route.location);',
    ].indexed) {
      final analyzedSource = _analyzedSource('''
import 'package:go_router/go_router.dart';

class FeatureNavigationCoordinator {
  static void popIfCan(Object context) {}
  static GoRouter open(GoRouter router) => router;
}
void close(Object context, bool ok, GoRouter router, GoRouteData route) {
  $body
}
''', addIgnorePrefix: addIgnorePrefix);

      final filePath = '$testPackageLibPath/features/coordinator_case_$index.dart';
      newFile(filePath, analyzedSource);
      await assertDiagnosticsInFile(filePath, [
        compatLint(analyzedSource, 'FeatureNavigationCoordinator.', ruleName),
      ]);
    }
  }

  Future<void> _reportsRouterGoEvenInCoreRouter() async {
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

  Future<void> _allowsFallbackRouteGoHelper() async {
    await assertAllows(r'''
final class FeatureNavigation {
  void popWithFallback(fallbackRoute) {
    fallbackRoute.go(this);
  }
}
''');
  }

  Future<void> _reportsTestFileRawNavigation() async {
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

  Future<void> _scansPartFileSourceInsteadOfDefiningLibrary() async {
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

  Future<void> _reportsInjectedRouterNavigation() async {
    const source = r'''
import 'package:go_router/go_router.dart';

GoRouter readRouter() => GoRouter();

void openHome() {
  readRouter().go('/home');
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "readRouter().go('/home');", ruleName),
    ]);
  }

  Future<void> _allowsTypedRouteNavigation() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

void openHome(BuildContext context) {
  const HomeRoute().go(context);
}
''');
  }
}

final class _RouterRawRouteDefinitionTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterRawRouteDefinitionTest)> get _allCases =>
      caseSet<_RouterRawRouteDefinitionTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsRawGoRouteOutsideRouterBoundary': (t) =>
              t._reportsRawGoRouteOutsideRouterBoundary(),
          'test_reportsRawGoRouteWithSeparatedCallParen': (t) =>
              t._reportsRawGoRouteWithSeparatedCallParen(),
          'test_reportsRawShellRouteOutsideRouterBoundary': (t) =>
              t._reportsRawShellRouteOutsideRouterBoundary(),
          'test_reportsRawGoRouterOutsideRouterBoundary': (t) =>
              t._reportsRawGoRouterOutsideRouterBoundary(),
          'test_allowsRouterBoundary': (t) => t._allowsRouterBoundary(),
          'test_reportsTestHarnessRouterOutsideHelper': (t) =>
              t._reportsTestHarnessRouterOutsideHelper(),
          'test_allowsSharedTestRouterHelper': (t) => t._allowsSharedTestRouterHelper(),
        },
      );

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

  Future<void> _reportsRawGoRouteOutsideRouterBoundary() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/products/product_screen.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRoute(', ruleName)]);
  }

  Future<void> _reportsRawGoRouteWithSeparatedCallParen() async {
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

  Future<void> _reportsRawShellRouteOutsideRouterBoundary() async {
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

  Future<void> _reportsRawGoRouterOutsideRouterBoundary() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRouter(routes: const []);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/features/products/product_screen.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRouter(', ruleName)]);
  }

  Future<void> _allowsRouterBoundary() async {
    await assertAllows(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', path: '$testPackageLibPath/core/router/app_routes.dart');
  }

  Future<void> _reportsTestHarnessRouterOutsideHelper() async {
    final analyzedSource = _analyzedSource(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageRootPath/test/product_screen_test.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'GoRoute(', ruleName)]);
  }

  Future<void> _allowsSharedTestRouterHelper() async {
    await assertAllows(r'''
void build() {
  GoRoute(path: '/detail', builder: (_, _) => null);
}
''', path: '$testPackageRootPath/test/helpers/router_test_utils.dart');
  }
}

final class _RouterModalLocalHelpersTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterModalLocalHelpersTest)> get _allCases =>
      caseSet<_RouterModalLocalHelpersTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsModalRouteAbstraction': (t) => t._reportsModalRouteAbstraction(),
          'test_reportsProviderPresent': (t) => t._reportsProviderPresent(),
          'test_allowsLocalBottomSheetHelper': (t) => t._allowsLocalBottomSheetHelper(),
          'test_allowsThemedDialogHelper': (t) => t._allowsThemedDialogHelper(),
        },
      );

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

  Future<void> _reportsModalRouteAbstraction() async {
    final analyzedSource = _analyzedSource(r'''
abstract class ProductModalRoute<T> extends ModalRouteBase<T> {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ProductModalRoute', ruleName),
    ]);
  }

  Future<void> _reportsProviderPresent() async {
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

  Future<void> _allowsLocalBottomSheetHelper() async {
    await assertAllows(r'''
void open(context) {
  context.showScrollableBottomSheet<int>(builder: (_) => null);
}
''');
  }

  Future<void> _allowsThemedDialogHelper() async {
    await assertAllows(r'''
void open(context) {
  DialogTheme.showDialog<bool>(context: context, builder: (_) => null);
}
''');
  }
}

final class _RouterProviderScopeNavigationReadTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterProviderScopeNavigationReadTest)> get _allCases =>
      caseSet<_RouterProviderScopeNavigationReadTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsMultilineReadAfterContainerLookup': (t) =>
              t._reportsMultilineReadAfterContainerLookup(),
          'test_reportsRouterDelegateNavigatorContext': (t) =>
              t._reportsRouterDelegateNavigatorContext(),
          'test_reportsNavigatorKeyCurrentContext': (t) => t._reportsNavigatorKeyCurrentContext(),
          'test_allowsUnrelatedProviderScopeRead': (t) => t._allowsUnrelatedProviderScopeRead(),
          'test_allowsWidgetRefNavigationRead': (t) => t._allowsWidgetRefNavigationRead(),
          'test_reportsNavigatorGlobalKeyCurrentContext': (t) =>
              t._reportsNavigatorGlobalKeyCurrentContext(),
          'test_allowsNonNavigatorGlobalKeyCurrentContext': (t) =>
              t._allowsNonNavigatorGlobalKeyCurrentContext(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

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

  Future<void> _reportsMultilineReadAfterContainerLookup() async {
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

  Future<void> _reportsRouterDelegateNavigatorContext() async {
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

  Future<void> _reportsNavigatorKeyCurrentContext() async {
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

  Future<void> _allowsUnrelatedProviderScopeRead() async {
    await assertAllows(r'''
void open(context) {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(itemRepositoryProvider);
}
''');
  }

  Future<void> _allowsWidgetRefNavigationRead() async {
    await assertAllows(r'''
void open(ref, context) {
  ref.read(featureNavigationCoordinatorProvider).present(context, NumberPickerModalRoute());
}
''');
  }

  Future<void> _reportsNavigatorGlobalKeyCurrentContext() async {
    const source = r'''
import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

BuildContext? escape() {
  return rootNavigatorKey.currentContext;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'rootNavigatorKey.currentContext;', ruleName),
    ]);
  }

  Future<void> _allowsNonNavigatorGlobalKeyCurrentContext() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

class FormState {}

final formKey = GlobalKey<FormState>();

BuildContext? formContext() => formKey.currentContext;
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

const _notifierRefRiverpodStub = r'''
class Ref {}

abstract class AnyNotifier<StateT, ValueT> {
  Ref get ref => throw UnimplementedError();
}

abstract class Notifier<T> extends AnyNotifier<T, T> {}

abstract class AsyncNotifier<T> extends AnyNotifier<Future<T>, T> {}
''';

final class _NotifierStoredRefFieldTest extends _NotifierRuleTest {
  static Map<String, Future<void> Function(_NotifierStoredRefFieldTest)> get _allCases =>
      caseSet<_NotifierStoredRefFieldTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsInferredRefField': (t) => t._reportsInferredRefField(),
          'test_reportsAnnotatedNotifierBeforeCodegen': (t) =>
              t._reportsAnnotatedNotifierBeforeCodegen(),
          'test_allowsRefFieldOutsideNotifier': (t) => t._allowsRefFieldOutsideNotifier(),
          'test_allowsInheritedRefAndNonRefFields': (t) => t._allowsInheritedRefAndNonRefFields(),
          'test_allowsUnrelatedRefTypeInNotifierLikeClass': (t) =>
              t._allowsUnrelatedRefTypeInNotifierLikeClass(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _notifierRefRiverpodStub);
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
export 'package:riverpod/riverpod.dart' show Ref;

class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();
''');
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_stored_ref_field';
  @override
  String get needle => '_savedRef';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<int> {
  late final Ref _savedRef = ref;

  int build() => 0;
}
''';

  Future<void> _reportsInferredRefField() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod/riverpod.dart';

class OrdersNotifier extends AsyncNotifier<int> {
  late final _r = ref;

  Future<int> build() async => 0;
}
''', addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_r = ref', ruleName)]);
  }

  Future<void> _reportsAnnotatedNotifierBeforeCodegen() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class ProductEditorNotifier extends _$ProductEditorNotifier {
  Ref? _ref;

  int build() => 0;
}
''', addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_ref;', ruleName)]);
  }

  Future<void> _allowsRefFieldOutsideNotifier() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class CartSession {
  CartSession(this._ref);

  final Ref _ref;
}
''');
  }

  Future<void> _allowsInheritedRefAndNonRefFields() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<int> {
  final _pending = <int>[];

  int build() {
    final current = ref;
    return _pending.length + (identical(current, ref) ? 0 : 1);
  }
}
''');
  }

  Future<void> _allowsUnrelatedRefTypeInNotifierLikeClass() async {
    await assertAllows(r'''
class Ref {}

class Notifier<T> {}

class CartNotifier extends Notifier<int> {
  final Ref _ref = Ref();
}
''');
  }

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

final class _NotifierTimerWithoutOnDisposeTest extends _NotifierRuleTest {
  static Map<String, Future<void> Function(_NotifierTimerWithoutOnDisposeTest)> get _allCases =>
      caseSet<_NotifierTimerWithoutOnDisposeTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsSkillDraftNotifierAsWritten': (t) => t._reportsSkillDraftNotifierAsWritten(),
          'test_allowsTimerCancelledInOnDispose': (t) => t._allowsTimerCancelledInOnDispose(),
          'test_allowsTimerOutsideNotifier': (t) => t._allowsTimerOutsideNotifier(),
          'test_allowsLocalTimerLookalike': (t) => t._allowsLocalTimerLookalike(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_timer_without_on_dispose';
  @override
  String get needle => '_debounce;';
  @override
  String get source => '''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class ProductSearch extends Notifier<List<String>> {
  Timer? _debounce;

  @override
  List<String> build() => const <String>[];

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {});
  }
}
''';

  Future<void> _reportsSkillDraftNotifierAsWritten() async {
    const source = '''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class DraftNotifier extends AsyncNotifier<String> {
  Timer? _persistTimer;

  @override
  Future<String> build() async => '';

  void schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 50), () {});
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_persistTimer;', ruleName),
    ]);
  }

  Future<void> _allowsTimerCancelledInOnDispose() async {
    await assertAllows('''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class ProductSearchOk extends Notifier<List<String>> {
  Timer? _debounce;

  @override
  List<String> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const <String>[];
  }
}
''');
  }

  Future<void> _allowsTimerOutsideNotifier() async {
    await assertAllows('''
import 'dart:async';

class Ticker {
  Timer? _timer;
  void stop() => _timer?.cancel();
}
''');
  }

  Future<void> _allowsLocalTimerLookalike() async {
    await assertAllows('''
import 'package:riverpod/riverpod.dart';

class Timer {}

class Stopwatch extends Notifier<int> {
  Timer? _timer;

  @override
  int build() => 0;
}
''');
  }
}

void _defineSourceScannerRulesPart10Tests() {
  analysisRuleSuite<_RouterDirectRouteCallTest>(
    'RouterDirectRouteCallTest',
    _RouterDirectRouteCallTest.new,
    _RouterDirectRouteCallTest._allCases,
  );
  analysisRuleSuite<_RouterRawRouteDefinitionTest>(
    'RouterRawRouteDefinitionTest',
    _RouterRawRouteDefinitionTest.new,
    _RouterRawRouteDefinitionTest._allCases,
  );
  analysisRuleSuite<_RouterModalLocalHelpersTest>(
    'RouterModalLocalHelpersTest',
    _RouterModalLocalHelpersTest.new,
    _RouterModalLocalHelpersTest._allCases,
  );
  analysisRuleSuite<_RouterProviderScopeNavigationReadTest>(
    'RouterProviderScopeNavigationReadTest',
    _RouterProviderScopeNavigationReadTest.new,
    _RouterProviderScopeNavigationReadTest._allCases,
  );
  analysisRuleSuite<_NotifierStoredRefFieldTest>(
    'NotifierStoredRefFieldTest',
    _NotifierStoredRefFieldTest.new,
    _NotifierStoredRefFieldTest._allCases,
  );
  analysisRuleSuite<_NotifierTimerWithoutOnDisposeTest>(
    'NotifierTimerWithoutOnDisposeTest',
    _NotifierTimerWithoutOnDisposeTest.new,
    _NotifierTimerWithoutOnDisposeTest._allCases,
  );
}
