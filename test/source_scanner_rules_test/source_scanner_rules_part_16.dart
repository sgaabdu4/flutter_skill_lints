// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class WebViewInitInBuildNoGateTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'webview_init_in_build_no_gate';
  @override
  String get needle => 'WebViewWidget(controller:';
  @override
  String get source => r'''
class WebViewWidget {
  WebViewWidget({Object? controller});
}
class ConsumerWidget extends Widget {}

class DemoSheet extends ConsumerWidget {
  Object build(Object context) {
    return WebViewWidget(controller: Object());
  }
}
''';

  Future<void> test_allowsWithUserTappedGate() async {
    await assertAllows(r'''
class WebViewWidget {
  WebViewWidget({Object? controller});
}
class ConsumerWidget extends Widget {}

class DemoSheet extends ConsumerWidget {
  bool _userTappedPlay = false;
  Object build(Object context) {
    if (_userTappedPlay) return WebViewWidget(controller: Object());
    return Object();
  }
}
''');
  }

  Future<void> test_reportsWhenGateFieldExistsButConstructorUngated() async {
    final analyzedSource = _analyzedSource(r'''
class WebViewWidget {
  WebViewWidget({Object? controller});
}
class ConsumerWidget extends Widget {}

class DemoSheet extends ConsumerWidget {
  bool _userTappedPlay = false;
  Object build(Object context) {
    return WebViewWidget(controller: Object());
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'WebViewWidget(controller:', ruleName),
    ]);
  }

  Future<void> test_allowsHeavyWidgetOutsideBuild() async {
    await assertAllows(r'''
class WebViewWidget {
  WebViewWidget({Object? controller});
}
class ConsumerWidget extends Widget {}

class DemoSheet extends ConsumerWidget {
  Object onTap() => WebViewWidget(controller: Object());
  Object build(Object context) => Object();
}
''');
  }
}

@reflectiveTest
final class ServiceStorageReadNoMemoTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'service_storage_read_no_memo';
  @override
  String get needle => '_storage.read<bool>(key)';
  @override
  String get source => r'''
class PreferenceService {
  final Object _storage = Object();
  Future<bool> shouldShowPrompt(Object tour) async {
    final seen = await _storage.read<bool>(key);
    return seen;
  }
}
''';

  Future<void> test_allowsWithMemoCache() async {
    await assertAllows(r'''
class PreferenceService {
  final Object _storage = Object();
  final Map<String, bool> _cache = {};
  Future<bool> shouldShowPrompt(Object tour) async {
    if (_cache.containsKey(key)) return _cache[key]!;
    final seen = await _storage.read<bool>(key);
    return seen;
  }
}
''');
  }

  Future<void> test_allowsNonServiceClass() async {
    await assertAllows(r'''
class ContentRepository {
  final Object _storage = Object();
  Future<bool> shouldShowPrompt(Object tour) async {
    final seen = await _storage.read<bool>(key);
    return seen;
  }
}
''');
  }
}

@reflectiveTest
final class KeepAliveWatchesUnboundedCollectionTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'keepalive_watches_unbounded_collection';
  @override
  String get needle => 'ref.watch(historyProvider.select((s) => s.logs))';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class ProgressNotifier {
  Object build() {
    final ref = Object();
    final logs = ref.watch(historyProvider.select((s) => s.logs));
    return [...logs];
  }
}
''';

  Future<void> test_allowsPureProjection() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class ProgressNotifier {
  Object build() {
    final ref = Object();
    final logs = ref.watch(historyProvider.select((s) => s.logs));
    return logs;
  }
}
''');
  }

  Future<void> test_allowsDirectPureProjection() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
Object historyLogs(Object ref) {
  return ref.watch(historyProvider.select((s) => s.logs));
}
''');
  }

  Future<void> test_allowsExpressionBodyPureProjection() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
Object historyLogs(Object ref) => ref.watch(historyProvider.select((s) => s.logs));
''');
  }

  Future<void> test_allowsAutoDispose() async {
    await assertAllows(r'''
class ProgressNotifier {
  Object build() {
    final ref = Object();
    final logs = ref.watch(historyProvider.select((s) => s.logs));
    return logs;
  }
}
''');
  }

  Future<void> test_allowsKeepAliveWithBoundedProjection() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class ProgressNotifier {
  Object build() {
    final ref = Object();
    final count = ref.watch(historyProvider.select((s) => s.count));
    return count;
  }
}
''');
  }

  Future<void> test_reportsMultilineSelect() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

