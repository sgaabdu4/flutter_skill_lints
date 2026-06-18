// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RiverpodEventCounterSignalForbiddenTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_event_counter_signal_forbidden';
  @override
  String get needle => 'class ChartShareSuccessSignal';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$ChartShareSuccessSignal {
  int state = 0;
  int build() => 0;
}

@riverpod
class ChartShareSuccessSignal extends _$ChartShareSuccessSignal {
  @override
  int build() => 0;

  void notify() => state++;
}
''';

  Future<void> test_reportsStatePlusOneVariant() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$SaveSuccessEvent {
  int state = 0;
  int build() => 0;
}

@riverpod
class SaveSuccessEvent extends _$SaveSuccessEvent {
  @override
  int build() => 0;

  void notify() {
    state = state + 1;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'class SaveSuccessEvent', ruleName),
    ]);
  }

  Future<void> test_reportsPayloadSignalProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$CreatedExerciseSignal {
  String? state;
  String? build() => null;
}

@riverpod
class CreatedExerciseSignal extends _$CreatedExerciseSignal {
  @override
  String? build() => null;

  void notify(String exerciseId) => state = exerciseId;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'class CreatedExerciseSignal', ruleName),
    ]);
  }

  Future<void> test_reportsFunctionEventProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@Riverpod(keepAlive: true)
Stream<String> notificationTapEvents(Ref ref) => Stream<String>.fromIterable(const <String>[]);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'notificationTapEvents', ruleName),
    ]);
  }

  Future<void> test_allowsPayloadStreamName() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@Riverpod(keepAlive: true)
Stream<String> notificationTapPayloads(Ref ref) => Stream<String>.fromIterable(const <String>[]);
''');
  }

  Future<void> test_allowsOwningNotifierStateSerial() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

final class ChartShareState {
  const ChartShareState({required this.isSharing, required this.successSerial});

  final bool isSharing;
  final int successSerial;

  ChartShareState markShared() =>
      ChartShareState(isSharing: false, successSerial: successSerial + 1);
}

class _$ChartShareNotifier {
  ChartShareState state = const ChartShareState(isSharing: false, successSerial: 0);
  ChartShareState build() => state;
}

@riverpod
class ChartShareNotifier extends _$ChartShareNotifier {
  @override
  ChartShareState build() => const ChartShareState(isSharing: false, successSerial: 0);

  void markShared() {
    state = state.markShared();
  }
}
''');
  }

  Future<void> test_allowsDomainCounterNotifier() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$RetryCounter {
  int state = 0;
  int build() => 0;
}

@riverpod
class RetryCounter extends _$RetryCounter {
  @override
  int build() => 0;

  void increment() => state++;
}
''');
  }

  Future<void> test_allowsDurableStatusNotifier() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

enum InitialSyncStatus { idle, syncing, complete, failed }

class _$InitialSyncStatusNotifier {
  InitialSyncStatus state = InitialSyncStatus.idle;
  InitialSyncStatus build() => InitialSyncStatus.idle;
}

@riverpod
class InitialSyncStatusNotifier extends _$InitialSyncStatusNotifier {
  @override
  InitialSyncStatus build() => InitialSyncStatus.idle;

  void markSyncing() => state = InitialSyncStatus.syncing;
}
''');
  }
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
final itemByIdProvider = ItemFamily();

class ProviderArg<T> {
  Object select(Object Function(T? value) selector) => Object();
}

class Item {
  const Item(this.name);

  final String name;
}

class ItemFamily {
  ProviderArg<Item> call(String id) => ProviderArg<Item>();
}

class ItemConfig {
  const ItemConfig(this.itemId);

  final String itemId;
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TodoList {
  Object build(ItemConfig config) {
    final ref = WidgetRef();
    final isNewItem = ref.watch(
      itemByIdProvider(config.itemId).select((w) => w?.name.isEmpty ?? true),
    );
    return isNewItem;
  }
}
''');
  }

  Future<void> test_allowsDirectWatchOfComputedProjectionProvider() async {
    await assertAllows(r'''
final trainerCardSummaryProvider = Object();
final workoutLogGroupedSetEntriesProvider = Object();
final activeWorkoutSetsForExerciseProvider = FamilyProvider();
final activeWorkoutCompletedSetCountForExerciseProvider = FamilyProvider();
final goRouterProvider = Object();
final weightUnitProvider = Object();

class FamilyProvider {
  Object call(String id) => Object();
}

class WidgetRef {
  Object watch(Object provider) => Object();
}

class TrainerCard {
  Object build() {
    final ref = WidgetRef();
    final summary = ref.watch(trainerCardSummaryProvider);
    final entries = ref.watch(workoutLogGroupedSetEntriesProvider);
    final sets = ref.watch(activeWorkoutSetsForExerciseProvider('exercise-1'));
    final count = ref.watch(activeWorkoutCompletedSetCountForExerciseProvider('exercise-1'));
    final router = ref.watch(goRouterProvider);
    final unit = ref.watch(weightUnitProvider);
    return (summary, entries, sets, count, router, unit);
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
