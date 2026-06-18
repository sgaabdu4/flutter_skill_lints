// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
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

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source);
  }
}

@reflectiveTest
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
}

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

@reflectiveTest
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source, path: path);
  }
}

@reflectiveTest
final class DebugPrintBlankingMasksMatchesTest extends _RuntimeBugRuleTest {
  // Lock in the source_scanner_rule._blankDebugCalls behavior: tokens that
  // would otherwise trigger a rule MUST be ignored when buried inside
  // `debugPrint(...)` / `print(...)`.
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source);
  }

  Future<void> test_allowsPrintStatement() async {
    await assertAllows(r'''
class HiddenPrintCall {
  void log() {
    print("ref.read(provider.notifier).saveEntry(amount: 0)");
  }
}
''');
  }
}

@reflectiveTest
final class IsTestFileSkipsRuleTest extends _RuntimeBugRuleTest {
  // Confirm the universal `if (context.isTestFile) return;` early-exit at the
  // top of every new rule scan: identical buggy fixture under a `_test.dart`
  // path must produce no diagnostic.
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
  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    newFile(path!, analyzedSource);
    await assertNoDiagnosticsInFile(path!);
  }
}

@reflectiveTest
final class DialogRuleSkipsTestFileTest extends _DialogRuleTest {
  // Per-family coverage of the universal `if (context.isTestFile) return;`
  // guard: dialog rule under a `_test.dart` path must produce no diagnostic
  // even with an obviously buggy fixture.
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
  Future<void> test_reportsDiagnostic() async {
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    newFile(path!, analyzedSource);
    await assertNoDiagnosticsInFile(path!);
  }
}

@reflectiveTest
final class DebugPrintMultilineBlankingTest extends _RuntimeBugRuleTest {
  // Cover the multi-line branch of source_scanner_rule._blankDebugCalls: a
  // `debugPrint(...)` spanning multiple lines must blank EVERY embedded
  // token so a buggy-looking string never triggers a downstream rule.
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source);
  }
}

@reflectiveTest
final class DatasourceBoundaryFourGettersAllowedTest extends _RuntimeBugRuleTest {
  // Boundary: 4 single-value getters is just under the `< 5` cutoff — must
  // NOT trigger. Locks the off-by-one in case the threshold is ever tweaked.
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
  Future<void> test_reportsDiagnostic() async {
    await assertAllows(source);
  }
}

@reflectiveTest
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

@reflectiveTest
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

  Future<void> test_allowsWithTimerDebounce() async {
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

  Future<void> test_reportsQueueAndGenerationWithoutDebounce() async {
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

  Future<void> test_allowsNonNotifierClass() async {
    await assertAllows(r'''
class Helper {
  void _scheduleDraftPersist() {
    unawaited(_enqueueDraftPersist());
  }
  Future<void> _enqueueDraftPersist() async {}
}
''');
  }
}

@reflectiveTest
final class NotifierAsyncInitStaleStateWriteTest extends _RuntimeBugRuleTest {
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

  Future<void> test_allowsGenerationGuardBeforeStateWrite() async {
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

  Future<void> test_allowsStateWriteBeforeAwait() async {
    await assertAllows(r'''
class ActiveWorkoutNotifier extends _$ActiveWorkoutNotifier {
  Future<void> _loadWorkout() async {
    state = state.copyWith(isLoading: true);
    await repository.load();
  }
}
''');
  }

  Future<void> test_allowsNonNotifierClass() async {
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

@reflectiveTest
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

  Future<void> test_allowsLoadBeforeLoop() async {
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

  Future<void> test_allowsLoaderInLoopHeader() async {
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

  Future<void> test_allowsCollectionForInMapLiteral() async {
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

  Future<void> test_allowsLoaderAfterBracelessLoop() async {
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

@reflectiveTest
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

  Future<void> test_allowsAwaitedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  Future<void> togglePlay(Object controller) async {
    await controller.playVideo();
  }
}
''');
  }

  Future<void> test_allowsWrappedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  void togglePlay(Object controller) {
    PlayerCommand.runIgnoringErrors(() => controller.playVideo());
  }
}
''');
  }

  Future<void> test_allowsReturnedCommand() async {
    await assertAllows(r'''
class DemoPlayer {
  Future<void> togglePlay(Object controller) {
    return controller.playVideo();
  }
}
''');
  }

  Future<void> test_allowsCatchError() async {
    await assertAllows(r'''
class DemoPlayer {
  void togglePlay(Object controller) {
    unawaited(controller.playVideo().catchError(_log));
  }
}
''');
  }
}
