part of '../source_scanner_rules_test.dart';

final class _NotifierEnsureDepsTest extends _NotifierFixtureTest {
  static Map<String, Future<void> Function(_NotifierEnsureDepsTest)> get _allCases =>
      caseSet<_NotifierEnsureDepsTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsConstructorInjectedFinalRepository': (t) =>
              t._allowsConstructorInjectedFinalRepository(),
          'test_reportsUninitializedLateRepository': (t) => t._reportsUninitializedLateRepository(),
          'test_reportsNullableConstructorInjectedRepository': (t) =>
              t._reportsNullableConstructorInjectedRepository(),
          'test_reportsDynamicConstructorInjectedRepository': (t) =>
              t._reportsDynamicConstructorInjectedRepository(),
        },
      );

  @override
  String get ruleName => 'notifier_ensure_deps';

  Future<void> _allowsConstructorInjectedFinalRepository() async {
    await assertAllows(r'''
abstract interface class IItemsRepository {
  Future<void> addItem(String item);
}
class TestableItemsNotifier {
  TestableItemsNotifier(this._repository);
  final IItemsRepository _repository;
  Future<void> addItem(String item) async {
    await _repository.addItem(item);
  }
}
''');
  }

  Future<void> _reportsUninitializedLateRepository() async {
    const source = r'''
abstract interface class IItemsRepository {
  Future<void> addItem(String item);
}
class UninitializedItemsNotifier {
  late IItemsRepository _repository;
  Future<void> addItem(String item) async {
    await _repository.addItem(item);
  }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, '  Future<void> addItem(String item) async {', ruleName),
    ]);
  }

  Future<void> _reportsNullableConstructorInjectedRepository() async {
    const source = r'''
abstract interface class IItemsRepository { Future<void> addItem(String item); }
class TestableItemsNotifier {
  TestableItemsNotifier(this._repository);
  final IItemsRepository? _repository;
  Future<void> addItem(String item) async { await _repository!.addItem(item); }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, '  Future<void> addItem(String item) async {', ruleName),
    ]);
  }

  Future<void> _reportsDynamicConstructorInjectedRepository() async {
    const source = r'''
class TestableItemsNotifier {
  TestableItemsNotifier(this._repository);
  final dynamic _repository;
  Future<void> addItem(String item) async { await _repository.addItem(item); }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, '  Future<void> addItem(String item) async {', ruleName),
    ]);
  }
}

final class _NotifierWatchMethodTest extends _NotifierFixtureTest {
  static Map<String, Future<void> Function(_NotifierWatchMethodTest)> get _allCases =>
      caseSet<_NotifierWatchMethodTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsListenOutsideBuild': (t) => t._reportsListenOutsideBuild(),
          'test_allowsWatchAndListenInBuild': (t) => t._allowsWatchAndListenInBuild(),
        },
      );

  @override
  String get ruleName => 'notifier_watch_method';

  static const _prelude = r'''
class Notifier<T> {
  Ref get ref => Ref();
}

class Ref {
  Object watch(Object provider) => Object();
  void listen(Object provider, void Function(Object? previous, Object next) listener) {}
}

final authProvider = Object();
''';

  /// async-mutations.md:61: use ref.listen in build() for side effects.
  Future<void> _reportsListenOutsideBuild() async {
    final analyzedSource = _analyzedSource('''$_prelude
class SessionNotifier extends Notifier<int> {
  int build() => 0;

  void startListening() {
    ref.listen(authProvider, (previous, next) {});
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'void startListening', ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsWatchAndListenInBuild() async {
    await assertAllows('''$_prelude
class SessionNotifier extends Notifier<int> {
  int build() {
    ref.watch(authProvider);
    ref.listen(authProvider, (previous, next) {});
    return 0;
  }

  void listen() {}
}
''');
  }
}

abstract class _ServicesMixinsRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesMixinsSourceRules;
}

abstract class _ServicesExtendedRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesExtendedSourceRules;
}

