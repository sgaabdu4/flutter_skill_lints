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
  void setUp() {
    newPackage('sdk').addFile('lib/sdk.dart', r'''
class Client {
  const Client();
}

class Repository<T> {
  const Repository();
}
''');
    newPackage('appwrite')
      ..addFile('lib/src/service.dart', 'class Service {}')
      ..addFile('lib/appwrite.dart', r'''
import 'src/service.dart';

class TablesDB extends Service {
  TablesDB(Object client);
}

class Account extends Service {
  Account(Object client);
}
''');
    super.setUp();
  }

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

  Future<void> test_allowsCollectionProjectionNamedQueue() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {
  List<int> watch(Object provider) => const [1, 2];
}

typedef QueueProjection = ({List<int> items, int count});
final itemSourceProvider = Object();

@Riverpod(keepAlive: true)
QueueProjection selectedItemsQueue(Ref ref) {
  final items = ref.watch(itemSourceProvider);
  return (items: List.unmodifiable(items), count: items.length);
}
''');
  }

  Future<void> test_allowsCollectionProjectionWhoseElementLooksLikeService() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}
const riverpod = Riverpod();

class ItemService {
  const ItemService(this.code);
  final String code;
}

class Ref {
  List<ItemService> watch(Object provider) => const [];
}

final sourceServicesProvider = Object();
final searchProvider = Object();

@riverpod
List<ItemService> filteredItemServices(Ref ref) {
  final search = ref.watch(searchProvider);
  final services = ref.watch(sourceServicesProvider);
  return services.where((service) => service.code.contains(search.toString())).toList();
}
''');
  }

  Future<void> test_reportsTypedStableServiceWatchWithGenericFactoryName() async {
    const source = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {
  Object watch(Object provider) => Object();
}

abstract interface class IQueueService {}
class QueueService implements IQueueService {
  QueueService(Object client);
}
final clientProvider = Object();

@Riverpod(keepAlive: true)
IQueueService createQueue(Ref ref) => QueueService(ref.watch(clientProvider));
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(clientProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsGenericInfrastructureReturnType() async {
    const source = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Item {}
abstract interface class IRepository<T> {}
class Repository<T> implements IRepository<T> {
  Repository(Object client);
}
class Ref { Object watch(Object provider) => Object(); }
final clientProvider = Object();
final accountClientProvider = Object();

@Riverpod(keepAlive: true)
IRepository<Item> repository(Ref ref) => Repository<Item>(ref.watch(clientProvider));
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(clientProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsQualifiedInfrastructureReturnTypeThroughFuture() async {
    const source = r'''
import 'package:sdk/sdk.dart' as sdk;

class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref { Object watch(Object provider) => Object(); }
final clientProvider = Object();

@Riverpod(keepAlive: true)
Future<sdk.Repository<int>> repository(Ref ref) async {
  ref.watch(clientProvider);
  return const sdk.Repository<int>();
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(clientProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsAppwriteTablesAndAccountServicesByResolvedBase() async {
    const source = r'''
import 'package:appwrite/appwrite.dart' as appwrite;

class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref { Object watch(Object provider) => Object(); }
final clientProvider = Object();

@Riverpod(keepAlive: true)
appwrite.TablesDB appwriteTablesDB(Ref ref) =>
    appwrite.TablesDB(ref.watch(clientProvider));

@Riverpod(keepAlive: true)
Future<appwrite.Account> appwriteAccount(Ref ref) async {
  return appwrite.Account(ref.watch(accountClientProvider));
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(clientProvider)', ruleName),
      compatLint(analyzedSource, 'ref.watch(accountClientProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsLocalServiceBaseLookalike() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Service {}
class TablesDB extends Service {
  TablesDB(Object client);
}
class Ref { Object watch(Object provider) => Object(); }
final clientProvider = Object();

@Riverpod(keepAlive: true)
TablesDB localTablesDB(Ref ref) => TablesDB(ref.watch(clientProvider));
''');
  }

  Future<void> test_doesNotUnwrapUserDefinedFutureName() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Future<T> {
  const Future();
}

abstract interface class IRepository<T> {}
class Ref { Object watch(Object provider) => Object(); }
final dependencyProvider = Object();

@Riverpod(keepAlive: true)
Future<IRepository<int>> projectedValue(Ref ref) {
  ref.watch(dependencyProvider);
  return const Future<IRepository<int>>();
}
''');
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
  Future<void> test_reportsCrashReportThenRethrow() async {
    const source = r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

class TodoRepository {
  Future<int> load(Future<int> Function() source) async {
    try {
      return await source();
    } on Exception catch (error, stackTrace) {
      Crash.error(error, stackTrace);
      rethrow;
    }
  }
}
''';
    final filePath = '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_reportsCrashReportThenThrowCaughtError() async {
    const source = r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception catch (error, stackTrace) {
    Crash.error(error, stackTrace);
    throw error;
  }
}
''';
    final filePath = '$testPackageLibPath/features/todos/data/datasources/todo_datasource.dart';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Crash.error(error, stackTrace);', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsReportThenMappedTypedError() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

class AppException implements Exception {}

Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception catch (error, stackTrace) {
    Crash.error(error, stackTrace);
    throw AppException();
  }
}
''', path: path);
  }

  Future<void> test_allowsRethrowWithoutReport() async {
    await assertAllows(r'''
Future<int> load(Future<int> Function() source) async {
  try {
    return await source();
  } on Exception {
    rethrow;
  }
}
''', path: path);
  }
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

abstract class _CrashSdkRuleTest extends _DataCrashRuleTest {
  @override
  void setUp() {
    final sentry = newPackage('sentry_flutter');
    sentry.addFile('lib/src/options.dart', r'''
class SentryFlutterOptions {
  bool sendDefaultPii = false;
  bool attachScreenshot = false;
  bool attachViewHierarchy = false;
}
''');
    sentry.addFile('lib/sentry_flutter.dart', r'''
import 'src/options.dart';
export 'src/options.dart';

abstract final class Sentry {
  static Future<void> captureException(Object error, {StackTrace? stackTrace}) async {}
}

abstract final class SentryFlutter {
  static Future<void> init(void Function(SentryFlutterOptions) configure, {Object? appRunner}) async {}
}
''');
    newPackage('firebase_crashlytics').addFile('lib/firebase_crashlytics.dart', r'''
class FirebaseCrashlytics {
  static final FirebaseCrashlytics instance = FirebaseCrashlytics();
  void recordFlutterFatalError(Object details) {}
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal = false}) async {}
}
''');
    newPackage('flutter').addFile('lib/foundation.dart', r'''
class FlutterError {
  static void Function(Object details)? onError;
  static void presentError(Object details) {}
}
''');
    super.setUp();
    sdkRoot.getFile('lib/ui/ui.dart').writeAsStringSync(r'''
library dart.ui;

class PlatformDispatcher {
  static PlatformDispatcher get instance => PlatformDispatcher();
  bool Function(Object error, StackTrace stack)? onError;
}
''');
    final libraries = sdkRoot.getFile('lib/_internal/sdk_library_metadata/lib/libraries.dart');
    libraries.writeAsStringSync(
      libraries.readAsStringSync().replaceFirst(
        '};',
        '  "ui": const LibraryInfo("ui/ui.dart", categories: "Shared"),\n};',
      ),
    );
  }

  String get crashServicePath => '$testPackageLibPath/core/crash/crash_service.dart';
}

@reflectiveTest
final class CrashDirectSentryCallTest extends _CrashSdkRuleTest {
  @override
  String get ruleName => 'crash_direct_sentry_call';
  @override
  String get needle => "import 'package:sentry_flutter/sentry_flutter.dart';";
  @override
  String get path => '$testPackageLibPath/features/checkout/data/checkout_repository.dart';
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';
''';

  Future<void> test_reportsImportAndCaptureCall() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> submit(Object error) async {
  await Sentry.captureException(error);
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "import 'package:sentry_flutter", ruleName),
      compatLint(source, 'Sentry.captureException(error)', ruleName),
    ]);
  }

  Future<void> test_reportsSdkUseInOtherCoreCrashFiles() async {
    final filePath = '$testPackageLibPath/core/crash/sentry_config.dart';
    const source = r'''
// ignore_for_file: unused_import
import 'package:sentry_flutter/sentry_flutter.dart';
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "import 'package:sentry_flutter", ruleName),
    ]);
  }

  Future<void> test_allowsCrashService() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

abstract final class Crash {
  static Future<void> init({required void Function() appRunner}) =>
      SentryFlutter.init((options) {}, appRunner: appRunner);

  static void error(Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
''', path: crashServicePath);
  }

  Future<void> test_allowsCrashFacadeCalls() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

