part of '../source_scanner_rules_test.dart';

final class _SyncSaveAllNoDirtyGuardTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_SyncSaveAllNoDirtyGuardTest)> get _allCases =>
      caseSet<_SyncSaveAllNoDirtyGuardTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsWhenGuarded': (t) => t._allowsWhenGuarded(),
          'test_allowsNonEntitySaveAll': (t) => t._allowsNonEntitySaveAll(),
          'test_reportsMultilineSaveAll': (t) => t._reportsMultilineSaveAll(),
        },
      );

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

final class _SaveAllFullCollectionAfterSubsetMutationTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_SaveAllFullCollectionAfterSubsetMutationTest)>
  get _allCases => caseSet<_SaveAllFullCollectionAfterSubsetMutationTest>(
    parent: _SourceRuleTest._allCases,
    own: {'test_allowsChangedSubsetWrite': (t) => t._allowsChangedSubsetWrite()},
  );

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

final class _CollectionGetterAllocatesEachAccessTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_CollectionGetterAllocatesEachAccessTest)>
  get _allCases => caseSet<_CollectionGetterAllocatesEachAccessTest>(
    parent: _SourceRuleTest._allCases,
    own: {'test_allowsLateFinalCachedGetter': (t) => t._allowsLateFinalCachedGetter()},
  );

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

final class _ExpandoDerivedCacheForbiddenTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_ExpandoDerivedCacheForbiddenTest)> get _allCases =>
      caseSet<_ExpandoDerivedCacheForbiddenTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsLateFinalDerivedIndex': (t) => t._allowsLateFinalDerivedIndex(),
          'test_skipsTestFiles': (t) => t._skipsTestFiles(),
        },
      );

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

final class _AdHocIdIndexLookupTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_AdHocIdIndexLookupTest)> get _allCases =>
      caseSet<_AdHocIdIndexLookupTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsSharedLookupExtension': (t) => t._allowsSharedLookupExtension(),
          'test_reportsIndexOfByKeySubscriptedInPlace': (t) =>
              t._reportsIndexOfByKeySubscriptedInPlace(),
          'test_allowsSkillCachedIndexOfByKey': (t) => t._allowsSkillCachedIndexOfByKey(),
          'test_allowsReturnedIndexMap': (t) => t._allowsReturnedIndexMap(),
        },
      );

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

final class _LinearIdLookupInHotPathTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_LinearIdLookupInHotPathTest)> get _allCases =>
      caseSet<_LinearIdLookupInHotPathTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsMultilineLookupInIterationCallback': (t) =>
              t._reportsMultilineLookupInIterationCallback(),
          'test_reportsLookupInForEachCallback': (t) => t._reportsLookupInForEachCallback(),
          'test_reportsLookupInCollectionFor': (t) => t._reportsLookupInCollectionFor(),
          'test_reportsNestedIndexWhereLookup': (t) => t._reportsNestedIndexWhereLookup(),
          'test_reportsManualLookupLoopInsideLoop': (t) => t._reportsManualLookupLoopInsideLoop(),
          'test_reportsLookupInBuild': (t) => t._reportsLookupInBuild(),
          'test_reportsIndexedManualLookupInsideCallback': (t) =>
              t._reportsIndexedManualLookupInsideCallback(),
          'test_reportsLookupInWidgetBuilderFunction': (t) =>
              t._reportsLookupInWidgetBuilderFunction(),
          'test_allowsLookupInSingleCallMapCallback': (t) =>
              t._allowsLookupInSingleCallMapCallback(),
          'test_reportsLookupOverIdListInNotifier': (t) => t._reportsLookupOverIdListInNotifier(),
          'test_reportsCompoundAndBlockPredicatesInLoop': (t) =>
              t._reportsCompoundAndBlockPredicatesInLoop(),
          'test_reportsLookupInGetters': (t) => t._reportsLookupInGetters(),
          'test_allowsOneOffRepositoryMutation': (t) => t._allowsOneOffRepositoryMutation(),
          'test_allowsOneOffNotifierLookup': (t) => t._allowsOneOffNotifierLookup(),
          'test_allowsSingleManualLookupLoop': (t) => t._allowsSingleManualLookupLoop(),
          'test_allowsLookupInTapCallbackInsideBuild': (t) =>
              t._allowsLookupInTapCallbackInsideBuild(),
          'test_allowsLookupInLoopIterable': (t) => t._allowsLookupInLoopIterable(),
          'test_allowsMapIndex': (t) => t._allowsMapIndex(),
        },
      );

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

final class _NestedLinearLookupByIdTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_NestedLinearLookupByIdTest)> get _allCases =>
      caseSet<_NestedLinearLookupByIdTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsMultilineIndexWhereLookup': (t) => t._reportsMultilineIndexWhereLookup(),
          'test_reportsLookupOverIdListInNotifier': (t) => t._reportsLookupOverIdListInNotifier(),
          'test_allowsLookupByUnrelatedLongerName': (t) => t._allowsLookupByUnrelatedLongerName(),
          'test_reportsNestedLookupInTopLevelFunction': (t) =>
              t._reportsNestedLookupInTopLevelFunction(),
          'test_reportsNestedLookupInCollectionFor': (t) => t._reportsNestedLookupInCollectionFor(),
          'test_allowsLookupNotKeyedByLoopVariable': (t) => t._allowsLookupNotKeyedByLoopVariable(),
          'test_allowsPreIndexedMap': (t) => t._allowsPreIndexedMap(),
        },
      );

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

void _defineSourceScannerRulesPart15Tests() {
  analysisRuleSuite<_SyncSaveAllNoDirtyGuardTest>(
    'SyncSaveAllNoDirtyGuardTest',
    _SyncSaveAllNoDirtyGuardTest.new,
    _SyncSaveAllNoDirtyGuardTest._allCases,
  );
  analysisRuleSuite<_SaveAllFullCollectionAfterSubsetMutationTest>(
    'SaveAllFullCollectionAfterSubsetMutationTest',
    _SaveAllFullCollectionAfterSubsetMutationTest.new,
    _SaveAllFullCollectionAfterSubsetMutationTest._allCases,
  );
  analysisRuleSuite<_CollectionGetterAllocatesEachAccessTest>(
    'CollectionGetterAllocatesEachAccessTest',
    _CollectionGetterAllocatesEachAccessTest.new,
    _CollectionGetterAllocatesEachAccessTest._allCases,
  );
  analysisRuleSuite<_ExpandoDerivedCacheForbiddenTest>(
    'ExpandoDerivedCacheForbiddenTest',
    _ExpandoDerivedCacheForbiddenTest.new,
    _ExpandoDerivedCacheForbiddenTest._allCases,
  );
  analysisRuleSuite<_AdHocIdIndexLookupTest>(
    'AdHocIdIndexLookupTest',
    _AdHocIdIndexLookupTest.new,
    _AdHocIdIndexLookupTest._allCases,
  );
  analysisRuleSuite<_LinearIdLookupInHotPathTest>(
    'LinearIdLookupInHotPathTest',
    _LinearIdLookupInHotPathTest.new,
    _LinearIdLookupInHotPathTest._allCases,
  );
  analysisRuleSuite<_NestedLinearLookupByIdTest>(
    'NestedLinearLookupByIdTest',
    _NestedLinearLookupByIdTest.new,
    _NestedLinearLookupByIdTest._allCases,
  );
}
