// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RiverpodKeepaliveFamilyTest extends _RiverpodRuleTest {
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
  String get ruleName => 'freezed_legacy_when_map';
  @override
  String get needle => 'when();';
  @override
  String get source => r'''
class User {
  Object label(Union union) => union.when();
}

class Union {}
''';

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
    super.setUp();
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