void submit(Object error) {
  Crash.error(error, StackTrace.current);
}
''', path: path);
  }
}

@reflectiveTest
final class CrashCustomGlobalErrorHandlerTest extends _CrashSdkRuleTest {
  @override
  String get ruleName => 'crash_custom_global_error_handler';
  @override
  String get needle => 'FlutterError.onError = FlutterError.presentError;';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_handlers.dart';
  @override
  String get source => r'''
import 'package:flutter/foundation.dart';

void installHandlers() {
  FlutterError.onError = FlutterError.presentError;
}
''';

  Future<void> test_reportsPlatformDispatcherHandler() async {
    const source = r'''
import 'dart:ui';

void installHandlers() {
  PlatformDispatcher.instance.onError = (error, stack) => true;
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'PlatformDispatcher.instance.onError', ruleName),
    ]);
  }

  Future<void> test_reportsCustomHandlerInCrashService() async {
    const source = r'''
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void installHandlers() {
  FlutterError.onError = (details) => Sentry.captureException(details);
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> test_reportsCustomHandlerInsideCrashFacade() async {
    const source = r'''
import 'dart:async';

import 'package:flutter/foundation.dart';

abstract final class Crash {
  static Future<void> init({required FutureOr<void> Function() appRunner}) async {
    FlutterError.onError = FlutterError.presentError;
    await appRunner();
  }
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> test_reportsCrashlyticsHandlersOutsideCrashFacade() async {
    const source = r'''
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

void installHandlers() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
}
''';
    newFile(crashServicePath, source);

    await assertDiagnosticsInFile(crashServicePath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
    ]);
  }

  Future<void> test_reportsBootstrapHandlers() async {
    const source = r'''
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> bootstrap() async {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
''';
    final bootstrapPath = '$testPackageLibPath/bootstrap.dart';
    newFile(bootstrapPath, source);

    await assertDiagnosticsInFile(bootstrapPath, [
      compatLint(source, 'FlutterError.onError =', ruleName),
      compatLint(source, 'PlatformDispatcher.instance.onError =', ruleName),
    ]);
  }

  Future<void> test_allowsCrashlyticsHandlersInsideCrashFacade() async {
    newFile(crashServicePath, r'''
import 'dart:async';
import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract final class Crash {
  static Future<void> init({required FutureOr<void> Function() appRunner}) async {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await appRunner();
  }
}
''');
    final mainPath = '$testPackageLibPath/main.dart';
    newFile(mainPath, r'''
import 'core/crash/crash_service.dart';

void runApp(Object app) {}

Future<void> main() async {
  await Crash.init(appRunner: () => runApp(Object()));
}
''');

    await assertNoDiagnosticsInFile(crashServicePath);
    await assertNoDiagnosticsInFile(mainPath);
  }

  Future<void> test_allowsReadingHandler() async {
    await assertAllows(r'''
import 'package:flutter/foundation.dart';

final previous = FlutterError.onError;
''', path: path);
  }
}

