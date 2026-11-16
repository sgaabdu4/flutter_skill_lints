part of '../source_scanner_rules_test.dart';

final class _RouterSplashWaitsForInitialSyncTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterSplashWaitsForInitialSyncTest)> get _allCases =>
      caseSet<_RouterSplashWaitsForInitialSyncTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsAuthLoadingSplashGate': (t) => t._allowsAuthLoadingSplashGate(),
          'test_allowsInitialSyncStatusOutsideSplashRedirect': (t) =>
              t._allowsInitialSyncStatusOutsideSplashRedirect(),
        },
      );

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

final class _RouterComplexExtraTest extends _RouterRuleTest {
  static Map<String, Future<void> Function(_RouterComplexExtraTest)> get _allCases =>
      caseSet<_RouterComplexExtraTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
          'test_reportsTypedRouteExtraCall': (t) => t._reportsTypedRouteExtraCall(),
          'test_reportsGoRouterStateExtraRead': (t) => t._reportsGoRouterStateExtraRead(),
          'test_reportsContextNavigationExtraArgument': (t) =>
              t._reportsContextNavigationExtraArgument(),
          'test_allowsTypedRouteWithoutExtra': (t) => t._allowsTypedRouteWithoutExtra(),
          'test_allowsTestFixtureExtraRead': (t) => t._allowsTestFixtureExtraRead(),
          'test_allowsUnrelatedNamedExtraArgument': (t) => t._allowsUnrelatedNamedExtraArgument(),
        },
      );

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

void _defineSourceScannerRulesPart08BTests() {
  analysisRuleSuite<_RouterSplashWaitsForInitialSyncTest>(
    'RouterSplashWaitsForInitialSyncTest',
    _RouterSplashWaitsForInitialSyncTest.new,
    _RouterSplashWaitsForInitialSyncTest._allCases,
  );
  analysisRuleSuite<_RouterComplexExtraTest>(
    'RouterComplexExtraTest',
    _RouterComplexExtraTest.new,
    _RouterComplexExtraTest._allCases,
  );
}