final class _ServiceSingletonTest extends _ServicesMixinsRuleTest {
  static Map<String, Future<void> Function(_ServiceSingletonTest)> get _allCases =>
      caseSet<_ServiceSingletonTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsPlainBoringSingleton': (t) => t._allowsPlainBoringSingleton(),
          'test_allowsFireAndForgetMethodsOnly': (t) => t._allowsFireAndForgetMethodsOnly(),
          'test_allowsPrivateBackingFieldWithTrivialGetter': (t) =>
              t._allowsPrivateBackingFieldWithTrivialGetter(),
          'test_reportsMutableStateEvenWithResetForTest': (t) =>
              t._reportsMutableStateEvenWithResetForTest(),
          'test_reportsPublicDataReturningMethod': (t) => t._reportsPublicDataReturningMethod(),
          'test_reportsPublicGetterState': (t) => t._reportsPublicGetterState(),
          'test_reportsPublicConstructorNextToPrivateConstructor': (t) =>
              t._reportsPublicConstructorNextToPrivateConstructor(),
          'test_reportsPublicGetterOverPrivateField': (t) =>
              t._reportsPublicGetterOverPrivateField(),
          'test_reportsFactoryAndInstanceCacheSingletons': (t) =>
              t._reportsFactoryAndInstanceCacheSingletons(),
          'test_allowsConstantAndRegistryInstances': (t) => t._allowsConstantAndRegistryInstances(),
          'test_reportsDebugInjectionSeam': (t) => t._reportsDebugInjectionSeam(),
        },
      );

  @override
  String get ruleName => 'service_singleton';
  @override
  String get needle => 'static final instance';
  @override
  String get source => 'class UserService { static final instance = UserService(); }';

  Future<void> _allowsPlainBoringSingleton() async {
    await assertAllows('''
/// Talks to the push backend through its locator.
final class UserService {
  UserService._();

  static final UserService instance = UserService._();
}
''');
  }

  Future<void> _allowsFireAndForgetMethodsOnly() async {
    await assertAllows('''
final class PushTokenRefresh {
  PushTokenRefresh._();

  static final PushTokenRefresh instance = PushTokenRefresh._();

  Future<void> refresh() async {}
  void trackAttempt() {}
}
''');
  }

  Future<void> _allowsPrivateBackingFieldWithTrivialGetter() async {
    await assertAllows('''
final class UserService {
  UserService._();

  static final UserService _instance = UserService._();
  static UserService get instance => _instance;
}
''');
  }

  Future<void> _reportsMutableStateEvenWithResetForTest() async {
    const source = '''
final class AudioPlayerService {
  AudioPlayerService._();

  static final AudioPlayerService instance = AudioPlayerService._();

  final _queue = <Clip>[];

  void resetForTest() => _queue.clear();
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final AudioPlayerService instance', ruleName),
    ]);
  }

  Future<void> _reportsPublicDataReturningMethod() async {
    const source = '''
final class UserService {
  UserService._();

  static final UserService instance = UserService._();

  Future<User> loadUser() async => User();
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final UserService instance', ruleName),
    ]);
  }

  Future<void> _reportsPublicGetterState() async {
    const source = '''
final class UserService {
  UserService._();

  static final UserService instance = UserService._();

  bool get ready => true;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final UserService instance', ruleName),
    ]);
  }

  Future<void> _reportsPublicConstructorNextToPrivateConstructor() async {
    const source = '''
final class RunService {
  RunService();
  RunService._();

  static final RunService instance = RunService._();

  Future<void> run() async {}
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final RunService instance', ruleName),
    ]);
  }

  Future<void> _reportsPublicGetterOverPrivateField() async {
    const source = '''
final class TokenService {
  TokenService._();

  static final TokenService instance = TokenService._();

  final String _token = 'token';

  String get token => _token;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final TokenService instance', ruleName),
    ]);
  }

  /// #51: cache singletons belong to service_singleton, including the factory-exposed shape.
  Future<void> _reportsFactoryAndInstanceCacheSingletons() async {
    const source = '''
class SharedCache {
  SharedCache._();
  static final SharedCache instance = SharedCache._();
  final Map<String, String> entries = <String, String>{};
  void put(String key, String value) => entries[key] = value;
}

class SharedCacheWithFactory {
  SharedCacheWithFactory._();
  static final SharedCacheWithFactory _instance = SharedCacheWithFactory._();
  factory SharedCacheWithFactory() => _instance;
  final Map<String, String> entries = <String, String>{};
  void put(String key, String value) => entries[key] = value;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static final SharedCache instance', ruleName),
      compatLint(analyzedSource, 'factory SharedCacheWithFactory()', ruleName),
    ]);
  }

  /// #51 control: constant and registry instances are not singletons.
  Future<void> _allowsConstantAndRegistryInstances() async {
    await assertAllows('''
final class Money {
  const Money(this.cents);

  static const zero = Money(0);

  final int cents;
}

final class Palette {
  Palette._(this.hex);

  static final light = Palette._(0xFFFFFF);
  static final dark = Palette._(0x000000);

  final int hex;
}
''');
  }

  Future<void> _reportsDebugInjectionSeam() async {
    const source = '''
final class UserService {
  UserService._();

  static UserService _instance = UserService._();
  static UserService get instance => _instance;

  static void debugUse(UserService service) {
    _instance = service;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'static UserService get instance', ruleName),
    ]);
  }
}

final class _ServiceInlineConcreteDependencyTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_ServiceInlineConcreteDependencyTest)> get _allCases =>
      caseSet<_ServiceInlineConcreteDependencyTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsProviderValue': (t) => t._allowsProviderValue(),
          'test_skipsTests': (t) => t._skipsTests(),
        },
      );

  @override
  String get ruleName => 'service_inline_concrete_dependency';
  @override
  String get needle => 'plugin: FlutterLocalNotificationsPlugin()';
  @override
  String get source => r'''
class FlutterLocalNotificationsPlugin {}
class BackgroundAlarmService {
  BackgroundAlarmService({required FlutterLocalNotificationsPlugin plugin});
}

Object backgroundAlarmService(Ref ref) {
  return BackgroundAlarmService(plugin: FlutterLocalNotificationsPlugin());
}
''';

  Future<void> _allowsProviderValue() async {
    await assertAllows(r'''
class FlutterLocalNotificationsPlugin {}
class BackgroundAlarmService {
  BackgroundAlarmService({required FlutterLocalNotificationsPlugin plugin});
}

Object backgroundAlarmService(Ref ref) {
  return BackgroundAlarmService(plugin: ref.read(flutterLocalNotificationsPluginProvider));
}
''');
  }

  Future<void> _skipsTests() async {
    await assertAllows(r'''
class FlutterLocalNotificationsPlugin {}
class BackgroundAlarmService {
  BackgroundAlarmService({required FlutterLocalNotificationsPlugin plugin});
}

Object backgroundAlarmService(Ref ref) {
  return BackgroundAlarmService(plugin: FlutterLocalNotificationsPlugin());
}
''', path: '$testPackageRootPath/test/core/services/background_alarm_service_test.dart');
  }
}

final class _HiddenDependencyDefaultParamTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_HiddenDependencyDefaultParamTest)> get _allCases =>
      caseSet<_HiddenDependencyDefaultParamTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsDefaultedFunctionSeam': (t) => t._reportsDefaultedFunctionSeam(),
          'test_allowsRequiredFunctionSeam': (t) => t._allowsRequiredFunctionSeam(),
        },
      );

  @override
  String get ruleName => 'hidden_dependency_default_param';
  @override
  String get needle => 'OAuthAuthenticator? authenticator';
  @override
  String get source => r'''
typedef OAuthAuthenticator = Future<String> Function({
  required String url,
  required String callbackUrlScheme,
});

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    OAuthAuthenticator? authenticator,
  });
}
''';

  Future<void> _reportsDefaultedFunctionSeam() async {
    const source = r'''
