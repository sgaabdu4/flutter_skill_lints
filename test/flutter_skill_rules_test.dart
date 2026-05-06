// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/avoid_dynamic_except_json_maps.dart';
import 'package:flutter_skill_lints/src/rules/avoid_legacy_riverpod_apis.dart';
import 'package:flutter_skill_lints/src/rules/avoid_null_bang.dart';
import 'package:flutter_skill_lints/src/rules/avoid_route_param_throw_in_build.dart';
import 'package:flutter_skill_lints/src/rules/avoid_showcase_key_filtering.dart';
import 'package:flutter_skill_lints/src/rules/avoid_shrink_wrap.dart';
import 'package:flutter_skill_lints/src/rules/avoid_silent_repository_null_return.dart';
import 'package:flutter_skill_lints/src/rules/avoid_sync_notifier_state_read.dart';
import 'package:flutter_skill_lints/src/rules/avoid_widget_build_helpers.dart';
import 'package:flutter_skill_lints/src/rules/guard_context_pop.dart';
import 'package:flutter_skill_lints/src/rules/use_context_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_invalidate.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_sealed_freezed_classes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRefMountedAfterAwaitTest);
    defineReflectiveTests(UseContextMountedAfterAwaitTest);
    defineReflectiveTests(AvoidLegacyRiverpodApisTest);
    defineReflectiveTests(AvoidDynamicExceptJsonMapsTest);
    defineReflectiveTests(AvoidNullBangTest);
    defineReflectiveTests(AvoidWidgetBuildHelpersTest);
    defineReflectiveTests(AvoidShrinkWrapTest);
    defineReflectiveTests(GuardContextPopTest);
    defineReflectiveTests(UseRefInvalidateTest);
    defineReflectiveTests(UseSealedFreezedClassesTest);
    defineReflectiveTests(AvoidRouteParamThrowInBuildTest);
    defineReflectiveTests(AvoidShowcaseKeyFilteringTest);
    defineReflectiveTests(AvoidSilentRepositoryNullReturnTest);
    defineReflectiveTests(AvoidSyncNotifierStateReadTest);
  });
}

abstract class _FlutterSkillRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    _addRiverpodPackage();
    _addFreezedPackage();
    _addShowcasePackage();
    super.setUp();
  }

  ExpectedDiagnostic lintFor(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  ExpectedDiagnostic lintForLast(String source, String needle) {
    final offset = source.lastIndexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {
  bool get mounted => true;
  bool canPop() => true;
  void pop() {}
  void go(String location) {}
}

abstract class Widget {
  const Widget();
}

class SizedBox extends Widget {
  const SizedBox();
}

class Text extends Widget {
  const Text(String data);
}

class ListView extends Widget {
  const ListView({bool shrinkWrap = false});
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}
''');
  }

  void _addRiverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  bool get mounted => true;
  T read<T>(Object provider) => throw UnimplementedError();
  T watch<T>(Object provider) => throw UnimplementedError();
  T refresh<T>(Object provider) => throw UnimplementedError();
  void invalidate(Object provider) {}
}

class WidgetRef extends Ref {}
class AutoDisposeRef extends Ref {}
class FutureProviderRef<T> extends Ref {}

class Notifier<T> {
  Ref get ref => Ref();
  late T state;
  T build() => throw UnimplementedError();
}

class AsyncNotifier<T> extends Notifier<T> {}

class Provider<T> {
  Provider(T Function(Ref ref) create);
}

class StateProvider<T> {
  StateProvider(T Function(Ref ref) create);
}

class StateNotifierProvider<T, S> {
  StateNotifierProvider(T Function(Ref ref) create);
}

class ChangeNotifierProvider<T> {
  ChangeNotifierProvider(T Function(Ref ref) create);
}

class NotifierProvider<T, S> {
  NotifierProvider(T Function() create);
}

class AsyncNotifierProvider<T, S> {
  AsyncNotifierProvider(T Function() create);
}

class FutureProvider<T> {
  FutureProvider(Future<T> Function(Ref ref) create);
}

class StreamProvider<T> {
  StreamProvider(Stream<T> Function(Ref ref) create);
}
''');
    newPackage(
      'flutter_riverpod',
    ).addFile('lib/flutter_riverpod.dart', "export 'package:riverpod/riverpod.dart';\n");
  }

  void _addFreezedPackage() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
  }

  void _addShowcasePackage() {
    newPackage('showcaseview').addFile('lib/showcaseview.dart', r'''
class GlobalKey {
  Object? get currentContext => null;
}

class ShowCaseWidget {
  static ShowCaseWidget of(Object? context) => ShowCaseWidget();
  void startShowCase(List<GlobalKey> keys) {}
}
''');
  }
}

@reflectiveTest
final class UseRefMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseRefMountedAfterAwait();
    super.setUp();
  }

  Future<void> test_reportsRefAfterAwait() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    ref.read(provider);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.read(provider)')]);
  }

  Future<void> test_allowsGuardedRefAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted) return;
    ref.read(provider);
  }
}
''');
  }
}

@reflectiveTest
final class UseContextMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseContextMountedAfterAwait();
    super.setUp();
  }

  Future<void> test_reportsContextAfterAwait() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> test_allowsMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  if (!context.mounted) return;
  context.pop();
}
''');
  }
}

@reflectiveTest
final class AvoidLegacyRiverpodApisTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidLegacyRiverpodApis();
    super.setUp();
  }

  Future<void> test_reportsLegacyProvider() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final counterProvider = StateProvider<int>((ref) => 0);
