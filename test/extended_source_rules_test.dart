// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/architecture_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/showcase_extended_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArchModelMissingToEntityTest);
    defineReflectiveTests(ArchModelExtendsEntityTest);
    defineReflectiveTests(ArchDomainJsonAnnotationTest);
    defineReflectiveTests(FreezedMissingPrivateConstructorTest);
    defineReflectiveTests(RouterImpureRedirectTest);
    defineReflectiveTests(RouterShellTabPushTest);
    defineReflectiveTests(ShowcaseV4ApiTest);
    defineReflectiveTests(ShowcaseGetNamedUnhandledTest);
    defineReflectiveTests(ShowcaseScopeStringLiteralTest);
    defineReflectiveTests(ServiceStaticSideEffectTest);
    defineReflectiveTests(ServiceRandomPerCallTest);
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
    final expected = compatLint(analyzedSource, needle, ruleName, lineStart: lineStart);
    final filePath = path;
    if (filePath == null) {
      await assertDiagnostics(analyzedSource, [expected]);
      return;
    }

    newFile(filePath, analyzedSource);
    await assertDiagnosticsInFile(filePath, [expected]);
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

  ExpectedDiagnostic compatLint(
    String source,
    String needle,
    String name, {
    bool lineStart = false,
  }) {
    var offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    if (lineStart) {
      offset = source.lastIndexOf('\n', offset) + 1;
    }

    final lineEnd = source.indexOf('\n', offset);
    final end = lineEnd < 0 ? source.length : lineEnd;
    return lint(offset, math.max(1, end - offset), name: name);
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

abstract class _ShowcaseExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => showcaseExtendedSourceRules;
}

@reflectiveTest
final class ShowcaseV4ApiTest extends _ShowcaseExtendedRuleTest {
  @override
  String get ruleName => 'showcase_v4_api';
  @override
  String get source => 'void start(context) => ShowCaseWidget.of(context).startShowCase([]);';
  @override
  String get needle => 'ShowCaseWidget';
}

@reflectiveTest
final class ShowcaseGetNamedUnhandledTest extends _ShowcaseExtendedRuleTest {
  @override
  String get ruleName => 'showcase_get_named_unhandled';
  @override
  String get source => '''
void start() {
  ShowcaseView.getNamed(scope).startShowCase(keys);
}
''';
  @override
  String get needle => 'ShowcaseView';
}

@reflectiveTest
final class ShowcaseScopeStringLiteralTest extends _ShowcaseExtendedRuleTest {
  @override
  String get ruleName => 'showcase_scope_string_literal';
  @override
  String get source => '''
final target = AppShowcaseTarget(
  scope: 'profile',
  child: child,
);
''';
  @override
  String get needle => 'scope:';

  Future<void> test_allowsLiteralScopeInTests() async {
    await assertAllows('''
void main() {
  service.markAllToursCompleted(scope: 'test-scope');
}
''', path: '$testPackageRootPath/test/showcase_service_test.dart');
  }
}

abstract class _ServicesExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesExtendedSourceRules;
}

@reflectiveTest
final class ServiceStaticSideEffectTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'service_static_side_effect';
  @override
  String get source => '''
abstract final class TokenUtils {
  static String make() => DateTime.now().millisecondsSinceEpoch.toString();
}
''';
  @override
  String get needle => 'abstract final class TokenUtils';
}

@reflectiveTest
final class ServiceRandomPerCallTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'service_random_per_call';
  @override
  String get source => '''
class RetryDelay {
  int next() {
    final rng = math.Random();
    return rng.nextInt(10);
  }
}
''';
  @override
  String get needle => 'Random';
}

@reflectiveTest
final class FireForgetInTestsTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'fire_forget_in_tests';
  @override
  String get path => '$testPackageRootPath/test/analytics_test.dart';
  @override
  String get source => 'void main() { unawaited(service.track()); }';
  @override
  String get needle => 'unawaited';
}
