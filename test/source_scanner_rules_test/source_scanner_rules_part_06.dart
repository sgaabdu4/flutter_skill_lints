part of '../source_scanner_rules_test.dart';

final class _WidgetTryCatchBoundaryTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetTryCatchBoundaryTest)> get _allCases =>
      caseSet<_WidgetTryCatchBoundaryTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsCleanupWithoutCatching': (t) => t._allowsCleanupWithoutCatching(),
          'test_reportsNestedCatchInsideCleanup': (t) => t._reportsNestedCatchInsideCleanup(),
          'test_allowsTryCatchInNotifier': (t) => t._allowsTryCatchInNotifier(),
          'test_reportsTryCatchInWidgetFileHelperClass': (t) =>
              t._reportsTryCatchInWidgetFileHelperClass(),
        },
      );

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

  Future<void> _allowsCleanupWithoutCatching() async {
    await assertAllows(r'''
class TodoScreen extends Widget {
  Future<void> save() async {
    try {
      await saveAction();
    } finally {
      resetIndicator();
    }
  }
}
''', path: path);
  }

  Future<void> _reportsNestedCatchInsideCleanup() async {
    final analyzedSource = _analyzedSource(r'''
class TodoScreen extends Widget {
  Future<void> save() async {
    try {
      await saveAction();
    } finally {
      try /* handler */ { resetIndicator(); } on Object { recover(); }
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);
    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'try /* handler */', ruleName),
    ]);
  }

  Future<void> _allowsTryCatchInNotifier() async {
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

  Future<void> _reportsTryCatchInWidgetFileHelperClass() async {
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

final class _WidgetAwaitsNotifierResultTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetAwaitsNotifierResultTest)> get _allCases =>
      caseSet<_WidgetAwaitsNotifierResultTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsAwaitedDialogBeforeSynchronousNotifierDispatch': (t) =>
              t._allowsAwaitedDialogBeforeSynchronousNotifierDispatch(),
          'test_reportsMultilineAwaitedNotifierResult': (t) =>
              t._reportsMultilineAwaitedNotifierResult(),
          'test_reportsIfAwaitedNotifierResult': (t) => t._reportsIfAwaitedNotifierResult(),
          'test_reportsNotifierThenResultBranch': (t) => t._reportsNotifierThenResultBranch(),
          'test_reportsMultilineNotifierThenResultBranch': (t) =>
              t._reportsMultilineNotifierThenResultBranch(),
          'test_allowsNavigatorThenWithoutNotifierResult': (t) =>
              t._allowsNavigatorThenWithoutNotifierResult(),
          'test_allowsDispatchWithoutResultBranch': (t) => t._allowsDispatchWithoutResultBranch(),
        },
      );

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

  Future<void> _allowsAwaitedDialogBeforeSynchronousNotifierDispatch() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}
Future<T?> showDialog<T>() async => null;
class ConfirmScreen extends ConsumerWidget {
  Future<void> confirm() async {
    final confirmed = await showDialog<bool>();
    if (confirmed == true) {
      ref.read(formProvider.notifier).update('done');
    }
  }
}
''', path: path);
  }

  Future<void> _reportsMultilineAwaitedNotifierResult() async {
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

  Future<void> _reportsIfAwaitedNotifierResult() async {
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

  Future<void> _reportsNotifierThenResultBranch() async {
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

  Future<void> _reportsMultilineNotifierThenResultBranch() async {
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

  Future<void> _allowsNavigatorThenWithoutNotifierResult() async {
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

  Future<void> _allowsDispatchWithoutResultBranch() async {
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

final class _WidgetLocalMutationFlagTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetLocalMutationFlagTest)> get _allCases =>
      caseSet<_WidgetLocalMutationFlagTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsGetterBackedNotifierMutation': (t) =>
              t._reportsGetterBackedNotifierMutation(),
          'test_allowsUiOnlyBusyFlag': (t) => t._allowsUiOnlyBusyFlag(),
          'test_allowsNotifierOwnedSavingStateWatch': (t) =>
              t._allowsNotifierOwnedSavingStateWatch(),
        },
      );

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

  Future<void> _reportsGetterBackedNotifierMutation() async {
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

  Future<void> _allowsUiOnlyBusyFlag() async {
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

  Future<void> _allowsNotifierOwnedSavingStateWatch() async {
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

final class _WidgetDerivedCollectionLogicTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetDerivedCollectionLogicTest)> get _allCases =>
      caseSet<_WidgetDerivedCollectionLogicTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsComputedProviderCollectionLogic': (t) =>
              t._allowsComputedProviderCollectionLogic(),
          'test_reportsDataNamespaceCollectionLogic': (t) =>
              t._reportsDataNamespaceCollectionLogic(),
          'test_reportsDataNamespaceLoopCollectionLogic': (t) =>
              t._reportsDataNamespaceLoopCollectionLogic(),
          'test_reportsExpressionBodiedPrivateHelper': (t) =>
              t._reportsExpressionBodiedPrivateHelper(),
          'test_reportsWrappedExpressionBodiedDataNamespaceHelper': (t) =>
              t._reportsWrappedExpressionBodiedDataNamespaceHelper(),
          'test_allowsExpressionBodiedHelperWithoutCollectionWork': (t) =>
              t._allowsExpressionBodiedHelperWithoutCollectionWork(),
          'test_reportsTopLevelDerivedCollection': (t) => t._reportsTopLevelDerivedCollection(),
        },
      );

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

  Future<void> _allowsComputedProviderCollectionLogic() async {
    await assertAllows(r'''
List<Exercise> filteredExercises(Ref ref) {
  final items = ref.watch(exercisesProvider);
  return items.where((item) => item.isVisible).toList();
}
''', path: '$testPackageLibPath/features/exercises/presentation/notifiers/exercise_filters.dart');
  }

  Future<void> _reportsDataNamespaceCollectionLogic() async {
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

  Future<void> _reportsDataNamespaceLoopCollectionLogic() async {
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

  Future<void> _reportsExpressionBodiedPrivateHelper() async {
    final analyzedSource = _analyzedSource(r'''
class StatefulWidget extends Widget {}
class State<T> extends Widget {}

class ExerciseList extends StatefulWidget {}

class _ExerciseListState extends State<ExerciseList> {
  List<Exercise> _visible(List<Exercise> items) => items.where((item) => item.isVisible).toList();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '.where', ruleName)]);
  }

  Future<void> _reportsWrappedExpressionBodiedDataNamespaceHelper() async {
    final analyzedSource = _analyzedSource(r'''
abstract final class ExerciseListData {
  static List<Exercise> visible(List<Exercise> items) =>
      items.where((item) => item.isVisible).toList();
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [compatLint(analyzedSource, '.where', ruleName)]);
  }

  Future<void> _allowsExpressionBodiedHelperWithoutCollectionWork() async {
    await assertAllows(r'''
class StatefulWidget extends Widget {}
class State<T> extends Widget {}

class ExerciseList extends StatefulWidget {}

class _ExerciseListState extends State<ExerciseList> {
  List<Exercise> _items(List<Exercise> items) => items;
}
''', path: path);
  }

  Future<void> _reportsTopLevelDerivedCollection() async {
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

final class _A11yTextScaleClampTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_A11yTextScaleClampTest)> get _allCases =>
      caseSet<_A11yTextScaleClampTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _AppShellBootstrapSideEffectsTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_AppShellBootstrapSideEffectsTest)> get _allCases =>
      caseSet<_AppShellBootstrapSideEffectsTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsDeclarativeAppShell': (t) => t._allowsDeclarativeAppShell(),
          'test_allowsBootstrapWidgetListeners': (t) => t._allowsBootstrapWidgetListeners(),
          'test_allowsFeatureWidgetListeners': (t) => t._allowsFeatureWidgetListeners(),
        },
      );

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

  Future<void> _allowsDeclarativeAppShell() async {
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

  Future<void> _allowsBootstrapWidgetListeners() async {
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

  Future<void> _allowsFeatureWidgetListeners() async {
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

void _defineSourceScannerRulesPart06Tests() {
  analysisRuleSuite<_WidgetTryCatchBoundaryTest>(
    'WidgetTryCatchBoundaryTest',
    _WidgetTryCatchBoundaryTest.new,
    _WidgetTryCatchBoundaryTest._allCases,
  );
  analysisRuleSuite<_WidgetAwaitsNotifierResultTest>(
    'WidgetAwaitsNotifierResultTest',
    _WidgetAwaitsNotifierResultTest.new,
    _WidgetAwaitsNotifierResultTest._allCases,
  );
  analysisRuleSuite<_WidgetLocalMutationFlagTest>(
    'WidgetLocalMutationFlagTest',
    _WidgetLocalMutationFlagTest.new,
    _WidgetLocalMutationFlagTest._allCases,
  );
  analysisRuleSuite<_WidgetDerivedCollectionLogicTest>(
    'WidgetDerivedCollectionLogicTest',
    _WidgetDerivedCollectionLogicTest.new,
    _WidgetDerivedCollectionLogicTest._allCases,
  );
  analysisRuleSuite<_A11yTextScaleClampTest>(
    'A11yTextScaleClampTest',
    _A11yTextScaleClampTest.new,
    _A11yTextScaleClampTest._allCases,
  );
  analysisRuleSuite<_AppShellBootstrapSideEffectsTest>(
    'AppShellBootstrapSideEffectsTest',
    _AppShellBootstrapSideEffectsTest.new,
    _AppShellBootstrapSideEffectsTest._allCases,
  );
}
