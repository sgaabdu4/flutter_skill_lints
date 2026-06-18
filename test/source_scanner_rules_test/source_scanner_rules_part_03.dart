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
