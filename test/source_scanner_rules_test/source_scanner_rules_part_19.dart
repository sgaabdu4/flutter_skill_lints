part of '../source_scanner_rules_test.dart';

final class _ArchInterfaceContractTest extends _ArchitectureRuleTest {
  static Map<String, Future<void> Function(_ArchInterfaceContractTest)> get _allCases =>
      caseSet<_ArchInterfaceContractTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsResolvedImportedInterface': (t) => t._allowsResolvedImportedInterface(),
          'test_reportsSecondClassWithoutInterface': (t) => t._reportsSecondClassWithoutInterface(),
          'test_reportsConcreteInterfaceClassWithoutContract': (t) =>
              t._reportsConcreteInterfaceClassWithoutContract(),
          'test_allowsAbstractInterfaceContractDeclaration': (t) =>
              t._allowsAbstractInterfaceContractDeclaration(),
        },
      );

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

  Future<void> _allowsResolvedImportedInterface() async {
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

  Future<void> _reportsSecondClassWithoutInterface() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = r'''
abstract interface class IItemsRepository {}
class ItemsRepository implements IItemsRepository {}
class MissingRepository {}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'abstract interface class', ruleName)]);
  }

  Future<void> _reportsConcreteInterfaceClassWithoutContract() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = 'interface class PublicRepository {}';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'interface class', ruleName)]);
  }

  Future<void> _allowsAbstractInterfaceContractDeclaration() async {
    final path = '$testPackageLibPath/features/items/domain/repositories/items_repository.dart';
    newFile(path, 'abstract interface class IItemsRepository {}');
    await assertNoDiagnosticsInFile(path);
  }
}

final class _ArchRepositoryGeneratedExtendsTest extends _ArchitectureRuleTest {
  static Map<String, Future<void> Function(_ArchRepositoryGeneratedExtendsTest)> get _allCases =>
      caseSet<_ArchRepositoryGeneratedExtendsTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsRepositoryInterfaceImplementation': (t) =>
              t._allowsRepositoryInterfaceImplementation(),
          'test_allowsGeneratedNotifierClasses': (t) => t._allowsGeneratedNotifierClasses(),
          'test_allowsRiverpodGeneratedProviderClass': (t) =>
              t._allowsRiverpodGeneratedProviderClass(),
        },
      );

  @override
  String get ruleName => 'arch_repository_generated_extends';
  @override
  String get needle => r'extends _$OrderRepository';
  @override
  String get source => r'''
abstract class _$OrderRepository {}

class OrderRepository extends _$OrderRepository {}
''';

  Future<void> _allowsRepositoryInterfaceImplementation() async {
    await assertAllows(r'''
abstract interface class IOrderRepository {}

class HiveOrderRepository implements IOrderRepository {}
''');
  }

  Future<void> _allowsGeneratedNotifierClasses() async {
    await assertAllows(r'''
abstract class _$OrderRepositoryNotifier {}

class OrderRepositoryNotifier extends _$OrderRepositoryNotifier {}
''');
  }

  Future<void> _allowsRiverpodGeneratedProviderClass() async {
    await assertAllows(r'''
const riverpod = Object();

abstract class _$OrderRepository {}

@riverpod
class OrderRepository extends _$OrderRepository {}
''');
  }
}

final class _ArchConcreteDependencyTest extends _ArchitectureRuleTest {
  static Map<String, Future<void> Function(_ArchConcreteDependencyTest)> get _allCases =>
      caseSet<_ArchConcreteDependencyTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsProviderReturningConcreteRepository': (t) =>
              t._reportsProviderReturningConcreteRepository(),
          'test_allowsProviderReturningRepositoryInterface': (t) =>
              t._allowsProviderReturningRepositoryInterface(),
        },
      );

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

  Future<void> _reportsProviderReturningConcreteRepository() async {
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

  Future<void> _allowsProviderReturningRepositoryInterface() async {
    await assertAllows('''
$_providerPrelude
@Riverpod(keepAlive: true)
IOrderRepository orderRepository(Ref ref) => HiveOrderRepository();

@Riverpod(keepAlive: true)
Future<IOrderRepository> asyncOrderRepository(Ref ref) async => HiveOrderRepository();
''', path: '$testPackageLibPath/features/orders/repositories/order_repository.dart');
  }
}

final class _RiverpodWidgetRefOutsideWidgetTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodWidgetRefOutsideWidgetTest)> get _allCases =>
      caseSet<_RiverpodWidgetRefOutsideWidgetTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsServiceMethodParameter': (t) => t._reportsServiceMethodParameter(),
          'test_allowsWidgetsStatesAndMixinsOnState': (t) =>
              t._allowsWidgetsStatesAndMixinsOnState(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

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

  Future<void> _reportsServiceMethodParameter() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutService {
  void submit(WidgetRef ref) => ref.read(Object());
}
''';
    await assertDiagnostics(source, [compatLint(source, 'WidgetRef ref)', ruleName)]);
  }

  Future<void> _allowsWidgetsStatesAndMixinsOnState() async {
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

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

final class _RiverpodGeneratedProviderAliasTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodGeneratedProviderAliasTest)> get _allCases =>
      caseSet<_RiverpodGeneratedProviderAliasTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsGetterStaticAndFamilyAliases': (t) =>
              t._reportsGetterStaticAndFamilyAliases(),
          'test_allowsGeneratedDeclarationsLocalsAndManualProviders': (t) =>
              t._allowsGeneratedDeclarationsLocalsAndManualProviders(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

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

  Future<void> _reportsGetterStaticAndFamilyAliases() async {
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

  Future<void> _allowsGeneratedDeclarationsLocalsAndManualProviders() async {
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

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

final class _ServiceProviderWatchDependencyTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_ServiceProviderWatchDependencyTest)> get _allCases =>
      caseSet<_ServiceProviderWatchDependencyTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsRepositoryFactoryWatch': (t) => t._reportsRepositoryFactoryWatch(),
          'test_allowsCollectionProjectionNamedQueue': (t) =>
              t._allowsCollectionProjectionNamedQueue(),
          'test_allowsCollectionProjectionWhoseElementLooksLikeService': (t) =>
              t._allowsCollectionProjectionWhoseElementLooksLikeService(),
          'test_reportsTypedStableServiceWatchWithGenericFactoryName': (t) =>
              t._reportsTypedStableServiceWatchWithGenericFactoryName(),
          'test_reportsGenericInfrastructureReturnType': (t) =>
              t._reportsGenericInfrastructureReturnType(),
          'test_reportsQualifiedInfrastructureReturnTypeThroughFuture': (t) =>
              t._reportsQualifiedInfrastructureReturnTypeThroughFuture(),
          'test_reportsAppwriteTablesAndAccountServicesByResolvedBase': (t) =>
              t._reportsAppwriteTablesAndAccountServicesByResolvedBase(),
          'test_allowsLocalServiceBaseLookalike': (t) => t._allowsLocalServiceBaseLookalike(),
          'test_doesNotUnwrapUserDefinedFutureName': (t) => t._doesNotUnwrapUserDefinedFutureName(),
          'test_allowsReadDependency': (t) => t._allowsReadDependency(),
          'test_allowsComputedProviderWatch': (t) => t._allowsComputedProviderWatch(),
          'test_allowsWatchedReactiveCredentialState': (t) =>
              t._allowsWatchedReactiveCredentialState(),
          'test_allowsClientRebuiltFromLiveConfig': (t) => t._allowsClientRebuiltFromLiveConfig(),
          'test_reportsStableClientWatchBesideReactiveCredential': (t) =>
              t._reportsStableClientWatchBesideReactiveCredential(),
          'test_reportsStableDependencyValuesThroughAsyncWrappers': (t) =>
              t._reportsStableDependencyValuesThroughAsyncWrappers(),
          'test_reportsNotifierMembersWatchingStableInfrastructure': (t) =>
              t._reportsNotifierMembersWatchingStableInfrastructure(),
          'test_allowsNotifierBuildWatchingStateAndConfig': (t) =>
              t._allowsNotifierBuildWatchingStateAndConfig(),
          'test_allowsNotifierPersistStorageWatch': (t) => t._allowsNotifierPersistStorageWatch(),
          'test_allowsLookalikeNotifierBase': (t) => t._allowsLookalikeNotifierBase(),
        },
      );

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

  Future<void> _reportsRepositoryFactoryWatch() async {
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

  Future<void> _allowsCollectionProjectionNamedQueue() async {
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

  Future<void> _allowsCollectionProjectionWhoseElementLooksLikeService() async {
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

  Future<void> _reportsTypedStableServiceWatchWithGenericFactoryName() async {
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

  Future<void> _reportsGenericInfrastructureReturnType() async {
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

  Future<void> _reportsQualifiedInfrastructureReturnTypeThroughFuture() async {
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

  Future<void> _reportsAppwriteTablesAndAccountServicesByResolvedBase() async {
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

  Future<void> _allowsLocalServiceBaseLookalike() async {
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

  Future<void> _doesNotUnwrapUserDefinedFutureName() async {
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

  Future<void> _allowsReadDependency() async {
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

  Future<void> _allowsComputedProviderWatch() async {
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

  Future<void> _allowsWatchedReactiveCredentialState() async {
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

  Future<void> _allowsClientRebuiltFromLiveConfig() async {
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

  Future<void> _reportsStableClientWatchBesideReactiveCredential() async {
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

  Future<void> _reportsStableDependencyValuesThroughAsyncWrappers() async {
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

  Future<void> _reportsNotifierMembersWatchingStableInfrastructure() async {
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

  Future<void> _allowsNotifierBuildWatchingStateAndConfig() async {
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

  Future<void> _allowsNotifierPersistStorageWatch() async {
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

  Future<void> _allowsLookalikeNotifierBase() async {
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

void _defineSourceScannerRulesPart19Tests() {
  analysisRuleSuite<_RiverpodGeneratedProviderAliasTest>(
    'RiverpodGeneratedProviderAliasTest',
    _RiverpodGeneratedProviderAliasTest.new,
    _RiverpodGeneratedProviderAliasTest._allCases,
  );
  analysisRuleSuite<_RiverpodWidgetRefOutsideWidgetTest>(
    'RiverpodWidgetRefOutsideWidgetTest',
    _RiverpodWidgetRefOutsideWidgetTest.new,
    _RiverpodWidgetRefOutsideWidgetTest._allCases,
  );
  analysisRuleSuite<_ArchInterfaceContractTest>(
    'ArchInterfaceContractTest',
    _ArchInterfaceContractTest.new,
    _ArchInterfaceContractTest._allCases,
  );
  analysisRuleSuite<_ArchRepositoryGeneratedExtendsTest>(
    'ArchRepositoryGeneratedExtendsTest',
    _ArchRepositoryGeneratedExtendsTest.new,
    _ArchRepositoryGeneratedExtendsTest._allCases,
  );
  analysisRuleSuite<_ArchConcreteDependencyTest>(
    'ArchConcreteDependencyTest',
    _ArchConcreteDependencyTest.new,
    _ArchConcreteDependencyTest._allCases,
  );
  analysisRuleSuite<_ServiceProviderWatchDependencyTest>(
    'ServiceProviderWatchDependencyTest',
    _ServiceProviderWatchDependencyTest.new,
    _ServiceProviderWatchDependencyTest._allCases,
  );
}
