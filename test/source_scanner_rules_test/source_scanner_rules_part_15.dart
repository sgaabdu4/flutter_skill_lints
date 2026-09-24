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
  static const _item = r'''
import 'package:flutter/widgets.dart';

class Item {
  const Item(this.id);
  final String id;
}
''';

  @override
  String get ruleName => 'linear_id_lookup_in_hot_path';
  @override
  String get needle => '.firstWhere(';
  @override
  String get source =>
      '''
$_item
void applyAll(List<Item> items, List<String> changes, String selectedId) {
  for (final change in changes) {
    final selected = items.firstWhere((item) => item.id == selectedId);
    print('\$change \$selected');
  }
}
''';

  Future<void> test_reportsMultilineLookupInIterationCallback() async {
    const source =
        '''
$_item
List<Item> resolve(List<Item> items, List<String> ids) {
  return ids
      .map(
        (id) => items.firstWhere(
          (item) => item.id == id,
        ),
      )
      .toList();
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_reportsLookupInForEachCallback() async {
    const source =
        '''
$_item
void apply(List<Item> items, List<String> ids) {
  ids.forEach((id) {
    final index = items.indexWhere((item) => item.id == id);
    print(index);
  });
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_reportsLookupInCollectionFor() async {
    const source =
        '''
$_item
List<Item> resolve(List<Item> items, List<String> ids) => [
  for (final id in ids) items.firstWhere((item) => item.id == id),
];
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_reportsNestedIndexWhereLookup() async {
    const source =
        '''
$_item
class Change {
  const Change(this.itemId);
  final String itemId;
}

class ItemRepository {
  void applyChanges(List<Item> items, List<Change> changes) {
    for (final change in changes) {
      final index = items.indexWhere((item) => item.id == change.itemId);
      if (index >= 0) print(change);
    }
  }
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_reportsManualLookupLoopInsideLoop() async {
    const source =
        '''
$_item
void apply(List<Item> items, List<String> ids) {
  for (final id in ids) {
    for (final item in items) {
      if (item.id == id) print(item);
    }
  }
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'for (final item', ruleName),
    ]);
  }

  Future<void> test_reportsLookupInBuild() async {
    const source =
        '''
$_item
class ItemTile extends Widget {
  ItemTile(this.items, this.itemId);
  final List<Item> items;
  final String itemId;

  Widget build(BuildContext context) {
    final item = items.firstWhere((item) => item.id == itemId);
    print(item);
    return this;
  }
}
''';

    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_reportsIndexedManualLookupInsideCallback() async {
    const source =
        '''
$_item
void apply(List<Item> items, List<String> ids) {
  ids.forEach((id) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].id == id) print(i);
    }
  });
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'for (var i', ruleName)]);
  }

  Future<void> test_reportsLookupInWidgetBuilderFunction() async {
    const source =
        '''
$_item
Widget buildTile(List<Item> items, String itemId, Widget Function(Item) tile) {
  return tile(items.firstWhere((item) => item.id == itemId));
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_allowsLookupInSingleCallMapCallback() async {
    await assertAllows('''
$_item
void cache(Map<String, Item> cache, List<Item> items, String itemId) {
  cache.putIfAbsent(itemId, () => items.firstWhere((item) => item.id == itemId));
}
''');
  }

  Future<void> test_reportsLookupOverIdListInNotifier() async {
    const source =
        '''
$_item
class ItemNotifier {
  void removeAll(List<Item> items, List<String> ids) {
    for (final id in ids) {
      final index = items.indexWhere((item) => item.id == id);
      if (index >= 0) items.removeAt(index);
    }
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_reportsCompoundAndBlockPredicatesInLoop() async {
    const source =
        '''
$_item
void apply(List<Item> items, List<String> ids, bool active) {
  for (final id in ids) {
    final first = items.firstWhere((item) => item.id == id && active);
    final index = items.indexWhere((item) {
      return item.id == id;
    });
    print('\$first \$index');
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.firstWhere(', ruleName),
      compatLint(analyzedSource, '.indexWhere(', ruleName),
    ]);
  }

  Future<void> test_allowsOneOffRepositoryMutation() async {
    await assertAllows('''
final class StoredValue {
  const StoredValue(this.id);
  final String id;
}

abstract interface class IExampleRepository {
  void replace(String id, StoredValue replacement);
}

final class ExampleRepository implements IExampleRepository {
  ExampleRepository(this._values);
  final List<StoredValue> _values;

  @override
  void replace(String id, StoredValue replacement) {
    final index = _values.indexWhere((value) => value.id == id);
    if (index != -1) _values[index] = replacement;
  }
}
''');
  }

  Future<void> test_allowsOneOffNotifierLookup() async {
    await assertAllows('''
$_item
class ItemNotifier {
  Item? itemById(List<Item> items, String itemId) {
    return items.firstWhere(
      (item) => item.id == itemId,
    );
  }
}
''');
  }

  Future<void> test_allowsSingleManualLookupLoop() async {
    await assertAllows('''
$_item
Item? itemById(List<Item> items, String itemId) {
  for (final item in items) {
    if (item.id == itemId) return item;
  }
  return null;
}
''');
  }

  Future<void> test_allowsLookupInTapCallbackInsideBuild() async {
    await assertAllows('''
$_item
class Button extends Widget {
  Button({required this.onPressed});
  final void Function() onPressed;
}

class ItemTile extends Widget {
  ItemTile(this.items, this.itemId);
  final List<Item> items;
  final String itemId;

  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        final item = items.firstWhere((item) => item.id == itemId);
        print(item);
      },
    );
  }
}
''');
  }

  Future<void> test_allowsLookupInLoopIterable() async {
    await assertAllows('''
$_item
void printFrom(List<Item> items, String itemId) {
  for (final item in items.skip(items.indexWhere((item) => item.id == itemId))) {
    print(item);
  }
}
''');
  }

  Future<void> test_allowsMapIndex() async {
    await assertAllows('''
$_item
void apply(Map<String, Item> itemsById, List<String> ids) {
  for (final id in ids) {
    print(itemsById[id]);
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

  Future<void> test_reportsLookupOverIdListInNotifier() async {
    const source = r'''
class ItemNotifier {
  void removeAll(List<Object> items, List<String> ids) {
    for (final id in ids) {
      final index = items.indexWhere((item) => item.id == id);
      if (index >= 0) items.removeAt(index);
    }
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_allowsLookupByUnrelatedLongerName() async {
    await assertAllows(r'''
class ItemNotifier {
  void removeAll(List<Object> items, List<String> ids, String idx) {
    for (final id in ids) {
      final index = items.indexWhere((item) => item.id == idx);
      if (index >= 0) print(id);
    }
  }
}
''');
  }

  Future<void> test_reportsNestedLookupInTopLevelFunction() async {
    const source = r'''
void applyChanges(List<Object> items, List<Object> changes) {
  for (final change in changes) {
    final index = items.indexWhere((item) => item.id == change.itemId);
    if (index >= 0) apply(change);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.indexWhere(', ruleName)]);
  }

  Future<void> test_reportsNestedLookupInCollectionFor() async {
    const source = r'''
List<Object> resolve(List<Object> items, List<String> ids) => [
  for (final id in ids) items.firstWhere((item) => item.id == id),
];
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> test_allowsLookupNotKeyedByLoopVariable() async {
    await assertAllows(r'''
void applyAll(List<Object> items, List<Object> changes, String selectedId) {
  for (final change in changes) {
    final selected = items.firstWhere((item) => item.id == selectedId);
    print('$change $selected');
  }
}
''');
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
