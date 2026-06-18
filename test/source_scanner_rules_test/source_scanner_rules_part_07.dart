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
abstract final class DateTimeX {
  static DateTime nowUtc() => DateTime.timestamp();
  static DateTime nowLocal() => nowUtc().toLocal();
}
''', addIgnorePrefix: addIgnorePrefix),
    );

    await assertNoDiagnosticsInFile(filePath);
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

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'Future<List<Item>?>', ruleName),
    ]);
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

  Future<void> test_allowsNullableErrorOutsideFreezedState() async {
    await assertAllows(r'''
class PlainState {
  const PlainState({this.error});

  final String? error;
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
