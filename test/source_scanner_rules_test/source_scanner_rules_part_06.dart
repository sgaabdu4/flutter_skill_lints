// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class WidgetTryCatchBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_try_catch_boundary';
  @override
  String get needle => 'try {';
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/screens/todo_screen.dart';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}

class TodoScreen extends ConsumerWidget {
  Object build(Object context, WidgetRef ref) {
    try {
      ref.read(todoProvider.notifier).save();
    } catch (e) {
      return e;
    }
    return Object();
  }
}
''';

  Future<void> test_allowsTryCatchInNotifier() async {
    await assertAllows(r'''
class TodosNotifier {
  Future<void> save() async {
    try {
      await repository.save();
    } catch (e) {
      state = errorState;
    }
  }
}
''', path: '$testPackageLibPath/features/todos/presentation/notifiers/todos_notifier.dart');
  }

  Future<void> test_reportsTryCatchInWidgetFileHelperClass() async {
    final analyzedSource = _analyzedSource(r'''
class TodoBackend {
  Future<void> save() async {
    try {
      await repository.save();
    } catch (_) {}
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'try {', ruleName)]);
  }
}

@reflectiveTest
final class WidgetAwaitsNotifierResultTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_awaits_notifier_result';
  @override
  String get needle => 'await ref';
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/screens/todo_screen.dart';
  @override
  String get source => r'''
class State<T> extends Widget {}
class TodoScreen {}

class _TodoScreenState extends State<TodoScreen> {
  Future<void> save() async {
    final ok = await ref.read(todoProvider.notifier).save();
    if (ok) context.pop();
  }
}
''';

  Future<void> test_reportsMultilineAwaitedNotifierResult() async {
    final analyzedSource = _analyzedSource(r'''
class ConsumerState<T> extends Widget {}
class TodoScreen {}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  Future<void> save() async {
    final destination = await ref
        .read(authProvider.notifier)
        .resolveAuthSuccessDestination();
    switch (destination) {
      case Object():
        return;
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'await ref', ruleName)]);
  }

  Future<void> test_reportsIfAwaitedNotifierResult() async {
    final analyzedSource = _analyzedSource(r'''
class ConsumerWidget extends Widget {}

class TodoScreen extends ConsumerWidget {
  Future<void> save() async {
    if (await ref.read(todoProvider.notifier).save()) {
      context.pop();
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'await ref', ruleName)]);
  }

  Future<void> test_reportsNotifierThenResultBranch() async {
    final analyzedSource = _analyzedSource(r'''
class ConsumerWidget extends Widget {}

class TodoScreen extends ConsumerWidget {
  void save() {
    unawaited(
      ref.read(todoProvider.notifier).save().then((saved) {
        if (saved) context.pop();
      }),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref.read', ruleName)]);
  }

  Future<void> test_reportsMultilineNotifierThenResultBranch() async {
    final analyzedSource = _analyzedSource(r'''
class ConsumerState<T> extends Widget {}
class TodoScreen {}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  void save() {
    unawaited(
      ref
          .read(todoProvider.notifier)
          .save()
          .then((saved) {
            if (saved) context.pop();
          }),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, 'ref', ruleName)]);
  }

  Future<void> test_allowsNavigatorThenWithoutNotifierResult() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class TodoScreen extends ConsumerWidget {
  void close() {
    unawaited(
      Navigator.of(context).maybePop().then((_) {
        context.pop();
      }),
    );
  }
}
''', path: path);
  }

  Future<void> test_allowsDispatchWithoutResultBranch() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class TodoScreen extends ConsumerWidget {
  Future<void> save() async {
    await ref.read(todoProvider.notifier).save();
  }
}
''', path: path);
  }
}

