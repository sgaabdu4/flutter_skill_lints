part of '../source_scanner_rules_test.dart';

final class _RiverpodSelectIdentityForbiddenTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodSelectIdentityForbiddenTest)> get _allCases =>
      caseSet<_RiverpodSelectIdentityForbiddenTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsFieldSelect': (t) => t._allowsFieldSelect(),
          'test_allowsRecordSelect': (t) => t._allowsRecordSelect(),
          'test_allowsNonRiverpodIdentitySelectApi': (t) => t._allowsNonRiverpodIdentitySelectApi(),
          'test_reportsTypedIdentitySelect': (t) => t._reportsTypedIdentitySelect(),
          'test_reportsMultilineIdentitySelect': (t) => t._reportsMultilineIdentitySelect(),
        },
      );

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

  Future<void> _allowsFieldSelect() async {
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

  Future<void> _allowsRecordSelect() async {
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

  Future<void> _allowsNonRiverpodIdentitySelectApi() async {
    await assertAllows(r'''
class Query<T> {
  Object select(Object Function(T value) selector) => Object();
}

final query = Query<int>();

final selected = query.select((value) => value);
''');
  }

  Future<void> _reportsTypedIdentitySelect() async {
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

  Future<void> _reportsMultilineIdentitySelect() async {
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

final class _RiverpodMutationExperimentalWarningTest extends _RiverpodMutationRuleTest {
  static Map<String, Future<void> Function(_RiverpodMutationExperimentalWarningTest)>
  get _allCases => caseSet<_RiverpodMutationExperimentalWarningTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_allowsDocumentedTrailingExperimentalNote': (t) =>
          t._allowsDocumentedTrailingExperimentalNote(),
      'test_allowsLeadingExperimentalNote': (t) => t._allowsLeadingExperimentalNote(),
      'test_reportsMutationBesideNeighbourExperimentalNote': (t) =>
          t._reportsMutationBesideNeighbourExperimentalNote(),
      'test_allowsLocalMutationLookalike': (t) => t._allowsLocalMutationLookalike(),
      'test_allowsQualifiedNonRiverpodMutation': (t) => t._allowsQualifiedNonRiverpodMutation(),
    },
  );

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

  Future<void> _allowsDocumentedTrailingExperimentalNote() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
''', path: path);
  }

  Future<void> _allowsLeadingExperimentalNote() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

// Mutation is experimental in Riverpod 3.
final addTodoMutation = Mutation<void>();
''', path: path);
  }

  Future<void> _reportsMutationBesideNeighbourExperimentalNote() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
final removeTodoMutation = Mutation<int>();
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'Mutation<int>()', ruleName)]);
  }

  Future<void> _allowsLocalMutationLookalike() async {
    await assertAllows(r'''
class Mutation<T> {
  const Mutation();
}

final widget = Mutation<int>();
''', path: path);
  }

  Future<void> _allowsQualifiedNonRiverpodMutation() async {
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

final class _RiverpodMutationTopLevelTest extends _RiverpodMutationRuleTest {
  static Map<String, Future<void> Function(_RiverpodMutationTopLevelTest)> get _allCases =>
      caseSet<_RiverpodMutationTopLevelTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsDocumentedFileScopeFinal': (t) => t._allowsDocumentedFileScopeFinal(),
          'test_reportsStaticClassField': (t) => t._reportsStaticClassField(),
          'test_reportsNonFinalTopLevel': (t) => t._reportsNonFinalTopLevel(),
          'test_allowsLocalMutationLookalike': (t) => t._allowsLocalMutationLookalike(),
        },
      );

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

  Future<void> _allowsDocumentedFileScopeFinal() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final addTodoMutation = Mutation<void>(); // experimental API — may change without major bump
''');
  }

  Future<void> _reportsStaticClassField() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class TodoMutations {
  static final addTodo = Mutation<void>();
}
''';
    await assertDiagnostics(source, [compatLint(source, needle, ruleName)]);
  }

  Future<void> _reportsNonFinalTopLevel() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

var addTodoMutation = Mutation<void>();
''';
    await assertDiagnostics(source, [compatLint(source, needle, ruleName)]);
  }

  Future<void> _allowsLocalMutationLookalike() async {
    await assertAllows(r'''
class Mutation<T> {}

