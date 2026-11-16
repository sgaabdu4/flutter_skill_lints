part of '../persistence_crash_source_rules_test.dart';

abstract class _HiveRuleTest extends _PersistenceCrashRuleTest {
  @override
  void setUp() {
    newPackage('hive_ce').addFile('lib/hive_ce.dart', r'''
class HiveType {
  const HiveType({required this.typeId});
  final int typeId;
}

class HiveField {
  const HiveField(this.index);
  final int index;
}

class AdapterSpec<T> {
  const AdapterSpec();
}

class GenerateAdapters {
  const GenerateAdapters(this.specs, {this.firstTypeId = 0, this.reservedTypeIds = const {}});
  final List<AdapterSpec<Object?>> specs;
  final int firstTypeId;
  final Set<int> reservedTypeIds;
}

abstract class Box<E> {
  E? get(Object key);
}

abstract class HiveInterface {
  Future<Box<E>> openBox<E>(String name);
}

HiveInterface get Hive => throw UnimplementedError();
''');
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Notifier<T> {
  T build();
  late T state;
}
''');
    super.setUp();
  }

  void newLibFile(String name, String content) => newFile('$testPackageLibPath/$name', content);
}

final class _HiveDuplicateFieldIdTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveDuplicateFieldIdTest)> get _allCases =>
      caseSet<_HiveDuplicateFieldIdTest>(
        parent: const {},
        own: {
          'test_reportsDuplicateField': (t) => t._reportsDuplicateField(),
          'test_allowsSameIndexesInSeparateHiveTypes': (t) =>
              t._allowsSameIndexesInSeparateHiveTypes(),
        },
      );

  @override
  String get ruleName => 'hive_duplicate_field_id';

  Future<void> _reportsDuplicateField() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(0)
  final String value = '';
}
''', '@HiveField(0)\n  final String value');
  }

  Future<void> _allowsSameIndexesInSeparateHiveTypes() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class FirstEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(1)
  final String value = '';
}

@HiveType(typeId: 2)
class SecondEntry {
  @HiveField(0)
  final String key = '';

  @HiveField(1)
  final String value = '';
}
''');
  }
}

final class _HiveDuplicateTypeIdTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveDuplicateTypeIdTest)> get _allCases =>
      caseSet<_HiveDuplicateTypeIdTest>(
        parent: const {},
        own: {
          'test_reportsDuplicateTypeId': (t) => t._reportsDuplicateTypeId(),
          'test_reportsDuplicateWithImportedHiveType': (t) =>
              t._reportsDuplicateWithImportedHiveType(),
          'test_reportsDuplicatesJoinedThroughGeneratedRegistrar': (t) =>
              t._reportsDuplicatesJoinedThroughGeneratedRegistrar(),
          'test_reportsDuplicatesJoinedByDirectImports': (t) =>
              t._reportsDuplicatesJoinedByDirectImports(),
          'test_leavesDeeperJoinToTheImportedLibrary': (t) =>
              t._leavesDeeperJoinToTheImportedLibrary(),
          'test_allowsDistinctTypeIdsAcrossFiles': (t) => t._allowsDistinctTypeIdsAcrossFiles(),
        },
      );

  @override
  String get ruleName => 'hive_duplicate_type_id';

  Future<void> _reportsDuplicateTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {}

@HiveType(typeId: 1)
class UserEntry {}
''', '@HiveType(typeId: 1)\nclass UserEntry');
  }

  Future<void> _reportsDuplicateWithImportedHiveType() async {
    newLibFile('first_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 7)
class FirstEntry {}
''');
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/first_entry.dart';

@HiveType(typeId: 7)
class SecondEntry {}
''', '@HiveType(typeId: 7)');
  }

  Future<void> _reportsDuplicatesJoinedThroughGeneratedRegistrar() async {
    _newCrossFileEntries(secondTypeId: 7);
    newLibFile('hive_registrar.g.dart', r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';
''');
    await assertRuleDiagnostic(r'''
import 'package:test/hive_registrar.g.dart';

void initializeStorage() {}
''', "import 'package:test/hive_registrar.g.dart';");
  }

  Future<void> _reportsDuplicatesJoinedByDirectImports() async {
    _newCrossFileEntries(secondTypeId: 7);
    await assertRuleDiagnostic(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''', "import 'package:test/second_entry.dart';");
  }

  Future<void> _leavesDeeperJoinToTheImportedLibrary() async {
    _newCrossFileEntries(secondTypeId: 7);
    newLibFile('entries.dart', r'''
export 'package:test/first_entry.dart';
export 'package:test/second_entry.dart';
''');
    await assertRuleNoDiagnostics(r'''
import 'package:test/entries.dart';

void initializeStorage() {}
''');
  }

  Future<void> _allowsDistinctTypeIdsAcrossFiles() async {
    _newCrossFileEntries(secondTypeId: 8);
    await assertRuleNoDiagnostics(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''');
  }

  void _newCrossFileEntries({required int secondTypeId}) {
    newLibFile('first_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 7)
class FirstEntry {}
''');
    newLibFile('second_entry.dart', '''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: $secondTypeId)
class SecondEntry {}
''');
  }
}

final class _HiveReservedTypeIdsMissingTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveReservedTypeIdsMissingTest)> get _allCases =>
      caseSet<_HiveReservedTypeIdsMissingTest>(
        parent: const {},
        own: {
          'test_reportsMissingReservedTypeIds': (t) => t._reportsMissingReservedTypeIds(),
          'test_reportsReservationThatOmitsTheHiveTypeId': (t) =>
              t._reportsReservationThatOmitsTheHiveTypeId(),
          'test_reservedTypeIdsPresent_noDiagnostic': (t) =>
              t._reservedTypeIdsPresentNoDiagnostic(),
          'test_reportsHiveTypeInAnotherFileOfTheRegistrationScope': (t) =>
              t._reportsHiveTypeInAnotherFileOfTheRegistrationScope(),
          'test_allowsReservedHiveTypeInAnotherFile': (t) =>
              t._allowsReservedHiveTypeInAnotherFile(),
        },
      );

  @override
  String get ruleName => 'hive_reserved_type_ids_missing';

  Future<void> _reportsMissingReservedTypeIds() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1)
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> _reportsReservationThatOmitsTheHiveTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1, reservedTypeIds: {5})
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> _reservedTypeIdsPresentNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters(
  [AdapterSpec<User>()],
  firstTypeId: 1,
  reservedTypeIds: {0},
)
void hiveAdapters() {}

class User {}
''');
  }

  Future<void> _reportsHiveTypeInAnotherFileOfTheRegistrationScope() async {
    _newDocLayout(reservation: '');
    await assertRuleDiagnostic(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''', "import 'package:test/hive_adapters.dart';");
  }

  Future<void> _allowsReservedHiveTypeInAnotherFile() async {
    _newDocLayout(reservation: ', reservedTypeIds: {0}');
    await assertRuleNoDiagnostics(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''');
  }

  void _newDocLayout({required String reservation}) {
    newLibFile('cache_entry.dart', r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}
''');
    newLibFile('hive_adapters.dart', '''
import 'package:hive_ce/hive_ce.dart';

class UserModel {}

@GenerateAdapters([AdapterSpec<UserModel>()], firstTypeId: 1$reservation)
void hiveAdapters() {}
''');
  }
}

final class _HiveTypeOnFreezedClassTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveTypeOnFreezedClassTest)> get _allCases =>
      caseSet<_HiveTypeOnFreezedClassTest>(
        parent: const {},
        own: {
          'test_reportsHiveTypeOnFreezedClass': (t) => t._reportsHiveTypeOnFreezedClass(),
          'test_allowsHiveTypeOnPlainClass': (t) => t._allowsHiveTypeOnPlainClass(),
        },
      );

  @override
  String get ruleName => 'hive_type_on_freezed_class';

  Future<void> _reportsHiveTypeOnFreezedClass() async {
    await assertRuleDiagnostic(r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

@freezed
@HiveType(typeId: 31)
class RunModel {}
''', '@HiveType(typeId: 31)');
  }

  Future<void> _allowsHiveTypeOnPlainClass() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {
  CacheEntry({required this.key});

  @HiveField(0)
  final String key;
}
''');
  }
}

final class _HiveAdapterSpecDomainTypeTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_HiveAdapterSpecDomainTypeTest)> get _allCases =>
      caseSet<_HiveAdapterSpecDomainTypeTest>(
        parent: const {},
        own: {
          'test_reportsDomainEntitySpec': (t) => t._reportsDomainEntitySpec(),
          'test_allowsDataModelSpec': (t) => t._allowsDataModelSpec(),
        },
      );

  @override
  String get ruleName => 'hive_adapter_spec_domain_type';

  Future<void> _reportsDomainEntitySpec() async {
    newLibFile('features/run/domain/entities/run.dart', 'class Run {}\n');
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/features/run/domain/entities/run.dart';

@GenerateAdapters([
  AdapterSpec<Run>(),
], firstTypeId: 1)
void hiveAdapters() {}
''', 'AdapterSpec<Run>()');
  }

  Future<void> _allowsDataModelSpec() async {
    newLibFile('features/run/data/models/run_model.dart', 'class RunModel {}\n');
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:test/features/run/data/models/run_model.dart';

@GenerateAdapters([
  AdapterSpec<RunModel>(),
], firstTypeId: 1)
void hiveAdapters() {}
''');
  }
}

