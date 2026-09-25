// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class ArchInterfaceContractTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_interface_contract';
  @override
  String get needle => 'class UserDatasource';
  @override
  bool get lineStart => true;
  @override
  bool get addIgnorePrefix => false;
  @override
  String get path => '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
  @override
  String get source => 'class UserDatasource {}';

  Future<void> test_allowsResolvedImportedInterface() async {
    newFile(
      '$testPackageLibPath/features/items/domain/repositories/items_repository.dart',
      'abstract interface class IItemsRepository {}',
    );
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    newFile(path, r'''
import '../../domain/repositories/items_repository.dart';

class ItemsRepository implements IItemsRepository {}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_reportsSecondClassWithoutInterface() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = r'''
abstract interface class IItemsRepository {}
class ItemsRepository implements IItemsRepository {}
class MissingRepository {}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'abstract interface class', ruleName)]);
  }

  Future<void> test_reportsConcreteInterfaceClassWithoutContract() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = 'interface class PublicRepository {}';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'interface class', ruleName)]);
  }

  Future<void> test_allowsAbstractInterfaceContractDeclaration() async {
    final path = '$testPackageLibPath/features/items/domain/repositories/items_repository.dart';
    newFile(path, 'abstract interface class IItemsRepository {}');
    await assertNoDiagnosticsInFile(path);
  }
}

@reflectiveTest
final class ArchRepositoryGeneratedExtendsTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_repository_generated_extends';
  @override
  String get needle => r'extends _$OrderRepository';
  @override
  String get source => r'''
abstract class _$OrderRepository {}

class OrderRepository extends _$OrderRepository {}
''';

  Future<void> test_allowsRepositoryInterfaceImplementation() async {
    await assertAllows(r'''
abstract interface class IOrderRepository {}

class HiveOrderRepository implements IOrderRepository {}
''');
  }

  Future<void> test_allowsGeneratedNotifierClasses() async {
    await assertAllows(r'''
abstract class _$OrderRepositoryNotifier {}

class OrderRepositoryNotifier extends _$OrderRepositoryNotifier {}
''');
  }

  Future<void> test_allowsRiverpodGeneratedProviderClass() async {
    await assertAllows(r'''
const riverpod = Object();

abstract class _$OrderRepository {}

@riverpod
class OrderRepository extends _$OrderRepository {}
''');
  }
}

@reflectiveTest
final class ArchConcreteDependencyTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_concrete_dependency';
  @override
  String get needle => 'final UserDatasource';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/data/repositories/user_repository.dart';
  @override
  String get source => r'''
abstract interface class IUserRepository {}

class UserDatasource {}

class UserRepository {
  final UserDatasource _datasource;
}
''';

  static const _providerPrelude = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

abstract interface class IOrderRepository {}

class HiveOrderRepository implements IOrderRepository {}
''';

  Future<void> test_reportsProviderReturningConcreteRepository() async {
    final filePath = '$testPackageLibPath/features/orders/repositories/order_repository.dart';
    const source =
        '''
$_providerPrelude
@Riverpod(keepAlive: true)
HiveOrderRepository orderRepository(Ref ref) => HiveOrderRepository();

@Riverpod(keepAlive: true)
Future<HiveOrderRepository> asyncOrderRepository(Ref ref) async => HiveOrderRepository();
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'HiveOrderRepository orderRepository', ruleName),
      compatLint(source, 'Future<HiveOrderRepository> asyncOrderRepository', ruleName),
    ]);
  }

  Future<void> test_allowsProviderReturningRepositoryInterface() async {
    await assertAllows('''
$_providerPrelude
@Riverpod(keepAlive: true)
IOrderRepository orderRepository(Ref ref) => HiveOrderRepository();

@Riverpod(keepAlive: true)
Future<IOrderRepository> asyncOrderRepository(Ref ref) async => HiveOrderRepository();
''', path: '$testPackageLibPath/features/orders/repositories/order_repository.dart');
  }
}

