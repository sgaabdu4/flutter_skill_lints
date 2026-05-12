// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/architecture_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/data_crash_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/freezed_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/hive_persistence_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/riverpod_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/router_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/services_mixins_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/showcase_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';
import 'package:flutter_skill_lints/src/rules/state_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/test_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/ui_source_rules.dart';
import 'package:flutter_skill_lints/src/rules/value_object_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RiverpodReadInitStateTest);
    defineReflectiveTests(RiverpodServiceLocatorTest);
    defineReflectiveTests(RiverpodWatchNoSelectTest);
    defineReflectiveTests(RiverpodSelectArrowSyntaxTest);
    defineReflectiveTests(RiverpodMutationExperimentalWarningTest);
    defineReflectiveTests(RiverpodAutoDisposeKeepAliveDependenciesTest);
    defineReflectiveTests(RiverpodFeatureNotifierKeepaliveTest);
    defineReflectiveTests(RiverpodKeepaliveFamilyTest);
    defineReflectiveTests(DartStaticNamespaceTest);
    defineReflectiveTests(FreezedPerClassExplicitToJsonTest);
    defineReflectiveTests(FreezedToJsonWithFromJsonTest);
    defineReflectiveTests(FreezedLegacyWhenMapTest);
    defineReflectiveTests(FreezedRequiredValueClassTest);
    defineReflectiveTests(ArchDomainImportTest);
    defineReflectiveTests(ArchDomainSerializationTest);
    defineReflectiveTests(ArchInterfaceContractTest);
    defineReflectiveTests(ArchRepositoryGeneratedExtendsTest);
    defineReflectiveTests(ArchConcreteDependencyTest);
    defineReflectiveTests(ArchDatasourceTryCatchTest);
    defineReflectiveTests(ArchWidgetPathTest);
    defineReflectiveTests(AtomicProviderAccessTest);
    defineReflectiveTests(TypedIdRawIdTest);
    defineReflectiveTests(RecordsMapReturnTest);
    defineReflectiveTests(ObjectMapCastTest);
    defineReflectiveTests(StyleRawTokenTest);
    defineReflectiveTests(StyleRawTextStyleTest);
    defineReflectiveTests(StringsHardcodedTest);
    defineReflectiveTests(UiSnackbarBoundaryTest);
    defineReflectiveTests(A11yTextScaleClampTest);
    defineReflectiveTests(PerfBuildWorkTest);
    defineReflectiveTests(PerfListviewChildrenTest);
    defineReflectiveTests(StateRawResponseTest);
    defineReflectiveTests(StateRawErrorToStringTest);
    defineReflectiveTests(StateFreezedNullableErrorTest);
    defineReflectiveTests(StateBroadInvalidationTest);
    defineReflectiveTests(AsyncContextMountedStyleTest);
    defineReflectiveTests(RouterStringNavTest);
    defineReflectiveTests(RouterPopThenPushTest);
    defineReflectiveTests(RouterRedirectWatchTest);
    defineReflectiveTests(RouterRedirectLoadingBounceTest);
    defineReflectiveTests(RouterComplexExtraTest);
    defineReflectiveTests(RouterGoRouterOfTest);
    defineReflectiveTests(RouterUntypedNavigatorPushTest);
    defineReflectiveTests(ShowcaseListenManualHandleTest);
    defineReflectiveTests(ShowcasePrevNullGuardTest);
    defineReflectiveTests(ShowcaseDefaultScopeTest);
    defineReflectiveTests(ShowcaseDisposeOnTapTest);
    defineReflectiveTests(NotifierEnsureDepsTest);
    defineReflectiveTests(NotifierWatchMethodTest);
    defineReflectiveTests(ServiceSingletonTest);
    defineReflectiveTests(MixinMixinClassTest);
    defineReflectiveTests(MixinNameSuffixTest);
    defineReflectiveTests(MixinMutableStateTest);
    defineReflectiveTests(DataLogRethrowTest);
    defineReflectiveTests(CrashPossiblePiiTest);
    defineReflectiveTests(CrashRunZonedGuardedLegacyTest);
    defineReflectiveTests(TestProviderContainerTest);
    defineReflectiveTests(TestUncontrolledScopeTest);
    defineReflectiveTests(TestCreateContainerTest);
    defineReflectiveTests(TestMockConcreteTest);
    defineReflectiveTests(TestPumpAndSettleTest);
    defineReflectiveTests(TestTapAtTest);
    defineReflectiveTests(TestInlineValueKeyTest);
    defineReflectiveTests(TestFirstMatchFinderTest);
    defineReflectiveTests(VoPublicRawConstructorTest);
    defineReflectiveTests(DomainEntityPrimitiveFactoryTest);
    defineReflectiveTests(DomainCustomCopyWithTest);
    defineReflectiveTests(FreezedDisableMapWhenRequiredTest);
    defineReflectiveTests(HiveFieldNoVoTypeTest);
  });
}

abstract class _SourceRuleTest extends AnalysisRuleTest {
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
// ignore_for_file: extends_non_class, final_not_initialized, implements_non_class, undefined_function, undefined_identifier, undefined_method, unused_import
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
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {}
class Widget {}
''');
  }
}

abstract class _RiverpodRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => riverpodSourceRules;
}

@reflectiveTest
final class RiverpodReadInitStateTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_read_init_state';
  @override
  String get needle => 'ref.read(provider)';
  @override
  String get source => r'''
final provider = Object();

class WidgetRef {
  Object read(Object provider) => Object();
}

class TodosState {
  final ref = WidgetRef();

  void initState() {
    ref.read(provider);
  }
}
''';
}

@reflectiveTest
final class RiverpodServiceLocatorTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_service_locator';
  @override
  String get needle => 'class ServiceLocator';
  @override
  String get source => 'class ServiceLocator {}';
}

@reflectiveTest
final class RiverpodWatchNoSelectTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_watch_no_select';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
final provider = Object();

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TodoList {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider);
  }
}
''';

  Future<void> test_allowsMultilineFamilyProviderSelect() async {
    await assertNoDiagnostics(r'''
final workoutByIdProvider = WorkoutFamily();

class ProviderArg<T> {
  Object select(Object Function(T? value) selector) => Object();
}

class Workout {
  const Workout(this.name);

  final String name;
}

class WorkoutFamily {
  ProviderArg<Workout> call(String id) => ProviderArg<Workout>();
}

class WorkoutConfig {
  const WorkoutConfig(this.workoutId);

  final String workoutId;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TodoList {
  Object build(WorkoutConfig config) {
    final ref = WidgetRef();
    final isNewWorkout = ref.watch(
      workoutByIdProvider(config.workoutId).select((w) => w?.name.isEmpty ?? true),
    );
    return isNewWorkout;
  }
}
''');
  }
}

