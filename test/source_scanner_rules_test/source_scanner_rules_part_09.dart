part of '../source_scanner_rules_test.dart';

final class _RouterGoRouterOfTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterGoRouterOfTest)> get _allCases =>
      caseSet<_RouterGoRouterOfTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsGoCall': (t) => t._reportsGoCall(),
          'test_reportsPushNamed': (t) => t._reportsPushNamed(),
          'test_reportsTypedGenericPush': (t) => t._reportsTypedGenericPush(),
          'test_allowsTypedRoutePush': (t) => t._allowsTypedRoutePush(),
          'test_reportsGoRouterOfInsideCoreRouter': (t) => t._reportsGoRouterOfInsideCoreRouter(),
          'test_reportsMultilineGoRouterOfPush': (t) => t._reportsMultilineGoRouterOfPush(),
        },
      );

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

  Future<void> _reportsGoCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).go('/home');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).go', ruleName),
    ]);
  }

  Future<void> _reportsPushNamed() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).pushNamed('detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).pushNamed', ruleName),
    ]);
  }

  Future<void> _reportsTypedGenericPush() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).push<bool>('/detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).push', ruleName),
    ]);
  }

  Future<void> _allowsTypedRoutePush() async {
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

  Future<void> _reportsGoRouterOfInsideCoreRouter() async {
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

  Future<void> _reportsMultilineGoRouterOfPush() async {
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

final class _RouterUntypedNavigatorPushTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterUntypedNavigatorPushTest)> get _allCases =>
      caseSet<_RouterUntypedNavigatorPushTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsCupertinoPageRoute': (t) => t._reportsCupertinoPageRoute(),
          'test_reportsPageRouteBuilder': (t) => t._reportsPageRouteBuilder(),
          'test_reportsPushReplacement': (t) => t._reportsPushReplacement(),
          'test_reportsPushAndRemoveUntil': (t) => t._reportsPushAndRemoveUntil(),
          'test_allowsNavigatorPop': (t) => t._allowsNavigatorPop(),
          'test_allowsTypedRoutePush': (t) => t._allowsTypedRoutePush(),
        },
      );

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

  Future<void> _reportsCupertinoPageRoute() async {
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

  Future<void> _reportsPageRouteBuilder() async {
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

  Future<void> _reportsPushReplacement() async {
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

  Future<void> _reportsPushAndRemoveUntil() async {
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

  Future<void> _allowsNavigatorPop() async {
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

  Future<void> _allowsTypedRoutePush() async {
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

final class _RouterContextNavigationExtensionTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterContextNavigationExtensionTest)> get _allCases =>
      caseSet<_RouterContextNavigationExtensionTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsBottomSheetExtension': (t) => t._allowsBottomSheetExtension(),
          'test_allowsTypedFallbackContextExtension': (t) =>
              t._allowsTypedFallbackContextExtension(),
          'test_reportsTypedFallbackContextExtensionWithoutPopIfCan': (t) =>
              t._reportsTypedFallbackContextExtensionWithoutPopIfCan(),
          'test_reportsMultilineContextExtensionDeclaration': (t) =>
              t._reportsMultilineContextExtensionDeclaration(),
          'test_reportsPrefixedContextExtensionDeclaration': (t) =>
              t._reportsPrefixedContextExtensionDeclaration(),
          'test_reportsContextExtensionCallingTopLevelFallbackHelper': (t) =>
              t._reportsContextExtensionCallingTopLevelFallbackHelper(),
          'test_reportsRouteVariableContextExtension': (t) =>
              t._reportsRouteVariableContextExtension(),
          'test_allowsNonNavigationContextExtension': (t) =>
              t._allowsNonNavigationContextExtension(),
          'test_allowsTopLevelFallbackHelperAfterContextExtension': (t) =>
              t._allowsTopLevelFallbackHelperAfterContextExtension(),
          'test_reportsStringFallbackThroughGoRouterHelper': (t) =>
              t._reportsStringFallbackThroughGoRouterHelper(),
          'test_reportsStringPushThroughGoRouterInExtension': (t) =>
              t._reportsStringPushThroughGoRouterInExtension(),
          'test_allowsSkillGoRouterPopX': (t) => t._allowsSkillGoRouterPopX(),
          'test_allowsSameNamedLocalExtensionMethod': (t) =>
              t._allowsSameNamedLocalExtensionMethod(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

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

  Future<void> _allowsBottomSheetExtension() async {
    await assertAllows(r'''
class BuildContext {}

extension BottomSheetX on BuildContext {
  Future<T?> showScrollableBottomSheet<T>({required Object builder}) async => null;
}
''');
  }

  Future<void> _allowsTypedFallbackContextExtension() async {
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

  Future<void> _reportsTypedFallbackContextExtensionWithoutPopIfCan() async {
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

  Future<void> _reportsMultilineContextExtensionDeclaration() async {
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

  Future<void> _reportsPrefixedContextExtensionDeclaration() async {
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

  Future<void> _reportsContextExtensionCallingTopLevelFallbackHelper() async {
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

  Future<void> _reportsRouteVariableContextExtension() async {
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

  Future<void> _allowsNonNavigationContextExtension() async {
    await assertAllows(r'''
class BuildContext {}

extension ContextThemeX on BuildContext {
  Object get colors => Object();
}
''');
  }

  Future<void> _allowsTopLevelFallbackHelperAfterContextExtension() async {
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

  Future<void> _reportsStringFallbackThroughGoRouterHelper() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension PopOrGoPathX on BuildContext {
  bool popIfCan<T extends Object?>([T? result]) => false;
  void popOrGoPath<T extends Object?>(String fallbackPath, [T? result]) {
    if (popIfCan<T>(result)) return;
    go(fallbackPath);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'go(fallbackPath);', ruleName),
    ]);
  }

  Future<void> _reportsStringPushThroughGoRouterInExtension() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension OpenPathX on BuildContext {
  Future<void> openPath(String path) => GoRouter.of(this).push<void>(path);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(this).push<void>(path);', ruleName),
    ]);
  }

  Future<void> _allowsSkillGoRouterPopX() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension GoRouterPopX on BuildContext {
  bool popIfCan<T extends Object?>([T? result]) {
    final rootNavigator = Navigator.maybeOf(this, rootNavigator: true);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop<T>(result);
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

  Future<void> _allowsSameNamedLocalExtensionMethod() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

extension LocalGoX on BuildContext {
  void go(String label) {}
  void goLabel(String label) => go(label);
}
''');
  }
}

final class _RouterNavigationWrapperApiTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterNavigationWrapperApiTest)> get _allCases =>
      caseSet<_RouterNavigationWrapperApiTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsPrivateNavigationCoordinatorImplementation': (t) =>
              t._reportsPrivateNavigationCoordinatorImplementation(),
          'test_reportsFeatureNavigationInterface': (t) => t._reportsFeatureNavigationInterface(),
          'test_reportsFeatureNavigationCoordinator': (t) =>
              t._reportsFeatureNavigationCoordinator(),
          'test_reportsRouteWrapperFunctionCall': (t) => t._reportsRouteWrapperFunctionCall(),
          'test_reportsRouteWrapperFunctionDeclaration': (t) =>
              t._reportsRouteWrapperFunctionDeclaration(),
        },
      );

  @override
  String get ruleName => 'router_navigation_wrapper_api';
  @override
  String get needle => 'class FeatureNavigationCoordinator';
  @override
  String get source => r'''
class FeatureNavigationCoordinator {}
''';

  Future<void> _reportsPrivateNavigationCoordinatorImplementation() async {
    final analyzedSource = _analyzedSource(r'''
final class _FeatureNavigationCoordinator {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final class _FeatureNavigationCoordinator', ruleName),
    ]);
  }

  Future<void> _reportsFeatureNavigationInterface() async {
    final analyzedSource = _analyzedSource(r'''
abstract interface class FeatureNavigation {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'abstract interface class FeatureNavigation', ruleName),
    ]);
  }

  Future<void> _reportsFeatureNavigationCoordinator() async {
    final analyzedSource = _analyzedSource(r'''
final class ProductNavigationCoordinator {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final class ProductNavigationCoordinator', ruleName),
    ]);
  }

  Future<void> _reportsRouteWrapperFunctionCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(router) {
  navigateToHomeRoute(router);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'navigateToHomeRoute', ruleName),
    ]);
  }

  Future<void> _reportsRouteWrapperFunctionDeclaration() async {
    final analyzedSource = _analyzedSource(r'''
void navigateToHomeRoute(router) {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'navigateToHomeRoute', ruleName),
    ]);
  }
}

void _defineSourceScannerRulesPart09Tests() {
  analysisRuleSuite<_RouterGoRouterOfTest>(
    'RouterGoRouterOfTest',
    _RouterGoRouterOfTest.new,
    _RouterGoRouterOfTest._allCases,
  );
  analysisRuleSuite<_RouterUntypedNavigatorPushTest>(
    'RouterUntypedNavigatorPushTest',
    _RouterUntypedNavigatorPushTest.new,
    _RouterUntypedNavigatorPushTest._allCases,
  );
  analysisRuleSuite<_RouterContextNavigationExtensionTest>(
    'RouterContextNavigationExtensionTest',
    _RouterContextNavigationExtensionTest.new,
    _RouterContextNavigationExtensionTest._allCases,
  );
  analysisRuleSuite<_RouterNavigationWrapperApiTest>(
    'RouterNavigationWrapperApiTest',
    _RouterNavigationWrapperApiTest.new,
    _RouterNavigationWrapperApiTest._allCases,
  );
}