@reflectiveTest
final class ArchDatasourceTryCatchTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_datasource_try_catch';
  @override
  String get needle => 'catch (_) {';
  @override
  String get path => '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
  @override
  String get source => r'''
class UserDatasource {
  Future<void> load() async {
    try {
      await Future<void>.value();
    } catch (_) {
      rethrow;
    }
  }
}
''';

  Future<void> test_reportsRethrowOnlyCatchBeforeFinally() async {
    final analyzedSource = _analyzedSource(r'''
class UserDatasource {
  Future<void> load() async {
    try {
      await Future<void>.value();
    } on Exception {
      rethrow;
    } finally {
      await Future<void>.value();
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'on Exception {', ruleName)]);
  }

  /// networking.md:30-43, hive-persistence.md:72 and state-management-lifecycle.md:69-72.
  Future<void> test_allowsSkillDataLayerCatches() async {
    await assertAllows(r'''
class AppException implements Exception {
  const AppException(this.code);
  final String code;
}

class UserDatasource {
  Future<Object?> fetch() async {
    try {
      return await Future<Object?>.value();
    } on Exception {
      throw const AppException('network');
    }
  }

  Map<String, Object?> read() {
    try {
      return <String, Object?>{};
    } on FormatException {
      return <String, Object?>{};
    }
  }

  Future<void> remove(String id) async {
    try {
      await Future<void>.value();
    } catch (_) {
      await restore(id);
      rethrow;
    }
  }

  Future<Object?> readOrNull() async {
    try {
      return await Future<Object?>.value();
    } on FormatException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> restore(String id) async {}
}
''', path: path);
  }
}

@reflectiveTest
final class RiverpodWidgetRefOutsideWidgetTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

class WidgetRef {
  void read(Object provider) {}
}

abstract class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class ConsumerStatefulWidget extends StatefulWidget {}

abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => WidgetRef();
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_widget_ref_outside_widget';
  @override
  String get needle => 'WidgetRef ref;';
  @override
  bool get addIgnorePrefix => false;
  @override
  String get source => r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartSyncService {
  CartSyncService(this.ref);

  final WidgetRef ref;

  void sync() => ref.read(Object());
}
''';

  Future<void> test_reportsServiceMethodParameter() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutService {
  void submit(WidgetRef ref) => ref.read(Object());
}
''';
    await assertDiagnostics(source, [compatLint(source, 'WidgetRef ref)', ruleName)]);
  }

  Future<void> test_allowsWidgetsStatesAndMixinsOnState() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}

class CartPage extends ConsumerStatefulWidget {}

class _CartPageState extends ConsumerState<CartPage> {
  void refresh(WidgetRef other) => other.read(Object());
}

mixin CartActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void clear(WidgetRef other) => other.read(Object());
}

extension CartRef on WidgetRef {
  void clearCart() => read(Object());
}
''', addIgnorePrefix: false);
  }

  Future<void> test_severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class RiverpodGeneratedProviderAliasTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _riverpodProviderStub);
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_generated_provider_alias';
  @override
  String get needle => 'cartAliasProvider = cartProvider;';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final cartProvider = CartProvider._();

final cartAliasProvider = cartProvider;
''';

  Future<void> test_reportsGetterStaticAndFamilyAliases() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final class ItemFamily extends ProviderOrFamily {
  ItemFamily._();

  CartProvider call(String id) => CartProvider._();
}

final cartProvider = CartProvider._();
final itemProvider = ItemFamily._();

CartProvider get cartGetterAlias => cartProvider;

abstract final class Providers {
  static final cart = cartProvider;
}

final firstItemProvider = itemProvider('first');
''';
    await assertDiagnostics(source, [
      compatLint(source, 'cartGetterAlias =>', ruleName),
      compatLint(source, 'cart = cartProvider;', ruleName),
      compatLint(source, 'firstItemProvider =', ruleName),
    ]);
  }

  Future<void> test_allowsGeneratedDeclarationsLocalsAndManualProviders() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final cartProvider = CartProvider._();
final manualProvider = Provider<int>((ref) => 1);

int read() {
  final provider = cartProvider;
  return provider.hashCode;
}
''', addIgnorePrefix: false);
  }

  Future<void> test_severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
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
    newPackage('riverpod')
      ..addFile('lib/riverpod.dart', 'sealed class AsyncValue<T> {}')
      ..addFile('lib/src/framework.dart', r'''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class Provider<T> {
  Provider<Future<T>> get future => throw UnimplementedError();
}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
}
class Storage<KeyT, EncodedT> {}
abstract class AnyNotifier<StateT, ValueT> {
  Ref get ref => throw UnimplementedError();
}
extension NotifierPersistX<StateT, ValueT> on AnyNotifier<StateT, ValueT> {
  void persist<KeyT, EncodedT>(FutureOr<Storage<KeyT, EncodedT>> storage, {required KeyT key}) {}
}
abstract class Notifier<T> extends AnyNotifier<T, T> {}
abstract class AsyncNotifier<T> extends AnyNotifier<AsyncValue<T>, T> {}
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

  Future<void> test_allowsWatchedReactiveCredentialState() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Provider<T> {}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
}

