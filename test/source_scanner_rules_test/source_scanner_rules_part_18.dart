part of '../source_scanner_rules_test.dart';

final class ScrollListenerWidgetPrefixTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'scroll_listener_no_throttle';
  @override
  String get needle => 'widget._scrollController.addListener(';
  @override
  String get source => r'''
class FeedScreenState {
  Object widget = Object();
  void init(Object ref) {
    widget._scrollController.addListener(() {
      ref.read(provider.notifier).loadMore();
    });
  }
}
''';
}

final class ScrollListenerAllowsDebouncerTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'scroll_listener_no_throttle';
  @override
  String get needle => 'class FeedScreenWithDebouncer';
  @override
  String get source => r'''
class Debouncer { void call(Object cb) {} }
class FeedScreenWithDebouncer {
  final Object _scrollController = Object();
  final Debouncer _debouncer = Debouncer();
  void init(Object ref) {
    _scrollController.addListener(() {
      ref.read(provider.notifier).loadMore();
    });
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class UserVisibleDurationTooLongTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'user_visible_duration_too_long';
  @override
  String get needle => 'Duration(milliseconds: 500)';
  @override
  String? get path =>
      '$testPackageRootPath/lib/features/search/presentation/notifiers/search_notifier.dart';
  @override
  String get source => r'''
class SearchNotifier {
  static const _searchDebounceDuration = Duration(milliseconds: 500);
}
''';

  Future<void> _reportsHardWaitInAsyncMethod() async {
    final analyzedSource = _analyzedSource(r'''
class SaveNotifier extends AsyncNotifier<void> {
  Future<void> save() async {
    state = AsyncLoading();
    await Future<void>.delayed(const Duration(milliseconds: 51));
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path!, analyzedSource);

    await assertDiagnosticsInFile(path!, [
      compatLint(analyzedSource, 'Duration(milliseconds: 51)', ruleName),
    ]);
  }

  Future<void> _allowsSyncSettleTimerInAsyncMethod() async {
    await assertAllows(r'''
class SaveNotifier {
  static const _syncSettleDelay = Duration(seconds: 2);

  Future<void> save() async {
    await Future<void>.delayed(_syncSettleDelay);
  }
}
''', path: path);
  }
}

final class UserVisibleDurationAllowsSnappyDebounceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'user_visible_duration_too_long';
  @override
  String get needle => 'class SearchNotifier';
  @override
  String? get path =>
      '$testPackageRootPath/lib/features/search/presentation/notifiers/search_notifier.dart';
  @override
  String get source => r'''
class SearchNotifier {
  static const _searchDebounceDuration = Duration(milliseconds: 150);
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

final class UserVisibleDurationAllowsRetryBackoffTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'user_visible_duration_too_long';
  @override
  String get needle => 'class RetryService';
  @override
  String? get path => '$testPackageRootPath/lib/core/services/retry_service.dart';
  @override
  String get source => r'''