@reflectiveTest
final class RiverpodSelectArrowSyntaxTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_select_arrow_syntax';
  @override
  String get needle => '.select((todo)';
  @override
  String get source => r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo) {
      return todo.title;
    }));
  }
}
''';

  Future<void> test_allowsArrowSelect() async {
    await assertAllows(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo) => todo.title));
  }
}
''');
  }

  Future<void> test_allowsNonRiverpodSelectApi() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

final query = Query<int>();

final selected = query.select((value) {
  return value.isEven;
});
''');
  }

  Future<void> test_allowsUnrelatedSelectNearRefWatch() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = Object();
final query = Query<int>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    ref.watch(provider);
    return query.select((value) {
      return value.isEven;
    });
  }
}
''');
  }

  Future<void> test_reportsTypedBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((Todo todo) {
      return todo.title;
    }));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.select((Todo todo)', ruleName),
    ]);
  }

  Future<void> test_reportsTrailingCommaBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo,) {
      return todo.title;
    }));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.select((todo,)', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineBlockSelect() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title);

  final String title;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(
      provider.select(
        (todo) {
          return todo.title;
        },
      ),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.select', ruleName)]);
  }
}

@reflectiveTest
final class RiverpodMutationExperimentalWarningTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_mutation_experimental_warning';
  @override
  String get needle => 'Mutation<int>()';
  @override
  String get path =>
      '$testPackageLibPath/features/todos/presentation/notifiers/todos_notifier.dart';
  @override
  String get source => r'''
class Mutation<T> {
  const Mutation();
}

final saveMutation = Mutation<int>();
''';

  Future<void> test_allowsNearbyExperimentalWarning() async {
    await assertAllows(r'''
class Mutation<T> {
  const Mutation();
}

// experimental API while Riverpod finalizes mutation support.
final saveMutation = Mutation<int>();
''', path: path);
  }

  Future<void> test_allowsMutationClassDeclaration() async {
    await assertAllows(r'''
class Mutation<T> {
  const Mutation();
}
''', path: path);
  }

  Future<void> test_allowsTypedefDeclaration() async {
    await assertAllows(r'''
typedef Mutation<T> = Object;
''', path: path);
  }

  Future<void> test_allowsQualifiedNonRiverpodMutation() async {
    await assertAllows(r'''
class Graphql {
  const Graphql();

  Object Mutation<T>() => Object();
}

const graphql = Graphql();

final saveMutation = graphql.Mutation<int>();
''', path: path);
  }

  Future<void> test_allowsGraphqlMutationWidgetOutsideNotifier() async {
    await assertAllows(r'''
class Mutation<T> {
  const Mutation();
}

final widget = Mutation<int>();
''', path: '$testPackageLibPath/features/todos/presentation/widgets/mutation_widget.dart');
  }
}

@reflectiveTest
final class RiverpodAutoDisposeKeepAliveDependenciesTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_auto_dispose_keepalive_dependencies';
  @override
  String get needle => '@riverpod';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@Riverpod(keepAlive: true)
Object exercises(Ref ref) => Object();

@riverpod
Object workoutSummary(Ref ref) {
  ref.watch(activeWorkoutProvider);
  ref.watch(exercisesProvider.select((value) => value));
  return Object();
}
''';

  Future<void> test_reportsClassProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@riverpod
class WorkoutSummaryNotifier {
  Object build() {
    ref.watch(activeWorkoutProvider);
    return Object();
  }
}
''', addIgnorePrefix: true);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '@riverpod', ruleName)]);
  }

  Future<void> test_allowsAlreadyKeepAlive() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@Riverpod(keepAlive: true)
Object workoutSummary(Ref ref) {
  ref.watch(activeWorkoutProvider);
  return Object();
}
''');
  }

  Future<void> test_allowsMixedKeepAliveAndAutoDisposeDependencies() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@riverpod
Object transientSelection(Ref ref) => Object();

@riverpod
Object workoutSummary(Ref ref) {
  ref.watch(activeWorkoutProvider);
  ref.watch(transientSelectionProvider);
  return Object();
}
''');
  }

  Future<void> test_allowsUnknownExternalDependency() async {
    await assertAllows(r'''
const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@riverpod
Object workoutSummary(Ref ref) {
  ref.watch(externalProvider);
  return Object();
}
''');
  }

  Future<void> test_allowsFamilyProviderTarget() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@riverpod
Object workoutSummary(Ref ref, String workoutId) {
  ref.watch(activeWorkoutProvider);
  return Object();
}
''');
  }

  Future<void> test_allowsFamilyNotifierTarget() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object watch(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@riverpod
class WorkoutSummaryNotifier {
  Object build(String workoutId) {
    ref.watch(activeWorkoutProvider);
    return Object();
  }
}
''');
  }

  Future<void> test_allowsReadOnlyKeepAliveProviderUse() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Object();

class Ref {
  Object read(Object provider) => Object();
}

@Riverpod(keepAlive: true)
Object activeWorkout(Ref ref) => Object();

@riverpod
Object workoutSummary(Ref ref) {
  ref.read(activeWorkoutProvider);
  return Object();
}
''');
  }
}

@reflectiveTest
final class RiverpodFeatureNotifierKeepaliveTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_feature_notifier_keepalive';
  @override
  String get needle => '@riverpod';
  @override
  String get path =>
      '$testPackageLibPath/features/history/presentation/notifiers/history_calendar_notifier.dart';
  @override
  String get source => r'''
const riverpod = Object();

@riverpod
class HistoryCalendarNotifier {
  Object build() => Object();
}
''';

  Future<void> test_reportsExplicitKeepAliveFalse() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: false)
class HistoryCalendarNotifier {
  Object build() => Object();
}
''', addIgnorePrefix: addIgnorePrefix);

    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, '@Riverpod(keepAlive: false)', ruleName),
    ]);
  }

  Future<void> test_allowsKeepAliveFeatureNotifier() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class HistoryCalendarNotifier {
  Object build() => Object();
}
''', path: path);
  }

  Future<void> test_allowsFamilyFeatureNotifier() async {
    await assertAllows(
      r'''
const riverpod = Object();

@riverpod
class WorkoutEditorNotifier {
  Object build(String workoutId) => Object();
}
''',
      path:
          '$testPackageLibPath/features/workouts/presentation/notifiers/workout_editor_notifier.dart',
    );
  }

  Future<void> test_allowsComputedFunctionProviderInNotifierFile() async {
    await assertAllows(r'''
const riverpod = Object();

class Ref {}

@riverpod
Object historyCalendarSessions(Ref ref) => Object();
''', path: path);
  }

  Future<void> test_allowsDocumentedEphemeralNotifier() async {
    await assertAllows(
      r'''
const riverpod = Object();

