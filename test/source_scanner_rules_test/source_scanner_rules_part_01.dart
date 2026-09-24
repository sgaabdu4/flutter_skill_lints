// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

const _riverpodProviderStub = r'''
abstract class ProviderOrFamily {}

abstract class ProviderBase<T> extends ProviderOrFamily {}

abstract class $FunctionalProvider<T> extends ProviderBase<T> {}

class Ref {}

final class Provider<T> extends $FunctionalProvider<T> {
  Provider(T Function(Ref ref) create);

  static const family = ProviderFamilyBuilder();
}

final class ProviderFamily<T, A> extends ProviderOrFamily {
  ProviderFamily(T Function(Ref ref, A arg) create);

  Provider<T> call(A arg) => throw UnimplementedError();
}

final class ProviderFamilyBuilder {
  const ProviderFamilyBuilder();

  ProviderFamily<T, A> call<T, A>(T Function(Ref ref, A arg) create) => ProviderFamily(create);
}
''';

const _flutterRiverpodWidgetStub = r'''
class Source<T> {}

class WidgetRef {
  T watch<T>(Source<T> source) => throw UnimplementedError();
  T read<T>(Source<T> source) => throw UnimplementedError();
}

abstract class ConsumerStatefulWidget {}

abstract class ConsumerState<T extends ConsumerStatefulWidget> {
  WidgetRef get ref => WidgetRef();

  void initState() {}
}
''';

abstract class _RiverpodRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => riverpodSourceRules;
}

@reflectiveTest
final class RiverpodReadInitStateTest extends _RiverpodRuleTest {
  Future<void> test_allowsDeferredAndAdjacentReads() async {
    await assertAllows(r'''
import 'dart:async';
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    Future<void>.microtask(() { ref.read(provider); });
  }
  void later() { ref.read(provider); }
}
''');
  }

  Future<void> test_reportsImmediatelyInvokedRead() async {
    final analyzedSource = _analyzedSource(r'''
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    (() { ref.read(provider); })();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> test_reportsSynchronousCallback() async {
    final analyzedSource = _analyzedSource(r'''
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    [1].forEach((_) { ref.read(provider); });
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> test_reportsReadAfterDeferredCallbackOnSameLine() async {
    final analyzedSource = _analyzedSource(r'''
import 'dart:async';
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    Future<void>.microtask(() { ref.read(provider); }); ref.read(provider);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      lint(analyzedSource.lastIndexOf(needle), needle.length + 1),
    ]);
  }

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
final class RiverpodManualProviderTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _riverpodProviderStub);
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_manual_provider';
  @override
  String get needle => 'final featureNavigationCoordinatorProvider';
  @override
  String get source => r'''
class Provider<T> {
  const Provider(T Function(Ref ref) create);
}

class Ref {}

final featureNavigationCoordinatorProvider = Provider((ref) => Object());
''';

  Future<void> test_reportsTypedManualProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Provider<T> {
  const Provider(T Function(Ref ref) create);
}

class Ref {}

final itemRepositoryProvider = Provider<Object>((ref) => Object());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final itemRepositoryProvider', ruleName),
    ]);
  }

  Future<void> test_reportsFamilyProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Provider {
  static Object family(Object create) => Object();
}

final itemByIdProvider = Provider.family((ref, id) => Object());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final itemByIdProvider', ruleName),
    ]);
  }

  Future<void> test_reportsGenericFamilyProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Provider {
  static Object family<T, Arg>(Object create) => Object();
}

class Exercise {
  const Exercise();
}

final availableOptionsProvider = Provider.family<List<Exercise>, String>((ref, itemId) {
  return const <Exercise>[];
});
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final availableOptionsProvider', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineGenericFamilyProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Provider {
  static Object family<T, Arg>(Object create) => Object();
}

class Exercise {
  const Exercise();
}

final availableOptionsProvider =
    Provider.family<List<Exercise>, String>((ref, itemId) {
  return const <Exercise>[];
});
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final availableOptionsProvider', ruleName),
    ]);
  }

  Future<void> test_reportsOtherManualProviderTypes() async {
    final analyzedSource = _analyzedSource(r'''
class FutureProvider<T> {
  const FutureProvider(Object create);
}

class StreamProvider<T> {
  const StreamProvider(Object create);
}

final itemFutureProvider = FutureProvider<Object>((ref) => Object());
final itemStreamProvider = StreamProvider<Object>((ref) => Object());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'final itemFutureProvider', ruleName),
      compatLint(analyzedSource, 'final itemStreamProvider', ruleName),
    ]);
  }

