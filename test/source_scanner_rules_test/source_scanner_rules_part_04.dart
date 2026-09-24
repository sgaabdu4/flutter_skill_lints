// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RiverpodKeepaliveFamilyTest extends _RiverpodRuleTest {
  Future<void> test_allowsNearbyRequiredFieldsAndMethods() async {
    await assertAllows(r'''
class Riverpod { const Riverpod({bool keepAlive = false}); }
class Ref {}
class Request { Request({required String title}); }
@Riverpod(keepAlive: true)
Object repository(Ref ref) => Object();
@Riverpod(keepAlive: true)
class Visibility {
  bool build() => false;
  void update({required bool visible}) {}
}
''');
  }

  @override
  String get ruleName => 'riverpod_keepalive_family';
  @override
  String get needle => '@Riverpod';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
Object todoProvider({required String todoId}) => Object();
''';

  Future<void> test_reportsRefFamilyParameter() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(keepAlive: true)
Object todoProvider(Ref ref, String todoId) => Object();
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> test_allowsKeepAliveProviderWithoutFamilyArgument() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(keepAlive: true)
Object repositoryProvider(Ref ref) => Object();
''');
  }

  Future<void> test_allowsFamilyProviderAfterKeepAliveProviderBody() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {}

@Riverpod(keepAlive: true)
Object mapProvider(Ref ref) {
  return Object();
}

@riverpod
Object cardProvider(Ref ref, String id) {
  return Object();
}
''');
  }

  Future<void> test_allowsKeepAliveClassProviderWithoutBuildArgument() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class RepositoryNotifier {
  Object build() => Object();
}
''');
  }

  Future<void> test_reportsMultilineKeepAliveFamilyAnnotation() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(
  keepAlive: true,
)
Object todoProvider(Ref ref, String todoId) => Object();
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> test_reportsKeepAliveClassBuildFamily() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class TodoNotifier {
  Object build(String todoId) => Object();
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> test_allowsTickerModeKeepAliveWorkaround() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

/// keepAlive: all deps are keepAlive.
/// Auto-dispose triggers Riverpod 3.2.x TickerMode assertion (rrousselGit/riverpod#4709).
@Riverpod(keepAlive: true)
Object todoProvider(Ref ref, String todoId) => Object();
''');
  }

  Future<void> test_allowsDocumentedWorkaroundNoteOnAnnotationLine() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(keepAlive: true) // keepAlive: Riverpod #4709 workaround
Object todoProvider(Ref ref, String todoId) => Object();
''');
  }

  Future<void> test_reportsFamilyBesideNeighbourWorkaroundNote() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

// keepAlive: Riverpod #4709 workaround
@Riverpod(keepAlive: true)
Object pinnedTodo(Ref ref, String todoId) => Object();

@Riverpod(keepAlive: true)
Object cachedTodo(Ref ref, String todoId) => Object();
''', addIgnorePrefix: addIgnorePrefix);
    final offset = analyzedSource.lastIndexOf(needle);
    await assertDiagnostics(analyzedSource, [
      lint(offset, analyzedSource.indexOf('\n', offset) - offset, name: ruleName),
    ]);
  }
}

abstract class _FreezedRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => freezedSourceRules;
}

@reflectiveTest
final class DartStaticNamespaceTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'dart_static_namespace';
  @override
  String get needle => 'class Tokens';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Tokens {
  Tokens._();
  static const spacing = 8;
}
''';

  Future<void> test_allowsPrivateConstructorSingletonWithInstanceMembers() async {
    await assertAllows(r'''
class SharedCache {
  SharedCache._();
  static final SharedCache instance = SharedCache._();
  final Map<String, String> entries = <String, String>{};
  void put(String key, String value) => entries[key] = value;
}
''');
  }

  Future<void> test_allowsPrivateConstructorWithFactoryAndInstanceMembers() async {
    await assertAllows(r'''
class SharedCache {
  SharedCache._();
  static final SharedCache _instance = SharedCache._();
  factory SharedCache() => _instance;
  final Map<String, String> entries = <String, String>{};
  void put(String key, String value) => entries[key] = value;
}
''');
  }
}

@reflectiveTest
final class FreezedPerClassExplicitToJsonTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_per_class_explicit_to_json';
  @override
  String get needle => '@JsonSerializable';
  @override
  String get source => r'''
class JsonSerializable {
  const JsonSerializable({bool explicitToJson = false});
}

@JsonSerializable(explicitToJson: true)
class UserDto {}
''';
}

@reflectiveTest
final class FreezedToJsonWithFromJsonTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_to_json_with_from_json';
  @override
  String get needle => '@Freezed';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Freezed {
  const Freezed({bool toJson = false});
}

@Freezed(toJson: true)
class User {
  const User._();

  factory User.fromJson(Map<String, dynamic> json) => const User._();
}
''';
}

@reflectiveTest
final class FreezedLegacyWhenMapTest extends _FreezedRuleTest {
  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed { const Freezed(); }
const freezed = Freezed();
''');
    newFile('$testPackageLibPath/union.freezed.dart', r'''
part of 'union.dart';
mixin _$Union { String when() => 'legacy'; }
''');
    super.setUp();
  }

  @override
  String get ruleName => 'freezed_legacy_when_map';
  @override
  String get needle => 'when();';
  @override
  String get path => '$testPackageLibPath/union.dart';
  @override
  String get source => r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'union.freezed.dart';
