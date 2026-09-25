// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/architecture_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

part 'extended_source_rules_test/extended_source_rules_part_01.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArchModelMissingToEntityTest);
    defineReflectiveTests(ArchRepositoryInlineEntityMappingTest);
    defineReflectiveTests(ArchModelExtendsEntityTest);
    defineReflectiveTests(ArchDomainJsonAnnotationTest);
    defineReflectiveTests(FreezedMissingPrivateConstructorTest);
    defineReflectiveTests(RouterImpureRedirectTest);
    defineReflectiveTests(RouterShellTabPushTest);
    defineReflectiveTests(ServiceStaticSideEffectTest);
    defineReflectiveTests(ServiceRandomPerCallTest);
    defineReflectiveTests(HiddenDependencyFallbackTest);
    defineReflectiveTests(ImplicitNullFallbackTest);
    defineReflectiveTests(FireForgetInTestsTest);
  });
}

abstract class _ExtendedSourceRuleTest extends AnalysisRuleTest {
  List<ScannerRule> get rules;
  String get ruleName;
  String get source;
  String get needle;
  String? get path => null;
  bool get lineStart => false;
  bool get addIgnorePrefix => true;

  @override
  void setUp() {
    rule = rules.singleWhere((rule) => rule.name == ruleName);
    _addFlutterPackage();
    super.setUp();
  }

  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    final filePath = path;
    if (filePath == null) {
      await assertDiagnostics(analyzedSource, [
        compatLint(analyzedSource, needle, ruleName, lineStart: lineStart),
      ]);
      return;
    }

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, needle, ruleName, lineStart: lineStart),
    ]);
  }

  Future<void> assertAllows(String source, {String? path, bool addIgnorePrefix = true}) async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    if (path == null) {
      await assertNoDiagnostics(analyzedSource);
      return;
    }

    newFile(path, analyzedSource);
    await assertNoDiagnosticsInFile(path);
  }

  String _analyzedSource(String source, {required bool addIgnorePrefix}) {
    if (!addIgnorePrefix) return source;
    return '''
// ignore_for_file: const_with_non_type, creation_with_non_type, extends_non_class, final_not_initialized, implements_non_class, mixin_of_non_class, redirect_to_non_class, undefined_annotation, undefined_class, undefined_function, undefined_identifier, undefined_method, unused_import
$source''';
  }

  T compatLint<T>(String source, String needle, String name, {bool lineStart = false}) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name) as T;
  }

  void _addFlutterPackage() {
    newPubspecYamlFile(testPackageRootPath, '''
name: test_package
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: any
  go_router: any
  riverpod_annotation: any
  freezed_annotation: any
''');
  }
}

abstract class _ArchitectureExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => architectureExtendedSourceRules;
}

@reflectiveTest
final class ArchModelMissingToEntityTest extends _ArchitectureExtendedRuleTest {
  @override
  String get ruleName => 'arch_model_missing_to_entity';
  @override
  String get path => '$testPackageLibPath/features/items/data/models/item_model.dart';
  @override
  String get source => 'class ItemModel { const ItemModel(); }';
  @override
  String get needle => '// ignore_for_file';
  @override
  bool get lineStart => true;

  static const _modelSource = r'''
final class WorkoutSetModel {
  const WorkoutSetModel({required this.id});
  final String id;
}
''';

  Future<void> test_allowsMapperExtensionInDataMappers() async {
    final modelPath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    newFile(modelPath, _modelSource);
    newFile('$testPackageLibPath/features/workouts/domain/entities/workout_set.dart', r'''
final class WorkoutSet {
  const WorkoutSet({required this.id});
  final String id;
}
''');
    newFile('$testPackageLibPath/features/workouts/data/mappers/workout_set_mapper.dart', r'''
import '../../domain/entities/workout_set.dart';
import '../models/workout_set_model.dart';

extension WorkoutSetMapper on WorkoutSetModel {
  WorkoutSet toEntity() => WorkoutSet(id: id);
}
''');

    await assertNoDiagnosticsInFile(modelPath);
  }