final class _NotifierHiveAccessTest extends _HiveRuleTest {
  static Map<String, Future<void> Function(_NotifierHiveAccessTest)> get _allCases =>
      caseSet<_NotifierHiveAccessTest>(
        parent: const {},
        own: {
          'test_reportsHiveInNotifier': (t) => t._reportsHiveInNotifier(),
          'test_allowsRepositoryNotifierAndHiveDatasource': (t) =>
              t._allowsRepositoryNotifierAndHiveDatasource(),
        },
      );

  @override
  String get ruleName => 'notifier_hive_access';

  Future<void> _reportsHiveInNotifier() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod/riverpod.dart';

class CountNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    final box = await Hive.openBox<int>('counts');
    state = box.get('n') ?? 0;
  }
}
''', "Hive.openBox<int>('counts');");
  }

  Future<void> _allowsRepositoryNotifierAndHiveDatasource() async {
    await assertRuleNoDiagnostics(r'''
import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod/riverpod.dart';

abstract interface class ICountRepository {
  Future<int> load();
}

class HiveCountDatasource implements ICountRepository {
  @override
  Future<int> load() async {
    final box = await Hive.openBox<int>('counts');
    return box.get('n') ?? 0;
  }
}

class CountNotifier extends Notifier<int> {
  CountNotifier(this._repository);

  final ICountRepository _repository;

  @override
  int build() => 0;

  Future<void> load() async {
    state = await _repository.load();
  }
}
''');
  }
}

final class _HiveTestCloseMissingTest extends _PersistenceCrashRuleTest {
  static Map<String, Future<void> Function(_HiveTestCloseMissingTest)> get _allCases =>
      caseSet<_HiveTestCloseMissingTest>(
        parent: const {},
        own: {
          'test_reportsMissingCloseInTest': (t) => t._reportsMissingCloseInTest(),
          'test_closePresent_noDiagnostic': (t) => t._closePresentNoDiagnostic(),
        },
      );

  @override
  String get ruleName => 'hive_test_close_missing';

  Future<void> _reportsMissingCloseInTest() async {
    await assertRuleDiagnostic(
      r'''
class Hive {
  static void init(String path) {}
}

void setUpStorage() {
  Hive.init('tmp');
}
''',
      'Hive.init',
      path: '$testPackageRootPath/test/hive_helper_test.dart',
    );
  }

  Future<void> _closePresentNoDiagnostic() async {
    await assertRuleNoDiagnostics(r'''
class Hive {
  static void init(String path) {}
  static Future<void> close() async {}
}

void setUpStorage() {
  Hive.init('tmp');
}

Future<void> tearDownStorage() async {
  await Hive.close();
}
''', path: '$testPackageRootPath/test/hive_helper_test.dart');
  }
}

void _definePersistenceCrashSourceRulesPart01Tests() {
  analysisRuleSuite<_HiveDuplicateFieldIdTest>(
    'HiveDuplicateFieldIdTest',
    _HiveDuplicateFieldIdTest.new,
    _HiveDuplicateFieldIdTest._allCases,
  );
  analysisRuleSuite<_HiveDuplicateTypeIdTest>(
    'HiveDuplicateTypeIdTest',
    _HiveDuplicateTypeIdTest.new,
    _HiveDuplicateTypeIdTest._allCases,
  );
  analysisRuleSuite<_HiveReservedTypeIdsMissingTest>(
    'HiveReservedTypeIdsMissingTest',
    _HiveReservedTypeIdsMissingTest.new,
    _HiveReservedTypeIdsMissingTest._allCases,
  );
  analysisRuleSuite<_HiveTestCloseMissingTest>(
    'HiveTestCloseMissingTest',
    _HiveTestCloseMissingTest.new,
    _HiveTestCloseMissingTest._allCases,
  );
  analysisRuleSuite<_HiveTypeOnFreezedClassTest>(
    'HiveTypeOnFreezedClassTest',
    _HiveTypeOnFreezedClassTest.new,
    _HiveTypeOnFreezedClassTest._allCases,
  );
  analysisRuleSuite<_HiveAdapterSpecDomainTypeTest>(
    'HiveAdapterSpecDomainTypeTest',
    _HiveAdapterSpecDomainTypeTest.new,
    _HiveAdapterSpecDomainTypeTest._allCases,
  );
  analysisRuleSuite<_NotifierHiveAccessTest>(
    'NotifierHiveAccessTest',
    _NotifierHiveAccessTest.new,
    _NotifierHiveAccessTest._allCases,
  );
}