abstract interface class IApiService {}
class ApiService implements IApiService {
  ApiService(String credential);
}
final credentialProvider = Provider<String>();

@Riverpod(keepAlive: true)
IApiService apiService(Ref ref) => ApiService(ref.watch(credentialProvider));
''');
  }

  Future<void> test_allowsClientRebuiltFromLiveConfig() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Provider<T> {}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
}

class AppConfig {
  const AppConfig(this.endpoint);
  final String endpoint;
}
class ApiClient {
  ApiClient(String endpoint);
}
final appConfigProvider = Provider<Future<AppConfig>>();

@Riverpod(keepAlive: true)
Future<ApiClient> apiClient(Ref ref) async {
  final config = await ref.watch(appConfigProvider);
  return ApiClient(config.endpoint);
}
''');
  }

  Future<void> test_reportsStableClientWatchBesideReactiveCredential() async {
    const source = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Provider<T> {}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
}

class HttpClient {}
abstract interface class IApiService {}
class ApiService implements IApiService {
  ApiService(String credential, HttpClient client);
}
final credentialProvider = Provider<String>();
final httpClientProvider = Provider<HttpClient>();

@Riverpod(keepAlive: true)
IApiService apiService(Ref ref) =>
    ApiService(ref.watch(credentialProvider), ref.watch(httpClientProvider));
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(httpClientProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsStableDependencyValuesThroughAsyncWrappers() async {
    const source = r'''
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:riverpod/riverpod.dart';

class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Provider<T> {}
class Ref {
  T watch<T>(Provider<T> provider) => throw UnimplementedError();
}

class StorageLocalDatasource {}
abstract interface class IAuthRepository {}
class AuthRepository implements IAuthRepository {
  AuthRepository(Object storage, Object account);
}
final storageProvider = Provider<AsyncValue<StorageLocalDatasource>>();
final accountProvider = Provider<Future<appwrite.Account>>();

@Riverpod(keepAlive: true)
IAuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(storageProvider), ref.watch(accountProvider));
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(storageProvider)', ruleName),
      compatLint(analyzedSource, 'ref.watch(accountProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsNotifierMembersWatchingStableInfrastructure() async {
    const source = r'''
import 'package:riverpod/src/framework.dart';

class Product {}
abstract interface class IProductRepository {
  Future<List<Product>> fetchAll();
}
final productRepositoryProvider = Provider<IProductRepository>();

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    return repo.fetchAll();
  }

  Future<IProductRepository> get _repository => ref.watch(productRepositoryProvider.future);
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(productRepositoryProvider);', ruleName),
      compatLint(analyzedSource, 'ref.watch(productRepositoryProvider.future)', ruleName),
    ]);
  }

  Future<void> test_allowsNotifierBuildWatchingStateAndConfig() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';
import 'package:riverpod/src/framework.dart';

class Product {}
class Cart {}
class BackendConfig {
  const BackendConfig(this.endpoint);
  final String endpoint;
}
final productsProvider = Provider<AsyncValue<List<Product>>>();
final cartProvider = Provider<Cart>();
final backendConfigProvider = Provider<BackendConfig>();

class CheckoutNotifier extends Notifier<int> {
  int build() {
    ref.watch(productsProvider);
    ref.watch(cartProvider);
    ref.watch(backendConfigProvider);
    return 0;
  }
}
''');
  }

  Future<void> test_allowsNotifierPersistStorageWatch() async {
    await assertAllows(r'''
import 'package:riverpod/src/framework.dart';

class Todo {}
final storageProvider = Provider<Storage<String, String>>();

class TodosNotifier extends AsyncNotifier<List<Todo>> {
  Future<List<Todo>> build() async {
    persist(ref.watch(storageProvider.future), key: 'todos');
    return [];
  }
}
''');
  }

  Future<void> test_allowsLookalikeNotifierBase() async {
    await assertAllows(r'''
import 'package:riverpod/src/framework.dart';

abstract interface class IProductRepository {}
final productRepositoryProvider = Provider<IProductRepository>();

abstract class AnyNotifier {
  Ref get ref => throw UnimplementedError();
}

class ProductsNotifier extends AnyNotifier {
  IProductRepository build() => ref.watch(productRepositoryProvider);
}
''');
  }
}
