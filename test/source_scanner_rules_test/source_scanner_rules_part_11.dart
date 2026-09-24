// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class NotifierLocalDependencyCacheTest extends _NotifierRuleTest {
  @override
  String get ruleName => 'notifier_local_dependency_cache';
  @override
  String get needle => '_repository';
  @override
  String get source => r'''
class Notifier<T> {}

abstract interface class IThingRepository {}

class ThingNotifier extends Notifier<int> {
  IThingRepository? _repository;

  int build() => 0;
}
''';

  Future<void> test_reportsServiceCache() async {
    const source = r'''
class Notifier<T> {}

abstract interface class IThingService {}

class ThingNotifier extends Notifier<int> {
  late final IThingService _service;

  int build() => 0;
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_service', ruleName)]);
  }

  Future<void> test_allowsStatelessProviderHelper() async {
    await assertAllows(r'''
class Ref {
  T read<T>(Object provider) => throw UnimplementedError();
}

abstract interface class IThingRepository {}
final thingRepositoryProvider = Object();

IThingRepository readThingRepository(Ref ref) => ref.read(thingRepositoryProvider);

class ThingNotifier {
  int build() => 0;
}
''');
  }

  Future<void> test_allowsLifecycleResourceField() async {
    await assertAllows(r'''
class Notifier<T> {}
class Timer {}

class ThingNotifier extends Notifier<int> {
  Timer? _timer;

  int build() => 0;
}
''');
  }
}

@reflectiveTest
final class NotifierEnsureDepsTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_ensure_deps';

  Future<void> test_allowsConstructorInjectedFinalRepository() async {
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

  Future<void> test_reportsUninitializedLateRepository() async {
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

  Future<void> test_reportsNullableConstructorInjectedRepository() async {
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

  Future<void> test_reportsDynamicConstructorInjectedRepository() async {
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

@reflectiveTest
final class NotifierWatchMethodTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_watch_method';
}

abstract class _ServicesMixinsRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesMixinsSourceRules;
}

abstract class _ServicesExtendedRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesExtendedSourceRules;
}

@reflectiveTest
final class ServiceSingletonTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'service_singleton';
  @override
  String get needle => 'static final instance';
  @override
  String get source => 'class UserService { static final instance = UserService(); }';

  Future<void> test_allowsPlainBoringSingleton() async {
    await assertAllows('''
/// Talks to the push backend through its locator.
final class UserService {
  UserService._();

  static final UserService instance = UserService._();
}
''');
  }

  Future<void> test_allowsFireAndForgetMethodsOnly() async {
    await assertAllows('''
final class PushTokenRefresh {
  PushTokenRefresh._();

  static final PushTokenRefresh instance = PushTokenRefresh._();

  Future<void> refresh() async {}
  void trackAttempt() {}
}
''');
  }

  Future<void> test_allowsPrivateBackingFieldWithTrivialGetter() async {
    await assertAllows('''
final class UserService {
  UserService._();

  static final UserService _instance = UserService._();
  static UserService get instance => _instance;
}
''');
  }

  Future<void> test_reportsMutableStateEvenWithResetForTest() async {
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

  Future<void> test_reportsPublicDataReturningMethod() async {
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

  Future<void> test_reportsPublicGetterState() async {
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

  Future<void> test_reportsPublicConstructorNextToPrivateConstructor() async {
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

  Future<void> test_reportsPublicGetterOverPrivateField() async {
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
  Future<void> test_reportsFactoryAndInstanceCacheSingletons() async {
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
  Future<void> test_allowsConstantAndRegistryInstances() async {
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

  Future<void> test_reportsDebugInjectionSeam() async {
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

@reflectiveTest
final class ServiceInlineConcreteDependencyTest extends _ServicesExtendedRuleTest {
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

  Future<void> test_allowsProviderValue() async {
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

  Future<void> test_skipsTests() async {
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

@reflectiveTest
final class HiddenDependencyDefaultParamTest extends _ServicesExtendedRuleTest {
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

  Future<void> test_reportsDefaultedFunctionSeam() async {
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

  Future<void> test_allowsRequiredFunctionSeam() async {
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

@reflectiveTest
final class RiverpodConfigDestructuringTest extends _ServicesExtendedRuleTest {
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

  Future<void> test_reportsAwaitedReadConfigLocal() async {
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

  Future<void> test_allowsSkillDestructuredConfig() async {
    await assertAllows('''
$_stubs
@Riverpod(keepAlive: true)
HttpClient backendClient(Ref ref) {
  final BackendConfig(:endpoint, :apiKey) = ref.watch(backendConfigProvider);
  return HttpClient(endpoint, apiKey);
}
''');
  }

  Future<void> test_allowsConfigUsedBeyondPropertyReads() async {
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

@reflectiveTest
final class MixinMixinClassTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_mixin_class';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinNameSuffixTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_name_suffix';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinMutableStateTest extends _ServicesMixinsRuleTest {
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

  Future<void> test_allowsPrivateLifecycleFieldsInConsumerStateMixin() async {
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

  Future<void> test_reportsPublicMutableFieldInStateMixin() async {
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

  Future<void> test_reportsPrivateMutableFieldInUnconstrainedMixin() async {
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

  Future<void> test_reportsUninitializedLateAndStaticMutableFields() async {
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

  Future<void> test_allowsExpressionBodiedMethodsAndGetters() async {
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

abstract class _DataCrashRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dataCrashSourceRules;
}

@reflectiveTest
final class DataLogRethrowTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'data_log_rethrow';
  @override
  String get needle => 'log(error);';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
  @override
  String get source => r'''
void log(Object value) {}

void load() {
  try {
    throw Object();
  } catch (error) {
    log(error);
    rethrow;
  }
}
''';
}

@reflectiveTest
final class CrashPossiblePiiTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_possible_pii';
  @override
  String get needle => 'Crash.error(email)';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Crash {
  static void error(Object value) {}
}

final email = Object();

void recordCrash() {
  Crash.error(email);
}
''';
}

abstract class _TestRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => testSourceRules;
}

abstract class _TestFileRuleTest extends _TestRuleTest {
  @override
  String get path => '$testPackageRootPath/test/widget_test.dart';
}

@reflectiveTest
final class TestProviderContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_provider_container';
  @override
  String get needle => 'ProviderContainer()';
  @override
  String get source => 'void main() { ProviderContainer(); }';
}

@reflectiveTest
final class TestUncontrolledScopeTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_uncontrolled_scope';
  @override
  String get needle => 'ProviderScope()';
  @override
  String get source => 'void main() { ProviderScope(); }';
}

@reflectiveTest
final class TestCreateContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_create_container';
  @override
  String get needle => 'createContainer()';
  @override
  String get source => 'void main() { createContainer(); }';
}
