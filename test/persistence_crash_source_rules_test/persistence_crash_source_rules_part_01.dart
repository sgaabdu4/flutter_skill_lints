// ignore_for_file: non_constant_identifier_names

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

@reflectiveTest
final class HiveDuplicateFieldIdTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_duplicate_field_id';

  Future<void> test_reportsDuplicateField() async {
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

  Future<void> test_allowsSameIndexesInSeparateHiveTypes() async {
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

@reflectiveTest
final class HiveDuplicateTypeIdTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_duplicate_type_id';

  Future<void> test_reportsDuplicateTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 1)
class CacheEntry {}

@HiveType(typeId: 1)
class UserEntry {}
''', '@HiveType(typeId: 1)\nclass UserEntry');
  }

  Future<void> test_reportsDuplicateWithImportedHiveType() async {
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

  Future<void> test_reportsDuplicatesJoinedThroughGeneratedRegistrar() async {
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

  Future<void> test_reportsDuplicatesJoinedByDirectImports() async {
    _newCrossFileEntries(secondTypeId: 7);
    await assertRuleDiagnostic(r'''
import 'package:test/first_entry.dart';
import 'package:test/second_entry.dart';

void initializeStorage() {}
''', "import 'package:test/second_entry.dart';");
  }

  Future<void> test_leavesDeeperJoinToTheImportedLibrary() async {
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

  Future<void> test_allowsDistinctTypeIdsAcrossFiles() async {
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

@reflectiveTest
final class HiveReservedTypeIdsMissingTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_reserved_type_ids_missing';

  Future<void> test_reportsMissingReservedTypeIds() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1)
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> test_reportsReservationThatOmitsTheHiveTypeId() async {
    await assertRuleDiagnostic(r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {}

@GenerateAdapters([AdapterSpec<User>()], firstTypeId: 1, reservedTypeIds: {5})
void hiveAdapters() {}

class User {}
''', '@GenerateAdapters');
  }

  Future<void> test_reservedTypeIdsPresent_noDiagnostic() async {
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

  Future<void> test_reportsHiveTypeInAnotherFileOfTheRegistrationScope() async {
    _newDocLayout(reservation: '');
    await assertRuleDiagnostic(r'''
import 'package:test/cache_entry.dart';
import 'package:test/hive_adapters.dart';

void initializeStorage() {}
''', "import 'package:test/hive_adapters.dart';");
  }

  Future<void> test_allowsReservedHiveTypeInAnotherFile() async {
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

@reflectiveTest
final class HiveTypeOnFreezedClassTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_type_on_freezed_class';

  Future<void> test_reportsHiveTypeOnFreezedClass() async {
    await assertRuleDiagnostic(r'''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive_ce.dart';

@freezed
@HiveType(typeId: 31)
class RunModel {}
''', '@HiveType(typeId: 31)');
  }

  Future<void> test_allowsHiveTypeOnPlainClass() async {
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

@reflectiveTest
final class HiveAdapterSpecDomainTypeTest extends _HiveRuleTest {
  @override
  String get ruleName => 'hive_adapter_spec_domain_type';

  Future<void> test_reportsDomainEntitySpec() async {
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

  Future<void> test_allowsDataModelSpec() async {
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

@reflectiveTest
final class NotifierHiveAccessTest extends _HiveRuleTest {
  @override
  String get ruleName => 'notifier_hive_access';

  Future<void> test_reportsHiveInNotifier() async {
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

  Future<void> test_allowsRepositoryNotifierAndHiveDatasource() async {
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

@reflectiveTest
final class HiveTestCloseMissingTest extends _PersistenceCrashRuleTest {
  @override
  String get ruleName => 'hive_test_close_missing';

  Future<void> test_reportsMissingCloseInTest() async {
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

  Future<void> test_closePresent_noDiagnostic() async {
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