typedef DeleteAccountPollDelay = Future<void> Function(Duration duration);
Future<void> defaultDelay(Duration duration) async {}

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    DeleteAccountPollDelay? deleteAccountPollDelay = defaultDelay,
  });
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DeleteAccountPollDelay? deleteAccountPollDelay', ruleName),
    ]);
  }

  Future<void> _allowsRequiredFunctionSeam() async {
    await assertAllows(r'''
typedef OAuthAuthenticator = Future<String> Function({
  required String url,
  required String callbackUrlScheme,
});

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    required OAuthAuthenticator authenticator,
  });
}
''');
  }
}

final class _RiverpodConfigDestructuringTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_RiverpodConfigDestructuringTest)> get _allCases =>
      caseSet<_RiverpodConfigDestructuringTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsAwaitedReadConfigLocal': (t) => t._reportsAwaitedReadConfigLocal(),
          'test_allowsSkillDestructuredConfig': (t) => t._allowsSkillDestructuredConfig(),
          'test_allowsConfigUsedBeyondPropertyReads': (t) =>
              t._allowsConfigUsedBeyondPropertyReads(),
        },
      );

  static const _stubs = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Provider<T> {}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
  T read<T>(Provider<T> provider) => throw UnimplementedError();
}

class BackendConfig {
  const BackendConfig(this.endpoint, this.apiKey);
  final String endpoint;
  final String apiKey;
  String describe() => endpoint;
}
class HttpClient {
  HttpClient(String endpoint, String apiKey);
  HttpClient.fromConfig(BackendConfig config);
}
final backendConfigProvider = Provider<BackendConfig>();
''';

  @override
  String get ruleName => 'riverpod_config_destructuring';
  @override
  String get needle => 'ref.watch(backendConfigProvider)';
  @override
  String get source =>
      '''