class RetryService {
  Future<void> retry() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

final class UserVisibleDurationAllowsDismissTimerTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'user_visible_duration_too_long';
  @override
  String get needle => 'class CelebrationOverlayState';
  @override
  String? get path => '$testPackageRootPath/lib/core/widgets/molecules/celebration_overlay.dart';
  @override
  String get source => r'''
class CelebrationOverlayState {
  Object _dismissTimer = Object();
  void initState() {
    _dismissTimer = Timer(const Duration(milliseconds: 2500), () {});
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

final class UserVisibleDurationAllowsSnackBarDurationTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'user_visible_duration_too_long';
  @override
  String get needle => 'class SquadSync';
  @override
  String? get path =>
      '$testPackageRootPath/lib/features/social/presentation/notifiers/squad_sync_notifier.dart';
  @override
  String get source => r'''
class SquadSync {
  void showSnackBar(Object messenger) {
    messenger.showSnackBar(AppSnackBar(duration: const Duration(seconds: 10)));
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

final class DebugPrintBlankingMasksMatchesTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_zero_value_save_no_guard';
  @override
  String get needle => 'class HiddenInPrint';
  @override
  String get source => r'''
class HiddenInPrint {
  void log(Object ref) {
    debugPrint("ref.read(provider.notifier).saveEntry(amount: 0, count: 0)");
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }

  Future<void> _allowsPrintStatement() async {
    await assertAllows(r'''
class HiddenPrintCall {
  void log() {
    print("ref.read(provider.notifier).saveEntry(amount: 0)");
  }
}
''');
  }
}

final class IsTestFileSkipsRuleTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'sync_save_all_no_dirty_guard';
  @override
  String get needle => 'class SyncService';
  @override
  String? get path => '$testPackageRootPath/test/some_widget_test.dart';
  @override
  String get source => r'''
class SyncService {
  void pushItems(String userId, List<Object> items) {
    remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    newFile(path!, analyzedSource);
    await assertNoDiagnosticsInFile(path!);
  }
}

final class DialogRuleSkipsTestFileTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_button_pop_then_state_mutation';
  @override
  String get needle => 'ref.read(provider.notifier).save()';
  @override
  String? get path => '$testPackageRootPath/test/dialog_widget_test.dart';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}
class Navigator { static Object of(Object c) => Object(); }

class EditDialog extends ConsumerWidget {
  final ref = Object();
  void onTap(Object context) {
    Navigator.of(context).pop();
    ref.read(provider.notifier).save();
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    newFile(path!, analyzedSource);
    await assertNoDiagnosticsInFile(path!);
  }
}

final class DebugPrintMultilineBlankingTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_zero_value_save_no_guard';
  @override
  String get needle => 'class MultilinePrint';
  @override
  String get source => r'''
class MultilinePrint {
  void log() {
    debugPrint(
      "ref.read(provider.notifier)"
      ".saveEntry(amount: 0, count: 0)",
    );
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class DatasourceBoundaryFourGettersAllowedTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'datasource_missing_batch_loader';
  @override
  String get needle => 'class FourGetterLocalDatasource';
  @override
  String get source => r'''
abstract class FourGetterLocalDatasource {
  Future<bool> getOptIn();
  Future<bool> isPremium();
  Future<bool> hasOnboarded();
  Future<int> getThemeIndex();
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class DatasourceBoundaryFiveGettersFiresTest extends _RuntimeBugRuleTest {
  // Boundary: exactly 5 getters is the cutoff and MUST trigger.
  @override
  String get ruleName => 'datasource_missing_batch_loader';
  @override
  String get needle => 'class FiveGetterLocalDatasource';
  @override
  String get source => r'''
abstract class FiveGetterLocalDatasource {
  Future<bool> getOptIn();
  Future<bool> isPremium();
  Future<bool> hasOnboarded();
  Future<int> getThemeIndex();
  Future<String> getNickname();
}
''';
}

final class NotifierPersistenceNoDebounceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_persistence_no_debounce';
  @override
  String get needle => 'void _scheduleDraftPersist(';
  @override
  String get source => r'''
class DraftNotifier {
  void toggle() {
    _scheduleDraftPersist();
  }

  void _scheduleDraftPersist() {
    unawaited(_enqueueDraftPersist());
  }

  Future<void> _enqueueDraftPersist() async {}
}
''';

  Future<void> _allowsWithTimerDebounce() async {
    await assertAllows(r'''
class DraftNotifier {
  Object? _debounceTimer;

  void _scheduleDraftPersist() {
    Timer(const Object(), () => unawaited(_enqueueDraftPersist()));
  }

  Future<void> _enqueueDraftPersist() async {}
}
''');
  }

