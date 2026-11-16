part of '../source_scanner_rules_test.dart';

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

  Future<void> _allowsWithUserTappedGate() async {
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

  Future<void> _reportsWhenGateFieldExistsButConstructorUngated() async {
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

  Future<void> _allowsHeavyWidgetOutsideBuild() async {
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

  Future<void> _allowsWithMemoCache() async {
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

  Future<void> _allowsNonServiceClass() async {
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

final class KeepAliveWatchesResolvedProviderLifecycleTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'keepalive_watches_unbounded_collection';
  @override
  String get needle => 'ref.watch(productProvider.select((s) => s.items))';
  @override
  String get path => '$testPackageLibPath/features/products/presentation/notifiers/sorted.dart';
  @override
  String get source => _sortedProducts;

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
}
class ProviderListenable<T> {
  const ProviderListenable();
  ProviderListenable<R> select<R>(R Function(T value) selector) => throw UnimplementedError();
}
''');
    super.setUp();
  }

  @override
  Future<void> _reportsDiagnostic() async {
    _addProductNotifier(keepAlive: false);
    await super._reportsDiagnostic();
  }

  Future<void> _allowsKeepAliveSourceFromAnotherFile() async {
    _addProductNotifier(keepAlive: true);
    await assertAllows(_sortedProducts, path: path, addIgnorePrefix: false);
  }

  void _addProductNotifier({required bool keepAlive}) {
    newFile('$testPackageLibPath/features/products/presentation/notifiers/product.dart', '''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class ProductState {
  const ProductState();
  List<int> get items => const [];
}

${keepAlive ? '@Riverpod(keepAlive: true)' : '@riverpod'}
class ProductNotifier {
  ProductState build() => const ProductState();
}

@ProviderFor(ProductNotifier)
const productProvider = ProviderListenable<ProductState>();
''');
  }

  static const _sortedProducts = r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'product.dart';

@Riverpod(keepAlive: true)
List<int> sortedProducts(Ref ref) {
  final items = ref.watch(productProvider.select((s) => s.items));
  return [...items];
}
''';
}

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

  Future<void> _reportsLocalPureProjection() async {
    final analyzedSource = _analyzedSource(r'''
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
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ref.watch(', ruleName)]);
  }

  Future<void> _reportsDirectPureProjection() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}
class Ref {}

@Riverpod(keepAlive: true)
Object historyLogs(Ref ref) {
  return ref.watch(historyProvider.select((s) => s.logs));
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ref.watch(', ruleName)]);
  }

  /// The skill's NEVER example (common-patterns/debounce-gate-batch.md).
  Future<void> _reportsSkillNeverExpressionBodyProjection() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}
class Ref {}
class Log {}

@Riverpod(keepAlive: true)
List<Log> session(Ref ref) => ref.watch(provider.select((s) => s.logs));
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ref.watch(', ruleName)]);
  }

  /// The skill's DO counterpart (common-patterns/debounce-gate-batch.md).
  Future<void> _allowsSkillDoBoundedProjection() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}
class Ref {}

@Riverpod(keepAlive: true)
int sessionCount(Ref ref) => ref.watch(provider.select((s) => s.count));
''');
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}
class Ref {}

@Riverpod(keepAlive: true)
Object sessionCount(Ref ref) => ref.watch(provider.select((s) => s.count));
''');
  }

  Future<void> _allowsAutoDispose() async {
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

  Future<void> _allowsKeepAliveWithBoundedProjection() async {
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

  Future<void> _reportsMultilineSelect() async {
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

  Future<void> _allowsWithLoadAll() async {
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

  Future<void> _allowsSmallInterface() async {
    await assertAllows(r'''
abstract class SettingsLocalDatasource {
  Future<Object> getToken();
  Future<bool> isExpired();
}
''');
  }
}

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

  Future<void> _allowsWithPositiveGuard() async {
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

  Future<void> _allowsDocEarlyReturnGuard() async {
    await assertAllows(r'''
class EntrySheet {
  void submit(Object ref, int amount, int count) {
    if (amount <= 0 && count <= 0) return; // no empty rows
    ref.read(provider.notifier).saveEntry(amount: amount, count: count);
  }
}
''');
  }

  Future<void> _allowsValueObjectSave() async {
    await assertAllows(r'''
class Distance {
  const Distance.fromMeters(this.meters);
  final double meters;
}

class EntrySheet {
  void submit(Object ref, double parsed) {
    final distance = Distance.fromMeters(parsed);
    ref.read(provider.notifier).save(distance: distance);
  }
}
''');
  }

  Future<void> _reportsZeroCheckThatDoesNotExit() async {
    final analyzedSource = _analyzedSource(r'''
class EntrySheet {
  void submit(Object ref, int amount, int count, List<String> log) {
    if (amount <= 0 && count <= 0) log.add('empty');
    ref.read(provider.notifier).saveEntry(amount: amount, count: count);
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '.saveEntry(', ruleName)]);
  }

  Future<void> _allowsNonSaveCall() async {
    await assertAllows(r'''
class EntrySheet {
  void _show(Object ref, int totalSeconds) {
    ref.read(activeProvider.notifier).preview(totalSeconds: totalSeconds);
  }
}
''');
  }

  Future<void> _reportsPlainSaveMethod() async {
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

  Future<void> _allowsValueObjectAtBoundary() async {
    await assertAllows(r'''
class EntrySheet {
  void _save(Object ref) {
    final distance = Distance.fromMeters(78000.0);
    ref.read(activeProvider.notifier).saveEntry(distance: distance);
  }
}
''');
  }

  Future<void> _allowsPlainNonUnitLocal() async {
    await assertAllows(r'''
class EntrySheet {
  void _save(Object ref) {
    double amount = 5;
    ref.read(activeProvider.notifier).saveEntry(amount: amount);
  }
}
''');
  }

  Future<void> _reportsPlainSaveMethod() async {
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

void _defineSourceScannerRulesPart16Tests() {
  analysisRuleSuite<WebViewInitInBuildNoGateTest>(
    'WebViewInitInBuildNoGateTest',
    WebViewInitInBuildNoGateTest.new,
    {
      'test_allowsWithUserTappedGate': (t) => t._allowsWithUserTappedGate(),
      'test_reportsWhenGateFieldExistsButConstructorUngated': (t) =>
          t._reportsWhenGateFieldExistsButConstructorUngated(),
      'test_allowsHeavyWidgetOutsideBuild': (t) => t._allowsHeavyWidgetOutsideBuild(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<ServiceStorageReadNoMemoTest>(
    'ServiceStorageReadNoMemoTest',
    ServiceStorageReadNoMemoTest.new,
    {
      'test_allowsWithMemoCache': (t) => t._allowsWithMemoCache(),
      'test_allowsNonServiceClass': (t) => t._allowsNonServiceClass(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<KeepAliveWatchesUnboundedCollectionTest>(
    'KeepAliveWatchesUnboundedCollectionTest',
    KeepAliveWatchesUnboundedCollectionTest.new,
    {
      'test_reportsLocalPureProjection': (t) => t._reportsLocalPureProjection(),
      'test_reportsDirectPureProjection': (t) => t._reportsDirectPureProjection(),
      'test_reportsSkillNeverExpressionBodyProjection': (t) =>
          t._reportsSkillNeverExpressionBodyProjection(),
      'test_allowsSkillDoBoundedProjection': (t) => t._allowsSkillDoBoundedProjection(),
      'test_allowsAutoDispose': (t) => t._allowsAutoDispose(),
      'test_allowsKeepAliveWithBoundedProjection': (t) => t._allowsKeepAliveWithBoundedProjection(),
      'test_reportsMultilineSelect': (t) => t._reportsMultilineSelect(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<KeepAliveWatchesResolvedProviderLifecycleTest>(
    'KeepAliveWatchesResolvedProviderLifecycleTest',
    KeepAliveWatchesResolvedProviderLifecycleTest.new,
    {
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
      'test_allowsKeepAliveSourceFromAnotherFile': (t) => t._allowsKeepAliveSourceFromAnotherFile(),
    },
  );
  analysisRuleSuite<DatasourceMissingBatchLoaderTest>(
    'DatasourceMissingBatchLoaderTest',
    DatasourceMissingBatchLoaderTest.new,
    {
      'test_allowsWithLoadAll': (t) => t._allowsWithLoadAll(),
      'test_allowsSmallInterface': (t) => t._allowsSmallInterface(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<NotifierZeroValueSaveNoGuardTest>(
    'NotifierZeroValueSaveNoGuardTest',
    NotifierZeroValueSaveNoGuardTest.new,
    {
      'test_allowsWithPositiveGuard': (t) => t._allowsWithPositiveGuard(),
      'test_allowsDocEarlyReturnGuard': (t) => t._allowsDocEarlyReturnGuard(),
      'test_allowsValueObjectSave': (t) => t._allowsValueObjectSave(),
      'test_reportsZeroCheckThatDoesNotExit': (t) => t._reportsZeroCheckThatDoesNotExit(),
      'test_allowsNonSaveCall': (t) => t._allowsNonSaveCall(),
      'test_reportsPlainSaveMethod': (t) => t._reportsPlainSaveMethod(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<NotifierParamRequiresValueObjectTest>(
    'NotifierParamRequiresValueObjectTest',
    NotifierParamRequiresValueObjectTest.new,
    {
      'test_allowsValueObjectAtBoundary': (t) => t._allowsValueObjectAtBoundary(),
      'test_allowsPlainNonUnitLocal': (t) => t._allowsPlainNonUnitLocal(),
      'test_reportsPlainSaveMethod': (t) => t._reportsPlainSaveMethod(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
}