// autoDispose: route-local draft should reset when the editor closes.
@riverpod
class WorkoutDraftNotifier {
  Object build() => Object();
}
''',
      path:
          '$testPackageLibPath/features/workouts/presentation/notifiers/workout_draft_notifier.dart',
    );
  }

  Future<void> test_allowsLifecycleCleanupNotifier() async {
    await assertAllows(
      r'''
const riverpod = Object();

class Ref {
  void onDispose(Object callback) {}
}

@riverpod
class CardioTimerNotifier {
  final ref = Ref();

  Object build() {
    ref.onDispose(() {});
    return Object();
  }
}
''',
      path:
          '$testPackageLibPath/features/active_workout/presentation/notifiers/cardio_timer_notifier.dart',
    );
  }

  Future<void> test_allowsNotifierOutsideFeaturePresentationNotifiers() async {
    await assertAllows(r'''
const riverpod = Object();

@riverpod
class DraftNotifier {
  Object build() => Object();
}
''', path: '$testPackageLibPath/core/notifiers/draft_notifier.dart');
  }
}

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
    final filePath = '$testPackageLibPath/features/workouts/domain/workout.dart';
    newFile('$testPackageLibPath/features/workouts/domain/workout.freezed.dart', r'''
part of 'workout.dart';

mixin _$Workout {}

final class _Workout implements Workout {
  const _Workout({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}
''');
    newFile(filePath, r'''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout.freezed.dart';

@freezed
sealed class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String name,
  }) = _Workout;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsDomainToDomainPackageImport() async {
    final filePath = '$testPackageLibPath/features/workouts/domain/workout.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:test_package/features/shared/domain/enums.dart';

final class Workout {}
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
final class ArchWidgetPathTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'arch_widget_path';
  @override
  String get needle => 'class TodoWidget';
  @override
  bool get addIgnorePrefix => false;
  @override
  String get path => '$testPackageLibPath/features/todos/widgets/todo_widget.dart';
  @override
  String get source => 'class TodoWidget {}';

  Future<void> test_allowsFeatureWidgetTestFiles() async {
    final filePath = '$testPackageRootPath/test/features/todos/widgets/todo_widget_test.dart';
    newFile(filePath, 'class TodoWidgetTest {}');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class AtomicProviderAccessTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'atomic_provider_access';
  @override
  String get needle => 'ref.read';
  @override
  String get path => '$testPackageLibPath/core/widgets/atoms/atom_button.dart';
  @override
  String get source => r'''
void build(ref, provider) {
  ref.read(provider);
}
''';
}

@reflectiveTest
final class TypedIdRawIdTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'typed_id_raw_id';
  @override
  String get needle => 'final String userId';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  final String userId;
  final String orgId;
}
''';
}

@reflectiveTest
final class RecordsMapReturnTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'records_map_return';
  @override
  String get needle => 'Map<String, dynamic> coordinates';
  @override
  String get path => '$testPackageLibPath/core/geometry.dart';
  @override
  String get source => 'Map<String, dynamic> coordinates() => {};';

  Future<void> test_allowsToMapPayloadBoundary() async {
    await assertNoDiagnostics(r'''
final class RestTimerActivityData {
  const RestTimerActivityData({
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.endTime,
  });

  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final DateTime endTime;

  Map<String, dynamic> toMap() => {
    'exerciseName': exerciseName,
    'currentSet': currentSet,
    'totalSets': totalSets,
    'endTimeEpoch': endTime.millisecondsSinceEpoch ~/ 1000,
  };
}
''');
  }
}

@reflectiveTest
final class ObjectMapCastTest extends _ArchitectureRuleTest {
  @override
  String get ruleName => 'avoid_object_map_cast';
  @override
  String get needle => 'as Map<String, Object?>';
  @override
  String get source => r'''
void read(Object? value) {
  final payload = value as Map<String, Object?>;
}
''';

  Future<void> test_allowsObjectMapDeclarations() async {
    await assertAllows(r'''
void read(Map<String, Object?> payload) {
  payload['ok'];
}
''');
  }

  Future<void> test_allowsDynamicMapCasts() async {
    await assertAllows(r'''
void read(Object? value) {
  final payload = value as Map<String, dynamic>;
}
''');
  }
}

abstract class _UiRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => uiSourceRules;
}

@reflectiveTest
final class StyleRawTokenTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_token';
  @override
  String get needle => 'EdgeInsets.all(8)';
  @override
  bool get lineStart => true;
  @override
  String get source => 'final inset = EdgeInsets.all(8);';

  Future<void> test_allowsRawTokensInThemeDefinitions() async {
    await assertAllows('''
class Color {
  const Color(int value);
}

abstract final class AppTheme {
  static const surface = Color(0xFF070707);
}
''', path: '$testPackageLibPath/core/theme/app_theme.dart');
  }

  Future<void> test_allowsRawTokensInTests() async {
    await assertAllows('''
class EdgeInsets {
  const EdgeInsets.all(double value);
}

void main() {
  expect(segment.padding, equals(const EdgeInsets.all(8)));
}
''', path: '$testPackageRootPath/test/core/theme/app_theme_test.dart');
  }

  Future<void> test_allowsDesignTokensWithDigits() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacing0 = 0.0;
  static const spacingMd2 = 14.0;
  static const spacing3xl = 32.0;
}

class EdgeInsets {
  const EdgeInsets.symmetric({double? horizontal, double? vertical});
}

class SizedBox extends Widget {
  const SizedBox({double? height});
}

final padding = EdgeInsets.symmetric(vertical: DesignTokens.spacingMd2);
final spacer = SizedBox(height: DesignTokens.spacing3xl);
final empty = SizedBox(height: DesignTokens.spacing0);
''');
  }

  Future<void> test_allowsZeroAndDerivedGeometry() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingSm = 8.0;
}

class EdgeInsets {
  const EdgeInsets.only({double? left});
}

class Radius {
  const Radius.circular(double value);
}

final leadingPadding = EdgeInsets.only(left: index == 0 ? 0 : DesignTokens.spacingSm);
final pillRadius = Radius.circular(height / 2);
''');
  }

  Future<void> test_allowsSwitchArmIndicesNearTokenConstructors() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingSm = 8.0;
}

class SizedBox extends Widget {
  const SizedBox({double? height});
}

Object itemBuilder(int index) => switch (index) {
  0 => const SizedBox(height: DesignTokens.spacingSm),
  1 => const SizedBox(height: DesignTokens.spacingSm),
  2 => const Object(),
  _ => const Object(),
};
''');
  }

  Future<void> test_allowsCollectionBoundArithmeticNearTokenConstructors() async {
    await assertAllows('''
abstract final class DesignTokens {
  static const spacingLg = 16.0;
}

class EdgeInsets {
  const EdgeInsets.only({double? right});
}

final padding = EdgeInsets.only(right: i < labels.length - 1 ? DesignTokens.spacingLg : 0);
''');
  }
}