$_stubs
@Riverpod(keepAlive: true)
HttpClient backendClient(Ref ref) {
  final config = ref.watch(backendConfigProvider);
  return HttpClient(config.endpoint, config.apiKey);
}
''';

  Future<void> _reportsAwaitedReadConfigLocal() async {
    const source =
        '''
$_stubs
final appConfigProvider = Provider<Future<BackendConfig>>();

Future<HttpClient> connect(Ref ref) async {
  final config = await ref.read(appConfigProvider);
  return HttpClient(config.endpoint, config.apiKey);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.read(appConfigProvider)', ruleName),
    ]);
  }

  Future<void> _allowsSkillDestructuredConfig() async {
    await assertAllows('''
$_stubs
@Riverpod(keepAlive: true)
HttpClient backendClient(Ref ref) {
  final BackendConfig(:endpoint, :apiKey) = ref.watch(backendConfigProvider);
  return HttpClient(endpoint, apiKey);
}
''');
  }

  Future<void> _allowsConfigUsedBeyondPropertyReads() async {
    await assertAllows('''
$_stubs
class Cart {
  final List<int> items = const [];
}
final cartProvider = Provider<Cart>();

HttpClient wholeConfig(Ref ref) {
  final config = ref.watch(backendConfigProvider);
  print(config.endpoint);
  return HttpClient.fromConfig(config);
}

String configMethod(Ref ref) {
  final config = ref.read(backendConfigProvider);
  return config.describe();
}

void unusedConfig(Ref ref) {
  final config = ref.watch(backendConfigProvider);
}

int nonConfigValue(Ref ref) {
  final cart = ref.watch(cartProvider);
  return cart.items.length;
}
''');
  }
}

final class _MixinMixinClassTest extends _ServicesMixinsRuleTest {
  static Map<String, Future<void> Function(_MixinMixinClassTest)> get _allCases =>
      caseSet<_MixinMixinClassTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'mixin_mixin_class';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

final class _MixinNameSuffixTest extends _ServicesMixinsRuleTest {
  static Map<String, Future<void> Function(_MixinNameSuffixTest)> get _allCases =>
      caseSet<_MixinNameSuffixTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'mixin_name_suffix';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

final class _MixinMutableStateTest extends _ServicesMixinsRuleTest {
  static Map<String, Future<void> Function(_MixinMutableStateTest)> get _allCases =>
      caseSet<_MixinMutableStateTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsPrivateLifecycleFieldsInConsumerStateMixin': (t) =>
              t._allowsPrivateLifecycleFieldsInConsumerStateMixin(),
          'test_reportsPublicMutableFieldInStateMixin': (t) =>
              t._reportsPublicMutableFieldInStateMixin(),
          'test_reportsPrivateMutableFieldInUnconstrainedMixin': (t) =>
              t._reportsPrivateMutableFieldInUnconstrainedMixin(),
          'test_reportsUninitializedLateAndStaticMutableFields': (t) =>
              t._reportsUninitializedLateAndStaticMutableFields(),
          'test_allowsExpressionBodiedMethodsAndGetters': (t) =>
              t._allowsExpressionBodiedMethodsAndGetters(),
        },
      );

  @override
  String get ruleName => 'mixin_mutable_state';
  @override
  String get needle => 'var count = 0';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
mixin class Trackable {
  var count = 0;
}
''';

  Future<void> _allowsPrivateLifecycleFieldsInConsumerStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/lifecycle_retry_mixin.dart';
    newFile(filePath, r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}
class ConsumerStatefulWidget extends StatefulWidget {}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {}

mixin LifecycleRetryMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _hasAttemptedRetry = false;
  bool _needsLifecycleRetry = false;
  bool _dependenciesInitialised = false;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsPublicMutableFieldInStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/scroll_mixin.dart';
    const source = r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}

mixin ScrollMixin<T extends StatefulWidget> on State<T> {
  bool isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool isReady = false', ruleName, lineStart: true),
    ]);
  }

  Future<void> _reportsPrivateMutableFieldInUnconstrainedMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/cache_mixin.dart';
    const source = r'''
mixin CacheMixin {
  bool _isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool _isReady = false', ruleName, lineStart: true),
    ]);
  }

  Future<void> _reportsUninitializedLateAndStaticMutableFields() async {
    final filePath = '$testPackageLibPath/core/mixins/remember_mixin.dart';
    const source = r'''
mixin RememberMixin {
  String? _cached;
  late int _hits;
  static var _instances = 0;
  final String label = 'remember';

  String remember(String value) {
    _hits = _instances;
    return _cached ??= '$value$_hits$label';
  }
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'String? _cached;', ruleName, lineStart: true),
      compatLint(source, 'late int _hits;', ruleName, lineStart: true),
      compatLint(source, 'static var _instances', ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsExpressionBodiedMethodsAndGetters() async {
    final filePath = '$testPackageLibPath/core/mixins/connectivity_mixin.dart';
    newFile(filePath, r'''
class ConnectivityService {
  bool get isConnected => true;
}
class StatefulWidget {}
class State<T extends StatefulWidget> {
  bool get mounted => true;
}

mixin ConnectivityMixin {
  bool checkConnectivity(ConnectivityService service) => service.isConnected;
}

mixin RouteAwareMixin<T extends StatefulWidget> on State<T> {
  bool get isActive => mounted;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

abstract class _TestRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => testSourceRules;
}

abstract class _TestFileRuleTest extends _TestRuleTest {
  @override
  String get path => '$testPackageRootPath/test/widget_test.dart';
}

final class _TestProviderContainerTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestProviderContainerTest)> get _allCases =>
      caseSet<_TestProviderContainerTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'test_provider_container';
  @override
  String get needle => 'ProviderContainer()';
  @override
  String get source => 'void main() { ProviderContainer(); }';
}

