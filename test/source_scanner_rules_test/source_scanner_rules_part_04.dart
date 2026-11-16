part of '../source_scanner_rules_test.dart';

final class RiverpodKeepaliveFamilyTest extends _RiverpodRuleTest {
  Future<void> _allowsNearbyRequiredFieldsAndMethods() async {
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

  Future<void> _reportsRefFamilyParameter() async {
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

  Future<void> _allowsKeepAliveProviderWithoutFamilyArgument() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(keepAlive: true)
Object repositoryProvider(Ref ref) => Object();
''');
  }

  Future<void> _allowsFamilyProviderAfterKeepAliveProviderBody() async {
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

  Future<void> _allowsKeepAliveClassProviderWithoutBuildArgument() async {
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

  Future<void> _reportsMultilineKeepAliveFamilyAnnotation() async {
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

  Future<void> _reportsKeepAliveClassBuildFamily() async {
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

  Future<void> _allowsTickerModeKeepAliveWorkaround() async {
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

  Future<void> _allowsDocumentedWorkaroundNoteOnAnnotationLine() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

@Riverpod(keepAlive: true) // keepAlive: Riverpod #4709 workaround
Object todoProvider(Ref ref, String todoId) => Object();
''');
  }

  Future<void> _reportsFamilyBesideNeighbourWorkaroundNote() async {
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

  Future<void> _allowsPrivateConstructorSingletonWithInstanceMembers() async {
    await assertAllows(r'''
class SharedCache {
  SharedCache._();
  static final SharedCache instance = SharedCache._();
  final Map<String, String> entries = <String, String>{};
  void put(String key, String value) => entries[key] = value;
}
''');
  }

  Future<void> _allowsPrivateConstructorWithFactoryAndInstanceMembers() async {
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

final class RecordUseOutsideFfiTest extends _FreezedRuleTest {
  @override
  void setUp() {
    newPackage('meta').addFile('lib/meta.dart', r'''
class RecordUse {
  const RecordUse();
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'record_use_outside_ffi';
  @override
  String get needle => '@RecordUse()';
  @override
  String get path => '$testPackageLibPath/core/utils/greeting.dart';
  @override
  String get source => r'''
import 'package:meta/meta.dart';

@RecordUse()
String greeting(String name) => 'Hello $name';
''';

  Future<void> _allowsFfiBinding() async {
    await assertAllows(r'''
import 'dart:ffi';
import 'package:meta/meta.dart';

abstract final class SquareBindings {
  @RecordUse()
  static int square(int value) => value * value;
}
''', path: '$testPackageLibPath/src/square_bindings.dart');
  }

  Future<void> _allowsNonMetaRecordUse() async {
    await assertAllows(r'''
class RecordUse {
  const RecordUse();
}

@RecordUse()
String greeting(String name) => 'Hello $name';
''', path: path);
  }
}

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
extension UnionPatterns on Union {
  String map() => 'legacy';
  String? whenOrNull() => null;
  String? mapOrNull() => null;
  String maybeWhen() => 'legacy';
}
''');
    super.setUp();
  }

  Future<void> _reportsEveryGeneratedPatternHelper() async {
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'union.freezed.dart';
@freezed
class Union with _$Union {
  String get label => map();
}
String mapped(Union union) => union.map();
String? whenNull(Union union) => union.whenOrNull();
String? mapNull(Union union) => union.mapOrNull();
String maybe(Union union) => union.maybeWhen();
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [
      compatLint(source, 'map();\n}', ruleName),
      compatLint(source, 'map();\nString?', ruleName),
      compatLint(source, 'whenOrNull();', ruleName),
      compatLint(source, 'mapOrNull();', ruleName),
      compatLint(source, 'maybeWhen();', ruleName),
    ]);
  }

  Future<void> _reportsHelpersOnConfiguredFreezedAnnotation() async {
    newFile('$testPackageLibPath/keyed.freezed.dart', r'''
part of 'keyed.dart';
mixin _$Keyed { String when() => 'legacy'; }
''');
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'keyed.freezed.dart';
@Freezed()
sealed class Keyed with _$Keyed {}
String label(Keyed keyed) => keyed.when();
''';
    final keyedPath = '$testPackageLibPath/keyed.dart';
    newFile(keyedPath, source);
    await assertDiagnosticsInFile(keyedPath, [compatLint(source, 'when();', ruleName)]);
  }

  Future<void> _allowsSameNamedHelpersOnNonFreezedTypes() async {
    await assertAllows(r'''
class AsyncValue<T> {
  R map<R>(R Function() data) => data();
  R? whenOrNull<R>({R Function()? data}) => data?.call();
  R? mapOrNull<R>({R Function()? data}) => data?.call();
}
int? label(AsyncValue<int> value, List<int> items) {
  items.map((item) => item + 1);
  value.map(() => 1);
  value.mapOrNull(data: () => 1);
  return value.whenOrNull(data: () => 1);
}
''');
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

  Future<void> _allowsUnrelatedMethodNamedWhen() async {
    await assertAllows(r'''
class AsyncValue<T> { T when({required T Function() data}) => data(); }
int label(AsyncValue<int> value) => value.when(data: () => 1);
''');
  }

  Future<void> _allowsBareMocktailWhenCall() async {
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

  Future<void> _allowsNonFreezedHiveTypeDataModel() async {
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

  Future<void> _allowsStaticCodecNamespaceInDataModels() async {
    final filePath = '$testPackageLibPath/features/todos/data/models/todo_list_codec.dart';
    newFile(filePath, r'''
abstract final class TodoListCodec {
  static List<String> decode(Object? payload) => switch (payload) {
    final List<Object?> items => [for (final item in items) '$item'],
    _ => const <String>[],
  };
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsDataModelWithUnresolvedHiveTypeLookalike() async {
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

  Future<void> _reportsEquatableDataModel() async {
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

  Future<void> _allowsFreezedDomainEntity() async {
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

  Future<void> _allowsFreezedDataModel() async {
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

  Future<void> _allowsDomainInterfaceContracts() async {
    final filePath = '$testPackageLibPath/features/users/domain/user_repository.dart';
    newFile(filePath, r'''
abstract interface class IUserRepository {
  Future<void> save();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _allowsNonModelDataClassOutsideModelsFolder() async {
    final filePath = '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
    newFile(filePath, r'''
class UserDatasource {
  Future<void> load() async {}
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

final class UseFreezedInsteadOfImmutableTest extends _FreezedRuleTest {
  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed { const Freezed(); }
const freezed = Freezed();
const unfreezed = Freezed();
''');
    super.setUp();
  }

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

  Future<void> _reportsUnfreezedStateClass() async {
    final filePath = '$testPackageLibPath/features/users/presentation/form_state.dart';
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@unfreezed
sealed class FormState {}
''';
    newFile(filePath, source);
    await assertDiagnosticsInFile(filePath, [compatLint(source, '@unfreezed', ruleName)]);
  }

  Future<void> _allowsSameNamedNonFreezedUnfreezedAnnotation() async {
    await assertAllows(r'''
class Marker { const Marker(); }
const unfreezed = Marker();

@unfreezed
class Draft {}
''', path: '$testPackageLibPath/features/users/presentation/draft.dart');
  }

  Future<void> _allowsImmutableTextInComments() async {
    await assertNoDiagnostics(r'''
// Use Freezed for immutable state classes.
final message = 'immutable value';
''');
  }

  Future<void> _allowsImmutableInTests() async {
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

  Future<void> _allowsSingleFreezedClassPerFile() async {
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

  Future<void> _allowsMultipleNonFreezedClasses() async {
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

void _defineSourceScannerRulesPart04Tests() {
  analysisRuleSuite<RiverpodKeepaliveFamilyTest>(
    'RiverpodKeepaliveFamilyTest',
    RiverpodKeepaliveFamilyTest.new,
    {
      'test_allowsNearbyRequiredFieldsAndMethods': (t) => t._allowsNearbyRequiredFieldsAndMethods(),
      'test_reportsRefFamilyParameter': (t) => t._reportsRefFamilyParameter(),
      'test_allowsKeepAliveProviderWithoutFamilyArgument': (t) =>
          t._allowsKeepAliveProviderWithoutFamilyArgument(),
      'test_allowsFamilyProviderAfterKeepAliveProviderBody': (t) =>
          t._allowsFamilyProviderAfterKeepAliveProviderBody(),
      'test_allowsKeepAliveClassProviderWithoutBuildArgument': (t) =>
          t._allowsKeepAliveClassProviderWithoutBuildArgument(),
      'test_reportsMultilineKeepAliveFamilyAnnotation': (t) =>
          t._reportsMultilineKeepAliveFamilyAnnotation(),
      'test_reportsKeepAliveClassBuildFamily': (t) => t._reportsKeepAliveClassBuildFamily(),
      'test_allowsTickerModeKeepAliveWorkaround': (t) => t._allowsTickerModeKeepAliveWorkaround(),
      'test_allowsDocumentedWorkaroundNoteOnAnnotationLine': (t) =>
          t._allowsDocumentedWorkaroundNoteOnAnnotationLine(),
      'test_reportsFamilyBesideNeighbourWorkaroundNote': (t) =>
          t._reportsFamilyBesideNeighbourWorkaroundNote(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<DartStaticNamespaceTest>(
    'DartStaticNamespaceTest',
    DartStaticNamespaceTest.new,
    {
      'test_allowsPrivateConstructorSingletonWithInstanceMembers': (t) =>
          t._allowsPrivateConstructorSingletonWithInstanceMembers(),
      'test_allowsPrivateConstructorWithFactoryAndInstanceMembers': (t) =>
          t._allowsPrivateConstructorWithFactoryAndInstanceMembers(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<RecordUseOutsideFfiTest>(
    'RecordUseOutsideFfiTest',
    RecordUseOutsideFfiTest.new,
    {
      'test_allowsFfiBinding': (t) => t._allowsFfiBinding(),
      'test_allowsNonMetaRecordUse': (t) => t._allowsNonMetaRecordUse(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<FreezedPerClassExplicitToJsonTest>(
    'FreezedPerClassExplicitToJsonTest',
    FreezedPerClassExplicitToJsonTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<FreezedToJsonWithFromJsonTest>(
    'FreezedToJsonWithFromJsonTest',
    FreezedToJsonWithFromJsonTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<FreezedLegacyWhenMapTest>(
    'FreezedLegacyWhenMapTest',
    FreezedLegacyWhenMapTest.new,
    {
      'test_reportsEveryGeneratedPatternHelper': (t) => t._reportsEveryGeneratedPatternHelper(),
      'test_reportsHelpersOnConfiguredFreezedAnnotation': (t) =>
          t._reportsHelpersOnConfiguredFreezedAnnotation(),
      'test_allowsSameNamedHelpersOnNonFreezedTypes': (t) =>
          t._allowsSameNamedHelpersOnNonFreezedTypes(),
      'test_allowsUnrelatedMethodNamedWhen': (t) => t._allowsUnrelatedMethodNamedWhen(),
      'test_allowsBareMocktailWhenCall': (t) => t._allowsBareMocktailWhenCall(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<FreezedRequiredValueClassTest>(
    'FreezedRequiredValueClassTest',
    FreezedRequiredValueClassTest.new,
    {
      'test_allowsNonFreezedHiveTypeDataModel': (t) => t._allowsNonFreezedHiveTypeDataModel(),
      'test_allowsStaticCodecNamespaceInDataModels': (t) =>
          t._allowsStaticCodecNamespaceInDataModels(),
      'test_reportsDataModelWithUnresolvedHiveTypeLookalike': (t) =>
          t._reportsDataModelWithUnresolvedHiveTypeLookalike(),
      'test_reportsEquatableDataModel': (t) => t._reportsEquatableDataModel(),
      'test_allowsFreezedDomainEntity': (t) => t._allowsFreezedDomainEntity(),
      'test_allowsFreezedDataModel': (t) => t._allowsFreezedDataModel(),
      'test_allowsDomainInterfaceContracts': (t) => t._allowsDomainInterfaceContracts(),
      'test_allowsNonModelDataClassOutsideModelsFolder': (t) =>
          t._allowsNonModelDataClassOutsideModelsFolder(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<UseFreezedInsteadOfImmutableTest>(
    'UseFreezedInsteadOfImmutableTest',
    UseFreezedInsteadOfImmutableTest.new,
    {
      'test_reportsUnfreezedStateClass': (t) => t._reportsUnfreezedStateClass(),
      'test_allowsSameNamedNonFreezedUnfreezedAnnotation': (t) =>
          t._allowsSameNamedNonFreezedUnfreezedAnnotation(),
      'test_allowsImmutableTextInComments': (t) => t._allowsImmutableTextInComments(),
      'test_allowsImmutableInTests': (t) => t._allowsImmutableInTests(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<FreezedOneClassPerFileTest>(
    'FreezedOneClassPerFileTest',
    FreezedOneClassPerFileTest.new,
    {
      'test_allowsSingleFreezedClassPerFile': (t) => t._allowsSingleFreezedClassPerFile(),
      'test_allowsMultipleNonFreezedClasses': (t) => t._allowsMultipleNonFreezedClasses(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
