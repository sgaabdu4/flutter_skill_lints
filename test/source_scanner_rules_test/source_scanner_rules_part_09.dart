// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RouterGoRouterOfTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_gorouter_of';
  @override
  String get needle => 'GoRouter.of(context).push';
  @override
  String get source => r'''
void open(context) {
  GoRouter.of(context).push('/detail');
}
''';

  Future<void> test_reportsGoCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).go('/home');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).go', ruleName),
    ]);
  }

  Future<void> test_reportsPushNamed() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).pushNamed('detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).pushNamed', ruleName),
    ]);
  }

  Future<void> test_reportsTypedGenericPush() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).push<bool>('/detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).push', ruleName),
    ]);
  }

  Future<void> test_allowsTypedRoutePush() async {
    await assertAllows(r'''
class ActiveItemRoute {
  const ActiveItemRoute();
  Future<T?> push<T>(context) async => null;
}

void open(context) {
  const ActiveItemRoute().push<void>(context);
}
''');
  }

  Future<void> test_reportsGoRouterOfInsideCoreRouter() async {
    final analyzedSource = _analyzedSource(r'''
class GoRouter {
  static GoRouter of(Object context) => GoRouter();
  Future<T?> push<T>(String location) async => null;
}

void open(context) {
  GoRouter.of(context).push<void>('/active_item');
}
''', addIgnorePrefix: addIgnorePrefix);
    final path = '$testPackageLibPath/core/router/router_provider.dart';

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'GoRouter.of(context).push', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineGoRouterOfPush() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter
      .of(context)
      .push<void>('/active_item');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'GoRouter', ruleName)]);
  }
}

@reflectiveTest
final class RouterUntypedNavigatorPushTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_untyped_navigator_push';
  @override
  String get needle => 'Navigator.of(context).push';
  @override
  String get source => r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
  Future<T?> pushReplacement<T>(Object route) async => null;
  Future<T?> pushAndRemoveUntil<T>(Object route, Object predicate) async => null;
  void pop() {}
}

class MaterialPageRoute {
  MaterialPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => null));
}
''';

  Future<void> test_reportsCupertinoPageRoute() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
}

class CupertinoPageRoute {
  CupertinoPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).push(CupertinoPageRoute(builder: (_) => null));
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).push', ruleName),
    ]);
  }

  Future<void> test_reportsPageRouteBuilder() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
}

class PageRouteBuilder {
  PageRouteBuilder({required Object pageBuilder});
}

void open(context) {
  Navigator.of(context).push(PageRouteBuilder(pageBuilder: (_, __, ___) => null));
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).push', ruleName),
    ]);
  }

  Future<void> test_reportsPushReplacement() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> pushReplacement<T>(Object route) async => null;
}

class MaterialPageRoute {
  MaterialPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => null),
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).pushReplacement', ruleName),
    ]);
  }

  Future<void> test_reportsPushAndRemoveUntil() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> pushAndRemoveUntil<T>(Object route, Object predicate) async => null;
}

class MaterialPageRoute {
  MaterialPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => null),
    (_) => false,
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).pushAndRemoveUntil', ruleName),
    ]);
  }

  Future<void> test_allowsNavigatorPop() async {
    await assertAllows(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  void pop() {}
}

void close(context) {
  Navigator.of(context).pop();
}
''');
  }

  Future<void> test_allowsTypedRoutePush() async {
    await assertAllows(r'''
class ActiveItemRoute {
  const ActiveItemRoute();
  Future<T?> push<T>(Object context) async => null;
}

void open(context) {
  const ActiveItemRoute().push<void>(context);
}
''', path: '$testPackageLibPath/core/router/app_routes.dart');
  }
}

@reflectiveTest
final class RouterContextNavigationExtensionTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_context_navigation_extension';
  @override
  String get needle => 'ProductDetailRoute(id: id).go';
  @override
  String get source => r'''
class BuildContext {}

class ProductDetailRoute {
  ProductDetailRoute({required String id});
  void go(BuildContext context) {}
}

extension ProductNavigationX on BuildContext {
  void showProduct(String id) {
    ProductDetailRoute(id: id).go(this);
  }
}
''';

  Future<void> test_allowsBottomSheetExtension() async {
    await assertAllows(r'''
class BuildContext {}

extension BottomSheetX on BuildContext {
  Future<T?> showScrollableBottomSheet<T>({required Object builder}) async => null;
}
''');
  }

  Future<void> test_allowsTypedFallbackContextExtension() async {
    await assertAllows(r'''
class BuildContext {}

class GoRouteData {
  void go(BuildContext context) {}
}

extension ContextNavigationX on BuildContext {
  bool popIfCan<T>([T? result]) => false;
  void popWithFallback<T>(GoRouteData fallbackRoute, [T? result]) {
    if (popIfCan<T>(result)) return;
    fallbackRoute.go(this);
  }
}
''');
  }

  Future<void> test_reportsTypedFallbackContextExtensionWithoutPopIfCan() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}

