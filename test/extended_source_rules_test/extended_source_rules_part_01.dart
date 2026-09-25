// ignore_for_file: non_constant_identifier_names

part of '../extended_source_rules_test.dart';

abstract class _ServicesExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesExtendedSourceRules;
}

@reflectiveTest
final class ServiceStaticSideEffectTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'service_static_side_effect';
  @override
  String get source => '''
abstract final class TokenUtils {
  static String make() => DateTime.now().millisecondsSinceEpoch.toString();
}
''';
  @override
  String get needle => 'abstract final class TokenUtils';

  Future<void> test_allowsTinyDirectSdkFacade() async {
    await assertAllows('''
abstract final class AnalyticsLog {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static Future<void> event(String name) {
    return _analytics.logEvent(name: name);
  }

  static Future<void> breadcrumb(String message) {
    return FirebaseCrashlytics.instance.log(message);
  }
}
''');
  }

  // hive-persistence.md "Testing with TypeAdapters": test helpers are not
  // production service facades.
  Future<void> test_allowsStaticTestHelperInTests() async {
    await assertAllows('''
import 'dart:io';

abstract final class HiveTestHelper {
  static Future<Directory> initialize(String testName) async => Directory(testName);
}
''', path: '$testPackageRootPath/test/shared/hive_test_helper.dart');
  }

  Future<void> test_reportsDataReturningStaticFacade() async {
    const source = '''
abstract final class AnalyticsLog {
  static FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  static Future<String> userId() async => 'id';
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'abstract final class AnalyticsLog', ruleName),
    ]);
  }

  Future<void> test_reportsPublicStaticGetter() async {
    const source = '''
abstract final class AnalyticsLog {
  static FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  static Future<void> event(String name) {
    return analytics.logEvent(name: name);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'abstract final class AnalyticsLog', ruleName),
    ]);
  }

  Future<void> test_reportsOverbuiltDebugBackendFacade() async {
    const source = '''
abstract final class AnalyticsLog {
  static IAnalyticsBackend _backend = FirebaseAnalyticsBackend();

  static void debugUseBackend(IAnalyticsBackend backend) {
    _backend = backend;
  }

  static Future<void> event(String name) {
    return FirebaseAnalytics.instance.logEvent(name: name);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'abstract final class AnalyticsLog', ruleName),
    ]);
  }
}

@reflectiveTest
final class ServiceRandomPerCallTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'service_random_per_call';
  @override
  String get source => '''
import 'dart:math' as math;

class RetryDelay {
  int next() {
    final rng = math.Random();
    return rng.nextInt(10);
  }
}
''';
  @override
  String get needle => 'Random';

  Future<void> test_reportsTopLevelFunctionAndClosure() async {
    const source = '''
import 'dart:math';

Duration jitter() {
  final perCall = Random();
  return Duration(milliseconds: perCall.nextInt(100));
}

final pick = () => Random(7).nextBool();
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Random();', ruleName),
      compatLint(analyzedSource, 'Random(7)', ruleName),
    ]);
  }

  Future<void> test_allowsHoistedModuleAndStaticRandom() async {
    await assertAllows('''
import 'dart:math' as math;

final _rng = math.Random();

class RetryDelay {
  static final _shared = math.Random();

  int next() => _rng.nextInt(10) + _shared.nextInt(10);
}

Duration jitter() => Duration(milliseconds: _rng.nextInt(100));
''');
  }
}

