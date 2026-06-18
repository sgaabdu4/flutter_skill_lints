// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class SyncSaveAllNoDirtyGuardTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'sync_save_all_no_dirty_guard';
  @override
  String get needle => '.saveAll(userId, items.map(ItemModel.fromEntity).toList())';
  @override
  String get source => r'''
class SyncService {
  void pushItems(String userId, List<Object> items) {
    remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
  }
}
''';

  Future<void> test_allowsWhenGuarded() async {
    await assertAllows(r'''
class SyncService {
  void pushItems(String userId, List<Object> items) {
    if (items.isEmpty) return;
    remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
  }
}
''');
  }

  Future<void> test_allowsNonEntitySaveAll() async {
    await assertAllows(r'''
class SyncService {
  void pushRaw(String userId, List<Object> items) {
    remote.saveAll(userId, items);
  }
}
''');
  }

  Future<void> test_reportsMultilineSaveAll() async {
    final analyzedSource = _analyzedSource(r'''
class SyncService {
  void pushItems(String userId, List<Object> items) {
    remote.saveAll(
      userId,
      items.map(ItemModel.fromEntity).toList(),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.saveAll(', ruleName)]);
  }
}

@reflectiveTest
final class SaveAllFullCollectionAfterSubsetMutationTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'save_all_full_collection_after_subset_mutation';
  @override
  String get needle => '.saveAll(items.map(ItemModel.fromEntity).toList())';
  @override
  String get source => r'''
class ItemRepository {
  void refresh(List<Object> items) {
    final index = items.indexWhere((item) => item.id == changed.id);
    if (index >= 0) {
      items[index] = changed;
    }
    local.saveAll(items.map(ItemModel.fromEntity).toList());
  }
}
''';

  Future<void> test_allowsChangedSubsetWrite() async {
    await assertAllows(r'''
class ItemRepository {
  void refresh(List<Object> items) {
    final changed = <Object>[];
    for (final item in items) {
      if (item.isDirty) changed.add(item);
    }
    if (changed.isNotEmpty) {
      local.mergeAll(changed.map(ItemModel.fromEntity).toList());
    }
  }
}
''');
  }
}

@reflectiveTest
final class CollectionGetterAllocatesEachAccessTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'collection_getter_allocates_each_access';
  @override
  String get needle => 'Map<String, List<Object>> get itemsByGroup {';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class ItemState {
  ItemState(this.items);
  final List<Object> items;

  Map<String, List<Object>> get itemsByGroup {
    final map = <String, List<Object>>{};
    for (final item in items) {
      (map[item.groupId] ??= <Object>[]).add(item);
    }
    return map;
  }
}
''';

  Future<void> test_allowsLateFinalCachedGetter() async {
    await assertAllows(r'''
class ItemState {
  ItemState(this.items);
  final List<Object> items;

  late final Map<String, List<Object>> itemsByGroup = _indexItems(items);
}
''');
  }
}

@reflectiveTest
final class ExpandoDerivedCacheForbiddenTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'expando_derived_cache_forbidden';
  @override
  String get needle => 'Expando<Map<String, Object>>';
  @override
  String get source => r'''
final _itemsByIdCache = Expando<Map<String, Object>>('ItemState.itemsById');
''';

  Future<void> test_allowsLateFinalDerivedIndex() async {
    await assertAllows(r'''
class ItemState {
  ItemState(this.items);
  final List<Object> items;

  late final Map<String, Object> byId = Map.unmodifiable({
    for (final item in items) item.id: item,
  });
}
''');
  }

  Future<void> test_skipsTestFiles() async {
    await assertAllows(r'''
final _cache = Expando<Map<String, Object>>('test cache');
''', path: '$testPackageRootPath/test/item_state_test.dart');
  }
}

@reflectiveTest
final class AdHocIdIndexLookupTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'ad_hoc_id_index_lookup';
  @override
  String get needle => '.indexBy(';
  @override
  String get source => r'''
class ItemNotifier {
  Item? itemById(List<Item> items, String itemId) {
    return items.indexBy((item) => item.id)[itemId];
  }
}
''';

  Future<void> test_allowsSharedLookupExtension() async {
    await assertAllows(r'''
class ItemNotifier {
  Item? itemById(List<Item> items, String itemId) {
    return items.lookupByKey(itemId, (item) => item.id);
  }
}
''');
  }

  Future<void> test_allowsReturnedIndexMap() async {
    await assertAllows(r'''
Map<String, Item> itemsById(List<Item> items) {
  return items.indexBy((item) => item.id);
}
''');
  }
}

