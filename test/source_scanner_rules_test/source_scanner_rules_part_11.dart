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
    final expected = compatLint(analyzedSource, '_service', ruleName);
    await assertDiagnostics(analyzedSource, [expected]);
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
final class ServiceProviderWatchDependencyTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'service_provider_watch_dependency';
  @override
  String get needle => 'ref.watch(flutterLocalNotificationsPluginProvider)';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class FlutterLocalNotificationsPlugin {}
class NotificationTapPayloadBus {}
abstract interface class INotificationService {}
class NotificationService implements INotificationService {
  NotificationService({
    required FlutterLocalNotificationsPlugin plugin,
    required NotificationTapPayloadBus tapPayloadBus,
  });
}

@Riverpod(keepAlive: true)
INotificationService notificationService(Ref ref) {
  final service = NotificationService(
    plugin: ref.watch(flutterLocalNotificationsPluginProvider),
    tapPayloadBus: ref.read(notificationTapPayloadBusProvider),
  );
  return service;
}
''';

  Future<void> test_reportsRepositoryFactoryWatch() async {
    const source = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class StorageLocalDatasource {}
abstract interface class IAuthLocalDatasource {}
class AuthLocalDatasource implements IAuthLocalDatasource {
  AuthLocalDatasource(StorageLocalDatasource storage);
}

@Riverpod(keepAlive: true)
IAuthLocalDatasource authLocalDatasource(Ref ref) {
  return AuthLocalDatasource(ref.watch(storageLocalDatasourceProvider));
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(storageLocalDatasourceProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsReadDependency() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class FlutterLocalNotificationsPlugin {}
abstract interface class INotificationService {}
class NotificationService implements INotificationService {
  NotificationService({required FlutterLocalNotificationsPlugin plugin});
}

@Riverpod(keepAlive: true)
INotificationService notificationService(Ref ref) {
  return NotificationService(plugin: ref.read(flutterLocalNotificationsPluginProvider));
}
''');
  }

  Future<void> test_allowsComputedProviderWatch() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@riverpod
int selectedCount(Ref ref) {
  return ref.watch(counterProvider);
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