final class _TestUncontrolledScopeTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestUncontrolledScopeTest)> get _allCases =>
      caseSet<_TestUncontrolledScopeTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'test_uncontrolled_scope';
  @override
  String get needle => 'ProviderScope()';
  @override
  String get source => 'void main() { ProviderScope(); }';
}

final class _TestCreateContainerTest extends _TestFileRuleTest {
  static Map<String, Future<void> Function(_TestCreateContainerTest)> get _allCases =>
      caseSet<_TestCreateContainerTest>(parent: _SourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'test_create_container';
  @override
  String get needle => 'createContainer()';
  @override
  String get source => 'void main() { createContainer(); }';
}

void _defineSourceScannerRulesPart11Tests() {
  analysisRuleSuite<_NotifierEnsureDepsTest>(
    'NotifierEnsureDepsTest',
    _NotifierEnsureDepsTest.new,
    _NotifierEnsureDepsTest._allCases,
  );
  analysisRuleSuite<_NotifierWatchMethodTest>(
    'NotifierWatchMethodTest',
    _NotifierWatchMethodTest.new,
    _NotifierWatchMethodTest._allCases,
  );
  analysisRuleSuite<_ServiceSingletonTest>(
    'ServiceSingletonTest',
    _ServiceSingletonTest.new,
    _ServiceSingletonTest._allCases,
  );
  analysisRuleSuite<_ServiceInlineConcreteDependencyTest>(
    'ServiceInlineConcreteDependencyTest',
    _ServiceInlineConcreteDependencyTest.new,
    _ServiceInlineConcreteDependencyTest._allCases,
  );
  analysisRuleSuite<_HiddenDependencyDefaultParamTest>(
    'HiddenDependencyDefaultParamTest',
    _HiddenDependencyDefaultParamTest.new,
    _HiddenDependencyDefaultParamTest._allCases,
  );
  analysisRuleSuite<_RiverpodConfigDestructuringTest>(
    'RiverpodConfigDestructuringTest',
    _RiverpodConfigDestructuringTest.new,
    _RiverpodConfigDestructuringTest._allCases,
  );
  analysisRuleSuite<_MixinMixinClassTest>(
    'MixinMixinClassTest',
    _MixinMixinClassTest.new,
    _MixinMixinClassTest._allCases,
  );
  analysisRuleSuite<_MixinNameSuffixTest>(
    'MixinNameSuffixTest',
    _MixinNameSuffixTest.new,
    _MixinNameSuffixTest._allCases,
  );
  analysisRuleSuite<_MixinMutableStateTest>(
    'MixinMutableStateTest',
    _MixinMutableStateTest.new,
    _MixinMutableStateTest._allCases,
  );
  analysisRuleSuite<_TestProviderContainerTest>(
    'TestProviderContainerTest',
    _TestProviderContainerTest.new,
    _TestProviderContainerTest._allCases,
  );
  analysisRuleSuite<_TestUncontrolledScopeTest>(
    'TestUncontrolledScopeTest',
    _TestUncontrolledScopeTest.new,
    _TestUncontrolledScopeTest._allCases,
  );
  analysisRuleSuite<_TestCreateContainerTest>(
    'TestCreateContainerTest',
    _TestCreateContainerTest.new,
    _TestCreateContainerTest._allCases,
  );
}
