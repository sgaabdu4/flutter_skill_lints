// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class DateTimeNowRequiresTimezoneIntentTest extends _UiRuleTest {
  @override
  String get ruleName => 'datetime_now_requires_timezone_intent';
  @override
  String get needle => 'DateTime.now()';
  @override
  String get source => 'final now = DateTime.now();';

  Future<void> test_reportsUtcIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.now().toUtc();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_reportsTimestampOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final savedAt = DateTime.timestamp();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.timestamp()', ruleName),
    ]);
  }

  Future<void> test_reportsLocalIntentAcrossLinesOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(r'''
final today = DateTime.now()
    .toLocal();
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsDateTimeXNowUtcForPersistedTimestamp() async {
    await assertAllows('final savedAt = DateTimeX.nowUtc();');
  }

  Future<void> test_reportsLocalNowForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class ItemLog {
  const ItemLog({required this.timestamp});
  final Object timestamp;
}

final log = ItemLog(timestamp: DateTimeX.nowLocal());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineLocalNowForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class ItemLog {
  const ItemLog({required this.timestamp});
  final Object timestamp;
}

final log = ItemLog(
  timestamp:
      DateTimeX.nowLocal(),
);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsDateTimeNowToLocalForPersistedTimestamp() async {
    final analyzedSource = _analyzedSource(r'''
class SquadCheckIn {
  const SquadCheckIn({required this.checkedInAt});
  final Object checkedInAt;
}

final checkIn = SquadCheckIn(checkedInAt: DateTime.now().toLocal());
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now().toLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowLocal().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentUtcDayBoundary() async {
    final analyzedSource = _analyzedSource(
      'final today = DateTimeX.nowUtc().startOfDay;',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowUtc()', ruleName),
    ]);
  }

  Future<void> test_allowsNamedCurrentDayBoundaryHelper() async {
    await assertAllows('final today = DateTimeX.nowLocalStartOfDay();');
  }

  Future<void> test_reportsInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().daysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentCalendarDateWindow() async {
    final analyzedSource = _analyzedSource(
      'final since = DateTimeX.nowLocal().calendarDaysBefore(60);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsMultilineInlineCurrentDateWindow() async {
    final analyzedSource = _analyzedSource(r'''
final since = DateTimeX.nowLocal()
    .daysBefore(60);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsInlineCurrentDateWindowFromStartOfDay() async {
    final analyzedSource = _analyzedSource(
      'final cutoff = DateTimeX.nowLocal().startOfDay.daysBefore(30);',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTimeX.nowLocal()', ruleName),
    ]);
  }

  Future<void> test_reportsEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      'final id = DateTime.now().millisecondsSinceEpoch.toString();',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_reportsInterpolatedEpochIntentOutsideExtensionBoundary() async {
    final analyzedSource = _analyzedSource(
      r"final id = 'draft-${DateTime.now().millisecondsSinceEpoch}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsRawStringThatMentionsDateTimeNow() async {
    final analyzedSource = _analyzedSource(
      r"final sample = r'${DateTime.now()}';",
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertNoDiagnostics(analyzedSource);
  }

  Future<void> test_allowsDateTimeXEpochIntent() async {
    await assertAllows('final id = DateTimeX.nowUtc().millisecondsSinceEpoch.toString();');
  }

  Future<void> test_allowsDateTimeExtensionCurrentBoundary() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    newFile(
      filePath,
      _analyzedSource(r'''
extension DateTimeX on DateTime {
  static DateTime nowUtc() => DateTime.timestamp();
  static DateTime nowLocal() => nowUtc().toLocal();
}
''', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }

  // Row 27: the skill's canonical DateTimeX (primitive-formatting.md).
  Future<void> test_allowsSkillDateTimeXStaticNowHelpers() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    newFile(
      filePath,
      _analyzedSource(r'''
extension DateTimeX on DateTime {
  static DateTime nowUtc() => DateTime.now().toUtc();
  static DateTime nowLocal() => DateTime.now();

  DateTime get asLocal => toLocal();
}
''', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> test_reportsStaticNowOutsideDateTimeExtension() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    final analyzedSource = _analyzedSource(r'''
extension StringClockX on String {
  static DateTime stringNow() => DateTime.now();
}

abstract final class Clock {
  static DateTime classNow() {
    return DateTime.now();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'DateTime.now();\n}\n\nabstract', ruleName),
      compatLint(analyzedSource, 'DateTime.now();\n  }', ruleName),
    ]);
  }

  Future<void> test_reportsRawNowInsideDateTimeExtensionHelper() async {
    final filePath = '$testPackageLibPath/core/extensions/date_time_extensions.dart';
    final analyzedSource = _analyzedSource(r'''
extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return identical(now, now);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'DateTime.now()', ruleName),
    ]);
  }

  Future<void> test_allowsTests() async {
    final filePath = '$testPackageRootPath/test/widgets/date_time_test.dart';
    newFile(
      filePath,
      _analyzedSource('final now = DateTime.now();', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
  }
}

// primitive-formatting.md:33/:60: ad-hoc DateFormat/NumberFormat is forbidden
// at call sites; the DateTimeX/NumX extensions own intl formatting.
@reflectiveTest
final class AdHocIntlFormatTest extends _UiRuleTest {
  @override
  void setUp() {
    newPackage('intl').addFile('lib/intl.dart', r'''
class DateFormat {
  DateFormat([String? pattern, String? locale]);
  DateFormat.yMMMd([String? locale]);
  String format(DateTime date) => '';
}
class NumberFormat {
  NumberFormat([String? pattern, String? locale]);
  factory NumberFormat.currency({String? locale, String? symbol}) => NumberFormat();
  String format(Object number) => '';
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'ad_hoc_intl_format';
  @override
  String get needle => "DateFormat('yyyy-MM-dd')";
  @override
  String get path => '$testPackageLibPath/features/orders/presentation/widgets/order_row.dart';
  @override
  String get source => r'''
import 'package:intl/intl.dart';

String placedLabel(DateTime placedAt) => DateFormat('yyyy-MM-dd').format(placedAt);
''';

  Future<void> test_reportsNumberFormatInWidgetMethod() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:intl/intl.dart';

final class OrderRow {
  String priceLabel(double price) => NumberFormat.currency(locale: 'en', symbol: r'$').format(price);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'NumberFormat.currency(', ruleName),
    ]);
  }

  Future<void> test_reportsDateFormatInNonPrimitiveExtension() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:intl/intl.dart';

final class Order {
  const Order(this.placedAt);
  final DateTime placedAt;
}

extension OrderX on Order {
  String get placedLabel => DateFormat.yMMMd().format(placedAt);
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'DateFormat.yMMMd()', ruleName),
    ]);
  }

  Future<void> test_allowsSkillPrimitiveExtensions() async {
    await assertAllows(r'''
import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  String formatShortDate(AppLocalizations l10n) {
    return DateFormat.yMMMd(l10n.localeName).format(toLocal());
  }
}

extension NumX on num {
  String asCurrency(AppLocalizations l10n, {String? symbol}) {
    return NumberFormat.currency(locale: l10n.localeName, symbol: symbol).format(this);
  }
}
''', path: '$testPackageLibPath/core/extensions/primitive_extensions.dart');
  }

  Future<void> test_allowsNonIntlFormatter() async {
    await assertAllows(r'''
final class DateFormat {
  const DateFormat(String pattern);
}

const isoDate = DateFormat('yyyy-MM-dd');
''', path: path);
  }

  Future<void> test_allowsTests() async {
    await assertAllows(r'''
import 'package:intl/intl.dart';

String expectedLabel(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
''', path: '$testPackageRootPath/test/features/orders/order_row_test.dart');
  }
}

