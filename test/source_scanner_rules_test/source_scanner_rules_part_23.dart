part of '../source_scanner_rules_test.dart';

abstract class _StateRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => stateSourceRules;
}

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

  Future<void> _reportsFutureNullableCollectionReturn() async {
    final analyzedSource = _analyzedSource(r'''
class Repository {
  Future<List<Item>?> loadItems() async => null;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'List<Item>?>', ruleName)]);
  }

  Future<void> _allowsNullableCollectionParametersAndLocals() async {
    await assertAllows(r'''
void track({Map<String, Object>? params}) {}
List<Object> children(List<Object>? conditionalItems) {
  final List<Object>? extra = null;
  return [...?conditionalItems, ...?extra];
}
''');
  }

  Future<void> _reportsFreezedFactoryParameterAndGetter() async {
    final analyzedSource = _analyzedSource(r'''
abstract class ProductState {
  const factory ProductState({List<Item>? items}) = _ProductState;

  List<Item>? get cached;
}

class _ProductState implements ProductState {
  const _ProductState({List<Item>? items});

  @override
  List<Item> get cached => const [];
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'List<Item>? items}) = _ProductState', ruleName),
      compatLint(analyzedSource, 'List<Item>? get cached', ruleName),
    ]);
  }

  Future<void> _allowsNonNullableCollectionDefault() async {
    await assertAllows(r'''
class ProductState {
  const ProductState({this.items = const []});

  final List<Item> items;
}
''');
  }

  Future<void> _allowsNullableElementCollection() async {
    await assertAllows(r'''
class ProductState {
  const ProductState({this.items = const []});

  final List<Item?> items;
}
''');
  }

  Future<void> _allowsMapTypeFollowedBySameLineTernary() async {
    await assertAllows(r'''
Object? select(Object? value) => value is Map<String, Object?> ? value : null;
''');
  }

  Future<void> _allowsMapTypeFollowedByMultilineTernary() async {
    await assertAllows(r'''
Object? select(Object? value) => value is Map<String, Object?>
    ? value
    : null;
''');
  }

  Future<void> _allowsNullableCallbackAcceptingNonNullableSet() async {
    await assertAllows(r'''
typedef ValueChanged<T> = void Function(T value);
class Selector {
  const Selector({this.onChanged});
  final ValueChanged<Set<String>>? onChanged;
}
''');
  }

  Future<void> _reportsNullableCollectionTypes() async {
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

  Future<void> _allowsNullableWireCollectionInDataModel() async {
    await assertAllows(r'''
class ProductModel {
  const ProductModel({this.items});

  final List<Item>? items;
}
''', path: '$testPackageLibPath/features/products/data/models/product_model.dart');
  }
}

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

  Future<void> _reportsConstructorDefaultThisField() async {
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

  Future<void> _allowsSearchQueryText() async {
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

  Future<void> _allowsDraftText() async {
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

  Future<void> _allowsOptionalDomainTextAsNullable() async {
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

final class StateBoolStringSentinelTest extends _StateRuleTest {
  @override
  String get ruleName => 'state_bool_string_sentinel';
  @override
  String get needle => "? '1' : '0'";
  @override
  String get source => r'''
String f(bool flag) => flag ? '1' : '0';
''';

  Future<void> _reportsZeroOneVariant() async {
    final analyzedSource = _analyzedSource(
      'String f(bool flag) => flag ? "0" : "1";',
      addIgnorePrefix: addIgnorePrefix,
    );

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '? "0" : "1"', ruleName)]);
  }

  Future<void> _allowsTypedBooleanRecordField() async {
    await assertAllows(r'''
({bool isRestoringDraft}) f(bool isRestoringDraft) => (
  isRestoringDraft: isRestoringDraft,
);
''');
  }

  Future<void> _allowsNonSentinelTernary() async {
    await assertAllows(r'''
String f(bool isLoading) => isLoading ? 'loading' : 'ready';
''');
  }
}

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

  Future<void> _reportsFormattedMultilineCopyWith() async {
    final analyzedSource = _analyzedSource(r'''
void f(state, Map<String, Object?> hugeJsonMap) {
  state = state.copyWith(
    total: 1,
    rawJson: hugeJsonMap,
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'state = state.copyWith', ruleName),
    ]);
  }

  Future<void> _reportsFreezedCallableCopyWith() async {
    final analyzedSource = _analyzedSource(r'''
class RawStateCopyWith {
  RawState call({int? total, Map<String, Object?>? rawJson}) => RawState();
}
class RawState {
  RawStateCopyWith get copyWith => RawStateCopyWith();
}
class RawNotifier {
  RawState state = RawState();
  void store(Map<String, Object?> hugeJsonMap) {
    state = state.copyWith(
      total: 1,
      rawJson: hugeJsonMap,
    );
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'state = state.copyWith', ruleName),
    ]);
  }

  Future<void> _reportsDirectlyStoredResponseValue() async {
    final analyzedSource = _analyzedSource(r'''
void f(state, Object response) {
  state = state.copyWith(
    data: response,
  );
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'state = state.copyWith', ruleName),
    ]);
  }

  Future<void> _allowsExtractedFields() async {
    await assertAllows(r'''
void f(state, Map<String, Object?> json) {
  state = state.copyWith(items: parseItems(json), total: json['total'] as int);
  state = state.copyWith(
    items: parseItems(json),
    total: json['total'] as int,
  );
}
''');
  }

  Future<void> _allowsFreezedCallableCopyWithExtractedFields() async {
    await assertAllows(r'''
class RawStateCopyWith {
  RawState call({int? total, String? status}) => RawState();
}
class RawState {
  RawStateCopyWith get copyWith => RawStateCopyWith();
}
class RawNotifier {
  RawState state = RawState();
  void store(Map<String, Object?> json) {
    state = state.copyWith(
      total: json['total'] as int? ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}
''');
  }
}

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

  Future<void> _allowsStructuredErrorMessage() async {
    await assertAllows(r'''
void fail(state, String message) {
  state = state.copyWith(error: message);
}
''');
  }

  /// state-management-lifecycle.md:92: never store the raw exception text.
  Future<void> _reportsCaughtExceptionText() async {
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

  /// The skill's AppErrorMapper.from wraps the caught error without storing its text (state-management-lifecycle.md "Domain Error Types").
  Future<void> _allowsTypedAppError() async {
    await assertAllows(r'''
class AppError {
  const AppError(this.message);
  final String message;
}

abstract final class AppErrorMapper {
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
      state = state.copyWith(error: AppErrorMapper.from(e));
    }
  }
}
''');
  }
}

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

  Future<void> _allowsStructuredFailure() async {
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
  Future<void> _reportsStringErrorsInAnyNotifierState() async {
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

  Future<void> _allowsNonStringErrorsAndWidgetState() async {
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

  Future<void> _allowsFreezedDtoWithNullableErrorField() async {
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

void _defineSourceScannerRulesPart23Tests() {
  analysisRuleSuite<NullableCollectionTypeTest>(
    'NullableCollectionTypeTest',
    NullableCollectionTypeTest.new,
    {
      'test_reportsFutureNullableCollectionReturn': (t) =>
          t._reportsFutureNullableCollectionReturn(),
      'test_allowsNullableCollectionParametersAndLocals': (t) =>
          t._allowsNullableCollectionParametersAndLocals(),
      'test_reportsFreezedFactoryParameterAndGetter': (t) =>
          t._reportsFreezedFactoryParameterAndGetter(),
      'test_allowsNonNullableCollectionDefault': (t) => t._allowsNonNullableCollectionDefault(),
      'test_allowsNullableElementCollection': (t) => t._allowsNullableElementCollection(),
      'test_allowsMapTypeFollowedBySameLineTernary': (t) =>
          t._allowsMapTypeFollowedBySameLineTernary(),
      'test_allowsMapTypeFollowedByMultilineTernary': (t) =>
          t._allowsMapTypeFollowedByMultilineTernary(),
      'test_allowsNullableCallbackAcceptingNonNullableSet': (t) =>
          t._allowsNullableCallbackAcceptingNonNullableSet(),
      'test_reportsNullableCollectionTypes': (t) => t._reportsNullableCollectionTypes(),
      'test_allowsNullableWireCollectionInDataModel': (t) =>
          t._allowsNullableWireCollectionInDataModel(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<StateEmptyStringSentinelTest>(
    'StateEmptyStringSentinelTest',
    StateEmptyStringSentinelTest.new,
    {
      'test_reportsConstructorDefaultThisField': (t) => t._reportsConstructorDefaultThisField(),
      'test_allowsSearchQueryText': (t) => t._allowsSearchQueryText(),
      'test_allowsDraftText': (t) => t._allowsDraftText(),
      'test_allowsOptionalDomainTextAsNullable': (t) => t._allowsOptionalDomainTextAsNullable(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<StateBoolStringSentinelTest>(
    'StateBoolStringSentinelTest',
    StateBoolStringSentinelTest.new,
    {
      'test_reportsZeroOneVariant': (t) => t._reportsZeroOneVariant(),
      'test_allowsTypedBooleanRecordField': (t) => t._allowsTypedBooleanRecordField(),
      'test_allowsNonSentinelTernary': (t) => t._allowsNonSentinelTernary(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<StateRawResponseTest>('StateRawResponseTest', StateRawResponseTest.new, {
    'test_reportsFormattedMultilineCopyWith': (t) => t._reportsFormattedMultilineCopyWith(),
    'test_reportsFreezedCallableCopyWith': (t) => t._reportsFreezedCallableCopyWith(),
    'test_reportsDirectlyStoredResponseValue': (t) => t._reportsDirectlyStoredResponseValue(),
    'test_allowsExtractedFields': (t) => t._allowsExtractedFields(),
    'test_allowsFreezedCallableCopyWithExtractedFields': (t) =>
        t._allowsFreezedCallableCopyWithExtractedFields(),
    'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
  });
  analysisRuleSuite<StateRawErrorToStringTest>(
    'StateRawErrorToStringTest',
    StateRawErrorToStringTest.new,
    {
      'test_allowsStructuredErrorMessage': (t) => t._allowsStructuredErrorMessage(),
      'test_reportsCaughtExceptionText': (t) => t._reportsCaughtExceptionText(),
      'test_allowsTypedAppError': (t) => t._allowsTypedAppError(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<StateFreezedNullableErrorTest>(
    'StateFreezedNullableErrorTest',
    StateFreezedNullableErrorTest.new,
    {
      'test_allowsStructuredFailure': (t) => t._allowsStructuredFailure(),
      'test_reportsStringErrorsInAnyNotifierState': (t) =>
          t._reportsStringErrorsInAnyNotifierState(),
      'test_allowsNonStringErrorsAndWidgetState': (t) => t._allowsNonStringErrorsAndWidgetState(),
      'test_allowsFreezedDtoWithNullableErrorField': (t) =>
          t._allowsFreezedDtoWithNullableErrorField(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<StateBroadInvalidationTest>(
    'StateBroadInvalidationTest',
    StateBroadInvalidationTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<AsyncContextMountedStyleTest>(
    'AsyncContextMountedStyleTest',
    AsyncContextMountedStyleTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
}
