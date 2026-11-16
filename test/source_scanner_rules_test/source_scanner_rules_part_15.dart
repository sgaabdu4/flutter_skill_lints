part of '../source_scanner_rules_test.dart';

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

  Future<void> _allowsWhenGuarded() async {
    await assertAllows(r'''
class SyncService {
  void pushItems(String userId, List<Object> items) {
    if (items.isEmpty) return;
    remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
  }
}
''');
  }

  Future<void> _allowsNonEntitySaveAll() async {
    await assertAllows(r'''
class SyncService {
  void pushRaw(String userId, List<Object> items) {
    remote.saveAll(userId, items);
  }
}
''');
  }

  Future<void> _reportsMultilineSaveAll() async {
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

  Future<void> _allowsChangedSubsetWrite() async {
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

  Future<void> _allowsLateFinalCachedGetter() async {
    await assertAllows(r'''
class ItemState {
  ItemState(this.items);
  final List<Object> items;

  late final Map<String, List<Object>> itemsByGroup = _indexItems(items);
}
''');
  }
}

final class ExpandoDerivedCacheForbiddenTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'expando_derived_cache_forbidden';
  @override
  String get needle => 'Expando<Map<String, Object>>';
  @override
  String get source => r'''
final _itemsByIdCache = Expando<Map<String, Object>>('ItemState.itemsById');
''';

  Future<void> _allowsLateFinalDerivedIndex() async {
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

  Future<void> _skipsTestFiles() async {
    await assertAllows(r'''
final _cache = Expando<Map<String, Object>>('test cache');
''', path: '$testPackageRootPath/test/item_state_test.dart');
  }
}

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

  Future<void> _allowsSharedLookupExtension() async {
    await assertAllows(r'''
class ItemNotifier {
  Item? itemById(List<Item> items, String itemId) {
    return items.lookupByKey(itemId, (item) => item.id);
  }
}
''');
  }

  // Row 21: the skill's indexOfByKey (collections-helpers.md) subscripted in place.
  Future<void> _reportsIndexOfByKeySubscriptedInPlace() async {
    const source = r'''
class ItemNotifier {
  Item? itemById(List<Item> items, String itemId) {
    return items.indexOfByKey((item) => item.id)[itemId];
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.indexOfByKey(', ruleName),
    ]);
  }

  Future<void> _allowsSkillCachedIndexOfByKey() async {
    await assertAllows(r'''
class ItemNotifier {
  List<Item?> itemsByIds(List<Item> items, List<String> ids) {
    final itemsById = items.indexOfByKey((item) => item.id);
    return [for (final id in ids) itemsById[id]];
  }
}
''');
  }

  Future<void> _allowsReturnedIndexMap() async {
    await assertAllows(r'''
Map<String, Item> itemsById(List<Item> items) {
  return items.indexBy((item) => item.id);
}
''');
  }
}

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

  Future<void> _reportsMultilineLookupInIterationCallback() async {
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

  Future<void> _reportsLookupInForEachCallback() async {
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

  Future<void> _reportsLookupInCollectionFor() async {
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

  Future<void> _reportsNestedIndexWhereLookup() async {
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

  Future<void> _reportsManualLookupLoopInsideLoop() async {
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

  Future<void> _reportsLookupInBuild() async {
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

  Future<void> _reportsIndexedManualLookupInsideCallback() async {
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

  Future<void> _reportsLookupInWidgetBuilderFunction() async {
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

  Future<void> _allowsLookupInSingleCallMapCallback() async {
    await assertAllows('''
$_item
void cache(Map<String, Item> cache, List<Item> items, String itemId) {
  cache.putIfAbsent(itemId, () => items.firstWhere((item) => item.id == itemId));
}
''');
  }

  Future<void> _reportsLookupOverIdListInNotifier() async {
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

  Future<void> _reportsCompoundAndBlockPredicatesInLoop() async {
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

  Future<void> _reportsLookupInGetters() async {
    const source =
        '''
$_item
class ItemsState {
  const ItemsState(this.items, this.itemId);
  final List<Item> items;
  final String itemId;

  Item get item => items.firstWhere((item) => item.id == itemId);
}

List<Item> currentItems = const [];

int get selectedIndex {
  return currentItems.indexWhere((item) => item.id == 'selected');
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.firstWhere(', ruleName),
      compatLint(analyzedSource, '.indexWhere(', ruleName),
    ]);
  }

  Future<void> _allowsOneOffRepositoryMutation() async {
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

  Future<void> _allowsOneOffNotifierLookup() async {
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

  Future<void> _allowsSingleManualLookupLoop() async {
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

  Future<void> _allowsLookupInTapCallbackInsideBuild() async {
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

  Future<void> _allowsLookupInLoopIterable() async {
    await assertAllows('''
$_item
void printFrom(List<Item> items, String itemId) {
  for (final item in items.skip(items.indexWhere((item) => item.id == itemId))) {
    print(item);
  }
}
''');
  }

  Future<void> _allowsMapIndex() async {
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

  Future<void> _reportsMultilineIndexWhereLookup() async {
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

  Future<void> _reportsLookupOverIdListInNotifier() async {
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

  Future<void> _allowsLookupByUnrelatedLongerName() async {
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

  Future<void> _reportsNestedLookupInTopLevelFunction() async {
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

  Future<void> _reportsNestedLookupInCollectionFor() async {
    const source = r'''
List<Object> resolve(List<Object> items, List<String> ids) => [
  for (final id in ids) items.firstWhere((item) => item.id == id),
];
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.firstWhere(', ruleName)]);
  }

  Future<void> _allowsLookupNotKeyedByLoopVariable() async {
    await assertAllows(r'''
void applyAll(List<Object> items, List<Object> changes, String selectedId) {
  for (final change in changes) {
    final selected = items.firstWhere((item) => item.id == selectedId);
    print('$change $selected');
  }
}
''');
  }

  Future<void> _allowsPreIndexedMap() async {
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

  Future<void> _reportsOmittedXasyncInLongRunningMethod() async {
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

  Future<void> _reportsClientWaitingForBackendCompletion() async {
    const source = r'''
class DeleteResult {}

abstract interface class AccountRemote {
  Future<DeleteResult> deleteAccount(String userId, {bool waitForCompletion = false});
  Future<bool> startDeleteAccount(String userId);
  Future<bool> waitForAccountDeleted(String userId, {int maxAttempts = 30});
  Future<DeleteResult> refreshProfile(String userId, {bool waitForCompletion = false});
}

class AccountRepository {
  AccountRepository(this.remote);
  final AccountRemote remote;

  Future<DeleteResult> deleteAccount(String userId) async {
    final result = await remote.deleteAccount(userId, waitForCompletion: true);
    return result;
  }

  Future<bool> deleteAccountInBackground(String userId) async {
    final started = await remote.startDeleteAccount(userId);
    if (!started) return false;
    await remote.deleteAccount(userId, waitForCompletion: false);
    return remote.waitForAccountDeleted(userId, maxAttempts: 60);
  }

  Future<DeleteResult> refresh(String userId) {
    return remote.refreshProfile(userId, waitForCompletion: true);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'deleteAccount(userId, waitForCompletion: true);', ruleName),
    ]);
  }

  Future<void> _allowsUnresolvedWaitForCompletionLookalike() async {
    await assertAllows(r'''
class AccountRepository {
  Future<void> deleteAccount(String userId) async {
    await remote.deleteAccount(userId, waitForCompletion: true);
  }
}
''');
  }

  Future<void> _allowsAsyncExecution() async {
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

  Future<void> _allowsForwardingWrapperWithXasyncParameter() async {
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

  Future<void> _allowsShortInteractiveFunction() async {
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

  Future<void> _allowsReconcileBeforeTelemetry() async {
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

  // networking.md "Long-Running Remote Work" WRONG: reports before reconcile.
  Future<void> _reportsSkillTelemetryBeforeWaitForReconcile() async {
    final source = _analyzedSource(r'''
class DeleteResult {
  const DeleteResult.ok();
  const DeleteResult.timedOut();
}

class AccountRepository {
  Future<DeleteResult> deleteAccount(String userId) async {
    try {
      return await remote.startDeleteAccount(userId);
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'deleteAccount');
      final deleted = await remote.waitForAccountDeleted(userId, maxAttempts: 60);
      return deleted ? .ok() : .timedOut();
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, 'Crash.error', ruleName)]);
  }

  Future<void> _reportsTelemetryWithoutReconcileAfterAsyncStart() async {
    final source = _analyzedSource(r'''
class AccountRepository {
  Future<bool> deleteAccount(String userId) async {
    try {
      await remote.startDeleteAccount(userId);
      return true;
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'startDelete');
      return false;
    }
  }

  Future<bool> removeWorkspace(String workspaceId) async {
    try {
      await functions.createExecution(functionId: workspaceFunctionId, xasync: true);
      return true;
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [
      compatLint(source, 'Crash.error', ruleName),
      compatLint(source, 'Sentry.captureException', ruleName),
    ]);
  }

  Future<void> _allowsSkillAsyncStartThenReconcile() async {
    await assertAllows(r'''
class DeleteResult {
  const DeleteResult.ok();
  const DeleteResult.timedOut();
}

class AccountRepository {
  Future<DeleteResult> deleteAccount(String userId) async {
    final started = await remote.startDeleteAccount(userId);
    if (!started.ok) return started;
    final deleted = await remote.waitForAccountDeleted(userId, maxAttempts: 60);
    return deleted ? .ok() : .timedOut();
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await functions.createExecution(functionId: deleteAccountFunctionId, xasync: true);
      return await waitForDeleted(userId, maxAttempts: 60);
    } catch (e, s) {
      final deleted = await _reconcileDeletedState();
      if (!deleted) Crash.error(e, s);
      return deleted;
    }
  }
}
''');
  }

  Future<void> _allowsOrdinaryDestructiveTelemetry() async {
    await assertAllows(r'''
class ProductNotifier {
  Future<void> deleteProduct(String id) async {
    try {
      await ref.read(productRepositoryProvider).delete(id);
    } on Exception catch (e, s) {
      state = state.copyWith(error: AppErrorMapper.from(e));
      Crash.error(e, s, reason: 'ProductNotifier.deleteProduct');
    }
  }

  Future<void> cancelSession() async {
    try {
      startTimer();
      await session.close();
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'cancelSession');
    }
  }
}
''');
  }
}