Object build() {
  final localMutation = Mutation<void>();
  return localMutation;
}
''');
  }
}

final class _RiverpodMutationRefReadTest extends _RiverpodMutationRuleTest {
  static Map<String, Future<void> Function(_RiverpodMutationRefReadTest)> get _allCases =>
      caseSet<_RiverpodMutationRefReadTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsDocumentedTransactionGet': (t) => t._allowsDocumentedTransactionGet(),
          'test_allowsRefReadOutsideMutationCallback': (t) =>
              t._allowsRefReadOutsideMutationCallback(),
          'test_allowsReadInLookalikeRun': (t) => t._allowsReadInLookalikeRun(),
        },
      );

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

  Future<void> _allowsDocumentedTransactionGet() async {
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

  Future<void> _allowsRefReadOutsideMutationCallback() async {
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

  Future<void> _allowsReadInLookalikeRun() async {
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

/// freezed-sealed.md:9 matches unions with `switch`, never `.when()`/`.map()`; Riverpod AsyncValue is sealed (freezed-sealed.md:136-146).
final class _AsyncValueSwitchOverWhenTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_AsyncValueSwitchOverWhenTest)> get _allCases =>
      caseSet<_AsyncValueSwitchOverWhenTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsEveryWhenAndMapHelper': (t) => t._reportsEveryWhenAndMapHelper(),
          'test_allowsSkillSealedSwitchAndWhenData': (t) => t._allowsSkillSealedSwitchAndWhenData(),
          'test_allowsSameNamedLocalAsyncValue': (t) => t._allowsSameNamedLocalAsyncValue(),
        },
      );

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

  Future<void> _reportsEveryWhenAndMapHelper() async {
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

  Future<void> _allowsSkillSealedSwitchAndWhenData() async {
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

  Future<void> _allowsSameNamedLocalAsyncValue() async {
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

final class _RiverpodAutoDisposeKeepAliveDependenciesTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodAutoDisposeKeepAliveDependenciesTest)>
  get _allCases => caseSet<_RiverpodAutoDisposeKeepAliveDependenciesTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsSameFileClassNotifier': (t) => t._reportsSameFileClassNotifier(),
      'test_allowsMixedKeepAliveAndAutoDisposeDependencies': (t) =>
          t._allowsMixedKeepAliveAndAutoDisposeDependencies(),
      'test_allowsUnresolvedDependency': (t) => t._allowsUnresolvedDependency(),
      'test_allowsAlreadyKeepAlive': (t) => t._allowsAlreadyKeepAlive(),
      'test_allowsFamilyProviderTarget': (t) => t._allowsFamilyProviderTarget(),
      'test_allowsFamilyNotifierTarget': (t) => t._allowsFamilyNotifierTarget(),
      'test_allowsReadOnlyKeepAliveProviderUse': (t) => t._allowsReadOnlyKeepAliveProviderUse(),
    },
  );

  @override
  String get ruleName => 'riverpod_auto_dispose_keepalive_dependencies';
  @override
  String get needle => '@riverpod';
  @override
  bool get addIgnorePrefix => false;

  /// performance.md:169: a computed provider over keepAlive providers declared in another file (plain and `.select` watches) stays keepAlive.
  @override
  String get source => r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
int cartTotal(Ref ref) {
  final items = ref.watch(cartItemsProvider);
  final rate = ref.watch(taxRateProvider.select((rate) => rate));
  return items.length * rate;
}
''';

  @override
  void setUp() {
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
class Riverpod {
  const Riverpod({this.keepAlive = false});
  final bool keepAlive;
}
const riverpod = Riverpod();
class ProviderFor {
  const ProviderFor(this.value);
  final Object value;
}
class Ref {
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}
class ProviderListenable<T> {
  const ProviderListenable();
  ProviderListenable<R> select<R>(R Function(T value) selector) => throw UnimplementedError();
}
''');
    super.setUp();
    newFile('$testPackageLibPath/sources.dart', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(keepAlive: true)
List<int> cartItems(Ref ref) => const [];

@Riverpod(keepAlive: true)
int taxRate(Ref ref) => 2;

@riverpod
int discount(Ref ref) => 0;

@ProviderFor(cartItems)
const cartItemsProvider = ProviderListenable<List<int>>();
@ProviderFor(taxRate)
const taxRateProvider = ProviderListenable<int>();
@ProviderFor(discount)
const discountProvider = ProviderListenable<int>();
const manualProvider = ProviderListenable<int>();
''');
  }

  Future<void> _reportsSameFileClassNotifier() async {
    const source = r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(keepAlive: true)
int activeItem(Ref ref) => 0;

@ProviderFor(activeItem)
const activeItemProvider = ProviderListenable<int>();

@riverpod
class ItemSummaryNotifier {
  ItemSummaryNotifier(this.ref);
  final Ref ref;
  int build() => ref.watch(activeItemProvider);
}
''';
    await assertDiagnostics(source, [compatLint(source, '@riverpod\nclass', ruleName)]);
  }

  Future<void> _allowsMixedKeepAliveAndAutoDisposeDependencies() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
int cartTotal(Ref ref) => ref.watch(cartItemsProvider).length - ref.watch(discountProvider);
''', addIgnorePrefix: false);
  }

  Future<void> _allowsUnresolvedDependency() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
int cartTotal(Ref ref) => ref.watch(cartItemsProvider).length + ref.watch(manualProvider);
''', addIgnorePrefix: false);
  }

  Future<void> _allowsAlreadyKeepAlive() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@Riverpod(keepAlive: true)
int cartTotal(Ref ref) => ref.watch(cartItemsProvider).length;
''', addIgnorePrefix: false);
  }

  Future<void> _allowsFamilyProviderTarget() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
