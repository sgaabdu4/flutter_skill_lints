// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RiverpodSelectIdentityForbiddenTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_select_identity_forbidden';
  @override
  String get needle => '.select((todo) => todo)';
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
    return ref.watch(provider.select((todo) => todo));
  }
}
''';

  Future<void> test_allowsFieldSelect() async {
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

  Future<void> test_allowsRecordSelect() async {
    await assertAllows(r'''
class ProviderArg<T> {
  Object select(Object Function(T value) selector) => Object();
}

class Todo {
  const Todo(this.title, this.done);

  final String title;
  final bool done;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

final provider = ProviderArg<Todo>();

class TodoTitle {
  Object build() {
    final ref = WidgetRef();
    return ref.watch(provider.select((todo) => (title: todo.title, done: todo.done)));
  }
}
''');
  }

  Future<void> test_allowsNonRiverpodIdentitySelectApi() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

final query = Query<int>();

final selected = query.select((value) => value);
''');
  }

  Future<void> test_reportsTypedIdentitySelect() async {
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
    return ref.watch(provider.select((Todo todo) => todo));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '.select((Todo todo) => todo)', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineIdentitySelect() async {
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
        (todo) => todo,
      ),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.select', ruleName)]);
  }
}

const _riverpodMutationStub = r'''
abstract class ProviderListenable<T> {}
sealed class MutationState<T> {}
final class MutationTransaction {
  T get<T>(ProviderListenable<T> listenable) => throw 'synthetic';
}
abstract class MutationTarget {}
final class Mutation<T> implements ProviderListenable<MutationState<T>> {
  Future<T> run(MutationTarget target, Future<T> Function(MutationTransaction tsx) cb) =>
      throw 'synthetic';
}
abstract class Ref implements MutationTarget {
  T read<T>(ProviderListenable<T> listenable) => throw 'synthetic';
}
''';

abstract class _RiverpodMutationRuleTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _riverpodMutationStub);
    super.setUp();
  }
}

@reflectiveTest
final class RiverpodMutationExperimentalWarningTest extends _RiverpodMutationRuleTest {
  @override
  String get ruleName => 'riverpod_mutation_experimental_warning';
  @override
  String get needle => 'Mutation<void>()';
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/screens/add_todo_screen.dart';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

final removeTodoMutation = Mutation<void>();
''';

  Future<void> test_allowsDocumentedTrailingExperimentalNote() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
''', path: path);
  }

  Future<void> test_allowsLeadingExperimentalNote() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

// Mutation is experimental in Riverpod 3.
final addTodoMutation = Mutation<void>();
''', path: path);
  }

  Future<void> test_reportsMutationBesideNeighbourExperimentalNote() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
final removeTodoMutation = Mutation<int>();
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'Mutation<int>()', ruleName)]);
  }

  Future<void> test_allowsLocalMutationLookalike() async {
    await assertAllows(r'''
class Mutation<T> {
  const Mutation();
}

final widget = Mutation<int>();
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
}

@reflectiveTest
final class RiverpodMutationTopLevelTest extends _RiverpodMutationRuleTest {
  @override
  String get ruleName => 'riverpod_mutation_top_level';
  @override
  String get needle => 'Mutation<void>()';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

class AddTodoScreen {
  Object build() {
    final localMutation = Mutation<void>();
    return localMutation;
  }
}
''';

  Future<void> test_allowsDocumentedFileScopeFinal() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
''');
  }

  Future<void> test_reportsStaticClassField() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodoMutations {
  static final addTodo = Mutation<void>();
}
''';
    await assertDiagnostics(source, [compatLint(source, needle, ruleName)]);
  }

  Future<void> test_reportsNonFinalTopLevel() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

var addTodoMutation = Mutation<void>();
''';
    await assertDiagnostics(source, [compatLint(source, needle, ruleName)]);
  }

  Future<void> test_allowsLocalMutationLookalike() async {
    await assertAllows(r'''
class Mutation<T> {}

Object build() {
  final localMutation = Mutation<void>();
  return localMutation;
}
''');
  }
}

@reflectiveTest
final class RiverpodMutationRefReadTest extends _RiverpodMutationRuleTest {
  @override
  String get ruleName => 'riverpod_mutation_ref_read';
  @override
  String get needle => 'ref.read(todoListProvider)';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

final todoListProvider = _Listenable();
final class _Listenable implements ProviderListenable<Object> {}
final removeTodoMutation = Mutation<void>();

void onPressed(Ref ref) {
  removeTodoMutation.run(ref, (tsx) async {
    ref.read(todoListProvider);
  });
}
''';

  Future<void> test_allowsDocumentedTransactionGet() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final todoListProvider = _Listenable();
final class _Listenable implements ProviderListenable<Object> {}
final addTodoMutation = Mutation<void>();

void onPressed(Ref ref) {
  addTodoMutation.run(ref, (tsx) async {
    tsx.get(todoListProvider);
  });
}
''');
  }

  Future<void> test_allowsRefReadOutsideMutationCallback() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final todoListProvider = _Listenable();
final class _Listenable implements ProviderListenable<Object> {}
final addTodoMutation = Mutation<void>();

void onPressed(Ref ref) {
  ref.read(todoListProvider);
  addTodoMutation.run(ref, (tsx) async {});
}
''');
  }

  Future<void> test_allowsReadInLookalikeRun() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final todoListProvider = _Listenable();
final class _Listenable implements ProviderListenable<Object> {}
class Job {
  Future<void> run(Object target, Future<void> Function(Object tsx) cb) => cb(target);
}
final job = Job();

void onPressed(Ref ref) {
  job.run(ref, (tsx) async {
    ref.read(todoListProvider);
  });
}
''');
  }
}

