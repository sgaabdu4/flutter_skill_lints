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

final class _RiverpodReadInitStateTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodReadInitStateTest)> get _allCases =>
      caseSet<_RiverpodReadInitStateTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsReadInAnotherMethod': (t) => t._allowsReadInAnotherMethod(),
          'test_reportsReadInsidePostFrameCallback': (t) => t._reportsReadInsidePostFrameCallback(),
          'test_reportsReadInsideMicrotask': (t) => t._reportsReadInsideMicrotask(),
          'test_reportsImmediatelyInvokedRead': (t) => t._reportsImmediatelyInvokedRead(),
          'test_reportsSynchronousCallback': (t) => t._reportsSynchronousCallback(),
        },
      );

  @override
  void setUp() {
    super.setUp();
    newPackage('flutter').addFile('lib/scheduler.dart', r'''
class SchedulerBinding {
  static SchedulerBinding get instance => throw UnimplementedError();
  void addPostFrameCallback(void Function(Duration timeStamp) callback) {}
}
''');
  }

  Future<void> _allowsReadInAnotherMethod() async {
    await assertAllows(r'''
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {}
  void later() { ref.read(provider); }
}
''');
  }

  Future<void> _reportsReadInsidePostFrameCallback() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/scheduler.dart';
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) { ref.read(provider); });
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> _reportsReadInsideMicrotask() async {
    final analyzedSource = _analyzedSource(r'''
import 'dart:async';
final provider = Object();
class Ref { Object read(Object value) => value; }
class View {
  final ref = Ref();
  void initState() {
    Future<void>.microtask(() { ref.read(provider); });
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, needle, ruleName)]);
  }

  Future<void> _reportsImmediatelyInvokedRead() async {
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

  Future<void> _reportsSynchronousCallback() async {
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

final class _RiverpodServiceLocatorTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodServiceLocatorTest)> get _allCases =>
      caseSet<_RiverpodServiceLocatorTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsPrefixedLocatorAndFactoryClasses': (t) =>
              t._reportsPrefixedLocatorAndFactoryClasses(),
          'test_allowsNamesThatOnlyContainTheBannedWords': (t) =>
              t._allowsNamesThatOnlyContainTheBannedWords(),
        },
      );

  @override
  String get ruleName => 'riverpod_service_locator';
  @override
  String get needle => 'class ServiceLocator';
  @override
  String get source => 'class ServiceLocator {}';

  Future<void> _reportsPrefixedLocatorAndFactoryClasses() async {
    const source = r'''
class AppServiceLocator {
  final Map<Type, Object> registry = {};
}

abstract class ApiServiceFactory {}

class LegacyBackendProvider {}
''';
    await assertDiagnostics(source, [
      compatLint(source, 'class AppServiceLocator', ruleName),
      compatLint(source, 'class ApiServiceFactory', ruleName),
      compatLint(source, 'class LegacyBackendProvider', ruleName),
    ]);
  }

  Future<void> _allowsNamesThatOnlyContainTheBannedWords() async {
    await assertAllows(r'''
class ServiceLocatorException implements Exception {}
class BackendProviderConfig {}
// class ServiceFactory {}
const note = 'class ServiceLocator {}';
''');
  }
}

final class _RiverpodManualProviderTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodManualProviderTest)> get _allCases =>
      caseSet<_RiverpodManualProviderTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsTypedManualProvider': (t) => t._reportsTypedManualProvider(),
          'test_reportsFamilyProvider': (t) => t._reportsFamilyProvider(),
          'test_reportsGenericFamilyProvider': (t) => t._reportsGenericFamilyProvider(),
          'test_reportsMultilineGenericFamilyProvider': (t) =>
              t._reportsMultilineGenericFamilyProvider(),
          'test_reportsOtherManualProviderTypes': (t) => t._reportsOtherManualProviderTypes(),
          'test_allowsGeneratedProviderDeclaration': (t) => t._allowsGeneratedProviderDeclaration(),
          'test_allowsProviderScope': (t) => t._allowsProviderScope(),
          'test_reportsResolvedTypedAndReturnedProviders': (t) =>
              t._reportsResolvedTypedAndReturnedProviders(),
          'test_reportsResolvedUntypedProvidersOnce': (t) =>
              t._reportsResolvedUntypedProvidersOnce(),
          'test_allowsGeneratedProviderSubclassesAndFamilyCalls': (t) =>
              t._allowsGeneratedProviderSubclassesAndFamilyCalls(),
        },
      );

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

  Future<void> _reportsTypedManualProvider() async {
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

  Future<void> _reportsFamilyProvider() async {
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

  Future<void> _reportsGenericFamilyProvider() async {
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

  Future<void> _reportsMultilineGenericFamilyProvider() async {
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

  Future<void> _reportsOtherManualProviderTypes() async {
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

  Future<void> _allowsGeneratedProviderDeclaration() async {
    await assertAllows(r'''
final featureNavigationCoordinatorProvider = FeatureNavigationCoordinatorProvider._();

final class FeatureNavigationCoordinatorProvider {
  FeatureNavigationCoordinatorProvider._();
}
''');
  }

  Future<void> _allowsProviderScope() async {
    await assertAllows(r'''
class ProviderScope {
  const ProviderScope({required Object child});
}

final scope = ProviderScope(child: Object());
''');
  }

  Future<void> _reportsResolvedTypedAndReturnedProviders() async {
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

  Future<void> _reportsResolvedUntypedProvidersOnce() async {
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

  Future<void> _allowsGeneratedProviderSubclassesAndFamilyCalls() async {
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

final class _RiverpodNotifierOverrideWithValueTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodNotifierOverrideWithValueTest)> get _allCases =>
      caseSet<_RiverpodNotifierOverrideWithValueTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsSingleLineStateConstructorOverride': (t) =>
              t._reportsSingleLineStateConstructorOverride(),
          'test_allowsNotifierFactoryOverride': (t) => t._allowsNotifierFactoryOverride(),
          'test_allowsRepositoryValueOverride': (t) => t._allowsRepositoryValueOverride(),
          'test_allowsAsyncValueOverride': (t) => t._allowsAsyncValueOverride(),
          'test_allowsTestFileStateOverride': (t) => t._allowsTestFileStateOverride(),
        },
      );

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

  Future<void> _reportsSingleLineStateConstructorOverride() async {
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

  Future<void> _allowsNotifierFactoryOverride() async {
    await assertAllows(r'''
final overrides = [
  onboardingProvider.overrideWith(E2eOnboardingNotifier.new),
];

class E2eOnboardingNotifier {}
''');
  }

  Future<void> _allowsRepositoryValueOverride() async {
    await assertAllows(r'''
final overrides = [
  authRepositoryProvider.overrideWithValue(authRepository),
];

final authRepository = Object();
''');
  }

  Future<void> _allowsAsyncValueOverride() async {
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

  Future<void> _allowsTestFileStateOverride() async {
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

final class _RiverpodConsumerStateDerivedCacheTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodConsumerStateDerivedCacheTest)> get _allCases =>
      caseSet<_RiverpodConsumerStateDerivedCacheTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsDayStartMemoizationField': (t) => t._reportsDayStartMemoizationField(),
          'test_reportsDerivedIndexField': (t) => t._reportsDerivedIndexField(),
          'test_reportsResolvedProviderDerivedFields': (t) =>
              t._reportsResolvedProviderDerivedFields(),
          'test_allowsLifecycleHandlesSeededFromProviders': (t) =>
              t._allowsLifecycleHandlesSeededFromProviders(),
          'test_severityIsError': (t) => t._severityIsError(),
          'test_allowsControllerStateWithProviderWatch': (t) =>
              t._allowsControllerStateWithProviderWatch(),
          'test_allowsNonConsumerStateMemoizationHelper': (t) =>
              t._allowsNonConsumerStateMemoizationHelper(),
        },
      );

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

  Future<void> _reportsDayStartMemoizationField() async {
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

  Future<void> _reportsDerivedIndexField() async {
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

  Future<void> _reportsResolvedProviderDerivedFields() async {
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

  Future<void> _allowsLifecycleHandlesSeededFromProviders() async {
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

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsControllerStateWithProviderWatch() async {
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

  Future<void> _allowsNonConsumerStateMemoizationHelper() async {
    await assertAllows(r'''
class HistoryPresenter {
  List<Object>? _historySource;
  List<bool> _heatmapCache = const [];
}
''');
  }
}

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

void _defineSourceScannerRulesPart01Tests() {
  analysisRuleSuite<_RiverpodReadInitStateTest>(
    'RiverpodReadInitStateTest',
    _RiverpodReadInitStateTest.new,
    _RiverpodReadInitStateTest._allCases,
  );
  analysisRuleSuite<_RiverpodServiceLocatorTest>(
    'RiverpodServiceLocatorTest',
    _RiverpodServiceLocatorTest.new,
    _RiverpodServiceLocatorTest._allCases,
  );
  analysisRuleSuite<_RiverpodManualProviderTest>(
    'RiverpodManualProviderTest',
    _RiverpodManualProviderTest.new,
    _RiverpodManualProviderTest._allCases,
  );
  analysisRuleSuite<_RiverpodNotifierOverrideWithValueTest>(
    'RiverpodNotifierOverrideWithValueTest',
    _RiverpodNotifierOverrideWithValueTest.new,
    _RiverpodNotifierOverrideWithValueTest._allCases,
  );
  analysisRuleSuite<_RiverpodConsumerStateDerivedCacheTest>(
    'RiverpodConsumerStateDerivedCacheTest',
    _RiverpodConsumerStateDerivedCacheTest.new,
    _RiverpodConsumerStateDerivedCacheTest._allCases,
  );
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
