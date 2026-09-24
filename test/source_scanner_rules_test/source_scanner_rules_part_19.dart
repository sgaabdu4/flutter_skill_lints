// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class ArchInterfaceContractTest extends _ArchitectureRuleTest {
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

  Future<void> test_allowsResolvedImportedInterface() async {
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

  Future<void> test_reportsSecondClassWithoutInterface() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = r'''
abstract interface class IItemsRepository {}
class ItemsRepository implements IItemsRepository {}
class MissingRepository {}
''';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'abstract interface class', ruleName)]);
  }

  Future<void> test_reportsConcreteInterfaceClassWithoutContract() async {
    final path = '$testPackageLibPath/features/items/data/repositories/items_repository.dart';
    const source = 'interface class PublicRepository {}';
    newFile(path, source);
    await assertDiagnosticsInFile(path, [compatLint(source, 'interface class', ruleName)]);
  }

  Future<void> test_allowsAbstractInterfaceContractDeclaration() async {
    final path = '$testPackageLibPath/features/items/domain/repositories/items_repository.dart';
    newFile(path, 'abstract interface class IItemsRepository {}');
    await assertNoDiagnosticsInFile(path);
  }
}

@reflectiveTest
final class ArchRepositoryGeneratedExtendsTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_repository_generated_extends';
  @override
  String get needle => r'extends _$OrderRepository';
  @override
  String get source => r'''
abstract class _$OrderRepository {}

class OrderRepository extends _$OrderRepository {}
''';

  Future<void> test_allowsRepositoryInterfaceImplementation() async {
    await assertAllows(r'''
abstract interface class IOrderRepository {}

class HiveOrderRepository implements IOrderRepository {}
''');
  }

  Future<void> test_allowsGeneratedNotifierClasses() async {
    await assertAllows(r'''
abstract class _$OrderRepositoryNotifier {}

class OrderRepositoryNotifier extends _$OrderRepositoryNotifier {}
''');
  }

  Future<void> test_allowsRiverpodGeneratedProviderClass() async {
    await assertAllows(r'''
const riverpod = Object();

abstract class _$OrderRepository {}

@riverpod
class OrderRepository extends _$OrderRepository {}
''');
  }
}

@reflectiveTest
final class ArchConcreteDependencyTest extends _ArchitectureRuleTest {
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
}

@reflectiveTest
final class ArchDatasourceTryCatchTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_datasource_try_catch';
  @override
  String get needle => 'catch (_) {';
  @override
  String get path => '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';
  @override
  String get source => r'''
class UserDatasource {
  Future<void> load() async {
    try {
      await Future<void>.value();
    } catch (_) {
      rethrow;
    }
  }
}
''';

  Future<void> test_reportsRethrowOnlyCatchBeforeFinally() async {
    final analyzedSource = _analyzedSource(r'''
class UserDatasource {
  Future<void> load() async {
    try {
      await Future<void>.value();
    } on Exception {
      rethrow;
    } finally {
      await Future<void>.value();
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'on Exception {', ruleName)]);
  }

  /// networking.md:30-43, hive-persistence.md:72 and state-management-lifecycle.md:69-72.
  Future<void> test_allowsSkillDataLayerCatches() async {
    await assertAllows(r'''
class AppException implements Exception {
  const AppException(this.code);
  final String code;
}

class UserDatasource {
  Future<Object?> fetch() async {
    try {
      return await Future<Object?>.value();
    } on Exception {
      throw const AppException('network');
    }
  }

  Map<String, Object?> read() {
    try {
      return <String, Object?>{};
    } on FormatException {
      return <String, Object?>{};
    }
  }

  Future<void> remove(String id) async {
    try {
      await Future<void>.value();
    } catch (_) {
      await restore(id);
      rethrow;
    }
  }

  Future<Object?> readOrNull() async {
    try {
      return await Future<Object?>.value();
    } on FormatException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> restore(String id) async {}
}
''', path: path);
  }
}