@reflectiveTest
final class StyleRawTextStyleTest extends _UiRuleTest {
  @override
  String get ruleName => 'style_raw_text_style';
  @override
  String get needle => 'TextStyle()';
  @override
  String get source => 'final style = TextStyle();';

  Future<void> test_allowsTextStyleInThemeDefinitions() async {
    await assertAllows('''
class TextStyle {
  const TextStyle({double? fontSize});
}

TextStyle appTextStyle({double fontSize = 14}) => TextStyle(fontSize: fontSize);
''', path: '$testPackageLibPath/core/theme/bento_tokens.dart');
  }

  Future<void> test_allowsTextStyleInTests() async {
    await assertAllows('''
class TextStyle {
  const TextStyle({double? fontSize});
}

void main() {
  expect(style, equals(const TextStyle(fontSize: 14)));
}
''', path: '$testPackageRootPath/test/core/theme/app_theme_test.dart');
  }
}

@reflectiveTest
final class StringsHardcodedTest extends _UiRuleTest {
  @override
  String get ruleName => 'strings_hardcoded';
  @override
  String get needle => "Text('Save'";
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Text {
  Text(String data);
}

final text = Text('Save');
''';

  Future<void> test_allowsStringsDefinitionFiles() async {
    final filePath = '$testPackageLibPath/features/settings/settings_strings.dart';
    newFile(filePath, r'''
class Text {
  Text(String data);
}

final text = Text('Save');
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class UiSnackbarBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'ui_snackbar_boundary';
  @override
  String get needle => 'ScaffoldMessenger.of';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/widgets/todo_view.dart';
  @override
  String get source =>
      'void build(context) { ScaffoldMessenger.of(context).showSnackBar(Object()); }';
}

@reflectiveTest
final class A11yTextScaleClampTest extends _UiRuleTest {
  @override
  String get ruleName => 'a11y_text_scale_clamp';
  @override
  String get needle => 'TextScaler.linear(1';
  @override
  String get path => '$testPackageLibPath/app.dart';
  @override
  bool get lineStart => true;
  @override
  String get source => 'final scaler = TextScaler.linear(1);';
}

@reflectiveTest
final class PerfBuildWorkTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_build_work';
  @override
  String get needle => 'items.sort()';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Screen {
  Object build() {
    final items = <int>[2, 1];
    items.sort();
    return Object();
  }
}
''';
}

@reflectiveTest
final class PerfListviewChildrenTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_listview_children';
  @override
  String get needle => 'ListView(children';
  @override
  String get source => 'final list = ListView(children: []);';
}

abstract class _StateRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => stateSourceRules;
}

@reflectiveTest
final class StateRawResponseTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_raw_response';
  @override
  String get needle => 'state = state.copyWith';
  @override
  String get source => r'''
void f(state) {
  state = state.copyWith(response: Object());
}
''';
}

@reflectiveTest
final class StateRawErrorToStringTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_raw_error_to_string';
  @override
  String get needle => 'error: e.toString()';
  @override
  String get source => r'''
void fail(state, Object e) {
  state = state.copyWith(error: e.toString());
}
''';

  Future<void> test_allowsStructuredErrorMessage() async {
    await assertAllows(r'''
void fail(state, String message) {
  state = state.copyWith(error: message);
}
''');
  }
}

@reflectiveTest
final class StateFreezedNullableErrorTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_freezed_nullable_error';
  @override
  String get needle => 'String? error';
  @override
  String get source => r'''
const freezed = Object();

@freezed
class LoginState {
  const LoginState({this.error});

  final String? error;
}
''';

  Future<void> test_allowsStructuredFailure() async {
    await assertAllows(r'''
const freezed = Object();

@freezed
class LoginState {
  const LoginState({this.failure});

  final Object? failure;
}
''');
  }

  Future<void> test_allowsNullableErrorOutsideFreezedState() async {
    await assertAllows(r'''
class LegacyState {
  const LegacyState({this.error});

  final String? error;
}
''');
  }

  Future<void> test_allowsFreezedDtoWithNullableErrorField() async {
    await assertAllows(r'''
const freezed = Object();

@freezed
class ApiErrorModel {
  const ApiErrorModel({this.error});

  final String? error;
}
''');
  }
}

@reflectiveTest
final class StateBroadInvalidationTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_broad_invalidation';
  @override
  String get needle => 'ref.invalidate(provider)';
  @override
  String get source => r'''
class Todos {
  void saveTodo(context, ref, provider) {
    ref.invalidate(provider);
    context.go('/todos');
  }
}
''';
}

@reflectiveTest
final class AsyncContextMountedStyleTest extends _StateRuleTest {
  @override
  String get ruleName => 'async_context_mounted_style';
  @override
  String get needle => 'mounted) return';
  @override
  String get source => r'''
class Screen {
  Future<void> save() async {
    await Future<void>.value();
    if (!mounted) return;
  }
}
''';
}

abstract class _RouterRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => routerSourceRules;
}

@reflectiveTest
final class RouterStringNavTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_string_nav';
  @override
  String get needle => "context.go('/home')";
  @override
  String get source => r'''
void navigate(context) {
  context.go('/home');
}
''';
}

@reflectiveTest
final class RouterPopThenPushTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_pop_then_push';
  @override
  String get needle => 'context.pop()';
  @override
  String get source => r'''
void navigate(context) {
  context.pop();
  context.push('/next');
}
''';
}

@reflectiveTest
final class RouterRedirectWatchTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_watch';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    ref.watch(provider);
    return null;
  },
);
''';
}

@reflectiveTest
final class RouterRedirectLoadingBounceTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_redirect_loading_bounce';
  @override
  String get needle => "if (isLoading) return '/loading';";
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
final router = GoRouter(
  redirect: () {
    if (isLoading) return '/loading';
    return null;
  },
);
''';
}

@reflectiveTest
final class RouterComplexExtraTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_complex_extra';
  @override
  String get needle => r'this.$extra';
  @override
  String get source => r'''
class Workout {}

class ActiveWorkoutRoute extends GoRouteData {
  const ActiveWorkoutRoute({this.$extra});

  final Workout? $extra;
}
''';

  @override
  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, r'$extra});', ruleName),
      compatLint(analyzedSource, r'$extra;', ruleName),
    ]);
  }

  Future<void> test_reportsTypedRouteExtraCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(workout) {
  ActiveWorkoutRoute($extra: workout);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, r'$extra:', ruleName)]);
  }

  Future<void> test_reportsGoRouterStateExtraRead() async {
    final analyzedSource = _analyzedSource(r'''