  Future<void> _allowsWithDotShorthandTimerDebounce() async {
    await assertAllows(r'''
import 'dart:async';

class DraftNotifier {
  Timer? _debounceTimer;

  void _scheduleDraftPersist() {
    _debounceTimer = .new(Duration.zero, () => unawaited(_enqueueDraftPersist()));
  }

  Future<void> _enqueueDraftPersist() async {}
}
''');
  }

  Future<void> _reportsQueueAndGenerationWithoutDebounce() async {
    const source = r'''
class DraftNotifier {
  Future<void> _persistQueue = Future<void>.value();
  int _persistGeneration = 0;

  void _scheduleDraftPersist() {
    final generation = ++_persistGeneration;
    unawaited(_enqueueDraftPersist(generation));
  }

  Future<void> _enqueueDraftPersist(int generation) async {
    _persistQueue = _persistQueue.then((_) => _persistDraft(generation));
  }

  Future<void> _persistDraft(int generation) async {}
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'void _scheduleDraftPersist(', ruleName),
    ]);
  }

  Future<void> _allowsNonNotifierClass() async {
    await assertAllows(r'''
class Helper {
  void _scheduleDraftPersist() {
    unawaited(_enqueueDraftPersist());
  }
  Future<void> _enqueueDraftPersist() async {}
}
''');
  }

  Future<void> _allowsAwaitedResourceHandleLifecycleWrites() async {
    await assertAllows(r'''
class Store {
  Future<void> write(String handle) async {}
}
class Remote {
  Future<String> create() async => 'synthetic';
}
class Resource {
  const Resource(this.handle);
  final String handle;
}
class ResourceNotifier {
  ResourceNotifier(this.store, this.remote);
  final Store store;
  final Remote remote;

  Future<void> createResource() async {
    final handle = await remote.create();
    await _persistResourceHandle(handle);
  }
  Future<void> reuseResource(Resource existing) async {
    await _persistResourceHandle(existing.handle);
  }
  Future<void> _persistResourceHandle(String handle) async {
    await store.write(handle);
  }
}
''');
  }

  Future<void> _allowsStateWriteAfterAwaitedLifecycleResult() async {
    await assertAllows(r'''
class Remote {
  Future<String> create() async => 'synthetic';
}
class ResourceNotifier {
  ResourceNotifier(this.remote);
  final Remote remote;
  String state = '';

  Future<void> createResource() async {
    final handle = await remote.create();
    state = handle;
    await _persistResourceHandle(handle);
  }
  Future<void> _persistResourceHandle(String handle) async {}
}
''');
  }

  Future<void> _allowsLookalikeLocalPersistFunctionInSetter() async {
    await assertAllows(r'''
class ResourceNotifier {
  String state = '';

  void rename(String handle) {
    Future<void> _persistResourceHandle(String value) async {}
    state = handle;
    _persistResourceHandle(handle);
  }
  Future<void> reuseResource(String handle) async {
    await _persistResourceHandle(handle);
  }
  Future<void> _persistResourceHandle(String handle) async {}
}
''');
  }

  Future<void> _reportsAsyncSetterPersistingAfterStateWrite() async {
    const source = r'''
class ThemeNotifier {
  String state = 'light';

  Future<void> setTheme(String mode) async {
    state = mode;
    await _persistTheme();
  }
  Future<void> _persistTheme() async {}
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Future<void> _persistTheme(', ruleName),
    ]);
  }