  Future<void> test_allowsGeneratedProviderDeclaration() async {
    await assertAllows(r'''
final featureNavigationCoordinatorProvider = FeatureNavigationCoordinatorProvider._();

final class FeatureNavigationCoordinatorProvider {
  FeatureNavigationCoordinatorProvider._();
}
''');
  }

  Future<void> test_allowsProviderScope() async {
    await assertAllows(r'''
class ProviderScope {
  const ProviderScope({required Object child});
}

final scope = ProviderScope(child: Object());
''');
  }

  Future<void> test_reportsResolvedTypedAndReturnedProviders() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final Provider<int> typedProvider = Provider<int>((ref) => 2);

Provider<int> buildProvider() => Provider<int>((ref) => 6);

final ProviderFamily<int, String> lengthProvider =
    Provider.family<int, String>((ref, id) => id.length);
''';
    await assertDiagnostics(source, [
      compatLint(source, 'Provider<int>((ref) => 2)', ruleName),
      compatLint(source, 'Provider<int>((ref) => 6)', ruleName),
      compatLint(source, 'Provider.family<int, String>', ruleName),
    ]);
  }

  Future<void> test_reportsResolvedUntypedProvidersOnce() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final plainProvider = Provider<int>((ref) => 1);
final multiLineProvider =
    Provider<int>(
  (ref) => 5,
);
''';
    await assertDiagnostics(source, [
      compatLint(source, 'final plainProvider', ruleName),
      compatLint(source, 'final multiLineProvider', ruleName),
    ]);
  }

  Future<void> test_allowsGeneratedProviderSubclassesAndFamilyCalls() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

final class ItemProvider extends $FunctionalProvider<int> {
  ItemProvider._();
}

final itemProvider = ItemProvider._();

int read(Ref ref, ProviderFamily<int, String> family) {
  final provider = family('id');
  return provider.hashCode;
}
''', addIgnorePrefix: false);
  }
}

@reflectiveTest
final class RiverpodNotifierOverrideWithValueTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_notifier_override_with_value';
  @override
  String get needle => 'appInitProvider.overrideWithValue';
  @override
  String get source => r'''
final overrides = [
  appInitProvider.overrideWithValue(
    const AppInitState(isInitialized: true),
  ),
];

class AppInitState {
  const AppInitState({this.isInitialized = false});

  final bool isInitialized;
}
''';

  Future<void> test_reportsSingleLineStateConstructorOverride() async {
    final analyzedSource = _analyzedSource(r'''
final overrides = [
  onboardingProvider.overrideWithValue(const OnboardingState(isLoading: false)),
];

class OnboardingState {
  const OnboardingState({this.isLoading = false});

  final bool isLoading;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'onboardingProvider.overrideWithValue', ruleName),
    ]);
  }

  Future<void> test_allowsNotifierFactoryOverride() async {
    await assertAllows(r'''
final overrides = [
  onboardingProvider.overrideWith(E2eOnboardingNotifier.new),
];

class E2eOnboardingNotifier {}
''');
  }

  Future<void> test_allowsRepositoryValueOverride() async {
    await assertAllows(r'''
final overrides = [
  authRepositoryProvider.overrideWithValue(authRepository),
];

final authRepository = Object();
''');
  }

  Future<void> test_allowsAsyncValueOverride() async {
    await assertAllows(r'''
final overrides = [
  userProvider.overrideWithValue(AsyncValue.data(const User(id: '1'))),
];

class AsyncValue<T> {
  static Object data<T>(T value) => Object();
}

class User {
  const User({required this.id});

  final String id;
}
''');
  }

  Future<void> test_allowsTestFileStateOverride() async {
    await assertAllows(r'''
final overrides = [
  authProvider.overrideWithValue(const AuthState()),
];

class AuthState {
  const AuthState();
}
''', path: '$testPackageRootPath/test/auth_notifier_test.dart');
  }
}