@reflectiveTest
final class WidgetLocalMutationFlagTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_local_mutation_flag';
  @override
  String get needle => '_isSaving';
  @override
  String get path => '$testPackageLibPath/features/todos/presentation/screens/todo_screen.dart';
  @override
  String get source => r'''
class ConsumerState<T> extends Widget {}
class TodoScreen {}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  bool _isSaving = false;

  void save() {
    ref.read(todoProvider.notifier).saveTodo();
  }
}
''';

  Future<void> test_reportsGetterBackedNotifierMutation() async {
    final analyzedSource = _analyzedSource(r'''
class ConsumerState<T> extends Widget {}
class ExercisePickerDraftNotifier {
  void saveNewWorkout() {}
}
class WorkoutDraftScreen {}

class WorkoutDraftScreenState extends ConsumerState<WorkoutDraftScreen> {
  bool _isSubmitting = false;

  ExercisePickerDraftNotifier get _notifier =>
      ref.read(exercisePickerDraftProvider('id').notifier);

  void save() {
    _notifier.saveNewWorkout();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '_isSubmitting', ruleName)]);
  }

  Future<void> test_allowsUiOnlyBusyFlag() async {
    await assertAllows(r'''
class State<T> extends Widget {}
class StoreButton {}

class _StoreButtonState extends State<StoreButton> {
  bool _isOpeningStore = false;

  void open() {
    _isOpeningStore = true;
  }
}
''');
  }

  Future<void> test_allowsNotifierOwnedSavingStateWatch() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class SaveButton extends ConsumerWidget {
  Object build() {
    final isSaving = ref.watch(formProvider.select((state) => state.isSaving));
    return isSaving;
  }
}
''');
  }
}

@reflectiveTest
final class WidgetDerivedCollectionLogicTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_derived_collection_logic';
  @override
  String get needle => '.where';
  @override
  String get path =>
      '$testPackageLibPath/features/exercises/presentation/widgets/exercise_list.dart';
  @override
  String get source => r'''
class StatefulWidget extends Widget {}
class State<T> extends Widget {}

class ExerciseList extends StatefulWidget {}

class _ExerciseListState extends State<ExerciseList> {
  List<Exercise> _filteredExercises(List<Exercise> items) {
    final filtered = items.where((item) => item.isVisible).toList();
    return filtered;
  }
}
''';

  Future<void> test_allowsComputedProviderCollectionLogic() async {
    await assertAllows(r'''
List<Exercise> filteredExercises(Ref ref) {
  final items = ref.watch(exercisesProvider);
  return items.where((item) => item.isVisible).toList();
}
''', path: '$testPackageLibPath/features/exercises/presentation/notifiers/exercise_filters.dart');
  }

  Future<void> test_reportsDataNamespaceCollectionLogic() async {
    final analyzedSource = _analyzedSource(r'''
abstract final class ExerciseListData {
  static List<Exercise> filteredExercises(List<Exercise> items) {
    return items.where((item) => item.isVisible).toList();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '.where', ruleName)]);
  }

  Future<void> test_reportsDataNamespaceLoopCollectionLogic() async {
    final analyzedSource = _analyzedSource(r'''
abstract final class ExerciseListData {
  static List<String> names(List<Exercise> items) {
    final names = <String>[];
    for (final item in items) {
      names.add(item.name);
    }
    return names;
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '.add', ruleName)]);
  }

  Future<void> test_reportsTopLevelDerivedCollection() async {
    final analyzedSource = _analyzedSource(r'''
final _visibleExercises = Exercise.values
    .where((exercise) => exercise.isVisible)
    .toList();
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'final _visibleExercises', ruleName, lineStart: true),
    ]);
  }
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
final class AppShellBootstrapSideEffectsTest extends _UiRuleTest {
  @override
  String get ruleName => 'app_shell_bootstrap_side_effects';
  @override
  String get needle => 'ref.listen(startupProvider';
  @override
  String get path => '$testPackageLibPath/app.dart';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}

class MaterialApp extends Widget {
  MaterialApp.router({Object? routerConfig});
}

class MyApp extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(startupProvider, (_, __) {});
    return MaterialApp.router(routerConfig: router);
  }
}
''';

  Future<void> test_allowsDeclarativeAppShell() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class MaterialApp extends Widget {
  MaterialApp.router({Object? routerConfig});
}

class MyApp extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(routerConfig: router);
  }
}
''', path: '$testPackageLibPath/app.dart');
  }

  Future<void> test_allowsBootstrapWidgetListeners() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class AppBootstrap extends ConsumerWidget {
  AppBootstrap(this.child);

  final Widget child;

  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(startupProvider);
    ref.listen(authProvider, (_, __) {});
    return child;
  }
}
''', path: '$testPackageLibPath/core/bootstrap/app_bootstrap.dart');
  }

  Future<void> test_allowsFeatureWidgetListeners() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class AccountScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(accountProvider, (_, __) {});
    return Widget();
  }
}
''', path: '$testPackageLibPath/features/account/presentation/screens/account_screen.dart');
  }
}