class GoRouteData {
  void go(BuildContext context) {}
}

extension ContextNavigationX on BuildContext {
  void popOrGo<T>(GoRouteData fallbackRoute, [T? result]) {
    fallbackRoute.go(this);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'fallbackRoute.go(this)', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineContextExtensionDeclaration() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}

class ProductDetailRoute {
  ProductDetailRoute({required String id});
  void go(BuildContext context) {}
}

extension ProductNavigationX
    on BuildContext {
  void showProduct(String id) {
    ProductDetailRoute(id: id).go(this);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ProductDetailRoute(id: id).go', ruleName),
    ]);
  }

  Future<void> test_reportsPrefixedContextExtensionDeclaration() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/widgets.dart' as widgets;

class ProductDetailRoute {
  ProductDetailRoute({required String id});
  void go(Object context) {}
}

extension ProductNavigationX on widgets.BuildContext {
  void showProduct(String id) {
    ProductDetailRoute(id: id).go(this);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ProductDetailRoute(id: id).go', ruleName),
    ]);
  }

  Future<void> test_reportsContextExtensionCallingTopLevelFallbackHelper() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}

class HomeRoute {
  const HomeRoute();
}

void popWithFallback(BuildContext context, HomeRoute route) {}

extension ContextNavigationX on BuildContext {
  void closeToHome() {
    popWithFallback(this, const HomeRoute());
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'popWithFallback(this', ruleName),
    ]);
  }

  Future<void> test_reportsRouteVariableContextExtension() async {
    final analyzedSource = _analyzedSource(r'''
class BuildContext {}

class ProductDetailRoute {
  ProductDetailRoute({required String id});
  void go(BuildContext context) {}
}

extension ProductNavigationX on BuildContext {
  void showProduct(String id) {
    final productRoute = ProductDetailRoute(id: id);
    productRoute.go(this);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'productRoute.go(this)', ruleName),
    ]);
  }

  Future<void> test_allowsNonNavigationContextExtension() async {
    await assertAllows(r'''
class BuildContext {}

extension ContextThemeX on BuildContext {
  Object get colors => Object();
}
''');
  }

  Future<void> test_allowsTopLevelFallbackHelperAfterContextExtension() async {
    await assertAllows(r'''
class BuildContext {}

class GoRouteData {
  void go(BuildContext context) {}
}

extension ContextThemeX on BuildContext {
  Object get colors => Object();
}

bool popIfCan<T>(BuildContext context, [T? result]) => false;

void popWithFallback<T>(BuildContext context, GoRouteData fallbackRoute, [T? result]) {
  if (popIfCan<T>(context, result)) return;
  fallbackRoute.go(context);
}
''');
  }
}

@reflectiveTest
final class RouterNavigationWrapperApiTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_navigation_wrapper_api';
  @override
  String get needle => 'class FeatureNavigationCoordinator';
  @override
  String get source => r'''
class FeatureNavigationCoordinator {}
''';

  Future<void> test_reportsPrivateNavigationCoordinatorImplementation() async {
    final analyzedSource = _analyzedSource(r'''
final class _FeatureNavigationCoordinator {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final class _FeatureNavigationCoordinator', ruleName),
    ]);
  }

  Future<void> test_reportsFeatureNavigationInterface() async {
    final analyzedSource = _analyzedSource(r'''
abstract interface class FeatureNavigation {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'abstract interface class FeatureNavigation', ruleName),
    ]);
  }

  Future<void> test_reportsFeatureNavigationCoordinator() async {
    final analyzedSource = _analyzedSource(r'''
final class ProductNavigationCoordinator {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final class ProductNavigationCoordinator', ruleName),
    ]);
  }

  Future<void> test_reportsRouteWrapperFunctionCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(router) {
  navigateToHomeRoute(router);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'navigateToHomeRoute', ruleName),
    ]);
  }

  Future<void> test_reportsRouteWrapperFunctionDeclaration() async {
    final analyzedSource = _analyzedSource(r'''
void navigateToHomeRoute(router) {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'navigateToHomeRoute', ruleName),
    ]);
  }
}