@freezed
class Union with _$Union {}
String label(Union union) => union.when();
''';

  Future<void> test_allowsUnrelatedMethodNamedWhen() async {
    await assertAllows(r'''
class AsyncValue<T> { T when({required T Function() data}) => data(); }
int label(AsyncValue<int> value) => value.when(data: () => 1);
''');
  }

  Future<void> test_allowsBareMocktailWhenCall() async {
    await assertNoDiagnostics(r'''
dynamic when(Object callback) => _Stub();

class _Stub {
  void thenReturn(Object value) {}
}

class Repository {
  int load() => 1;
}

void main() {
  final repository = Repository();
  when(() => repository.load()).thenReturn(1);
}
''');
  }
}

@reflectiveTest
final class FreezedRequiredValueClassTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_required_value_class';
  @override
  String get needle => 'class User';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  const User({required this.id});

  final String id;
}
''';

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    newPackage('equatable').addFile('lib/equatable.dart', r'''
class Equatable {}
''');
    newPackage('hive_ce').addFile('lib/hive_ce.dart', r'''
class HiveType {
  const HiveType({required this.typeId});
  final int typeId;
}

class HiveField {
  const HiveField(this.index);
  final int index;
}
''');
    super.setUp();
  }

  Future<void> test_allowsNonFreezedHiveTypeDataModel() async {
    final filePath = '$testPackageLibPath/features/cache/data/models/cache_entry.dart';
    newFile(filePath, r'''
import 'package:hive_ce/hive_ce.dart';

@HiveType(typeId: 0)
class CacheEntry {
  CacheEntry({required this.key, required this.value});

  @HiveField(0)
  final String key;

  @HiveField(1)
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsDataModelWithUnresolvedHiveTypeLookalike() async {
    final filePath = '$testPackageLibPath/features/cache/data/models/cache_entry.dart';
    const source = r'''
class HiveType {
  const HiveType({required this.typeId});
  final int typeId;
}

@HiveType(typeId: 0)
class CacheEntry {
  CacheEntry({required this.key});

  final String key;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'class HiveType', ruleName, lineStart: true),
      compatLint(source, 'class CacheEntry', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_reportsEquatableDataModel() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  UserModel(this.id);

  final String id;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'class UserModel extends Equatable', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsFreezedDomainEntity() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile('$testPackageLibPath/features/users/domain/user.freezed.dart', r'''
part of 'user.dart';

mixin _$User {}

final class _User implements User {
  const _User({
    required this.id,
  });

  final String id;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required String id,
  }) = _User;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsFreezedDataModel() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    newFile('$testPackageLibPath/features/users/data/models/user_model.freezed.dart', r'''
part of 'user_model.dart';

mixin _$UserModel {}

final class _UserModel implements UserModel {
  const _UserModel({
    required this.id,
  });

  final String id;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';

@freezed
sealed class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
  }) = _UserModel;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainInterfaceContracts() async {
    final filePath = '$testPackageLibPath/features/users/domain/user_repository.dart';
    newFile(filePath, r'''
abstract interface class IUserRepository {
  Future<void> save();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNonModelDataClassOutsideModelsFolder() async {
    final filePath = '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
    newFile(filePath, r'''
class UserDatasource {
  Future<void> load() async {}
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class UseFreezedInsteadOfImmutableTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'use_freezed_instead_of_immutable';
  @override
  String get needle => '@immutable';
  @override
  String get path => '$testPackageLibPath/features/users/presentation/user_state.dart';
  @override
  String get source => r'''
class Immutable {
  const Immutable();
}

const immutable = Immutable();

@immutable
class UserState {
  const UserState({required this.id});
  final String id;
}
''';

  Future<void> test_allowsImmutableTextInComments() async {
    await assertNoDiagnostics(r'''
// Use Freezed for immutable state classes.
final message = 'immutable value';
''');
  }

  Future<void> test_allowsImmutableInTests() async {
    final filePath = '$testPackageRootPath/test/features/users/user_state_test.dart';
    newFile(filePath, r'''
class Immutable {
  const Immutable();
}

const immutable = Immutable();

@immutable
class TestUserState {
  const TestUserState();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class FreezedOneClassPerFileTest extends _FreezedRuleTest {
  @override
  String get ruleName => 'freezed_one_class_per_file';
  @override
  String get needle => 'class UserFilters';
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();

mixin _$User {}

@freezed
sealed class User with _$User {
  const factory User({required String id}) = _User;
}

final class _User implements User {
  const _User({required this.id});
  final String id;
}

mixin _$UserFilters {}

@freezed
sealed class UserFilters with _$UserFilters {
  const factory UserFilters({required String query}) = _UserFilters;
}

final class _UserFilters implements UserFilters {
  const _UserFilters({required this.query});
  final String query;
}
''';

  Future<void> test_allowsSingleFreezedClassPerFile() async {
    await assertAllows(r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();

mixin _$User {}

@freezed
sealed class User with _$User {
  const factory User({required String id}) = _User;
}

final class _User implements User {
  const _User({required this.id});
  final String id;
}
''', path: '$testPackageLibPath/features/users/domain/user.dart');
  }

  Future<void> test_allowsMultipleNonFreezedClasses() async {
    await assertAllows(r'''
class User {
  const User();
}

class UserFilters {
  const UserFilters();
}
''', path: '$testPackageLibPath/features/users/presentation/user_helpers.dart');
  }
}

abstract class _ArchitectureRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => architectureSourceRules;
}

@reflectiveTest
final class ArchDomainImportTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_domain_import';
  @override
  String get needle => 'import';
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  bool get addIgnorePrefix => false;

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
    super.setUp();
  }

  @override
  String get source => r'''
import 'package:flutter/widgets.dart';

class User {
  Widget? widget;
}
''';

  Future<void> test_allowsFreezedAnnotationDomainEntity() async {
    final filePath = '$testPackageLibPath/features/items/domain/item.dart';
    newFile('$testPackageLibPath/features/items/domain/item.freezed.dart', r'''
part of 'item.dart';

mixin _$Item {}

final class _Item implements Item {
  const _Item({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';

@freezed
sealed class Item with _$Item {
  const factory Item({
    required String id,
    required String name,
  }) = _Item;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainToDomainPackageImport() async {
    final filePath = '$testPackageLibPath/features/items/domain/item.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/features/shared/domain/enums.dart';

final class Item {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsMirroredDomainTestFlutterImport() async {
    final filePath =
        '$testPackageRootPath/test/features/auth/domain/values/email_address_test.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist
import 'package:flutter_test/flutter_test.dart';

void main() {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsCoreConstantsImportFromDomain() async {
    final filePath = '$testPackageLibPath/features/auth/domain/auth_error.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/core/constants/auth_strings.dart';

final class AuthError {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        source,
        "import 'package:test_package/core/constants/auth_strings.dart';",
        ruleName,
      ),
    ]);
  }

  Future<void> test_reportsDartIoImportFromDomain() async {
    final filePath = '$testPackageLibPath/features/files/domain/entities/stored_file.dart';
    const source = r'''
// ignore_for_file: unused_import
import 'dart:io';

final class StoredFile {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, "import 'dart:io';", ruleName)]);
  }

  Future<void> test_reportsRelativeCoreExtensionImportFromDomain() async {
    newFile('$testPackageLibPath/core/extensions/num_extensions.dart', r'''
extension NumExtensions on num {
  num get doubled => this * 2;
}
''');
    final filePath = '$testPackageLibPath/features/runs/domain/entities/run.dart';
    const source = r'''
// ignore_for_file: unused_import
import '../../../../core/extensions/num_extensions.dart';

final class Run {}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, "import '../../../../core/extensions/num_extensions.dart';", ruleName),
    ]);
  }

  Future<void> test_allowsRelativeDomainAndPureDartImports() async {
    newFile('$testPackageLibPath/features/runs/domain/values/run_id.dart', r'''
final class RunId {}
''');
    final filePath = '$testPackageLibPath/features/runs/domain/entities/run.dart';
    newFile(filePath, r'''
// ignore_for_file: unused_import
import 'dart:math' as math;

import '../values/run_id.dart';

final class Run {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class ArchStorageSdkImportTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_storage_sdk_import';
  @override
  String get needle => "import 'dart:io';";
  @override
  String get path => '$testPackageLibPath/features/notes/presentation/notifiers/note_notifier.dart';
  @override
  String get source => r'''
import 'dart:io';

final class NoteNotifier {}
''';

  Future<void> test_reportsStorageSdkImportsInScreensRepositoriesAndServices() async {
    const imports = r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
''';
    for (final filePath in [
      '$testPackageLibPath/features/notes/presentation/screens/notes_screen.dart',
      '$testPackageLibPath/features/notes/repositories/note_repository.dart',
      '$testPackageLibPath/core/services/note_sync_service.dart',
    ]) {
      newFile(filePath, imports);
      await assertDiagnosticsInFile(filePath, [
        compatLint(imports, "import 'package:hive_ce_flutter/", ruleName),
        compatLint(imports, "import 'package:shared_preferences/", ruleName),
      ]);
    }
  }

  Future<void> test_allowsStorageSdkImportsInLocalDatasourcesAndMixins() async {
    await assertAllows(r'''
// ignore_for_file: uri_does_not_exist
import 'dart:io';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
''', path: '$testPackageLibPath/features/notes/data/datasources/note_local_datasource.dart');
    await assertAllows(r'''
import 'dart:io';
''', path: '$testPackageLibPath/core/services/appwrite_pagination_mixin.dart');
  }
}

@reflectiveTest
final class ArchDomainSerializationTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_domain_serialization';
  @override
  String get needle => 'Map<String, dynamic> toJson';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => 'class User { Map<String, dynamic> toJson() => {}; }';
}