@reflectiveTest
final class LinearIdLookupInHotPathTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'linear_id_lookup_in_hot_path';
  @override
  String get needle => '.firstWhere(';
  @override
  String get source => r'''
class ItemNotifier {
  Item? _itemById(List<Item> items, String itemId) {
    return items.firstWhere((item) => item.id == itemId);
  }
}
''';

  Future<void> test_reportsMultilineFirstWhereLookup() async {
    const source = r'''
class ItemNotifier {
  Item? _itemById(List<Item> items, String itemId) {
    return items.firstWhere(
      (item) => item.id == itemId,
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_reportsManualByIdLoop() async {
    const source = r'''
Item? itemById(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Item? itemById', ruleName),
    ]);
  }

  Future<void> test_allowsMapIndex() async {
    await assertAllows(r'''
class ItemNotifier {
  Item? _itemById(Map<String, Item> itemsById, String itemId) {
    return itemsById[itemId];
  }
}
''');
  }
}

@reflectiveTest
final class NestedLinearLookupByIdTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'nested_linear_lookup_by_id';
  @override
  String get needle => '.indexWhere(';
  @override
  String get source => r'''
class ItemRepository {
  void applyChanges(List<Object> items, List<Object> changes) {
    for (final change in changes) {
      final index = items.indexWhere((item) => item.id == change.itemId);
      if (index >= 0) apply(change);
    }
  }
}
''';

  Future<void> test_reportsMultilineIndexWhereLookup() async {
    const source = r'''
class ItemRepository {
  void applyChanges(List<Object> items, List<Object> changes) {
    for (final change in changes) {
      final index = items.indexWhere(
        (item) => item.id == change.itemId,
      );
      if (index >= 0) apply(change);
    }
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_allowsPreIndexedMap() async {
    await assertAllows(r'''
class ItemRepository {
  void applyChanges(List<Object> items, List<Object> changes) {
    final itemsById = {for (final item in items) item.id: item};
    for (final change in changes) {
      final item = itemsById[change.itemId];
      if (item != null) apply(change);
    }
  }
}
''');
  }
}

@reflectiveTest
final class AppwriteBlockingFunctionExecutionInClientTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'appwrite_blocking_function_execution_in_client';
  @override
  String get needle => 'createExecution(';
  @override
  String get source => r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await functions.createExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: false,
    );
  }
}
''';

  Future<void> test_reportsOmittedXasyncInLongRunningMethod() async {
    const source = r'''
class ImportRemoteDatasource {
  Future<void> importData(String userId) async {
    await functions.createExecution(
      functionId: importDataFunctionId,
      body: userId,
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'createExecution(', ruleName),
    ]);
  }

  Future<void> test_allowsAsyncExecution() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await functions.createExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: true,
    );
  }
}
''');
  }

  Future<void> test_allowsForwardingWrapperWithXasyncParameter() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await _createDeleteUserExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: true,
    );
  }

  Future<void> _createDeleteUserExecution({
    required String functionId,
    String? body,
    bool? xasync,
  }) {
    return functions.createExecution(functionId: functionId, body: body, xasync: xasync);
  }
}
''');
  }

  Future<void> test_allowsShortInteractiveFunction() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> ping(String userId) async {
    await functions.createExecution(
      functionId: pingFunctionId,
      body: userId,
    );
  }
}
''');
  }
}

@reflectiveTest
final class DestructiveFailureLoggedBeforeReconcileTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'destructive_failure_logged_before_reconcile';
  @override
  String get needle => 'Crash.error(e, s)';
  @override
  String get source => r'''
class AuthNotifier {
  Future<void> deleteAccount() async {
    try {
      await repository.deleteAccount();
    } catch (e, s) {
      Crash.error(e, s);
      await _reconcileDeletedAccountState();
    }
  }

  Future<void> _reconcileDeletedAccountState() async {}
}
''';

  Future<void> test_allowsReconcileBeforeTelemetry() async {
    await assertAllows(r'''
class AuthNotifier {
  Future<void> deleteAccount() async {
    try {
      await repository.deleteAccount();
    } catch (e, s) {
      final reconciled = await _reconcileDeletedAccountState();
      if (!reconciled) {
        Crash.error(e, s);
      }
    }
  }

  Future<bool> _reconcileDeletedAccountState() async => true;
}
''');
  }
}

@reflectiveTest
final class StorageClearPreservesMigrationStateTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'storage_clear_preserves_migration_state';
  @override
  String get needle => '.clear()';
  @override
  String get source => r'''
class SettingsLocalDatasource {
  Future<void> resetAll() async {
    final lastOpenedAppVersion = await _storage.read<String>(localDataLastOpenedAppVersionKey);
    await _storage.clear();
    if (lastOpenedAppVersion != null) {
      await _storage.save(localDataLastOpenedAppVersionKey, lastOpenedAppVersion);
    }
  }
}
''';

  Future<void> test_allowsHardClear() async {
    await assertAllows(r'''
class SettingsLocalDatasource {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }

  Future<void> test_allowsNonStorageBoundaryClass() async {
    await assertAllows(r'''
class MemoryCache {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }
}