''';
    await assertDiagnostics(source, [lintFor(source, 'StateProvider<int>')]);
  }

  Future<void> test_allowsUnifiedRef() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

int load(Ref ref) => ref.read(Object());
''');
  }
}

@reflectiveTest
final class AvoidDynamicExceptJsonMapsTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidDynamicExceptJsonMaps();
    super.setUp();
  }

  Future<void> test_reportsBareDynamic() async {
    const source = r'''
dynamic value;
Map<String, dynamic> json = {};
''';
    await assertDiagnostics(source, [lintFor(source, 'dynamic')]);
  }

  Future<void> test_allowsJsonMapDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;
''');
  }
}

@reflectiveTest
final class AvoidNullBangTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidNullBang();
    super.setUp();
  }

  Future<void> test_reportsNullBang() async {
    const source = r'''
void f(String? value) {
  value!;
}
''';
    await assertDiagnostics(source, [lintFor(source, '!')]);
  }

  Future<void> test_allowsNullCheck() async {
    await assertNoDiagnostics(r'''
void f(String? value) {
  if (value case final text?) {
    text.length;
  }
}
''');
  }
}

@reflectiveTest
final class AvoidWidgetBuildHelpersTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidWidgetBuildHelpers();
    super.setUp();
  }

  Future<void> test_reportsBuildHelper() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) => _buildTitle();

  Widget _buildTitle() => const SizedBox();
}
''';
    await assertDiagnostics(source, [lintForLast(source, '_buildTitle')]);
  }

  Future<void> test_allowsNamedWidgetClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class ScreenTitle extends StatelessWidget {
  const ScreenTitle();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}

@reflectiveTest
final class AvoidShrinkWrapTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidShrinkWrap();
    super.setUp();
  }

  Future<void> test_reportsShrinkWrapTrue() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final widget = ListView(shrinkWrap: true);
''';
    await assertDiagnostics(source, [lintFor(source, 'shrinkWrap: true')]);
  }

  Future<void> test_allowsDefaultListView() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final widget = ListView();
''');
  }
}

@reflectiveTest
final class GuardContextPopTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = GuardContextPop();
    super.setUp();
  }

  Future<void> test_reportsUnguardedPop() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void close(BuildContext context) {
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> test_allowsCanPopGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void close(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  }
}
''');
  }
}

@reflectiveTest
final class UseRefInvalidateTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseRefInvalidate();
    super.setUp();
  }

  Future<void> test_reportsIgnoredRefresh() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  ref.refresh(provider);
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.refresh(provider)')]);
  }

  Future<void> test_allowsUsedRefreshResult() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  final value = ref.refresh(provider);
  value.hashCode;
}
''');
  }
}

@reflectiveTest
final class UseSealedFreezedClassesTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseSealedFreezedClasses();
    super.setUp();
  }

  Future<void> test_reportsAbstractFreezed() async {
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
abstract class User {}
''';
    await assertDiagnostics(source, [lintFor(source, 'abstract')]);
  }

  Future<void> test_allowsSealedFreezed() async {
    await assertNoDiagnostics(r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {}
''');
  }
}

@reflectiveTest
final class AvoidRouteParamThrowInBuildTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidRouteParamThrowInBuild();
    super.setUp();
  }

  Future<void> test_reportsFirstWhereThrowInBuild() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => throw 'missing',
    );
    return Text(item);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'firstWhere')]);
  }

  Future<void> test_allowsFallbackValue() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => 'fallback',
    );
    return Text(item);
  }
}
''');
  }
}

@reflectiveTest
final class AvoidShowcaseKeyFilteringTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidShowcaseKeyFiltering();
    super.setUp();
  }

  Future<void> test_reportsCurrentContextFiltering() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

void start(BuildContext context, List<GlobalKey> keys) {
  ShowCaseWidget.of(context).startShowCase(
    keys.where((key) => key.currentContext != null).toList(),
  );
}
''';
    await assertDiagnostics(source, [lintFor(source, 'startShowCase')]);
  }

  Future<void> test_allowsFullKeyList() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

void start(BuildContext context, List<GlobalKey> keys) {
  ShowCaseWidget.of(context).startShowCase(keys);
}
''');
  }
}

@reflectiveTest
final class AvoidSilentRepositoryNullReturnTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidSilentRepositoryNullReturn();
    super.setUp();
  }

  Future<void> test_reportsNullRepositoryReturn() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  Object? _repository;

  @override
  int build() => 0;

  Future<void> saveTodo() async {
    if (_repository == null) return;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, '_repository == null')]);
  }

  Future<void> test_allowsEnsureBeforeNullCheck() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  Object? _repository;

  @override
  int build() => 0;

  Future<void> saveTodo() async {
    await _ensureRepository();
    if (_repository == null) return;
  }

  Future<void> _ensureRepository() async {}
}
''');
  }
}

@reflectiveTest
final class AvoidSyncNotifierStateReadTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidSyncNotifierStateRead();
    super.setUp();
  }

  Future<void> test_reportsStateReadInSyncBuild() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    return state;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'state')]);
  }

  Future<void> test_allowsDeferredLoad() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class TodosNotifier extends Notifier<int> {
  @override
  int build() {
    Future.microtask(_load);
    return 0;
  }

  void _load() {}
}
''');
  }
}
