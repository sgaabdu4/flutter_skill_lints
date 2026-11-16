part of '../extended_source_rules_test.dart';

abstract class _ServicesExtendedRuleTest extends _ExtendedSourceRuleTest {
  @override
  List<ScannerRule> get rules => servicesExtendedSourceRules;
}

final class _ServiceStaticSideEffectTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_ServiceStaticSideEffectTest)> get _allCases =>
      caseSet<_ServiceStaticSideEffectTest>(
        parent: _ExtendedSourceRuleTest._allCases,
        own: {
          'test_allowsTinyDirectSdkFacade': (t) => t._allowsTinyDirectSdkFacade(),
          'test_allowsStaticTestHelperInTests': (t) => t._allowsStaticTestHelperInTests(),
          'test_reportsDataReturningStaticFacade': (t) => t._reportsDataReturningStaticFacade(),
          'test_reportsPublicStaticGetter': (t) => t._reportsPublicStaticGetter(),
          'test_reportsOverbuiltDebugBackendFacade': (t) => t._reportsOverbuiltDebugBackendFacade(),
        },
      );

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

  Future<void> _allowsTinyDirectSdkFacade() async {
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

  // Test helpers are not production service facades (hive-persistence.md).
  Future<void> _allowsStaticTestHelperInTests() async {
    await assertAllows('''
import 'dart:io';

abstract final class HiveTestHelper {
  static Future<Directory> initialize(String testName) async => Directory(testName);
}
''', path: '$testPackageRootPath/test/shared/hive_test_helper.dart');
  }

  Future<void> _reportsDataReturningStaticFacade() async {
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

  Future<void> _reportsPublicStaticGetter() async {
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

  Future<void> _reportsOverbuiltDebugBackendFacade() async {
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

final class _ServiceRandomPerCallTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_ServiceRandomPerCallTest)> get _allCases =>
      caseSet<_ServiceRandomPerCallTest>(
        parent: _ExtendedSourceRuleTest._allCases,
        own: {
          'test_reportsTopLevelFunctionAndClosure': (t) => t._reportsTopLevelFunctionAndClosure(),
          'test_allowsHoistedModuleAndStaticRandom': (t) => t._allowsHoistedModuleAndStaticRandom(),
        },
      );

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

  Future<void> _reportsTopLevelFunctionAndClosure() async {
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

  Future<void> _allowsHoistedModuleAndStaticRandom() async {
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

final class _HiddenDependencyFallbackTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_HiddenDependencyFallbackTest)> get _allCases =>
      caseSet<_HiddenDependencyFallbackTest>(
        parent: _ExtendedSourceRuleTest._allCases,
        own: {
          'test_reportsRepositoryFallback': (t) => t._reportsRepositoryFallback(),
          'test_reportsFunctionDependencyFallback': (t) => t._reportsFunctionDependencyFallback(),
          'test_allowsNullableDomainValueFallback': (t) => t._allowsNullableDomainValueFallback(),
          'test_allowsFallbacksInTests': (t) => t._allowsFallbacksInTests(),
        },
      );

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

  Future<void> _reportsRepositoryFallback() async {
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

  Future<void> _reportsFunctionDependencyFallback() async {
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

  Future<void> _allowsNullableDomainValueFallback() async {
    await assertAllows('''
class FormState {
  final String? title;
  String get displayTitle => title ?? 'Untitled';
}
''');
  }

  Future<void> _allowsFallbacksInTests() async {
    await assertAllows('''
void main() {
  final service = overrideService ?? FakeNotificationService();
}
''', path: '$testPackageRootPath/test/service_test.dart');
  }
}

final class _ImplicitNullFallbackTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_ImplicitNullFallbackTest)> get _allCases =>
      caseSet<_ImplicitNullFallbackTest>(
        parent: _ExtendedSourceRuleTest._allCases,
        own: {
          'test_allowsSkillPrimitiveBoolAndNumFallbacks': (t) =>
              t._allowsSkillPrimitiveBoolAndNumFallbacks(),
          'test_reportsEmptyStringAndCollectionFallbacks': (t) =>
              t._reportsEmptyStringAndCollectionFallbacks(),
          'test_reportsChainedPrimitiveFallback': (t) => t._reportsChainedPrimitiveFallback(),
          'test_reportsNullableCallbackToStringFallback': (t) =>
              t._reportsNullableCallbackToStringFallback(),
          'test_allowsCopyWithFallback': (t) => t._allowsCopyWithFallback(),
          'test_allowsThrowFallback': (t) => t._allowsThrowFallback(),
          'test_allowsFallbacksInTests': (t) => t._allowsFallbacksInTests(),
          'test_reportsNativeParseAndEditorFallbacks': (t) =>
              t._reportsNativeParseAndEditorFallbacks(),
          'test_reportsRequiredStringWireFieldFromNullableEntity': (t) =>
              t._reportsRequiredStringWireFieldFromNullableEntity(),
          'test_reportsLookalikeNativeBoundaries': (t) => t._reportsLookalikeNativeBoundaries(),
          'test_reportsMappingOutsideTheWireFactory': (t) =>
              t._reportsMappingOutsideTheWireFactory(),
          'test_reportsFirstFallbackWhenSeveralShareALine': (t) =>
              t._reportsFirstFallbackWhenSeveralShareALine(),
        },
      );

  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class TextEditingController {
  String text = '';
}
''');
    super.setUp();
  }

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

  // Canonical UI examples use primitive bool/num fallbacks.
  Future<void> _allowsSkillPrimitiveBoolAndNumFallbacks() async {
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

  Future<void> _reportsEmptyStringAndCollectionFallbacks() async {
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

  Future<void> _reportsChainedPrimitiveFallback() async {
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

  Future<void> _reportsNullableCallbackToStringFallback() async {
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

  Future<void> _allowsCopyWithFallback() async {
    await assertAllows('''
class FormState {
  const FormState(this.title);
  final String title;

  FormState copyWith({String? title}) => FormState(title ?? this.title);
}
''');
  }

  Future<void> _allowsThrowFallback() async {
    await assertAllows('''
class RequiredLookup {
  String read(Map<String, String> values) =>
      values['id'] ?? (throw StateError('missing id'));
}
''');
  }

  Future<void> _allowsFallbacksInTests() async {
    await assertAllows('''
void main() {
  final granted = overrideGranted ?? false;
}
''', path: '$testPackageRootPath/test/permission_test.dart');
  }

  Future<void> _reportsNativeParseAndEditorFallbacks() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void edit(TextEditingController controller, String? value) {
  controller.text = value ?? '';
}
int? parseCount(String? value) => int.tryParse(value ?? '');
double? parseAmount(String? value) => double.tryParse(value ?? "");
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "?? '';", ruleName),
      compatLint(analyzedSource, "?? '');", ruleName),
      compatLint(analyzedSource, '?? "");', ruleName),
    ]);
  }

  Future<void> _reportsRequiredStringWireFieldFromNullableEntity() async {
    for (final (index, source) in [
      r'''
class Item {
  const Item(this.note);
  final String? note;
}
class ItemModel {
  const ItemModel({required this.note});
  final String note;
  factory ItemModel.fromEntity(Item item) => ItemModel(note: item.note ?? '');
  Item toEntity() => Item(note.isEmpty ? null : note);
}
''',
      r'''
class Item {
  const Item(this.note);
  final String? note;
}
abstract class ItemModel {
  const ItemModel._();
  const factory ItemModel({required String note}) = _ItemModel;
  String get note;
  factory ItemModel.fromEntity(Item item) => ItemModel(note: item.note ?? '');
  Item toEntity() => Item(note.isEmpty ? null : note);
}
class _ItemModel extends ItemModel {
  const _ItemModel({required this.note}) : super._();
  @override
  final String note;
}
''',
    ].indexed) {
      final path = '$testPackageLibPath/features/items/data/models/item_model_$index.dart';
      newFile(path, source);
      await assertDiagnosticsInFile(path, [compatLint(source, "?? ''", ruleName)]);
    }
  }

  Future<void> _reportsLookalikeNativeBoundaries() async {
    const source = r'''
class TextEditingController {
  String text = '';
}
class Parser {
  static int? tryParse(String input) => 0;
}
void edit(TextEditingController controller, String? value) {
  controller.text = value ?? '';
}
int? parse(String? value) => Parser.tryParse(value ?? '');
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "?? '';", ruleName),
      compatLint(analyzedSource, "?? '');", ruleName),
    ]);
  }

  Future<void> _reportsMappingOutsideTheWireFactory() async {
    const source = r'''
class Item {
  const Item(this.note);
  final String? note;
}
class ItemModel {
  const ItemModel({required this.note});
  final String note;
  factory ItemModel.fromEntity(Item item) => ItemModel(note: item.note ?? '');
}
''';
    for (final path in [
      '$testPackageLibPath/features/items/domain/item.dart',
      '$testPackageLibPath/features/items/repositories/item_repository.dart',
    ]) {
      newFile(path, source);
      await assertDiagnosticsInFile(path, [compatLint(source, "?? ''", ruleName)]);
    }
    final path = '$testPackageLibPath/features/items/data/models/item_model.dart';
    final otherFactory = source.replaceFirst('fromEntity', 'fromInput');
    newFile(path, otherFactory);
    await assertDiagnosticsInFile(path, [compatLint(otherFactory, "?? ''", ruleName)]);
    final optionalWireField = source.replaceFirst('required this.note', "this.note = ''");
    newFile(path, optionalWireField);
    await assertDiagnosticsInFile(path, [compatLint(optionalWireField, "?? ''", ruleName)]);
  }

  Future<void> _reportsFirstFallbackWhenSeveralShareALine() async {
    const source = r'''
String label(String? value, String? name) { int.tryParse(value ?? ''); return name ?? ''; }
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, "?? '');", ruleName)]);
  }
}

final class _FireForgetInTestsTest extends _ServicesExtendedRuleTest {
  static Map<String, Future<void> Function(_FireForgetInTestsTest)> get _allCases =>
      caseSet<_FireForgetInTestsTest>(parent: _ExtendedSourceRuleTest._allCases, own: {});

  @override
  String get ruleName => 'fire_forget_in_tests';
  @override
  String get path => '$testPackageRootPath/test/analytics_test.dart';
  @override
  String get source => 'void main() { unawaited(service.track()); }';
  @override
  String get needle => 'unawaited';
}

void _defineExtendedSourceRulesPart01Tests() {
  analysisRuleSuite<_ServiceStaticSideEffectTest>(
    'ServiceStaticSideEffectTest',
    _ServiceStaticSideEffectTest.new,
    _ServiceStaticSideEffectTest._allCases,
  );
  analysisRuleSuite<_ServiceRandomPerCallTest>(
    'ServiceRandomPerCallTest',
    _ServiceRandomPerCallTest.new,
    _ServiceRandomPerCallTest._allCases,
  );
  analysisRuleSuite<_HiddenDependencyFallbackTest>(
    'HiddenDependencyFallbackTest',
    _HiddenDependencyFallbackTest.new,
    _HiddenDependencyFallbackTest._allCases,
  );
  analysisRuleSuite<_ImplicitNullFallbackTest>(
    'ImplicitNullFallbackTest',
    _ImplicitNullFallbackTest.new,
    _ImplicitNullFallbackTest._allCases,
  );
  analysisRuleSuite<_FireForgetInTestsTest>(
    'FireForgetInTestsTest',
    _FireForgetInTestsTest.new,
    _FireForgetInTestsTest._allCases,
  );
}