  Future<void> _reportsSyncDraftUpdateCallingAsyncPersist() async {
    const source = r'''
class DraftNotifier {
  String state = '';

  Future<void> reuseDraft(String draft) async {
    await _persistDraft(draft);
  }
  void updateDraft(String draft) {
    state = draft;
    _persistDraft(draft);
  }
  Future<void> _persistDraft(String draft) async {}
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Future<void> _persistDraft(', ruleName),
    ]);
  }
}

final class NotifierAsyncInitStaleStateWriteTest extends _RuntimeBugRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  bool get mounted => true;
  T read<T>(Object provider) => throw UnimplementedError();
}

abstract class Notifier<T> {
  Ref get ref => Ref();
  late T state;
  T build();
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_async_init_stale_state_write';
  @override
  String get needle => 'state = state.copyWith(isRestoringDraft: false)';
  @override
  String get source => r'''
class ActiveWorkoutNotifier extends _$ActiveWorkoutNotifier {
  Future<void> _restoreDraft() async {
    final draft = await draftRepository.read();
    state = state.copyWith(isRestoringDraft: false);
  }
}
''';

  Future<void> _allowsGenerationGuardBeforeStateWrite() async {
    await assertAllows(r'''
class ActiveWorkoutNotifier extends _$ActiveWorkoutNotifier {
  int _draftRestoreGeneration = 0;

  Future<void> _restoreDraft() async {
    final restoreGeneration = _draftRestoreGeneration;
    final draft = await draftRepository.read();
    if (_isStaleDraftRestore(restoreGeneration)) {
      return;
    }
    state = state.copyWith(isRestoringDraft: false);
  }

  bool _isStaleDraftRestore(int restoreGeneration) {
    return restoreGeneration != _draftRestoreGeneration;
  }
}
''');
  }

  Future<void> _allowsStateWriteBeforeAwait() async {
    await assertAllows(r'''
class ActiveWorkoutNotifier extends _$ActiveWorkoutNotifier {
  Future<void> _loadWorkout() async {
    state = state.copyWith(isLoading: true);
    await repository.load();
  }
}
''');
  }

  Future<void> _allowsSkillRefMountedGuard() async {
    await assertAllows(
      _productEditorSource('''
    final product = await ref.read<Future<String>>(productRepositoryProvider);
    if (!ref.mounted) return;
    state = state.copyWith(name: product);'''),
      addIgnorePrefix: false,
    );
  }

  Future<void> _reportsMountedGuardOnNonRiverpodRefOrBeforeAwait() async {
    final source = _productEditorSource('''
    if (!ref.mounted) return;
    final product = await ref.read<Future<String>>(productRepositoryProvider);
    final other = _FakeRef();
    if (!other.mounted) return;
    state = state.copyWith(name: product);''');
    await assertDiagnostics(source, [
      compatLint(source, 'state = state.copyWith(name: product)', ruleName),
    ]);
  }

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }

  String _productEditorSource(String body) =>
      '''
import 'package:riverpod/riverpod.dart';

final productRepositoryProvider = Object();

class _FakeRef {
  bool get mounted => true;
}

class ProductFormState {
  const ProductFormState();

  ProductFormState copyWith({String? name}) => this;
}

class ProductEditor extends Notifier<ProductFormState> {
  @override
  ProductFormState build() => const ProductFormState();

  Future<void> _loadProduct(String id) async {
$body
  }
}
''';

  Future<void> _allowsNonNotifierClass() async {
    await assertAllows(r'''
class ActiveWorkoutRepository {
  Future<void> _restoreDraft() async {
    final draft = await draftRepository.read();
    state = state.copyWith(isRestoringDraft: false);
  }
}
''');
  }
}

final class FullCollectionLoadInLoopTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'full_collection_load_in_loop';
  @override
  String get needle => '.getAll(';
  @override
  String get source => r'''
class WorkoutInitializer {
  Future<void> initialize(List<String> exerciseIds) async {
    for (final exerciseId in exerciseIds) {
      final logs = await repository.getAll();
      apply(exerciseId, logs);
    }
  }
}
''';

  Future<void> _allowsLoadBeforeLoop() async {
    await assertAllows(r'''
class WorkoutInitializer {
  Future<void> initialize(List<String> exerciseIds) async {
    final logs = await repository.getAll();
    for (final exerciseId in exerciseIds) {
      apply(exerciseId, logs);
    }
  }
}
''');
  }

  Future<void> _allowsLoaderInLoopHeader() async {
    await assertAllows(r'''
class WorkoutInitializer {
  Future<void> initialize() async {
    for (final log in await repository.getAll()) {
      apply(log);
    }
  }
}
''');
  }

  Future<void> _allowsCollectionForInMapLiteral() async {
    await assertAllows(r'''
class SyncService {
  Future<Map<String, Object>> deltas() async {
    final byId = {
      for (final workout in await repository.getAll())
        workout.id: workout,
    };
    return byId;
  }
}
''');
  }

  Future<void> _allowsLoaderAfterBracelessLoop() async {
    await assertAllows(r'''
class Repo {
  Future<void> sync(List<String> ids) async {
    for (final id in ids) process(id);
    final all = await repository.getAll();
    apply(all);
  }
}
''');
  }
}

final class UnguardedFireAndForgetPlatformCommandTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'unguarded_fire_and_forget_platform_command';
  @override
  String get needle => 'unawaited(';
  @override
  String get source => r'''
class DemoPlayer {
  void togglePlay(Object controller) {
    unawaited(controller.playVideo());
  }
}
''';

  Future<void> _allowsAwaitedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  Future<void> togglePlay(Object controller) async {
    await controller.playVideo();
  }
}
''');
  }