int cartTotal(Ref ref, int multiplier) => ref.watch(cartItemsProvider).length * multiplier;
''', addIgnorePrefix: false);
  }

  Future<void> _allowsFamilyNotifierTarget() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
class CartTotalNotifier {
  CartTotalNotifier(this.ref);
  final Ref ref;
  int build(int multiplier) => ref.watch(cartItemsProvider).length * multiplier;
}
''', addIgnorePrefix: false);
  }

  Future<void> _allowsReadOnlyKeepAliveProviderUse() async {
    await assertAllows(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'sources.dart';

@riverpod
int cartTotal(Ref ref) => ref.read(cartItemsProvider).length;
''', addIgnorePrefix: false);
  }
}

final class _RiverpodFeatureNotifierKeepaliveTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodFeatureNotifierKeepaliveTest)> get _allCases =>
      caseSet<_RiverpodFeatureNotifierKeepaliveTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsExplicitKeepAliveFalse': (t) => t._reportsExplicitKeepAliveFalse(),
          'test_allowsKeepAliveFeatureNotifier': (t) => t._allowsKeepAliveFeatureNotifier(),
          'test_allowsFamilyFeatureNotifier': (t) => t._allowsFamilyFeatureNotifier(),
          'test_allowsComputedFunctionProviderInNotifierFile': (t) =>
              t._allowsComputedFunctionProviderInNotifierFile(),
          'test_allowsDocumentedEphemeralNotifier': (t) => t._allowsDocumentedEphemeralNotifier(),
          'test_allowsLifecycleCleanupNotifier': (t) => t._allowsLifecycleCleanupNotifier(),
          'test_allowsNotifierOutsideFeaturePresentationNotifiers': (t) =>
              t._allowsNotifierOutsideFeaturePresentationNotifiers(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

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

  Future<void> _reportsExplicitKeepAliveFalse() async {
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

  Future<void> _allowsKeepAliveFeatureNotifier() async {
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

  Future<void> _allowsFamilyFeatureNotifier() async {
    await assertAllows(r'''
const riverpod = Object();

@riverpod
class ItemEditorNotifier {
  Object build(String itemId) => Object();
}
''', path: '$testPackageLibPath/features/items/presentation/notifiers/item_editor_notifier.dart');
  }

  Future<void> _allowsComputedFunctionProviderInNotifierFile() async {
    await assertAllows(r'''
const riverpod = Object();

class Ref {}

@riverpod
Object historyCalendarSessions(Ref ref) => Object();
''', path: path);
  }

  Future<void> _allowsDocumentedEphemeralNotifier() async {
    await assertAllows(r'''
const riverpod = Object();

// autoDispose: route-local draft should reset when the editor closes.
@riverpod
class ItemDraftNotifier {
  Object build() => Object();
}
''', path: '$testPackageLibPath/features/items/presentation/notifiers/item_draft_notifier.dart');
  }

  Future<void> _allowsLifecycleCleanupNotifier() async {
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

  Future<void> _allowsNotifierOutsideFeaturePresentationNotifiers() async {
    await assertAllows(r'''
const riverpod = Object();

@riverpod
class DraftNotifier {
  Object build() => Object();
}
''', path: '$testPackageLibPath/core/notifiers/draft_notifier.dart');
  }

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

void _defineSourceScannerRulesPart03Tests() {
  analysisRuleSuite<_RiverpodSelectIdentityForbiddenTest>(
    'RiverpodSelectIdentityForbiddenTest',
    _RiverpodSelectIdentityForbiddenTest.new,
    _RiverpodSelectIdentityForbiddenTest._allCases,
  );
  analysisRuleSuite<_RiverpodMutationExperimentalWarningTest>(
    'RiverpodMutationExperimentalWarningTest',
    _RiverpodMutationExperimentalWarningTest.new,
    _RiverpodMutationExperimentalWarningTest._allCases,
  );
  analysisRuleSuite<_RiverpodMutationTopLevelTest>(
    'RiverpodMutationTopLevelTest',
    _RiverpodMutationTopLevelTest.new,
    _RiverpodMutationTopLevelTest._allCases,
  );
  analysisRuleSuite<_RiverpodMutationRefReadTest>(
    'RiverpodMutationRefReadTest',
    _RiverpodMutationRefReadTest.new,
    _RiverpodMutationRefReadTest._allCases,
  );
  analysisRuleSuite<_AsyncValueSwitchOverWhenTest>(
    'AsyncValueSwitchOverWhenTest',
    _AsyncValueSwitchOverWhenTest.new,
    _AsyncValueSwitchOverWhenTest._allCases,
  );
  analysisRuleSuite<_RiverpodAutoDisposeKeepAliveDependenciesTest>(
    'RiverpodAutoDisposeKeepAliveDependenciesTest',
    _RiverpodAutoDisposeKeepAliveDependenciesTest.new,
    _RiverpodAutoDisposeKeepAliveDependenciesTest._allCases,
  );
  analysisRuleSuite<_RiverpodFeatureNotifierKeepaliveTest>(
    'RiverpodFeatureNotifierKeepaliveTest',
    _RiverpodFeatureNotifierKeepaliveTest.new,
    _RiverpodFeatureNotifierKeepaliveTest._allCases,
  );
}
