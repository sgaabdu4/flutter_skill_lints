part of '../source_scanner_rules_test.dart';

final class _RiverpodWidgetProviderArgWrapperTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodWidgetProviderArgWrapperTest)> get _allCases =>
      caseSet<_RiverpodWidgetProviderArgWrapperTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsConsumerStateProviderArgField': (t) =>
              t._reportsConsumerStateProviderArgField(),
          'test_reportsBuildLocalProviderArgWrapper': (t) =>
              t._reportsBuildLocalProviderArgWrapper(),
          'test_reportsInlineProviderArgWrapper': (t) => t._reportsInlineProviderArgWrapper(),
          'test_allowsDirectProviderIdArg': (t) => t._allowsDirectProviderIdArg(),
          'test_allowsUiConfigNotPassedToProvider': (t) => t._allowsUiConfigNotPassedToProvider(),
        },
      );

  @override
  String get ruleName => 'riverpod_widget_provider_arg_wrapper';
  @override
  String get needle => '_config';
  @override
  String get source => r'''
class ExercisePickerConfig {
  const ExercisePickerConfig({required this.workoutId});

  final String workoutId;
}

class ExercisePickerScreen extends ConsumerStatefulWidget {
  String get workoutId => 'workout-1';
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  ExercisePickerConfig get _config => ExercisePickerConfig(workoutId: widget.workoutId);

  Object build(Object context) {
    return ref.watch(exercisePickerDraftProvider(_config).select((state) => state.canSave));
  }
}
''';

  Future<void> _reportsConsumerStateProviderArgField() async {
    final analyzedSource = _analyzedSource(r'''
class ExercisePickerArgs {
  const ExercisePickerArgs(this.workoutId);

  final String workoutId;
}

class ExercisePickerScreen extends ConsumerStatefulWidget {}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  late final ExercisePickerArgs _args;

  void initState() {
    _args = const ExercisePickerArgs('workout-1');
  }

  Object build(Object context) {
    return ref.watch(exercisePickerDraftProvider(_args).select((state) => state.canSave));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_args', ruleName)]);
  }

  Future<void> _reportsBuildLocalProviderArgWrapper() async {
    final analyzedSource = _analyzedSource(r'''
class ExercisePickerConfig {
  const ExercisePickerConfig({required this.workoutId});

  final String workoutId;
}

class ExercisePickerScreen {
  Object build(Object context) {
    final config = ExercisePickerConfig(workoutId: 'workout-1');
    return ref.watch(exercisePickerDraftProvider(config).select((state) => state.canSave));
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'config', ruleName)]);
  }

  Future<void> _reportsInlineProviderArgWrapper() async {
    final analyzedSource = _analyzedSource(r'''
class ExercisePickerConfig {
  const ExercisePickerConfig({required this.workoutId});

  final String workoutId;
}

class ExercisePickerScreen {
  Object build(Object context) {
    return ref.watch(
      exercisePickerDraftProvider(ExercisePickerConfig(workoutId: 'workout-1')).select(
        (state) => state.canSave,
      ),
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'exercisePickerDraftProvider', ruleName),
    ]);
  }

  Future<void> _allowsDirectProviderIdArg() async {
    await assertAllows(r'''
class ExercisePickerScreen extends ConsumerStatefulWidget {
  String get workoutId => 'workout-1';
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  Object build(Object context) {
    return ref.watch(exercisePickerDraftProvider(widget.workoutId).select((state) => state.canSave));
  }
}
''');
  }

  Future<void> _allowsUiConfigNotPassedToProvider() async {
    await assertAllows(r'''
class ButtonConfig {
  const ButtonConfig();
}

class Button {
  const Button({required this.config});

  final ButtonConfig config;
}

class FormSection {
  Object build(Object context) {
    final config = ButtonConfig();
    return Button(config: config);
  }
}
''');
  }
}

final class _RiverpodConsumerStateProviderSubscriptionTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodConsumerStateProviderSubscriptionTest)>
  get _allCases => caseSet<_RiverpodConsumerStateProviderSubscriptionTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsPrefixedProviderSubscriptionField': (t) =>
          t._reportsPrefixedProviderSubscriptionField(),
      'test_allowsRefListenInBuildWithoutStoredHandle': (t) =>
          t._allowsRefListenInBuildWithoutStoredHandle(),
      'test_allowsProviderSubscriptionOutsideWidgetState': (t) =>
          t._allowsProviderSubscriptionOutsideWidgetState(),
    },
  );

  @override
  String get ruleName => 'riverpod_consumer_state_provider_subscription';
  @override
  String get needle => '_exerciseSubscription';
  @override
  String get source => r'''
class ProviderSubscription<T> {
  void close() {}
}

class BentoExerciseCard extends ConsumerStatefulWidget {}

class _BentoExerciseCardState extends ConsumerState<BentoExerciseCard> {
  late final ProviderSubscription<Exercise?> _exerciseSubscription;
}
''';

  Future<void> _reportsPrefixedProviderSubscriptionField() async {
    final analyzedSource = _analyzedSource(r'''
class ProviderSubscription<T> {
  void close() {}
}

class Riverpod {
  const Riverpod();
}

class ExerciseDemoSheet extends ConsumerStatefulWidget {}

class _ExerciseDemoSheetState extends ConsumerState<ExerciseDemoSheet> {
  final riverpod.ProviderSubscription<Exercise?>? _exerciseSubscription = null;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_exerciseSubscription', ruleName),
    ]);
  }

  Future<void> _allowsRefListenInBuildWithoutStoredHandle() async {
    await assertAllows(r'''
class ExerciseStatsSheet extends ConsumerStatefulWidget {}

class _ExerciseStatsSheetState extends ConsumerState<ExerciseStatsSheet> {
  Object build(Object context) {
    ref.listen<Exercise?>(exerciseProvider, _handleExerciseChanged);
    return Object();
  }

  void _handleExerciseChanged(Exercise? previous, Exercise? next) {}
}
''');
  }

  Future<void> _allowsProviderSubscriptionOutsideWidgetState() async {
    await assertAllows(r'''
class ProviderSubscription<T> {
  void close() {}
}

class ExerciseLifecycleCoordinator {
  late final ProviderSubscription<Exercise?> _exerciseSubscription;
}
''');
  }
}

final class _RiverpodListenManualForbiddenTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodListenManualForbiddenTest)> get _allCases =>
      caseSet<_RiverpodListenManualForbiddenTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsAssignedListenManual': (t) => t._reportsAssignedListenManual(),
          'test_reportsListenManualInTests': (t) => t._reportsListenManualInTests(),
          'test_allowsRefListenInBuild': (t) => t._allowsRefListenInBuild(),
        },
      );

  @override
  String get ruleName => 'riverpod_listen_manual_forbidden';
  @override
  String get needle => 'ref.listenManual';
  @override
  String get source => r'''
class DisplayNameSheetState extends ConsumerStatefulWidget {}

class _DisplayNameSheetState extends ConsumerState<DisplayNameSheetState> {
  void init(Object provider) {
    ref.listenManual<String?>(provider, (_, current) {});
  }
}
''';

  Future<void> _reportsAssignedListenManual() async {
    final analyzedSource = _analyzedSource(r'''
class HomeScreen extends ConsumerStatefulWidget {}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Object? _subscription;
  void init(Object provider) {
    _subscription = ref.listenManual<bool>(provider, (_, current) {});
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.listenManual', ruleName),
    ]);
  }

  Future<void> _reportsListenManualInTests() async {
    final analyzedSource = _analyzedSource(r'''
void main() {
  testWidgets('wires listener', (tester) async {
    ref.listenManual<bool>(provider, (_, current) {});
  });
}
''', addIgnorePrefix: addIgnorePrefix);
    final testPath = '$testPackageRootPath/test/widgets/listen_manual_test.dart';
    newFile(testPath, analyzedSource);

    await assertDiagnosticsInFile(testPath, [
      compatLint(analyzedSource, 'ref.listenManual', ruleName),
    ]);
  }

  Future<void> _allowsRefListenInBuild() async {
    await assertAllows(r'''
class HomeScreen extends ConsumerStatefulWidget {}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Object build(Object context) {
    ref.listen<bool>(provider, (_, current) {});
    return Object();
  }
}
''');
  }
}

void _defineSourceScannerRulesPart01BTests() {
  analysisRuleSuite<_RiverpodWidgetProviderArgWrapperTest>(
    'RiverpodWidgetProviderArgWrapperTest',
    _RiverpodWidgetProviderArgWrapperTest.new,
    _RiverpodWidgetProviderArgWrapperTest._allCases,
  );
  analysisRuleSuite<_RiverpodConsumerStateProviderSubscriptionTest>(
    'RiverpodConsumerStateProviderSubscriptionTest',
    _RiverpodConsumerStateProviderSubscriptionTest.new,
    _RiverpodConsumerStateProviderSubscriptionTest._allCases,
  );
  analysisRuleSuite<_RiverpodListenManualForbiddenTest>(
    'RiverpodListenManualForbiddenTest',
    _RiverpodListenManualForbiddenTest.new,
    _RiverpodListenManualForbiddenTest._allCases,
  );
}