  Future<void> test_reportsMapperExtensionOnAnotherModel() async {
    final modelPath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    newFile(modelPath, _modelSource);
    newFile('$testPackageLibPath/features/workouts/data/mappers/workout_set_mapper.dart', r'''
final class OtherModel {}

extension WorkoutSetMapper on OtherModel {
  Object toEntity() => Object();
}
''');

    await assertDiagnosticsInFile(modelPath, [
      compatLint(_modelSource, 'final class', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsToDomainMapper() async {
    await assertAllows(r'''
final class OrderModel {
  const OrderModel({required this.id});
  final String id;
  Object toDomain() => Object();
}
''', path: '$testPackageLibPath/features/orders/data/models/order_model.dart');
  }
}

@reflectiveTest
final class ArchRepositoryInlineEntityMappingTest extends _ArchitectureExtendedRuleTest {
  @override
  String get ruleName => 'arch_repository_inline_entity_mapping';
  @override
  String get path => '$testPackageLibPath/features/products/repositories/product_repository.dart';
  @override
  bool get addIgnorePrefix => false;
  @override
  String get needle => 'Product(id: ProductId(model.id)';
  @override
  String get source => r'''
import '../data/models/product_model.dart';
import '../domain/entities/product.dart';
import '../domain/values/product_id.dart';

final class ProductRepository {
  Product map(ProductModel model) => Product(id: ProductId(model.id), name: model.name);
}
''';

  @override
  void setUp() {
    super.setUp();
    newFile('$testPackageLibPath/features/products/domain/values/product_id.dart', r'''
final class ProductId {
  const ProductId(this.value);
  final String value;
}
''');
    newFile('$testPackageLibPath/features/products/domain/entities/product.dart', r'''
import '../values/product_id.dart';

final class Product {
  const Product({required this.id, required this.name});
  final ProductId id;
  final String name;
}
''');
    newFile('$testPackageLibPath/features/products/data/models/product_model.dart', r'''
import '../../domain/entities/product.dart';
import '../../domain/values/product_id.dart';

final class ProductModel {
  const ProductModel({required this.id, required this.name});
  final String id;
  final String name;

  Product toEntity() => Product(id: ProductId(id), name: name);
}
''');
  }

  Future<void> test_allowsToEntityAndEntitiesBuiltFromDomainInputs() async {
    await assertAllows(
      r'''
import '../data/models/product_model.dart';
import '../domain/entities/product.dart';
import '../domain/values/product_id.dart';

final class ProductRepository {
  Product map(ProductModel model) => model.toEntity();
  Product draft(ProductId id) => Product(id: id, name: 'Draft');
}
''',
      path: path,
      addIgnorePrefix: false,
    );
  }
}

@reflectiveTest
final class ArchModelExtendsEntityTest extends _ArchitectureExtendedRuleTest {
  @override
  String get ruleName => 'arch_model_extends_entity';
  @override
  String get path => '$testPackageLibPath/features/items/data/models/item_model.dart';
  @override
  String get source => 'class ItemModel extends Item { const ItemModel(); }';
  @override
  String get needle => 'extends Item';
}

@reflectiveTest
final class ArchDomainJsonAnnotationTest extends _ArchitectureExtendedRuleTest {
  @override
  String get ruleName => 'arch_domain_json_annotation';
  @override
  String get path => '$testPackageLibPath/features/items/domain/entities/item.dart';
  @override
  String get source => '''
class Item {
  const Item({required this.name});
  @JsonKey(name: 'full_name')
  final String name;
}
''';
  @override
  String get needle => '@JsonKey';
  @override
  bool get lineStart => true;
}

abstract class _FreezedExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => freezedExtendedSourceRules;
}

@reflectiveTest
final class FreezedMissingPrivateConstructorTest extends _FreezedExtendedRuleTest {
  @override
  String get ruleName => 'freezed_missing_private_constructor';
  @override
  String get source => '''
@freezed
sealed class Order with _\$Order {
  const factory Order({required int cents}) = _Order;
  int get dollars => cents ~/ 100;
}
''';
  @override
  String get needle => 'sealed class Order';

  Future<void> test_factoryObjectPatternDoesNotRequirePrivateConstructor() async {
    await assertAllows(r'''
class OrderValue {
  const OrderValue(this.cents);
  final int cents;
}
@freezed
sealed class Order with _$Order {
  const factory Order({required int cents}) = _Order;
  factory Order.copy(OrderValue value) {
    final OrderValue(:cents) = value;
    return Order(cents: cents);
  }
}
''');
  }

  Future<void> test_staticHelpersDoNotRequirePrivateConstructor() async {
    await assertAllows(r'''
@freezed
sealed class Order with _$Order {
  const factory Order({required int cents}) = _Order;
  static int get scale => 100;
  static int normalize(int cents) => cents;
}
''');
  }

  Future<void> test_customBlockGetterRequiresPrivateConstructor() async {
    final source = _analyzedSource(r'''
@freezed
sealed class Order with _$Order {
  const factory Order({required int cents}) = _Order;
  int get dollars { return 100; }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, 'sealed class Order', ruleName)]);
  }

  Future<void> test_privateConstructorSupportsCustomMethod() async {
    await assertAllows(r'''
@freezed
sealed class Order with _$Order {
  const Order._();
  const factory Order({required int cents}) = _Order;
  int dollars() => 100;
}
''');
  }
}

abstract class _RouterExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => routerExtendedSourceRules;
}

@reflectiveTest
final class RouterImpureRedirectTest extends _RouterExtendedRuleTest {
  @override
  String get ruleName => 'router_impure_redirect';
  @override
  String get source => '''
final router = GoRouter(
  redirect: (context, state) {
    if (signedOut) return '/login';
    return null;
  },
);
''';
  @override
  String get needle => 'redirect:';
}

@reflectiveTest
final class RouterShellTabPushTest extends _RouterExtendedRuleTest {
  @override
  String get ruleName => 'router_shell_tab_push';
  @override
  String get source => '''
class Shell {
  final StatefulNavigationShell navigationShell;
  void open() {
    const ReportsRoute().push<void>(context);
    navigationShell.goBranch(1);
  }
}
''';
  @override
  String get needle => 'const ReportsRoute';
  @override
  bool get lineStart => true;

  @override
  void setUp() {
    newPackage('flutter').addFile('lib/material.dart', '''
class BuildContext {}
abstract class Widget {
  const Widget();
}
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}
class SizedBox extends Widget {
  const SizedBox();
}
class NavigationBar extends Widget {
  const NavigationBar({int selectedIndex = 0, void Function(int)? onDestinationSelected, List<Widget> destinations = const []});
}
class NavigationRail extends Widget {
  const NavigationRail({int? selectedIndex, void Function(int)? onDestinationSelected});
}
class BottomNavigationBar extends Widget {
  const BottomNavigationBar({int currentIndex = 0, void Function(int)? onTap});
}
class TextButton extends Widget {
  const TextButton({void Function()? onPressed});
}
''');
    newPackage('go_router').addFile('lib/go_router.dart', '''
import 'package:flutter/material.dart';
abstract class GoRouteData {
  const GoRouteData();
  void go(BuildContext context) {}
  Future<T?> push<T>(BuildContext context) async => null;
}
class StatefulNavigationShell extends Widget {
  const StatefulNavigationShell();
  int get currentIndex => 0;
  void goBranch(int index, {bool initialLocation = false}) {}
}
''');
    super.setUp();
  }

  Future<void> test_reportsInlineTabCallbackPush() async {
    const source = '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellInlineScaffold extends StatelessWidget {
  const AppShellInlineScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => unawaited(const HomeRoute().push<void>(context)),
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'const HomeRoute().push<void>(context)),', ruleName),
    ]);
  }

  Future<void> test_reportsPushInMethodReferencedByTabCallback() async {
    const source = '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> onTab(BuildContext context, int index) async {
    if (index == 0) {
      await const HomeRoute().push<void>(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => onTab(context, index),
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'const HomeRoute().push<void>(context);', ruleName),
    ]);
  }

  Future<void> test_reportsTypedGoInBottomNavigationTap() async {
    const source = '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {}

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: (index) => const HomeRoute().go(context),
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'const HomeRoute().go(context),', ruleName),
    ]);
  }

  Future<void> test_reportsMixedTabCallbackOnce() async {
    const source = '''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellMixedScaffold extends StatelessWidget {
  const AppShellMixedScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => index == 0
          ? unawaited(const HomeRoute().push<void>(context))
          : navigationShell.goBranch(index),
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '          ? unawaited', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsSkillGoBranchTearOff() async {
    await assertAllows('''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: navigationShell.goBranch,
    );
  }
}
''');
  }

  Future<void> test_allowsNonTabPushInShellClass() async {
    await assertAllows('''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => unawaited(const HomeRoute().push<void>(context)));
  }
}
''');
  }

  Future<void> test_allowsTabPushWithoutShell() async {
    await assertAllows('''
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeRoute extends GoRouteData {
  const HomeRoute();
}

class PlainTabs extends StatelessWidget {
  const PlainTabs();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(onDestinationSelected: (index) => unawaited(const HomeRoute().push<void>(context)));
  }
}
''');
  }

  Future<void> test_allowsStandaloneRoutePushInFileWithShellRoute() async {
    await assertAllows('''
class MainShellRoute {
  final StatefulNavigationShell navigationShell;
}

class HostCard {
  void openDetails() {
    unawaited(DetailFlowRoute().push<void>(context));
  }
}
''');
  }

  Future<void> test_allowsRoutePushInSiblingCallbackWhenMethodUsesShell() async {
    await assertAllows('''
class HostCard {
  Widget build(BuildContext context) {
    final startButton = Button(
      onTap: () {
        unawaited(DetailFlowRoute().push<void>(context));
      },
    );

    return Button(
      onTap: () {
        final navigationShell = StatefulNavigationShell.of(context);
        navigationShell.goBranch(1);
      },
      child: startButton,
    );
  }
}
''');
  }

  Future<void> test_allowsTypedGoFallbackWhenShellMissing() async {
    await assertAllows('''
class HostCard {
  void openPlan(BuildContext context) {
    final navigationShell = StatefulNavigationShell.maybeOf(context);
    if (navigationShell != null) {
      navigationShell.goBranch(1);
      return;
    }
    const ReportsRoute().go(context);
  }
}
''');
  }
}
