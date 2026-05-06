// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/flutter_skill_scanner_compat.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSkillScannerCompatTest);
  });
}

@reflectiveTest
final class FlutterSkillScannerCompatTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = FlutterSkillScannerCompat();
    _addFlutterPackage();
    super.setUp();
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

  Future<void> test_reportsRiverpodScannerRules() async {
    const source = r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

final provider = Object();

class WidgetRef {
  Object read(Object provider) => Object();
  Object watch(Object provider) => Object();
}

class ServiceLocator {}

class TodosState {
  final ref = WidgetRef();

  void initState() {
    ref.read(provider);
  }

  Object build() {
    return ref.watch(provider);
  }
}

@Riverpod(keepAlive: true)
Object todoProvider({required String todoId}) => Object();
''';

    await assertDiagnostics(source, [
      compatLint(source, 'class ServiceLocator', 'riverpod_service_locator'),
      compatLint(source, 'ref.read(provider)', 'riverpod_read_init_state'),
      compatLint(source, 'ref.watch(provider)', 'riverpod_watch_no_select'),
      compatLint(source, '@Riverpod', 'riverpod_keepalive_family'),
    ]);
  }

  Future<void> test_reportsFreezedAndStaticNamespaceRules() async {
    const source = r'''
class Freezed {
  const Freezed({bool toJson = false});
}

class JsonSerializable {
  const JsonSerializable({bool explicitToJson = false});
}

@Freezed(toJson: true)
class User {
  const User._();

  factory User.fromJson(Map<String, dynamic> json) => const User._();

  Object label(Union union) => union.when();
}

class Union {
  Object when() => Object();
}

@JsonSerializable(explicitToJson: true)
class UserDto {}

class Tokens {
  Tokens._();
  static const spacing = 8;
}
''';

    await assertDiagnostics(source, [
      compatLint(source, '@Freezed', 'freezed_to_json_with_from_json', lineStart: true),
      compatLint(source, 'when();', 'freezed_legacy_when_map'),
      compatLint(source, 'when() =>', 'freezed_legacy_when_map'),
      compatLint(source, '@JsonSerializable', 'freezed_per_class_explicit_to_json'),
      compatLint(source, 'class Tokens', 'dart_static_namespace', lineStart: true),
    ]);
  }

  Future<void> test_reportsArchitecturePathRules() async {
    const domainSource = r'''
import 'package:flutter/widgets.dart';

class User {
  User(this.userId, this.orgId, this.widget);

  final String userId;
  final String orgId;
  final Widget? widget;

  Map<String, dynamic> toJson() => {};
}
''';

    const repositorySource = r'''
class UserDatasource {}

class UserRepository {
  UserRepository(this._datasource);

  final UserDatasource _datasource;

  Object get datasource => _datasource;
}
''';

    const datasourceSource = r'''
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

    final domainPath = '$testPackageLibPath/features/users/domain/user.dart';
    final repositoryPath =
        '$testPackageLibPath/features/users/data/repositories/user_repository.dart';
    final datasourcePath =
        '$testPackageLibPath/features/users/data/datasources/user_datasource.dart';

    newFile(domainPath, domainSource);
    newFile(repositoryPath, repositorySource);
    newFile(datasourcePath, datasourceSource);

    await assertDiagnosticsInUnits([
      (
        domainPath,
        [
          compatLint(domainSource, 'import', 'arch_domain_import'),
          compatLint(
            domainSource,
            'Map<String, dynamic> toJson',
            'arch_domain_serialization',
            lineStart: true,
          ),
          compatLint(domainSource, 'final String userId', 'typed_id_raw_id', lineStart: true),
        ],
      ),
      (
        repositoryPath,
        [
          compatLint(
            repositorySource,
            'class UserDatasource',
            'arch_interface_contract',
            lineStart: true,
          ),
          compatLint(
            repositorySource,
            'final UserDatasource',
            'arch_concrete_dependency',
            lineStart: true,
          ),
        ],
      ),
      (
        datasourcePath,
        [
          compatLint(
            datasourceSource,
            'class UserDatasource',
            'arch_interface_contract',
            lineStart: true,
          ),
          compatLint(datasourceSource, 'try {', 'arch_datasource_try_catch'),
        ],
      ),
    ]);
  }

  Future<void> test_reportsUiStylePerfAndAccessibilityRules() async {
    const supportSource = r'''
class Text {
  Text(String data, {Object? style});
}

class TextStyle {
  TextStyle();
}

class EdgeInsets {
  static Object all(double value) => Object();
}

class ListView {
  ListView({Object? children});
}

class ScaffoldMessenger {
  static ScaffoldMessenger of(Object context) => ScaffoldMessenger();
  void showSnackBar(Object snackBar) {}
}

extension SortIntList on List<int> {
  void sort() {}
}
''';

    const source = r'''
import 'package:test/ui_support.dart';

class Screen {
  Object build(Object context) {
    final items = <int>[2, 1];
    items.sort();
    ScaffoldMessenger.of(context).showSnackBar(Object());
    return Text('Save', style: TextStyle());
  }
}

final inset = EdgeInsets.all(8);
final list = ListView(children: []);
''';

    newFile('$testPackageLibPath/ui_support.dart', supportSource);
    final path = '$testPackageLibPath/features/todos/presentation/widgets/todo_view.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'items.sort()', 'perf_build_work', lineStart: true),
      compatLint(source, 'ScaffoldMessenger.of', 'ui_snackbar_boundary', lineStart: true),
      compatLint(source, "Text('Save'", 'strings_hardcoded', lineStart: true),
      compatLint(source, 'TextStyle());', 'style_raw_text_style'),
      compatLint(source, 'EdgeInsets.all(8)', 'style_raw_token', lineStart: true),
      compatLint(source, 'ListView(children', 'perf_listview_children'),
    ]);
  }

  Future<void> test_reportsRouterAndShowcaseRules() async {
    const source = r'''
class BuildContext {
  void go(String location) {}
  void pop() {}
  void push(String location) {}
}

class Ref {
  Object watch(Object provider) => Object();
  void listenManual(Object provider, Object listener) {}
}

class GoRouter {
  GoRouter({Object? redirect});
}

class ShowcaseView {
  static void register() {}
}

class Showcase {
  Showcase({bool disposeOnTap = false, Object? onTargetClick});
}

class ShowcaseController {
  void start() {}
}

final provider = Object();
final isLoading = true;
final ref = Ref();
final showcase = ShowcaseController();

Object? maybePrevious() => Object();

void navigate(BuildContext context) {
  context.pop();
  context.push('/next');
  context.go('/home');
}

final router = GoRouter(
  redirect: () {
    ref.watch(provider);
    if (isLoading) return '/loading';
    return null;
  },
);

void startTour() {
  final ref = Ref();
  ref.listenManual(provider, (prev, next) {});
  final prev = maybePrevious();
  if (prev != null) {
    showcase.start();
  }
  ShowcaseView.register();
  Showcase(disposeOnTap: true);
}
''';

    await assertDiagnostics(source, [
      compatLint(source, 'context.pop()', 'router_pop_then_push'),
      compatLint(source, "context.push('/next')", 'router_string_nav'),
      compatLint(source, "context.go('/home')", 'router_string_nav'),
      compatLint(source, 'ref.watch(provider)', 'riverpod_watch_no_select'),
      compatLint(source, 'ref.watch(provider)', 'router_redirect_watch'),
      compatLint(
        source,
        "if (isLoading) return '/loading';",
        'router_redirect_loading_bounce',
        lineStart: true,
      ),
      compatLint(source, 'ref.listenManual', 'showcase_listen_manual_handle'),
      compatLint(source, 'prev != null', 'showcase_prev_null_guard'),
      compatLint(source, 'ShowcaseView.register', 'showcase_default_scope'),
      compatLint(source, 'disposeOnTap: true', 'showcase_dispose_on_tap'),
    ]);
  }

  Future<void> test_reportsNotifierServiceMixinDataCrashAndTestRules() async {
    const source = r'''
class Notifier<T> {
  Ref get ref => Ref();
}

class Ref {
  Object watch(Object provider) => Object();
}

class Repository {
  void save() {}
}

final provider = Object();

class TodosNotifier extends Notifier<int> {
  final Repository _repository = Repository();

  void updateTodo() {
    ref.watch(provider);
    _repository.save();
  }
}

class UserService {
  static final instance = UserService();
}

mixin class Trackable {
  var count = 0;
}

class Crash {
  static void error(Object value) {}
}

final email = Object();

void recordCrash() {
  Crash.error(email);
}
''';

    const recordsSource = r'''
Map<String, dynamic> coordinates() => {};
''';

    final path = '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
    final recordsPath = '$testPackageLibPath/core/geometry.dart';
    newFile(path, source);
    newFile(recordsPath, recordsSource);

    await assertDiagnosticsInUnits([
      (
        path,
        [
          compatLint(source, 'void updateTodo', 'notifier_watch_method', lineStart: true),
          compatLint(source, 'void updateTodo', 'notifier_ensure_deps', lineStart: true),
          compatLint(source, 'ref.watch(provider)', 'riverpod_watch_no_select'),
          compatLint(source, 'static final instance', 'service_singleton'),
          compatLint(source, 'mixin class Trackable', 'mixin_mixin_class'),
          compatLint(source, 'mixin class Trackable', 'mixin_name_suffix'),
          compatLint(source, 'var count = 0', 'mixin_mutable_state', lineStart: true),
          compatLint(source, 'Crash.error(email)', 'crash_possible_pii', lineStart: true),
          compatLint(source, 'Crash.error(email)', 'crash_unawaited_send', lineStart: true),
        ],
      ),
      (
        recordsPath,
        [compatLint(recordsSource, 'Map<String, dynamic> coordinates', 'records_map_return')],
      ),
    ]);
  }

  Future<void> test_reportsTestHarnessRules() async {
    const supportSource = r'''
class ProviderContainer {
  ProviderContainer();
}

class ProviderScope {
  ProviderScope();
}

class Mock {}

class UserRepository {}

class MockUserRepository extends Mock implements UserRepository {}

ProviderContainer createContainer() => ProviderContainer();

class ValueKey<T> {
  const ValueKey(T value);
}

class Tester {
  void pumpAndSettle() {}
  void tapAt(Object offset) {}
}

class Finder {
  Finder get first => this;
  Object byIcon(Object icon) => Object();
}

final find = Finder();
''';

    const source = r'''
import 'package:test/test_support.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  ProviderContainer();
  ProviderScope();
  createContainer();
  const ValueKey('todo-row');
  final tester = Tester();
  tester.pumpAndSettle();
  tester.tapAt(Object());
  find.byIcon(Object());
  find.first;
}
''';

    newFile('$testPackageLibPath/test_support.dart', supportSource);
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, source);

    await assertDiagnosticsInFile(path, [
      compatLint(source, 'class MockUserRepository', 'test_mock_concrete'),
      compatLint(source, 'ProviderContainer();', 'test_provider_container'),
      compatLint(source, 'ProviderScope();', 'test_uncontrolled_scope'),
      compatLint(source, 'createContainer();', 'test_create_container'),
      compatLint(source, "ValueKey('todo-row')", 'test_inline_value_key'),
      compatLint(source, 'pumpAndSettle()', 'test_pump_and_settle'),
      compatLint(source, 'tapAt(Object())', 'test_tap_at'),
      compatLint(source, 'find.byIcon', 'test_first_match_finder', lineStart: true),
      compatLint(source, 'find.first', 'test_first_match_finder', lineStart: true),
    ]);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {}
''');
  }
}