@reflectiveTest
final class CrashSentrySendDefaultPiiTest extends _CrashSdkRuleTest {
  @override
  String get ruleName => 'crash_sentry_send_default_pii';
  @override
  String get needle => 'options.sendDefaultPii = true;';
  @override
  String get path => crashServicePath;
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.sendDefaultPii = true;
});
''';

  Future<void> test_allowsFalse() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.sendDefaultPii = false;
});
''', path: path);
  }

  Future<void> test_allowsUnrelatedOptionClass() async {
    await assertAllows(r'''
class AnalyticsOptions {
  bool sendDefaultPii = false;
}

void configure(AnalyticsOptions options) {
  options.sendDefaultPii = true;
}
''', path: path);
  }
}

@reflectiveTest
final class CrashSentryCaptureOptInTest extends _CrashSdkRuleTest {
  @override
  String get ruleName => 'crash_sentry_capture_opt_in';
  @override
  String get needle => 'options.attachScreenshot = true;';
  @override
  String get path => crashServicePath;
  @override
  String get source => r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachScreenshot = true;
});
''';

  Future<void> test_reportsViewHierarchy() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachViewHierarchy = true;
});
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'options.attachViewHierarchy = true;', ruleName),
    ]);
  }

  Future<void> test_allowsDisabledCapture() async {
    await assertAllows(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> init() => SentryFlutter.init((options) {
  options.attachScreenshot = false;
  options.attachViewHierarchy = false;
});
''', path: path);
  }
}