class Workout {}

void build(context) {
  final routeWorkout = GoRouterState.of(context).extra as Workout?;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouterState.of(context).extra', ruleName),
    ]);
  }

  Future<void> test_reportsContextNavigationExtraArgument() async {
    final analyzedSource = _analyzedSource(r'''
void open(context, workout) {
  context.push('/active_workout', extra: workout);
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'extra: workout', ruleName),
    ]);
  }

  Future<void> test_allowsTypedRouteWithoutExtra() async {
    await assertAllows(r'''
class ActiveWorkoutRoute extends GoRouteData {
  const ActiveWorkoutRoute();
}

void open(context) {
  const ActiveWorkoutRoute().push<void>(context);
}
''');
  }

  Future<void> test_allowsTestFixtureExtraRead() async {
    await assertAllows(r'''
void build(state) {
  final text = state.extra == null ? 'active:no-extra' : 'active:has-extra';
}
''', path: '$testPackageRootPath/test/features/home/home_screen_auto_resume_test.dart');
  }

  Future<void> test_allowsUnrelatedNamedExtraArgument() async {
    await assertAllows(r'''
class DetailPanel {
  const DetailPanel({required this.extra});

  final Object extra;
}

void build(value) {
  DetailPanel(extra: value);
}
''');
  }
}

@reflectiveTest
final class RouterGoRouterOfTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_gorouter_of';
  @override
  String get needle => 'GoRouter.of(context).push';
  @override
  String get source => r'''
void open(context) {
  GoRouter.of(context).push('/detail');
}
''';

  Future<void> test_reportsGoCall() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).go('/home');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).go', ruleName),
    ]);
  }

  Future<void> test_reportsPushNamed() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).pushNamed('detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).pushNamed', ruleName),
    ]);
  }

  Future<void> test_reportsTypedGenericPush() async {
    final analyzedSource = _analyzedSource(r'''
void open(context) {
  GoRouter.of(context).push<bool>('/detail');
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'GoRouter.of(context).push', ruleName),
    ]);
  }

  Future<void> test_allowsTypedRoutePush() async {
    await assertAllows(r'''
class ActiveWorkoutRoute {
  const ActiveWorkoutRoute();
  Future<T?> push<T>(context) async => null;
}

void open(context) {
  const ActiveWorkoutRoute().push<void>(context);
}
''');
  }
}

@reflectiveTest
final class RouterUntypedNavigatorPushTest extends _RouterRuleTest {
  @override
  String get ruleName => 'router_untyped_navigator_push';
  @override
  String get needle => 'Navigator.of(context).push';
  @override
  String get source => r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
  Future<T?> pushReplacement<T>(Object route) async => null;
  Future<T?> pushAndRemoveUntil<T>(Object route, Object predicate) async => null;
  void pop() {}
}

class MaterialPageRoute {
  MaterialPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => null));
}
''';

  Future<void> test_reportsCupertinoPageRoute() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
}

class CupertinoPageRoute {
  CupertinoPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).push(CupertinoPageRoute(builder: (_) => null));
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).push', ruleName),
    ]);
  }

  Future<void> test_reportsPageRouteBuilder() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> push<T>(Object route) async => null;
}

class PageRouteBuilder {
  PageRouteBuilder({required Object pageBuilder});
}

void open(context) {
  Navigator.of(context).push(PageRouteBuilder(pageBuilder: (_, __, ___) => null));
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).push', ruleName),
    ]);
  }

  Future<void> test_reportsPushReplacement() async {
    final analyzedSource = _analyzedSource(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  Future<T?> pushReplacement<T>(Object route) async => null;
}

class MaterialPageRoute {
  MaterialPageRoute({required Object builder});
}

void open(context) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => null),
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Navigator.of(context).pushReplacement', ruleName),
    ]);
  }

  Future<void> test_allowsNavigatorPop() async {
    await assertAllows(r'''
class Navigator {
  static Navigator of(Object context) => Navigator();
  void pop() {}
}

void close(context) {
  Navigator.of(context).pop();
}
''');
  }

  Future<void> test_allowsTypedRoutePush() async {
    await assertAllows(r'''
class ActiveWorkoutRoute {
  const ActiveWorkoutRoute();
  Future<T?> push<T>(Object context) async => null;
}

void open(context) {
  const ActiveWorkoutRoute().push<void>(context);
}
''');
  }
}

abstract class _ShowcaseRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => showcaseSourceRules;
}

@reflectiveTest
final class ShowcaseListenManualHandleTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_listen_manual_handle';
  @override
  String get needle => 'ref.listenManual';
  @override
  String get source => 'void f(ref, provider) { ref.listenManual(provider, (prev, next) {}); }';
}

@reflectiveTest
final class ShowcasePrevNullGuardTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_prev_null_guard';
  @override
  String get needle => 'prev != null';
  @override
  String get source => r'''
void f(prev, showcase) {
  if (prev != null) {
    showcase.start();
  }
}
''';
}

@reflectiveTest
final class ShowcaseDefaultScopeTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_default_scope';
  @override
  String get needle => 'ShowcaseView.register';
  @override
  String get source => 'void f() { ShowcaseView.register(); }';
}

@reflectiveTest
final class ShowcaseDisposeOnTapTest extends _ShowcaseRuleTest {
  @override
  String get ruleName => 'showcase_dispose_on_tap';
  @override
  String get needle => 'disposeOnTap: true';
  @override
  String get source => 'final showcase = Showcase(disposeOnTap: true);';
}

abstract class _NotifierRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => notifierSourceRules;
}

abstract class _NotifierFixtureTest extends _NotifierRuleTest {
  @override
  String get needle => 'void updateTodo';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
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
''';
}

@reflectiveTest
final class NotifierEnsureDepsTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_ensure_deps';
}

@reflectiveTest
final class NotifierWatchMethodTest extends _NotifierFixtureTest {
  @override
  String get ruleName => 'notifier_watch_method';
}

abstract class _ServicesMixinsRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesMixinsSourceRules;
}

@reflectiveTest
final class ServiceSingletonTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'service_singleton';
  @override
  String get needle => 'static final instance';
  @override
  String get source => 'class UserService { static final instance = UserService(); }';
}

@reflectiveTest
final class MixinMixinClassTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_mixin_class';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinNameSuffixTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_name_suffix';
  @override
  String get needle => 'mixin class Trackable';
  @override
  String get source => 'mixin class Trackable {}';
}