// primitive-formatting.md:60: inline `.clamp(...)` is forbidden at call sites;
// NumX.clamped owns it.
@reflectiveTest
final class InlineNumClampTest extends _UiRuleTest {
  @override
  String get ruleName => 'inline_num_clamp';
  @override
  String get needle => 'clamp(0, 10)';
  @override
  String get path => '$testPackageLibPath/features/cart/presentation/widgets/cart_badge.dart';
  @override
  String get source => 'int visibleCount(int count) => count.clamp(0, 10);';

  // lists-forms-workflows.md:258 shows this batch bound; :60 forbids it.
  Future<void> test_reportsBatchBoundClamp() async {
    final analyzedSource = _analyzedSource(r'''
Iterable<List<T>> batches<T>(List<T> items, int batchSize) sync* {
  for (var i = 0; i < items.length; i += batchSize) {
    final end = (i + batchSize).clamp(0, items.length);
    yield items.sublist(i, end);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    final filePath = '$testPackageLibPath/core/utils/batch_utils.dart';
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'clamp(0, items.length)', ruleName),
    ]);
  }

  Future<void> test_allowsSkillNumExtension() async {
    await assertAllows(r'''
extension NumX on num {
  num clamped(num min, num max) => clamp(min, max);
}
''', path: '$testPackageLibPath/core/extensions/num_extensions.dart');
  }

  Future<void> test_allowsNonNumClamp() async {
    await assertAllows(r'''
final class TextScaler {
  const TextScaler();
  TextScaler clamp({double maxScaleFactor = 1}) => this;
}

TextScaler bounded(TextScaler scaler) => scaler.clamp(maxScaleFactor: 2);
''', path: path);
  }

  Future<void> test_allowsTests() async {
    await assertAllows(
      'final bounded = 12.clamp(0, 10);',
      path: '$testPackageRootPath/test/features/cart/cart_badge_test.dart',
    );
  }
}

@reflectiveTest
final class PerfBuildWorkTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_build_work';
  @override
  String get needle => 'items.sort()';
  @override
  bool get lineStart => true;
  @override
  String get source => r'''
class Screen {
  Object build() {
    final items = <int>[2, 1];
    items.sort();
    return Object();
  }
}
''';
}

@reflectiveTest
final class PerfListviewChildrenTest extends _UiRuleTest {
  @override
  String get ruleName => 'perf_listview_children';
  @override
  String get needle => 'ListView(children';
  @override
  String get source => 'final list = ListView(children: []);';
}

abstract class _StateRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => stateSourceRules;
}

@reflectiveTest
final class NullableCollectionTypeTest extends _StateRuleTest {
  @override
  String get ruleName => 'nullable_collection_type';
  @override
  String get needle => 'List<Item>? items';
  @override
  String get source => r'''
class ProductState {
  const ProductState({this.items});

  final List<Item>? items;
}
''';

  Future<void> test_reportsFutureNullableCollectionReturn() async {
    final analyzedSource = _analyzedSource(r'''
class Repository {
  Future<List<Item>?> loadItems() async => null;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'List<Item>?>', ruleName)]);
  }

  Future<void> test_reportsNullableMapDefaultParam() async {
    final analyzedSource = _analyzedSource(r'''
void track({Map<String, Object>? params}) {}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Map<String, Object>? params', ruleName),
    ]);
  }

  Future<void> test_allowsNonNullableCollectionDefault() async {
    await assertAllows(r'''
class ProductState {
  const ProductState({this.items = const []});

  final List<Item> items;
}
''');
  }

  Future<void> test_allowsNullableElementCollection() async {
    await assertAllows(r'''
class ProductState {
  const ProductState({this.items = const []});

  final List<Item?> items;
}
''');
  }

  Future<void> test_allowsMapTypeFollowedBySameLineTernary() async {
    await assertAllows(r'''
Object? select(Object? value) => value is Map<String, Object?> ? value : null;
''');
  }

  Future<void> test_allowsMapTypeFollowedByMultilineTernary() async {
    await assertAllows(r'''
Object? select(Object? value) => value is Map<String, Object?>
    ? value
    : null;
''');
  }

  Future<void> test_allowsNullableCallbackAcceptingNonNullableSet() async {
    await assertAllows(r'''
typedef ValueChanged<T> = void Function(T value);
class Selector {
  const Selector({this.onChanged});
  final ValueChanged<Set<String>>? onChanged;
}
''');
  }

  Future<void> test_reportsNullableCollectionTypes() async {
    const source = r'''
List<String>? items;
Map<String, Object?>? metadata;
Set<int>? ids;
''';
    await assertDiagnostics(source, [
      compatLint(source, 'List<String>? items', ruleName),
      compatLint(source, 'Map<String, Object?>? metadata', ruleName),
      compatLint(source, 'Set<int>? ids', ruleName),
    ]);
  }

  Future<void> test_allowsNullableWireCollectionInDataModel() async {
    await assertAllows(r'''
class ProductModel {
  const ProductModel({this.items});

  final List<Item>? items;
}
''', path: '$testPackageLibPath/features/products/data/models/product_model.dart');
  }
}

@reflectiveTest
final class StateEmptyStringSentinelTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_empty_string_sentinel';
  @override
  String get needle => "@Default('') final String selectedId";
  @override
  String get source => r'''
const freezed = Object();

class Default {
  const Default(Object value);
}

@freezed
class PickerState {
  const PickerState({required this.selectedId});

  @Default('') final String selectedId;
}
''';

  Future<void> test_reportsConstructorDefaultThisField() async {
    final analyzedSource = _analyzedSource(r'''
const freezed = Object();

@freezed
class PickerState {
  const PickerState({this.selectedId = ''});

  final String selectedId;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, "this.selectedId = ''", ruleName),
    ]);
  }

  Future<void> test_allowsSearchQueryText() async {
    await assertAllows(r'''
const freezed = Object();

class Default {
  const Default(Object value);
}

@freezed
class SearchState {
  const SearchState({required this.searchQuery});

  @Default('') final String searchQuery;
}
''');
  }

  Future<void> test_allowsDraftText() async {
    await assertAllows(r'''
const freezed = Object();

class Default {
  const Default(Object value);
}

@freezed
class FormState {
  const FormState({required this.draftName});

  @Default('') final String draftName;
}
''');
  }

  Future<void> test_allowsOptionalDomainTextAsNullable() async {
    await assertAllows(r'''
const freezed = Object();

@freezed
class ProfileState {
  const ProfileState({this.bio});

  final String? bio;
}
''');
  }
}