@reflectiveTest
final class CrashFacadePublicApiTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_facade_public_api';
  @override
  String get needle => 'setBackend(Object backend)';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_service.dart';
  @override
  String get source => r'''
abstract final class Crash {
  static Object? _backend;
  static void setBackend(Object backend) => _backend = backend;
  static void error(Object error, StackTrace stackTrace) {}
}
''';

  Future<void> test_reportsPublicField() async {
    const source = r'''
abstract final class Crash {
  static const checkoutTag = 'checkout';
  static void log(String message) {}
}
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [compatLint(source, "checkoutTag = 'checkout'", ruleName)]);
  }

  Future<void> test_allowsInitLogErrorAndPrivateMembers() async {
    await assertAllows(r'''
abstract final class Crash {
  static bool _enabled = false;
  static Future<void> init({required void Function() appRunner}) async {
    _enabled = true;
    appRunner();
  }
  static void log(String message, {Map<String, Object?> extras = const {}}) => _send(message);
  static void error(Object error, StackTrace stackTrace, {String? reason}) => _send(error);
  static void _send(Object value) {}
}
''', path: path);
  }
}

@reflectiveTest
final class CrashErrorRecursionTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_error_recursion';
  @override
  String get needle => 'Crash.error(sendError, sendStack);';
  @override
  String get path => '$testPackageLibPath/core/crash/crash_service.dart';
  @override
  String get source => r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {
    try {
      _send(error);
    } on Object catch (sendError, sendStack) {
      Crash.error(sendError, sendStack);
    }
  }
  static void _send(Object value) {}
}
''';

  Future<void> test_allowsContainedSendFailure() async {
    await assertAllows(r'''
void debugPrint(String message) {}

abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {
    try {
      _send(error);
    } on Object catch (sendError) {
      debugPrint('crash send failed: ${sendError.runtimeType}');
    }
  }
  static void _send(Object value) {}
}
''', path: path);
  }

  Future<void> test_allowsFeatureCallsToCrashError() async {
    await assertAllows(r'''
abstract final class Crash {
  static void error(Object error, StackTrace stackTrace) {}
}

void submit(Object error) {
  Crash.error(error, StackTrace.current);
}
''', path: '$testPackageLibPath/features/checkout/data/checkout_repository.dart');
  }
}

@reflectiveTest
final class CrashSentryAuthTokenInSourceTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_sentry_auth_token_in_source';
  @override
  String get needle => "'sntrys_fixture';";
  @override
  String get path => '$testPackageLibPath/core/config/sentry_upload.dart';
  @override
  String get source => r'''
const sentryAuthToken = 'sntrys_fixture';
''';

  Future<void> test_reportsEnvironmentBundledToken() async {
    const source = r'''
const sentryAuthToken = String.fromEnvironment('SENTRY_AUTH_TOKEN');
''';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, "String.fromEnvironment('SENTRY_AUTH_TOKEN')", ruleName),
    ]);
  }

  Future<void> test_allowsPublicDsnConfig() async {
    await assertAllows(r'''
const sentryDsn = String.fromEnvironment('SENTRY_DSN');
''', path: path);
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