@reflectiveTest
final class MixinMutableStateTest extends _ServicesMixinsRuleTest {
  @override
  String get ruleName => 'mixin_mutable_state';
  @override
  String get needle => 'var count = 0';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
mixin class Trackable {
  var count = 0;
}
''';

  Future<void> test_allowsPrivateLifecycleFieldsInConsumerStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/showcase_screen_mixin.dart';
    newFile(filePath, r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}
class ConsumerStatefulWidget extends StatefulWidget {}
class ConsumerState<T extends ConsumerStatefulWidget> extends State<T> {}

mixin ShowcaseScreenMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool _hasAttemptedTour = false;
  bool _needsShowcaseRetry = false;
  bool _dependenciesInitialised = false;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsPublicMutableFieldInStateMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/scroll_mixin.dart';
    const source = r'''
class StatefulWidget {}
class State<T extends StatefulWidget> {}

mixin ScrollMixin<T extends StatefulWidget> on State<T> {
  bool isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool isReady = false', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_reportsPrivateMutableFieldInUnconstrainedMixin() async {
    final filePath = '$testPackageLibPath/core/mixins/cache_mixin.dart';
    const source = r'''
mixin CacheMixin {
  bool _isReady = false;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'bool _isReady = false', ruleName, lineStart: true),
    ]);
  }
}

abstract class _DataCrashRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => dataCrashSourceRules;
}

@reflectiveTest
final class DataLogRethrowTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'data_log_rethrow';
  @override
  String get needle => 'log(error);';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/todos/data/repositories/todo_repository.dart';
  @override
  String get source => r'''
void log(Object value) {}

void load() {
  try {
    throw Object();
  } catch (error) {
    log(error);
    rethrow;
  }
}
''';
}

@reflectiveTest
final class CrashPossiblePiiTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_possible_pii';
  @override
  String get needle => 'Crash.error(email)';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Crash {
  static void error(Object value) {}
}

final email = Object();

void recordCrash() {
  Crash.error(email);
}
''';
}

@reflectiveTest
final class CrashRunZonedGuardedLegacyTest extends _DataCrashRuleTest {
  @override
  String get ruleName => 'crash_run_zoned_guarded_legacy';
  @override
  String get needle => 'runZonedGuarded';
  @override
  String get source => r'''
void main() {
  runZonedGuarded(() {}, (error, stack) {});
}
''';

  Future<void> test_allowsNearbyLegacyContext() async {
    await assertAllows(r'''
void main() {
  // legacy bridge while older crash wiring is removed.
  runZonedGuarded(() {}, (error, stack) {});
}
''');
  }

  Future<void> test_allowsRunZonedGuardedDeclaration() async {
    await assertAllows(r'''
void runZonedGuarded(Object body, Object onError) {}
''');
  }

  Future<void> test_allowsGenericRunZonedGuardedDeclaration() async {
    await assertAllows(r'''
R? runZonedGuarded<R>(Object body, Object onError) => null;
''');
  }

  Future<void> test_allowsRunZonedGuardedInCommentAndString() async {
    await assertAllows(r'''
// runZonedGuarded(() {}, (error, stack) {});
final text = 'runZonedGuarded';
''');
  }
}

abstract class _TestRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => testSourceRules;
}

abstract class _TestFileRuleTest extends _TestRuleTest {
  @override
  String get path => '$testPackageRootPath/test/widget_test.dart';
}

@reflectiveTest
final class TestProviderContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_provider_container';
  @override
  String get needle => 'ProviderContainer()';
  @override
  String get source => 'void main() { ProviderContainer(); }';
}

@reflectiveTest
final class TestUncontrolledScopeTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_uncontrolled_scope';
  @override
  String get needle => 'ProviderScope()';
  @override
  String get source => 'void main() { ProviderScope(); }';
}

@reflectiveTest
final class TestCreateContainerTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_create_container';
  @override
  String get needle => 'createContainer()';
  @override
  String get source => 'void main() { createContainer(); }';
}

