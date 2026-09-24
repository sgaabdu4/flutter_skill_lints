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

  static const _providerPrelude = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {}

abstract interface class IOrderRepository {}

class HiveOrderRepository implements IOrderRepository {}
''';

  Future<void> test_reportsProviderReturningConcreteRepository() async {
    final filePath = '$testPackageLibPath/features/orders/repositories/order_repository.dart';
    const source =
        '''
$_providerPrelude
@Riverpod(keepAlive: true)
HiveOrderRepository orderRepository(Ref ref) => HiveOrderRepository();

@Riverpod(keepAlive: true)
Future<HiveOrderRepository> asyncOrderRepository(Ref ref) async => HiveOrderRepository();
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'HiveOrderRepository orderRepository', ruleName),
      compatLint(source, 'Future<HiveOrderRepository> asyncOrderRepository', ruleName),
    ]);
  }

  Future<void> test_allowsProviderReturningRepositoryInterface() async {
    await assertAllows('''
$_providerPrelude
@Riverpod(keepAlive: true)
IOrderRepository orderRepository(Ref ref) => HiveOrderRepository();

@Riverpod(keepAlive: true)
Future<IOrderRepository> asyncOrderRepository(Ref ref) async => HiveOrderRepository();
''', path: '$testPackageLibPath/features/orders/repositories/order_repository.dart');
  }
}

@reflectiveTest
final class ArchDatasourceTryCatchTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_datasource_try_catch';
  @override
  String get needle => 'try {';
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
}