const _asyncValueDispatchStub = r'''
sealed class AsyncValue<T> {}
final class AsyncData<T> extends AsyncValue<T> {
  AsyncData(this.value);
  final T value;
}
final class AsyncError<T> extends AsyncValue<T> {
  AsyncError(this.error);
  final Object error;
}
final class AsyncLoading<T> extends AsyncValue<T> {}
extension AsyncValueExtensions<T> on AsyncValue<T> {
  R when<R>({
    required R Function(T value) data,
    required R Function() loading,
    required R Function(Object error) error,
  }) => throw StateError('synthetic');
  R maybeWhen<R>({R Function(T value)? data, required R Function() orElse}) =>
      throw StateError('synthetic');
  R? whenOrNull<R>({R Function(T value)? data}) => throw StateError('synthetic');
  R map<R>({required R Function(AsyncData<T> data) data}) => throw StateError('synthetic');
  R maybeMap<R>({R Function(AsyncData<T> data)? data, required R Function() orElse}) =>
      throw StateError('synthetic');
  R? mapOrNull<R>({R Function(AsyncData<T> data)? data}) => throw StateError('synthetic');
  AsyncValue<R> whenData<R>(R Function(T value) cb) => throw StateError('synthetic');
}
''';

/// freezed-sealed.md:9 matches unions with `switch`, never `.when()`/`.map()`;
/// Riverpod AsyncValue is sealed (freezed-sealed.md:136-146).
@reflectiveTest
final class AsyncValueSwitchOverWhenTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _asyncValueDispatchStub);
    super.setUp();
  }

  @override
  String get ruleName => 'async_value_switch_over_when';
  @override
  String get needle => 'when(';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

String label(AsyncValue<int> result) => result.when(
  data: (value) => '$value',
  loading: () => 'loading',
  error: (error) => 'error',
);
''';

  Future<void> test_reportsEveryWhenAndMapHelper() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class ResultView {
  Object build(AsyncValue<int> result) => [
    result.maybeWhen(orElse: () => 0),
    result.whenOrNull(data: (value) => value),
    result.map(data: (data) => data.value),
    result.maybeMap(orElse: () => 0),
    result.mapOrNull(data: (data) => data.value),
  ];
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      for (final helper in const ['maybeWhen(', 'whenOrNull(', 'map(', 'maybeMap(', 'mapOrNull('])
        compatLint(analyzedSource, helper, ruleName),
    ]);
  }

  Future<void> test_allowsSkillSealedSwitchAndWhenData() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class ResultView {
  Object build(AsyncValue<int> result) => (
    switch (result) {
      AsyncData(:final value) => '$value',
      AsyncError(:final error) => 'Error: $error',
      AsyncLoading() => 'loading',
    },
    result.whenData((value) => value + 1),
  );
}
''');
  }

  Future<void> test_allowsSameNamedLocalAsyncValue() async {
    await assertAllows(r'''
class AsyncValue<T> {
  R when<R>({required R Function(T value) data}) => throw StateError('synthetic');
  R map<R>(R Function(T value) cb) => throw StateError('synthetic');
}

Object label(AsyncValue<int> result) => (
  result.when(data: (value) => value),
  result.map((value) => value),
);
''');
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
Object activeItem(Ref ref) => Object();

@Riverpod(keepAlive: true)
Object exercises(Ref ref) => Object();

@riverpod
Object itemSummary(Ref ref) {
  ref.watch(activeItemProvider);
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
Object activeItem(Ref ref) => Object();

@riverpod
class ItemSummaryNotifier {
  Object build() {
    ref.watch(activeItemProvider);
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
Object activeItem(Ref ref) => Object();

@Riverpod(keepAlive: true)
Object itemSummary(Ref ref) {
  ref.watch(activeItemProvider);
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
Object activeItem(Ref ref) => Object();

@riverpod
Object transientSelection(Ref ref) => Object();

@riverpod
Object itemSummary(Ref ref) {
  ref.watch(activeItemProvider);
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
Object itemSummary(Ref ref) {
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
Object activeItem(Ref ref) => Object();

@riverpod
Object itemSummary(Ref ref, String itemId) {
  ref.watch(activeItemProvider);
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
Object activeItem(Ref ref) => Object();

@riverpod
class ItemSummaryNotifier {
  Object build(String itemId) {
    ref.watch(activeItemProvider);
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
Object activeItem(Ref ref) => Object();

@riverpod
Object itemSummary(Ref ref) {
  ref.read(activeItemProvider);
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
    await assertAllows(r'''
const riverpod = Object();

@riverpod
class ItemEditorNotifier {
  Object build(String itemId) => Object();
}
''', path: '$testPackageLibPath/features/items/presentation/notifiers/item_editor_notifier.dart');
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
    await assertAllows(r'''
const riverpod = Object();

// autoDispose: route-local draft should reset when the editor closes.
@riverpod
class ItemDraftNotifier {
  Object build() => Object();
}
''', path: '$testPackageLibPath/features/items/presentation/notifiers/item_draft_notifier.dart');
  }

  Future<void> test_allowsLifecycleCleanupNotifier() async {
    await assertAllows(
      r'''
const riverpod = Object();

class Ref {
  void onDispose(Object callback) {}
}

@riverpod
class EntryTimerNotifier {
  final ref = Ref();

  Object build() {
    ref.onDispose(() {});
    return Object();
  }
}
''',
      path:
          '$testPackageLibPath/features/active_item/presentation/notifiers/entry_timer_notifier.dart',
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