@Riverpod(keepAlive: true)
class ProgressNotifier {
  Object build() {
    final ref = Object();
    return [
      ...ref.watch(
        historyProvider.select((s) => s.logs),
      ),
    ];
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ref.watch(', ruleName)]);
  }
}

@reflectiveTest
final class DatasourceMissingBatchLoaderTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'datasource_missing_batch_loader';
  @override
  String get needle => 'class SettingsLocalDatasource';
  @override
  String get source => r'''
abstract class SettingsLocalDatasource {
  Future<bool> isOnboardingCompleted();
  Future<Object> getItemMode();
  Future<bool> isItemReminderEnabled();
  Future<Object> getDefaultRestTime();
  Future<Object> getWeightUnit();
  Future<Object> getReminderDays();
}
''';

  Future<void> test_allowsWithLoadAll() async {
    await assertAllows(r'''
abstract class SettingsLocalDatasource {
  Future<Object> loadAll();
  Future<bool> isOnboardingCompleted();
  Future<Object> getItemMode();
  Future<bool> isItemReminderEnabled();
  Future<Object> getDefaultRestTime();
  Future<Object> getWeightUnit();
  Future<Object> getReminderDays();
}
''');
  }

  Future<void> test_allowsSmallInterface() async {
    await assertAllows(r'''
abstract class SettingsLocalDatasource {
  Future<Object> getToken();
  Future<bool> isExpired();
}
''');
  }
}

@reflectiveTest
final class NotifierZeroValueSaveNoGuardTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_zero_value_save_no_guard';
  @override
  String get needle => '.saveEntry(';
  @override
  String get source => r'''
class EntrySheet {
  void _save(Object ref, int totalSeconds, double distance) {
    ref.read(activeProvider.notifier).saveEntry(
      durationSeconds: totalSeconds,
      distanceMeters: distance,
    );
  }
}
''';

  Future<void> test_allowsWithPositiveGuard() async {
    await assertAllows(r'''
class EntrySheet {
  void _save(Object ref, int totalSeconds, double distance) {
    if (totalSeconds > 0 || distance > 0) {
      ref.read(activeProvider.notifier).saveEntry(
        durationSeconds: totalSeconds,
        distanceMeters: distance,
      );
    }
  }
}
''');
  }

  Future<void> test_allowsNonSaveCall() async {
    await assertAllows(r'''
class EntrySheet {
  void _show(Object ref, int totalSeconds) {
    ref.read(activeProvider.notifier).preview(totalSeconds: totalSeconds);
  }
}
''');
  }

  Future<void> test_reportsPlainSaveMethod() async {
    final analyzedSource = _analyzedSource(r'''
class EntrySheet {
  void _save(Object ref, int totalSeconds) {
    ref.read(activeProvider.notifier).save(
      durationSeconds: totalSeconds,
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.save(', ruleName)]);
  }
}

@reflectiveTest
final class NotifierParamRequiresValueObjectTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_param_requires_value_object';
  @override
  String get needle => '.saveEntry(';
  @override
  String get source => r'''
class EntrySheet {
  void _save(Object ref) {
    double distanceMeters = 78000.0;
    ref.read(activeProvider.notifier).saveEntry(distanceMeters: distanceMeters);
  }
}
''';

  Future<void> test_allowsValueObjectAtBoundary() async {
    await assertAllows(r'''
class EntrySheet {
  void _save(Object ref) {
    final distance = Distance.fromMeters(78000.0);
    ref.read(activeProvider.notifier).saveEntry(distance: distance);
  }
}
''');
  }

  Future<void> test_allowsPlainNonUnitLocal() async {
    await assertAllows(r'''
class EntrySheet {
  void _save(Object ref) {
    double amount = 5;
    ref.read(activeProvider.notifier).saveEntry(amount: amount);
  }
}
''');
  }

  Future<void> test_reportsPlainSaveMethod() async {
    final analyzedSource = _analyzedSource(r'''
class EntrySheet {
  void _save(Object ref) {
    double distanceMeters = 78000.0;
    ref.read(activeProvider.notifier).save(distance: distanceMeters);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.save(', ruleName)]);
  }
}