@reflectiveTest
final class StateBoolStringSentinelTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_bool_string_sentinel';
  @override
  String get needle => "? '1' : '0'";
  @override
  String get source => r'''
String f(bool flag) => flag ? '1' : '0';
''';

  Future<void> test_reportsZeroOneVariant() async {
    final analyzedSource = _analyzedSource(
      'String f(bool flag) => flag ? "0" : "1";',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '? "0" : "1"', ruleName)]);
  }

  Future<void> test_allowsTypedBooleanRecordField() async {
    await assertAllows(r'''
({bool isRestoringDraft}) f(bool isRestoringDraft) => (
  isRestoringDraft: isRestoringDraft,
);
''');
  }

  Future<void> test_allowsNonSentinelTernary() async {
    await assertAllows(r'''
String f(bool isLoading) => isLoading ? 'loading' : 'ready';
''');
  }
}

@reflectiveTest
final class StateRawResponseTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_raw_response';
  @override
  String get needle => 'state = state.copyWith';
  @override
  String get source => r'''
void f(state) {
  state = state.copyWith(response: Object());
}
''';
}

@reflectiveTest
final class StateRawErrorToStringTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_raw_error_to_string';
  @override
  String get needle => 'error: e.toString()';
  @override
  String get source => r'''
void fail(state, Object e) {
  state = state.copyWith(error: e.toString());
}
''';

  Future<void> test_allowsStructuredErrorMessage() async {
    await assertAllows(r'''
void fail(state, String message) {
  state = state.copyWith(error: message);
}
''');
  }

  /// state-management-lifecycle.md:92: never store the raw exception text.
  Future<void> test_reportsCaughtExceptionText() async {
    final analyzedSource = _analyzedSource(r'''
class SearchState {
  SearchState copyWith({String? error}) => this;
}

class SearchFailure implements Exception {
  String get message => 'offline';
}

class SearchNotifier {
  SearchState state = SearchState();

  Future<void> search() async {
    try {
      await Future<void>.value();
    } on SearchFailure catch (failure) {
      state = state.copyWith(
        error: failure.message);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed: $e');
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile('$testPackageLibPath/search_notifier.dart', analyzedSource);
    await assertDiagnosticsInFile('$testPackageLibPath/search_notifier.dart', [
      compatLint(analyzedSource, 'error: failure.message', ruleName),
      compatLint(analyzedSource, r"error: 'Failed: $e'", ruleName),
    ]);
  }

  /// The skill's AppError.from wraps the caught error without storing its text.
  Future<void> test_allowsTypedAppError() async {
    await assertAllows(r'''
class AppError {
  const AppError(this.message);
  final String message;

  static AppError from(Object e) => AppError(e.toString());
}

class SearchState {
  SearchState copyWith({AppError? error}) => this;
}

class SearchNotifier {
  SearchState state = SearchState();

  Future<void> search() async {
    try {
      await Future<void>.value();
    } on Exception catch (e) {
      state = state.copyWith(error: AppError.from(e));
    }
  }
}
''');
  }
}

@reflectiveTest
final class StateFreezedNullableErrorTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_freezed_nullable_error';
  @override
  String get needle => 'String? error';
  @override
  String get source => r'''
const freezed = Object();

@freezed
class LoginState {
  const LoginState({this.error});

  final String? error;
}
''';

  Future<void> test_allowsStructuredFailure() async {
    await assertAllows(r'''
const freezed = Object();

@freezed
class LoginState {
  const LoginState({this.failure});

  final Object? failure;
}
''');
  }

  /// state-management-lifecycle.md:108: AppError is the sole error type in state.
  Future<void> test_reportsStringErrorsInAnyNotifierState() async {
    final analyzedSource = _analyzedSource(r'''
class SearchState {
  const SearchState({this.error, this.errorMessage = ''});

  final String? error;
  final String errorMessage;
}

class ProfileState {
  const ProfileState();

  const factory ProfileState.failure({String? error}) = ProfileFailure;
}

class ProfileFailure extends ProfileState {
  const ProfileFailure({this.error});

  final String? error;
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile('$testPackageLibPath/search_state.dart', analyzedSource);
    await assertDiagnosticsInFile('$testPackageLibPath/search_state.dart', [
      compatLint(analyzedSource, 'String? error;', ruleName),
      compatLint(analyzedSource, 'String errorMessage;', ruleName),
      compatLint(analyzedSource, 'String? error}) = ProfileFailure;', ruleName),
    ]);
  }

  Future<void> test_allowsNonStringErrorsAndWidgetState() async {
    await assertAllows(r'''
import 'package:flutter/widgets.dart';

class AppError {}

class SearchState {
  const SearchState({this.error, this.hasError = false, this.errorCount = 0});

  final AppError? error;
  final bool hasError;
  final int errorCount;
}

class SearchScreen extends StatefulWidget {}

class SearchScreenState extends State<SearchScreen> {
  String? error;
}
''');
  }

  Future<void> test_allowsFreezedDtoWithNullableErrorField() async {
    await assertAllows(r'''
const freezed = Object();

@freezed
class ApiErrorModel {
  const ApiErrorModel({this.error});

  final String? error;
}
''');
  }
}

@reflectiveTest
final class StateBroadInvalidationTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_broad_invalidation';
  @override
  String get needle => 'ref.invalidate(provider)';
  @override
  String get source => r'''
class Todos {
  void saveTodo(context, ref, provider) {
    ref.invalidate(provider);
    context.go('/todos');
  }
}
''';
}

@reflectiveTest
final class AsyncContextMountedStyleTest extends _StateRuleTest {
  @override
  String get ruleName => 'async_context_mounted_style';
  @override
  String get needle => 'mounted) return';
  @override
  String get source => r'''
class Screen {
  Future<void> save() async {
    await Future<void>.value();
    if (!mounted) return;
  }
}
''';
}