@reflectiveTest
final class HiddenDependencyFallbackTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'hidden_dependency_fallback';
  @override
  String get source => '''
class NotificationServiceHost {
  NotificationServiceHost({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
}
''';
  @override
  String get needle => '?? FlutterLocalNotificationsPlugin';

  Future<void> test_reportsRepositoryFallback() async {
    const source = '''
class ExerciseRepository {
  ExerciseRepository([IRemoteMutationQueue? queue])
    : _queue = queue ?? RemoteMutationQueue();

  final IRemoteMutationQueue _queue;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '?? RemoteMutationQueue', ruleName),
    ]);
  }

  Future<void> test_reportsFunctionDependencyFallback() async {
    const source = '''
typedef DeleteAccountPollDelay = Future<void> Function(Duration duration);

class AuthRemoteDatasource {
  AuthRemoteDatasource({DeleteAccountPollDelay? deleteAccountPollDelay})
    : _delay = deleteAccountPollDelay ?? ((duration) => Future<void>.delayed(duration));

  final DeleteAccountPollDelay _delay;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'deleteAccountPollDelay ??', ruleName),
    ]);
  }

  Future<void> test_allowsNullableDomainValueFallback() async {
    await assertAllows('''
class FormState {
  final String? title;
  String get displayTitle => title ?? 'Untitled';
}
''');
  }

  Future<void> test_allowsFallbacksInTests() async {
    await assertAllows('''
void main() {
  final service = overrideService ?? FakeNotificationService();
}
''', path: '$testPackageRootPath/test/service_test.dart');
  }
}

@reflectiveTest
final class ImplicitNullFallbackTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'implicit_null_fallback';
  @override
  String get source => '''
class ProfileState {
  String label(String? name) => name ?? '';
}
''';
  @override
  String get needle => "?? ''";

  // context-ui.md:22, routing-app-shell.md:198 and lists-forms-workflows.md:218
  // use primitive bool/num fallbacks in canonical code.
  Future<void> test_allowsSkillPrimitiveBoolAndNumFallbacks() async {
    await assertAllows('''
extension BuildContextX on BuildContext {
  bool get isCurrentModalRoute => ModalRoute.of(this)?.isCurrent ?? false;
}

void onAuthChanged(AuthState? prev, AuthState next) {
  if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
    const HomeRoute().go(context);
  }
}

class ProductFormNotifier {
  void setPrice(String value) {
    final parsed = double.tryParse(value);
    state = state.copyWith(
      draftPrice: parsed ?? 0,
      priceError: null,
    );
  }

  bool isVisible(bool? hidden) => !(hidden ?? true);
}
''');
  }

  Future<void> test_reportsEmptyStringAndCollectionFallbacks() async {
    const source = '''
class ProfileView {
  String name(String? value) => value ?? "";
  List<int> ids(List<int>? value) => value ?? const [];
  Map<String, int> counts(Map<String, int>? value) => value ?? {};
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '?? ""', ruleName),
      compatLint(analyzedSource, '?? const []', ruleName),
      compatLint(analyzedSource, '?? {}', ruleName),
    ]);
  }

  Future<void> test_reportsChainedPrimitiveFallback() async {
    const source = '''
class Insets {
  double resolve(double? bottom, double? vertical) => bottom ?? vertical ?? 0;
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '?? vertical ??', ruleName),
    ]);
  }

  Future<void> test_reportsNullableCallbackToStringFallback() async {
    const source = '''
class ChipGroup<T> {
  String label(T item, String Function(T)? labelBuilder) =>
      labelBuilder?.call(item) ?? item.toString();
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '?.call(item) ??', ruleName),
    ]);
  }

  Future<void> test_allowsCopyWithFallback() async {
    await assertAllows('''
class FormState {
  const FormState(this.title);
  final String title;

  FormState copyWith({String? title}) => FormState(title ?? this.title);
}
''');
  }

  Future<void> test_allowsThrowFallback() async {
    await assertAllows('''
class RequiredLookup {
  String read(Map<String, String> values) =>
      values['id'] ?? (throw StateError('missing id'));
}
''');
  }

  Future<void> test_allowsFallbacksInTests() async {
    await assertAllows('''
void main() {
  final granted = overrideGranted ?? false;
}
''', path: '$testPackageRootPath/test/permission_test.dart');
  }
}

@reflectiveTest
final class FireForgetInTestsTest extends _ServicesExtendedRuleTest {
  @override
  String get ruleName => 'fire_forget_in_tests';
  @override
  String get path => '$testPackageRootPath/test/analytics_test.dart';
  @override
  String get source => 'void main() { unawaited(service.track()); }';
  @override
  String get needle => 'unawaited';
}