  Future<void> _allowsWrappedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  void togglePlay(Object controller) {
    PlayerCommand.runIgnoringErrors(() => controller.playVideo());
  }
}
''');
  }

  Future<void> _allowsReturnedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  Future<void> togglePlay(Object controller) {
    return controller.playVideo();
  }
}
''');
  }

  Future<void> _allowsCatchError() async {
    await assertAllows(r'''
class DemoPlayer {
  void togglePlay(Object controller) {
    unawaited(controller.playVideo().catchError(_log));
  }
}
''');
  }
}

void _defineSourceScannerRulesPart18Tests() {
  analysisRuleSuite<NotifierPersistenceNoDebounceTest>(
    'NotifierPersistenceNoDebounceTest',
    NotifierPersistenceNoDebounceTest.new,
    {
      'test_allowsWithTimerDebounce': (t) => t._allowsWithTimerDebounce(),
      'test_allowsWithDotShorthandTimerDebounce': (t) => t._allowsWithDotShorthandTimerDebounce(),
      'test_reportsQueueAndGenerationWithoutDebounce': (t) =>
          t._reportsQueueAndGenerationWithoutDebounce(),
      'test_allowsNonNotifierClass': (t) => t._allowsNonNotifierClass(),
      'test_allowsAwaitedResourceHandleLifecycleWrites': (t) =>
          t._allowsAwaitedResourceHandleLifecycleWrites(),
      'test_allowsStateWriteAfterAwaitedLifecycleResult': (t) =>
          t._allowsStateWriteAfterAwaitedLifecycleResult(),
      'test_allowsLookalikeLocalPersistFunctionInSetter': (t) =>
          t._allowsLookalikeLocalPersistFunctionInSetter(),
      'test_reportsAsyncSetterPersistingAfterStateWrite': (t) =>
          t._reportsAsyncSetterPersistingAfterStateWrite(),
      'test_reportsSyncDraftUpdateCallingAsyncPersist': (t) =>
          t._reportsSyncDraftUpdateCallingAsyncPersist(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<NotifierAsyncInitStaleStateWriteTest>(
    'NotifierAsyncInitStaleStateWriteTest',
    NotifierAsyncInitStaleStateWriteTest.new,
    {
      'test_allowsGenerationGuardBeforeStateWrite': (t) =>
          t._allowsGenerationGuardBeforeStateWrite(),
      'test_allowsStateWriteBeforeAwait': (t) => t._allowsStateWriteBeforeAwait(),
      'test_allowsSkillRefMountedGuard': (t) => t._allowsSkillRefMountedGuard(),
      'test_reportsMountedGuardOnNonRiverpodRefOrBeforeAwait': (t) =>
          t._reportsMountedGuardOnNonRiverpodRefOrBeforeAwait(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsNonNotifierClass': (t) => t._allowsNonNotifierClass(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<UserVisibleDurationTooLongTest>(
    'UserVisibleDurationTooLongTest',
    UserVisibleDurationTooLongTest.new,
    {
      'test_reportsHardWaitInAsyncMethod': (t) => t._reportsHardWaitInAsyncMethod(),
      'test_allowsSyncSettleTimerInAsyncMethod': (t) => t._allowsSyncSettleTimerInAsyncMethod(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<FullCollectionLoadInLoopTest>(
    'FullCollectionLoadInLoopTest',
    FullCollectionLoadInLoopTest.new,
    {
      'test_allowsLoadBeforeLoop': (t) => t._allowsLoadBeforeLoop(),
      'test_allowsLoaderInLoopHeader': (t) => t._allowsLoaderInLoopHeader(),
      'test_allowsCollectionForInMapLiteral': (t) => t._allowsCollectionForInMapLiteral(),
      'test_allowsLoaderAfterBracelessLoop': (t) => t._allowsLoaderAfterBracelessLoop(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<UnguardedFireAndForgetPlatformCommandTest>(
    'UnguardedFireAndForgetPlatformCommandTest',
    UnguardedFireAndForgetPlatformCommandTest.new,
    {
      'test_allowsAwaitedCommand': (t) => t._allowsAwaitedCommand(),
      'test_allowsWrappedCommand': (t) => t._allowsWrappedCommand(),
      'test_allowsReturnedCommand': (t) => t._allowsReturnedCommand(),
      'test_allowsCatchError': (t) => t._allowsCatchError(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<ScrollListenerWidgetPrefixTest>(
    'ScrollListenerWidgetPrefixTest',
    ScrollListenerWidgetPrefixTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<ScrollListenerAllowsDebouncerTest>(
    'ScrollListenerAllowsDebouncerTest',
    ScrollListenerAllowsDebouncerTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<UserVisibleDurationAllowsSnappyDebounceTest>(
    'UserVisibleDurationAllowsSnappyDebounceTest',
    UserVisibleDurationAllowsSnappyDebounceTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<UserVisibleDurationAllowsRetryBackoffTest>(
    'UserVisibleDurationAllowsRetryBackoffTest',
    UserVisibleDurationAllowsRetryBackoffTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<UserVisibleDurationAllowsDismissTimerTest>(
    'UserVisibleDurationAllowsDismissTimerTest',
    UserVisibleDurationAllowsDismissTimerTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<UserVisibleDurationAllowsSnackBarDurationTest>(
    'UserVisibleDurationAllowsSnackBarDurationTest',
    UserVisibleDurationAllowsSnackBarDurationTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DebugPrintBlankingMasksMatchesTest>(
    'DebugPrintBlankingMasksMatchesTest',
    DebugPrintBlankingMasksMatchesTest.new,
    {
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
      'test_allowsPrintStatement': (t) => t._allowsPrintStatement(),
    },
  );
  analysisRuleSuite<IsTestFileSkipsRuleTest>(
    'IsTestFileSkipsRuleTest',
    IsTestFileSkipsRuleTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DialogRuleSkipsTestFileTest>(
    'DialogRuleSkipsTestFileTest',
    DialogRuleSkipsTestFileTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DebugPrintMultilineBlankingTest>(
    'DebugPrintMultilineBlankingTest',
    DebugPrintMultilineBlankingTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DatasourceBoundaryFourGettersAllowedTest>(
    'DatasourceBoundaryFourGettersAllowedTest',
    DatasourceBoundaryFourGettersAllowedTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DatasourceBoundaryFiveGettersFiresTest>(
    'DatasourceBoundaryFiveGettersFiresTest',
    DatasourceBoundaryFiveGettersFiresTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
}
