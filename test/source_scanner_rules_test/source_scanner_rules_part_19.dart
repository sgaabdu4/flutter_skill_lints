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

@reflectiveTest
final class RiverpodWidgetRefOutsideWidgetTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

class WidgetRef {
  void read(Object provider) {}
}

abstract class ConsumerWidget extends Widget {
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class ConsumerStatefulWidget extends StatefulWidget {}

abstract class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {
  WidgetRef get ref => WidgetRef();
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_widget_ref_outside_widget';
  @override
  String get needle => 'WidgetRef ref;';
  @override
  bool get addIgnorePrefix => false;
  @override
  String get source => r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartSyncService {
  CartSyncService(this.ref);

  final WidgetRef ref;

  void sync() => ref.read(Object());
}
''';

  Future<void> test_reportsServiceMethodParameter() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutService {
  void submit(WidgetRef ref) => ref.read(Object());
}
''';
    await assertDiagnostics(source, [compatLint(source, 'WidgetRef ref)', ruleName)]);
  }

  Future<void> test_allowsWidgetsStatesAndMixinsOnState() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => Widget();
}

class CartPage extends ConsumerStatefulWidget {}

class _CartPageState extends ConsumerState<CartPage> {
  void refresh(WidgetRef other) => other.read(Object());
}

mixin CartActions<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  void clear(WidgetRef other) => other.read(Object());
}

extension CartRef on WidgetRef {
  void clearCart() => read(Object());
}
''', addIgnorePrefix: false);
  }

  Future<void> test_severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

@reflectiveTest
final class RiverpodGeneratedProviderAliasTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _riverpodProviderStub);
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_generated_provider_alias';
  @override
  String get needle => 'cartAliasProvider = cartProvider;';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final cartProvider = CartProvider._();

final cartAliasProvider = cartProvider;
''';

  Future<void> test_reportsGetterStaticAndFamilyAliases() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final class ItemFamily extends ProviderOrFamily {
  ItemFamily._();

  CartProvider call(String id) => CartProvider._();
}

final cartProvider = CartProvider._();
final itemProvider = ItemFamily._();

CartProvider get cartGetterAlias => cartProvider;

abstract final class Providers {
  static final cart = cartProvider;
}

final firstItemProvider = itemProvider('first');
''';
    await assertDiagnostics(source, [
      compatLint(source, 'cartGetterAlias =>', ruleName),
      compatLint(source, 'cart = cartProvider;', ruleName),
      compatLint(source, 'firstItemProvider =', ruleName),
    ]);
  }

  Future<void> test_allowsGeneratedDeclarationsLocalsAndManualProviders() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final class CartProvider extends $FunctionalProvider<int> {
  CartProvider._();
}

final cartProvider = CartProvider._();
final manualProvider = Provider<int>((ref) => 1);

int read() {
  final provider = cartProvider;
  return provider.hashCode;
}
''', addIgnorePrefix: false);
  }

  Future<void> test_severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}