@reflectiveTest
final class RiverpodConsumerStateDerivedCacheTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', _flutterRiverpodWidgetStub);
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_consumer_state_derived_cache';
  @override
  String get needle => '_historySource';
  @override
  String get source => r'''
class MemberDetailHistoryCard extends ConsumerStatefulWidget {}

class _MemberDetailHistoryCardState extends ConsumerState<MemberDetailHistoryCard> {
  List<Object>? _historySource;

  Object build(Object context) {
    final async = ref.watch(memberDetailProvider.select((value) => value));
    return async;
  }
}
''';

  Future<void> test_reportsDayStartMemoizationField() async {
    final analyzedSource = _analyzedSource(r'''
class MemberDetailTopLiftsCard extends ConsumerStatefulWidget {}

class _MemberDetailTopLiftsCardState extends ConsumerState<MemberDetailTopLiftsCard> {
  DateTime? _topLiftsDayStart;
  List<Object> _topLiftsCache = const [];

  Object build(Object context) {
    final async = ref.watch(memberDetailProvider.select((value) => value));
    return async;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_topLiftsDayStart', ruleName),
      compatLint(analyzedSource, '_topLiftsCache', ruleName),
    ]);
  }

  Future<void> test_reportsDerivedIndexField() async {
    final analyzedSource = _analyzedSource(r'''
class ExercisePickerSheet extends ConsumerStatefulWidget {}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  Map<String, Object> _exerciseById = const {};

  Object build(Object context) {
    final items = ref.watch(exercisesProvider.select((state) => state.items));
    return items;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_exerciseById', ruleName),
    ]);
  }

  Future<void> test_reportsResolvedProviderDerivedFields() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductRepository {}

final itemsProvider = Source<List<int>>();
final repositoryProvider = Source<ProductRepository>();

class HistoryCard extends ConsumerStatefulWidget {}

class _HistoryCardState extends ConsumerState<HistoryCard> {
  List<int> _historyCache = const [];
  List<int> _visibleItems = const [];
  ProductRepository? _repository;
  ProductRepository? _lazyRepository;
  late final _eagerRepository = ref.read(repositoryProvider);

  @override
  void initState() {
    super.initState();
    _repository = ref.read(repositoryProvider);
  }

  void refresh() {
    _lazyRepository ??= ref.read(repositoryProvider);
  }

  Object build(Object context) {
    final items = ref.watch(itemsProvider);
    _historyCache = items;
    _visibleItems = items.where((item) => item > 0).toList();
    return [_historyCache, _visibleItems, _repository, _lazyRepository, _eagerRepository];
  }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, '_historyCache = const', ruleName),
      compatLint(source, '_visibleItems = const', ruleName),
      compatLint(source, '_repository;', ruleName),
      compatLint(source, '_lazyRepository;', ruleName),
      compatLint(source, '_eagerRepository =', ruleName),
    ]);
  }

  Future<void> test_allowsLifecycleHandlesSeededFromProviders() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextEditingController {
  TextEditingController({String text = ''});
  String text = '';
}

final nameProvider = Source<String>();

class NameField extends ConsumerStatefulWidget {}

class _NameFieldState extends ConsumerState<NameField> {
  late final TextEditingController _controller;
  static int _instances = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(nameProvider));
    _controller.text = ref.read(nameProvider);
    _instances = _instances + 1;
    _query = 'initial';
  }

  Object build(Object context) {
    final name = ref.watch(nameProvider);
    return [name, _controller, _query];
  }
}
''', addIgnorePrefix: false);
  }

  Future<void> test_severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_allowsControllerStateWithProviderWatch() async {
    await assertAllows(r'''
class TextEditingController {}

class SearchSheet extends ConsumerStatefulWidget {}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  late final TextEditingController _controller;
  String _query = '';

  Object build(Object context) {
    final items = ref.watch(itemsProvider.select((state) => state.items));
    return items;
  }
}
''');
  }

  Future<void> test_allowsNonConsumerStateMemoizationHelper() async {
    await assertAllows(r'''
class HistoryPresenter {
  List<Object>? _historySource;
  List<bool> _heatmapCache = const [];
}
''');
  }
}

@reflectiveTest
final class RiverpodWidgetProviderArgWrapperTest extends _RiverpodRuleTest {
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

  Future<void> test_reportsConsumerStateProviderArgField() async {
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

  Future<void> test_reportsBuildLocalProviderArgWrapper() async {
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

  Future<void> test_reportsInlineProviderArgWrapper() async {
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

  Future<void> test_allowsDirectProviderIdArg() async {
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

  Future<void> test_allowsUiConfigNotPassedToProvider() async {
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

@reflectiveTest
final class RiverpodConsumerStateProviderSubscriptionTest extends _RiverpodRuleTest {
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

  Future<void> test_reportsPrefixedProviderSubscriptionField() async {
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

  Future<void> test_allowsRefListenInBuildWithoutStoredHandle() async {
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

  Future<void> test_allowsProviderSubscriptionOutsideWidgetState() async {
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

@reflectiveTest
final class RiverpodListenManualForbiddenTest extends _RiverpodRuleTest {
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

  Future<void> test_reportsAssignedListenManual() async {
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

  Future<void> test_reportsListenManualInTests() async {
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

  Future<void> test_allowsRefListenInBuild() async {
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