@reflectiveTest
final class TestMockConcreteTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_mock_concrete';
  @override
  String get needle => 'class MockUserRepository';
  @override
  String get source => 'class MockUserRepository extends Mock implements UserRepository {}';

  Future<void> test_allowsExternalSdkBoundaryMocks() async {
    final filePath = '$testPackageRootPath/test/helpers/appwrite_test_utils.dart';
    newFile(filePath, r'''
class Mock {}
class TablesDB {}
class Account {}
class Teams {}
class MockTablesDB extends Mock implements TablesDB {}
class MockAccount extends Mock implements Account {}
class MockTeams extends Mock implements Teams {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsExternalPluginControllerMocks() async {
    final filePath = '$testPackageRootPath/test/core/widgets/exercise_demo_sheet_test.dart';
    newFile(filePath, r'''
class Mock {}
class YoutubePlayerController {}
class YoutubePlayerValue {}
class MockYoutubePlayerController extends Mock implements YoutubePlayerController {}
class MockYoutubePlayerValue extends Mock implements YoutubePlayerValue {}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class TestPumpAndSettleTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_pump_and_settle';
  @override
  String get needle => 'pumpAndSettle()';
  @override
  String get source => 'void main(tester) { tester.pumpAndSettle(); }';

  Future<void> test_allowsExplicitDurationArgument() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main(tester) {
  tester.pumpAndSettle(const Duration(seconds: 10));
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class TestTapAtTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_tap_at';
  @override
  String get needle => 'tapAt(Object())';
  @override
  String get source => 'void main(tester) { tester.tapAt(Object()); }';
}

@reflectiveTest
final class TestInlineValueKeyTest extends _TestRuleTest {
  @override
  String get ruleName => 'test_inline_value_key';
  @override
  String get needle => "ValueKey('todo-row')";
  @override
  String get source => r'''
class ValueKey<T> {
  const ValueKey(T value);
}

void main() {
  const ValueKey('todo-row');
}
''';
}

@reflectiveTest
final class TestFirstMatchFinderTest extends _TestFileRuleTest {
  @override
  String get ruleName => 'test_first_match_finder';
  @override
  String get needle => 'find.byIcon';
  @override
  bool get lineStart => true;
  @override
  String get source => 'void main() { find.byIcon(Object()); }';

  Future<void> test_allowsIterableFirstAccess() async {
    final filePath = '$testPackageRootPath/test/widget_test.dart';
    newFile(filePath, r'''
void main() {
  final values = [1, 2, 3];
  final first = values.first;
  first.toString();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

abstract class _ValueObjectRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => valueObjectSourceRules;
}

@reflectiveTest
final class VoPublicRawConstructorTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'vo_public_raw_constructor';
  @override
  String get needle => 'const factory Distance.meters';
  @override
  String get path => '$testPackageLibPath/core/domain/values/distance.dart';
  @override
  String get source => r'''
class Distance {
  const factory Distance.meters(double value) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';

  Future<void> test_allowsPrivateRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance._meters(double value) = _Meters;
  const Distance._();
  factory Distance.fromMeters(double m) {
    assert(m >= 0);
    return Distance._meters(m);
  }
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsValidatedFactoryWithoutRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method, undefined_identifier
class Email {
  const Email._raw(this.value);
  factory Email(String input) {
    return Email._raw(input);
  }
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsRedirectOutsideValueObjectsPath() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const factory User.empty(double placeholder) = _User;
  const User._();
}
class _User extends User {
  const _User(this.placeholder) : super._();
  final double placeholder;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsParameterlessPublicRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
class Distance {
  const factory Distance.zero() = _DistanceZero;
  const Distance._();
}
class _DistanceZero extends Distance {
  const _DistanceZero() : super._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsAnonymousPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email(String value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email(String value) = _Email;', ruleName),
    ]);
  }

  Future<void> test_reportsNullablePrimitiveParam() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email.raw(String? value) = _Email;
  const Email._();
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String? value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Email.raw(String? value) = _Email;', ruleName),
    ]);
  }

  Future<void> test_reportsMultiParamPublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/money.dart';
    const source = r'''
// ignore_for_file: undefined_method, undefined_class
class Money {
  const factory Money.usd(int cents, Currency currency) = _UsdMoney;
  const Money._();
}
class _UsdMoney extends Money {
  const _UsdMoney(this.cents, this.currency) : super._();
  final int cents;
  final Currency currency;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        source,
        'const factory Money.usd(int cents, Currency currency) = _UsdMoney;',
        ruleName,
      ),
    ]);
  }

  Future<void> test_reportsPassthroughPublicFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight_adjustment.dart';
    const source = r'''
// ignore_for_file: undefined_method
class WeightAdjustment {
  const factory WeightAdjustment._kilograms(double value) = _Kg;
  const WeightAdjustment._();
  factory WeightAdjustment.kilograms(double value) => WeightAdjustment._kilograms(value);
}
class _Kg extends WeightAdjustment {
  const _Kg(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'factory WeightAdjustment.kilograms', ruleName),
    ]);
  }

  Future<void> test_allowsValidatedFactoryWithAssert() async {
    final filePath = '$testPackageLibPath/core/domain/values/weight.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Weight {
  const factory Weight._kilograms(double value) = _Kg;
  const Weight._();
  factory Weight.kilograms(double value) {
    assert(value >= 0, 'Weight cannot be negative');
    return Weight._kilograms(value);
  }
}
class _Kg extends Weight {
  const _Kg(this.value) : super._();
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsTransformingFactory() async {
    final filePath = '$testPackageLibPath/core/domain/values/email.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class Email {
  const factory Email._raw(String value) = _Email;
  const Email._();
  factory Email(String input) => Email._raw(input.trim());
}
class _Email extends Email {
  const _Email(this.value) : super._();
  final String value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsMultiLinePublicRawRedirect() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const source = r'''
// ignore_for_file: undefined_method
class Distance {
  const factory Distance.meters(
    double value,
  ) = _Meters;
  const Distance._();
}
class _Meters extends Distance {
  const _Meters(this.value) : super._();
  final double value;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'const factory Distance.meters(', ruleName),
    ]);
  }
}

@reflectiveTest
final class DomainEntityPrimitiveFactoryTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'domain_entity_primitive_factory';
  @override
  String get needle => 'factory User.fromPrimitives';
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
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User.fromPrimitives(String id, int age) => User(id: id);
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''';

  Future<void> test_allowsAnonymousFreezedRedirect() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNamedFactoryInValueObjectsPath() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Distance {
  factory Distance.fromMeters(double m) {
    return _Meters(m);
  }
}
class _Meters implements Distance {
  const _Meters(this.value);
  final double value;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNamedFactoryInDataPath() async {
    final filePath = '$testPackageLibPath/features/users/data/models/user_model.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class UserModel {
  const factory UserModel({required String id}) = _UserModel;
  factory UserModel.fromPrimitives(String id) => UserModel(id: id);
}
class _UserModel implements UserModel {
  const _UserModel({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsPrivateNamedFactory() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User._fromInternal(String id) => User(id: id);
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsClassWithoutFreezedAnnotation() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User._();
  factory User.fromPrimitives(String id) => const User._();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsFromJsonFactoryInDomain() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_method, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  factory User.fromJson(Map<String, Object?> json) => const _User();
}
class _User implements User {
  const _User({this.id = ''});
  final String id;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsConstFactoryNamedVariant() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, redirect_to_invalid_function_type
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {
  const factory User({required String id}) = _User;
  const factory User.empty(String placeholder) = _EmptyUser;
}
class _User implements User {
  const _User({required this.id});
  final String id;
}
class _EmptyUser implements User {
  const _EmptyUser(this.placeholder);
  final String placeholder;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'factory User.empty', ruleName)]);
  }
}

@reflectiveTest
final class DomainCustomCopyWithTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'domain_custom_copy_with';
  @override
  String get needle => 'copyWith';
  @override
  String get path => '$testPackageLibPath/features/users/domain/user.dart';
  @override
  String get source => r'''
class User {
  const User({required this.id});
  final String id;
  User copyWith({String? id}) => User(id: id ?? this.id);
}
''';

  Future<void> test_allowsCopyWithCallSite() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_method
class User {
  const User({required this.id});
  final String id;
}

void use(User u) {
  final next = u.copyWith();
  next.toString();
}

extension on User {
  User copyAgain() => this;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithOutsideDomain() async {
    final filePath = '$testPackageLibPath/features/users/presentation/user_state.dart';
    newFile(filePath, r'''
class UserState {
  const UserState({required this.id});
  final String id;
  UserState copyWith({String? id}) => UserState(id: id ?? this.id);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithCommentInDomain() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User({required this.id});
  final String id;
  // Note: Freezed generates copyWith automatically; do not declare manually.
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsCopyWithInGeneratedMixin() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
// ignore_for_file: undefined_class, undefined_method
mixin _$User {
  User copyWith({String? id}) => throw UnimplementedError();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsGenericCopyWith() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
class User {
  const User({required this.id});
  final String id;
  User copyWith<T>({String? id}) => User(id: id ?? this.id);
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'copyWith<T>', ruleName)]);
  }

  Future<void> test_reportsAbstractCopyWithSignature() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    const source = r'''
abstract class User {
  const User();
  User copyWith({String? id});
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'copyWith({String? id})', ruleName),
    ]);
  }

  Future<void> test_allowsCopyWithInExtensionOutsideClass() async {
    final filePath = '$testPackageLibPath/features/users/domain/user.dart';
    newFile(filePath, r'''
class User {
  const User({required this.id});
  final String id;
}

extension UserCopy on User {
  User copyWith({String? id}) => User(id: id ?? this.id);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

@reflectiveTest
final class FreezedDisableMapWhenRequiredTest extends _ValueObjectRuleTest {
  @override
  String get ruleName => 'freezed_disable_map_when_required';
  @override
  String get needle => 'sealed class Distance';
  @override
  String get path => '$testPackageLibPath/core/domain/values/distance.dart';
  @override
  bool get addIgnorePrefix => false;

  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed({Object? map, Object? when});
}
class FreezedMapOptions {
  static const Object none = Object();
}
class FreezedWhenOptions {
  static const Object none = Object();
}
const freezed = Freezed();
''');
    super.setUp();
  }

  @override
  String get source => r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';

  Future<void> test_allowsFullOptOut() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsPartialOptOutMissingWhen() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const partialSource = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(map: FreezedMapOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';
    newFile(filePath, partialSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(partialSource, 'sealed class Distance', ruleName),
    ]);
  }

  Future<void> test_reportsPartialOptOutMissingMap() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    const partialSource = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(when: FreezedWhenOptions.none)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''';
    newFile(filePath, partialSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(partialSource, 'sealed class Distance', ruleName),
    ]);
  }

  Future<void> test_allowsNonSealedFreezedClass() async {
    final filePath = '$testPackageLibPath/core/domain/values/money.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class Money with _$Money {
  const Money._();
  const factory Money({required int cents}) = _Money;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsOutsideValueObjectsPath() async {
    final filePath = '$testPackageLibPath/features/users/domain/entities/user.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User with _$User {
  const User._();
  const factory User({required String id}) = _User;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsMultilineFullOptOut() async {
    final filePath = '$testPackageLibPath/core/domain/values/distance.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, mixin_of_non_class, redirect_to_non_class, extends_non_class
import 'package:freezed_annotation/freezed_annotation.dart';

@Freezed(
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
sealed class Distance with _$Distance {
  const Distance._();
  const factory Distance._meters(double value) = _Meters;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_allowsNoFreezedAnnotation() async {
    final filePath = '$testPackageLibPath/core/domain/values/state.dart';
    newFile(filePath, r'''
sealed class AppState {
  const AppState();
}
class IdleState extends AppState {
  const IdleState();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}

abstract class _HivePersistenceRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => hivePersistenceSourceRules;
}

@reflectiveTest
final class HiveFieldNoVoTypeTest extends _HivePersistenceRuleTest {
  @override
  String get ruleName => 'hive_field_no_vo_type';
  @override
  String get needle => 'Distance distance';
  @override
  String get path => '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
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
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSetModel {
  const factory WorkoutSetModel({
    required String id,
    required Distance distance,
  }) = _WorkoutSetModel;
}
class _WorkoutSetModel implements WorkoutSetModel {
  const _WorkoutSetModel({required this.id, required this.distance});
  final String id;
  final Distance distance;
}
''';

  Future<void> test_allowsPrimitiveTypedParams() async {
    final filePath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSetModel {
  const factory WorkoutSetModel({
    /// HiveField(0)
    required String id,
    /// HiveField(1)
    required double distanceMeters,
    /// HiveField(2)
    required int durationSeconds,
  }) = _WorkoutSetModel;
}
class _WorkoutSetModel implements WorkoutSetModel {
  const _WorkoutSetModel({required this.id, required this.distanceMeters, required this.durationSeconds});
  final String id;
  final double distanceMeters;
  final int durationSeconds;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsImportedVoNotInBaselineList() async {
    final filePath = '$testPackageLibPath/features/cycling/data/models/ride_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test_package/features/cycling/domain/values/cadence.dart';

@freezed
sealed class RideModel {
  const factory RideModel({required Cadence cadence}) = _RideModel;
}
class _RideModel implements RideModel {
  const _RideModel({required this.cadence});
  final Cadence cadence;
}
''';
    newFile('$testPackageLibPath/features/cycling/domain/values/cadence.dart', r'''
class Cadence {
  const Cadence._(this.rpm);
  final int rpm;
}
''');
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Cadence cadence', 'hive_field_no_vo_type'),
    ]);
  }

  Future<void> test_allowsVoTypeOutsideDataModelsPath() async {
    final filePath = '$testPackageLibPath/features/workouts/domain/entities/workout_set.dart';
    newFile(filePath, r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSet {
  const factory WorkoutSet({
    required String id,
    required Distance distance,
  }) = _WorkoutSet;
}
class _WorkoutSet implements WorkoutSet {
  const _WorkoutSet({required this.id, required this.distance});
  final String id;
  final Distance distance;
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsNullableVoParam() async {
    final filePath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSetModel {
  const factory WorkoutSetModel({
    required String id,
    Distance? distance,
  }) = _WorkoutSetModel;
}
class _WorkoutSetModel implements WorkoutSetModel {
  const _WorkoutSetModel({required this.id, this.distance});
  final String id;
  final Distance? distance;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Distance? distance', ruleName)]);
  }

  Future<void> test_reportsVoInsideListGeneric() async {
    final filePath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, non_type_as_type_argument
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSetModel {
  const factory WorkoutSetModel({
    required List<Distance> distances,
  }) = _WorkoutSetModel;
}
class _WorkoutSetModel implements WorkoutSetModel {
  const _WorkoutSetModel({required this.distances});
  final List distances;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Distance> distances', ruleName)]);
  }

  Future<void> test_reportsVoInsideMapGeneric() async {
    final filePath = '$testPackageLibPath/features/workouts/data/models/workout_set_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class, non_type_as_type_argument
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class WorkoutSetModel {
  const factory WorkoutSetModel({
    required Map<String, Money> totals,
  }) = _WorkoutSetModel;
}
class _WorkoutSetModel implements WorkoutSetModel {
  const _WorkoutSetModel({required this.totals});
  final Map totals;
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [compatLint(source, 'Money> totals', ruleName)]);
  }

  Future<void> test_reportsMultiVoFromShowClause() async {
    final filePath = '$testPackageLibPath/features/cycling/data/models/ride_model.dart';
    const source = r'''
// ignore_for_file: uri_does_not_exist, unused_import, undefined_class
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test_package/features/cycling/domain/values/units.dart' show Cadence, Tempo;

@freezed
sealed class RideModel {
  const factory RideModel({
    required Cadence cadence,
    required Tempo tempo,
  }) = _RideModel;
}
class _RideModel implements RideModel {
  const _RideModel({required this.cadence, required this.tempo});
  final Cadence cadence;
  final Tempo tempo;
}
''';
    newFile('$testPackageLibPath/features/cycling/domain/values/units.dart', r'''
class Cadence { const Cadence._(this.rpm); final int rpm; }
class Tempo { const Tempo._(this.bpm); final int bpm; }
''');
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      compatLint(source, 'Cadence cadence', ruleName),
      compatLint(source, 'Tempo tempo', ruleName),
    ]);
  }
}
