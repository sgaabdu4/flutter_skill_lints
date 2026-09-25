// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class RiverpodEventCounterSignalForbiddenTest extends _RiverpodRuleTest {
  @override
  String get ruleName => 'riverpod_event_counter_signal_forbidden';
  @override
  String get needle => 'class ChartShareSuccessSignal';
  @override
  String get source => r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$ChartShareSuccessSignal {
  int state = 0;
  int build() => 0;
}

@riverpod
class ChartShareSuccessSignal extends _$ChartShareSuccessSignal {
  @override
  int build() => 0;

  void notify() => state++;
}
''';

  Future<void> test_reportsStatePlusOneVariant() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$SaveSuccessEvent {
  int state = 0;
  int build() => 0;
}

@riverpod
class SaveSuccessEvent extends _$SaveSuccessEvent {
  @override
  int build() => 0;

  void notify() {
    state = state + 1;
  }
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'class SaveSuccessEvent', ruleName),
    ]);
  }

  Future<void> test_reportsPayloadSignalProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$CreatedExerciseSignal {
  String? state;
  String? build() => null;
}

@riverpod
class CreatedExerciseSignal extends _$CreatedExerciseSignal {
  @override
  String? build() => null;

  void notify(String exerciseId) => state = exerciseId;
}
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'class CreatedExerciseSignal', ruleName),
    ]);
  }

  Future<void> test_reportsFunctionEventProvider() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@Riverpod(keepAlive: true)
Stream<String> notificationTapEvents(Ref ref) => Stream<String>.fromIterable(const <String>[]);
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'notificationTapEvents', ruleName),
    ]);
  }

  /// riverpod_generator drops the `Notifier` suffix: this is `snackbarEventProvider`.
  Future<void> test_reportsNotifierSuffixedEventClassAndNestedGenericFunction() async {
    final analyzedSource = _analyzedSource(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$SnackbarEventNotifier {
  String? state;
  String? build() => null;
}

@riverpod
class SnackbarEventNotifier extends _$SnackbarEventNotifier {
  @override
  String? build() => null;
}

@riverpod
Future<List<int>> orderEvents(Ref ref) async => const <int>[];
''', addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'class SnackbarEventNotifier', ruleName),
      compatLint(analyzedSource, 'orderEvents', ruleName),
    ]);
  }

  Future<void> test_allowsEventNamesWithoutRiverpodAnnotation() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class SnackbarEventNotifier {
  String? build() => null;
}

Future<List<int>> orderEvents(Object ref) async => const <int>[];
''');
  }

  Future<void> test_allowsPayloadStreamName() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@Riverpod(keepAlive: true)
Stream<String> notificationTapPayloads(Ref ref) => Stream<String>.fromIterable(const <String>[]);
''');
  }

  Future<void> test_allowsOwningNotifierStateSerial() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

final class ChartShareState {
  const ChartShareState({required this.isSharing, required this.successSerial});

  final bool isSharing;
  final int successSerial;

  ChartShareState markShared() =>
      ChartShareState(isSharing: false, successSerial: successSerial + 1);
}

class _$ChartShareNotifier {
  ChartShareState state = const ChartShareState(isSharing: false, successSerial: 0);
  ChartShareState build() => state;
}

@riverpod
class ChartShareNotifier extends _$ChartShareNotifier {
  @override
  ChartShareState build() => const ChartShareState(isSharing: false, successSerial: 0);

  void markShared() {
    state = state.markShared();
  }
}
''');
  }

  Future<void> test_allowsDomainCounterNotifier() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class _$RetryCounter {
  int state = 0;
  int build() => 0;
}

@riverpod
class RetryCounter extends _$RetryCounter {
  @override
  int build() => 0;

  void increment() => state++;
}
''');
  }

  Future<void> test_allowsDurableStatusNotifier() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

enum InitialSyncStatus { idle, syncing, complete, failed }

class _$InitialSyncStatusNotifier {
  InitialSyncStatus state = InitialSyncStatus.idle;
  InitialSyncStatus build() => InitialSyncStatus.idle;
}

@riverpod
class InitialSyncStatusNotifier extends _$InitialSyncStatusNotifier {
  @override
  InitialSyncStatus build() => InitialSyncStatus.idle;

  void markSyncing() => state = InitialSyncStatus.syncing;
}
''');
  }
}

@reflectiveTest
final class RiverpodWatchNoSelectTest extends _RiverpodRuleTest {
  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class AsyncValue<T> {
}
abstract class ProviderListenable<T> {}
sealed class MutationState<T> {
  bool get isPending => false;
}
final class Mutation<T> implements ProviderListenable<MutationState<T>> {}
extension AsyncValueExtensions<T> on AsyncValue<T> {
  R when<R>({
    required R Function(T value) data,
    required R Function() loading,
    required R Function(Object error) error,
  }) => throw StateError('synthetic');
}
class Ref {
  T watch<T>(ProviderListenable<T> provider) => throw StateError('synthetic');
}
abstract class $FunctionalProvider<StateT> implements ProviderListenable<StateT> {}
abstract class $NotifierProvider<NotifierT, StateT> implements ProviderListenable<StateT> {}
''');
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:riverpod/riverpod.dart';
export 'package:riverpod/riverpod.dart';
class WidgetRef {
  T watch<T>(ProviderListenable<T> provider) => throw StateError('synthetic');
}
''');
    super.setUp();
  }

  @override
  String get ruleName => 'riverpod_watch_no_select';
  @override
  String get needle => 'ref.watch(provider)';
  @override
  String get source => r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
final provider = Source<Object>();

class TodoList {
  Object build(WidgetRef ref) {
    return ref.watch(provider);
  }
}
''';

  Future<void> test_allowsGeneratedNotifierBuildDependencies() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Riverpod {
  const Riverpod();
}
const riverpod = Riverpod();
class Source<T> implements ProviderListenable<T> {}
final provider = Source<Object>();
@riverpod
class DerivedNotifier {
  final ref = Ref();
  Object build() => ref.watch(provider);
}
''');
  }

  Future<void> test_allowsResolvedScalarResults() async {
    await assertAllows(r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
enum Selection { first, second }
final flagProvider = Source<bool>();
final optionalFlagProvider = Source<bool?>();
final textProvider = Source<String?>();
final integerProvider = Source<int>();
final decimalProvider = Source<double>();
final numericProvider = Source<num>();
final selectionProvider = Source<Selection>();
class ScalarView {
  Object build() {
    final ref = WidgetRef();
    return (
      ref.watch(flagProvider),
      ref.watch(optionalFlagProvider),
      ref.watch(textProvider),
      ref.watch(integerProvider),
      ref.watch(decimalProvider),
      ref.watch(numericProvider),
      ref.watch(selectionProvider),
    );
  }
}
""");
  }

  Future<void> test_reportsStructuredWatchBesideScalarOnSameLine() async {
    final analyzedSource = _analyzedSource(r"""
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class StateValue {
  const StateValue(this.title, this.subtitle);
  final String title;
  final String subtitle;
}
final flagProvider = Source<bool>();
final structuredProvider = Source<StateValue>();
class MixedView {
  Object build() {
    final ref = WidgetRef();
    return (ref.watch(flagProvider), ref.watch(structuredProvider));
  }
}
""", addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(structuredProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsMultilineFamilyProviderSelect() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
final itemByIdProvider = ItemFamily();

class ProviderArg<T> {
  ProviderListenable<Object> select(Object Function(T? value) selector) => throw 0;
}

class Item {
  const Item(this.name);

  final String name;
}

class ItemFamily {
  ProviderArg<Item> call(String id) => ProviderArg<Item>();
}

class ItemConfig {
  const ItemConfig(this.itemId);

  final String itemId;
}

class TodoList {
  Object build(ItemConfig config) {
    final ref = WidgetRef();
    final isNewItem = ref.watch(
      itemByIdProvider(config.itemId).select((w) => w?.name.isEmpty ?? true),
    );
    return isNewItem;
  }
}
''');
  }

  // performance.md:6: watch a generated computed projection provider directly
  // when the entire provider value is already the render projection: passed
  // whole, destructured as a record, or a projected collection read by length
  // and index (routing-app-shell.md:179 ProductListScreen).
  Future<void> test_allowsDirectWatchOfComputedProjectionProvider() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
class TrainerSummary {
  const TrainerSummary(this.title, this.sets);
  final String title;
  final int sets;
}
class TrainerCard extends Widget {
  TrainerCard({required TrainerSummary summary});
}
final class TrainerCardProvider extends $FunctionalProvider<TrainerSummary> {}
final trainerCardProvider = TrainerCardProvider();
final class TrainerTotalsProvider extends $FunctionalProvider<({String title, int sets})> {}
final trainerTotalsProvider = TrainerTotalsProvider();
final class ExerciseSetsProvider extends $FunctionalProvider<List<String>> {}
final class ExerciseSetsFamily {
  ExerciseSetsProvider call(String exerciseId) => ExerciseSetsProvider();
}
final exerciseSetsProvider = ExerciseSetsFamily();
final class ProductIdsProvider extends $FunctionalProvider<List<String>> {}
final productIdsProvider = ProductIdsProvider();

class TrainerScreen {
  Object build(WidgetRef ref) {
    final summary = ref.watch(trainerCardProvider);
    final (:title, :sets) = ref.watch(trainerTotalsProvider);
    final entries = ref.watch(exerciseSetsProvider('exercise-1'));
    return (TrainerCard(summary: summary), title, sets, entries.first);
  }
}

class ProductListScreen {
  Object build(WidgetRef ref) {
    final ids = ref.watch(productIdsProvider);
    return (ids.length, ids[0]);
  }
}
''');
  }

  // performance.md:76 WRONG: a broad watch read only by field reports, also
  // when the provider is a computed (functional) provider.
  static const _userSummarySource = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
class User {}
class UserState {
  const UserState(this.user, this.isLoading);
  final User user;
  final bool isLoading;
}
class UserSummary extends Widget {
  UserSummary({required User user});
}
PROVIDER
final userProvider = UserProvider();

class UserScreen {
  Widget build(WidgetRef ref) {
    final userState = ref.watch(userProvider);
    return UserSummary(user: userState.user);
  }
}
''';

  Future<void> test_reportsFieldReadOfComputedProvider() async {
    final source = _userSummarySource.replaceFirst(
      'PROVIDER',
      r'final class UserProvider extends $FunctionalProvider<UserState> {}',
    );
    await assertDiagnostics(source, [compatLint(source, 'ref.watch(userProvider)', ruleName)]);
  }

  Future<void> test_reportsFieldReadOfNotifierProvider() async {
    final source = _userSummarySource.replaceFirst(
      'PROVIDER',
      r'final class UserProvider extends $NotifierProvider<Object, UserState> {}',
    );
    await assertDiagnostics(source, [compatLint(source, 'ref.watch(userProvider)', ruleName)]);
  }

  // A notifier provider holds mutable state, whatever its name says.
  Future<void> test_reportsProjectionNamedNotifierProvider() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class TrainerSummary { String get title => ''; int get sets => 0; }
final class TrainerSummaryNotifierProvider
    extends $NotifierProvider<Object, TrainerSummary> {}
final trainerSummaryProvider = TrainerSummaryNotifierProvider();

class TrainerCard {
  Object build(WidgetRef ref) {
    final summary = ref.watch(trainerSummaryProvider);
    return (summary.title, summary.sets);
  }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, 'ref.watch(trainerSummaryProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsWholeListAndDtoPassedToWidgets() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class Item {}
class Details {}
class ItemsView {
  ItemsView({required List<Item> items});
}
class DetailsCard {
  DetailsCard({required Details? details});
}
final filteredItemsProvider = Source<List<Item>>();
final selectedDetailsProvider = Source<Details?>();
class View {
  Object build(WidgetRef ref) => (
    ItemsView(items: ref.watch(filteredItemsProvider)),
    DetailsCard(details: ref.watch(selectedDetailsProvider)),
  );
}
''');
  }

  Future<void> test_allowsWholeValuesThroughLocalBindings() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class Item {}
class Details {}
class ItemsView { ItemsView({required List<Item> items}); }
class DetailsCard { DetailsCard({required Details? details}); }
final filteredItemsProvider = Source<List<Item>>();
final selectedDetailsProvider = Source<Details?>();
class View {
  Object build(WidgetRef ref) {
    final items = ref.watch(filteredItemsProvider);
    final details = ref.watch(selectedDetailsProvider);
    return (ItemsView(items: items), DetailsCard(details: details));
  }
}
''');
  }

  // performance.md:26-27: reusable widgets get minimal view data, so a whole
  // multi-field state passed into an app widget reports (#36).
  static const _productStateWidget = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
class Source<T> implements ProviderListenable<T> {}
class ProductState {
  const ProductState(this.title, this.items, this.isLoading);
  final String title;
  final List<String> items;
  final bool isLoading;
}
class ProductSummary extends Widget {
  ProductSummary({required this.state});
  final ProductState state;
}
final productProvider = Source<ProductState>();
''';

  Future<void> test_reportsWholeMultiFieldStateIntoAppWidget() async {
    final analyzedSource = _analyzedSource('''$_productStateWidget
class ProductScreen {
  Widget build(WidgetRef ref) => ProductSummary(state: ref.watch(productProvider));
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(productProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsWholeMultiFieldStateLocalIntoAppWidget() async {
    final analyzedSource = _analyzedSource('''$_productStateWidget
class ProductScreen {
  Widget build(WidgetRef ref) {
    final state = ref.watch(productProvider);
    return ProductSummary(state: state);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(productProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsFreezedStateIntoAppWidget() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
class Source<T> implements ProviderListenable<T> {}
mixin _$ProductState {
  String get title;
  bool get isLoading;
  Object get copyWith => Object();
}
sealed class ProductState with _$ProductState {}
class ProductSummary extends Widget {
  ProductSummary({required this.state});
  final ProductState state;
}
final productProvider = Source<ProductState>();
class ProductScreen {
  Widget build(WidgetRef ref) => ProductSummary(state: ref.watch(productProvider));
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(productProvider)', ruleName),
    ]);
  }

  // riverpod-codegen.md:181 HistoryScreen and other whole view values stay clean.
  Future<void> test_allowsWholeViewValuesIntoAppWidget() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
class Source<T> implements ProviderListenable<T> {}
class Workout { const Workout(this.id, this.name); final String id; final String name; }
abstract class WorkoutPage implements Iterable<Workout> {
  List<Workout> get items;
  int get total;
}
mixin _$Label { String get text; Object get copyWith => Object(); }
sealed class Label with _$Label {}
class HistoryList extends Widget {
  HistoryList({required Object items});
}
final visibleHistoryProvider = Source<List<Workout>>();
final pagedHistoryProvider = Source<WorkoutPage>();
final totalsProvider = Source<({int count, double volume})>();
final labelProvider = Source<Label>();
final shareLinkProvider = Source<Uri>();
class HistoryScreen {
  Widget build(WidgetRef ref) {
    final visible = ref.watch(visibleHistoryProvider);
    final paged = ref.watch(pagedHistoryProvider);
    final totals = ref.watch(totalsProvider);
    final label = ref.watch(labelProvider);
    final shareLink = ref.watch(shareLinkProvider);
    return HistoryList(items: [
      HistoryList(items: visible),
      HistoryList(items: paged),
      HistoryList(items: totals),
      HistoryList(items: label),
      HistoryList(items: shareLink),
    ]);
  }
}
''');
  }

  // routing-app-shell.md:381: framework widgets take framework config, not
  // reusable-widget view data.
  Future<void> test_allowsWholeValueIntoFrameworkWidget() async {
    newFile(convertPath('/package/flutter/lib/material.dart'), r'''
import 'widgets.dart';
class MaterialApp extends Widget {
  MaterialApp.router({Object? routerConfig});
}
''');
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
class Source<T> implements ProviderListenable<T> {}
class ShellConfig {
  const ShellConfig(this.initialLocation, this.debugLogDiagnostics);
  final String initialLocation;
  final bool debugLogDiagnostics;
}
final shellConfigProvider = Source<ShellConfig>();
class MyApp {
  Widget build(WidgetRef ref) {
    final config = ref.watch(shellConfigProvider);
    return MaterialApp.router(routerConfig: config);
  }
}
''');
  }

  Future<void> test_allowsWholeListIteration() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
final itemCollectionProvider = Source<List<int>>();

class ListView {
  List<int> build(WidgetRef ref) {
    final items = ref.watch(itemCollectionProvider);
    return [for (final item in items) item];
  }
}

''');
  }

  Future<void> test_reportsSelectingOneIndexedListItem() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
final itemCollectionProvider = Source<List<int>>();

class ItemView {
  int build(WidgetRef ref, int index) {
    final items = ref.watch(itemCollectionProvider);
    return items[index];
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(itemCollectionProvider)', ruleName),
    ]);
  }

  // freezed-sealed.md:9 bans .when(); only the sealed switch is a whole-value use.
  Future<void> test_reportsWholeAsyncValueWhenDispatch() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
final imageProvider = Source<AsyncValue<int>>();

class AsyncView {
  Object build(WidgetRef ref) {
    final image = ref.watch(imageProvider);
    return image.when(
      data: (value) => value,
      loading: () => 'loading',
      error: (error) => 'error',
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(imageProvider)', ruleName),
    ]);
  }

  Future<void> test_reportsWholeDispatchOnSameNamedLocalAsyncValue() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class AsyncValue<T> {
  Object when({
    required Object Function(T value) data,
    required Object Function() loading,
    required Object Function(Object error) error,
  }) => Object();
}
final imageProvider = Source<AsyncValue<int>>();

class AsyncView {
  Object build(WidgetRef ref) {
    final image = ref.watch(imageProvider);
    return image.when(
      data: (value) => value,
      loading: () => 'loading',
      error: (error) => 'error',
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'ref.watch(imageProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsWholeAsyncStatusSwitch() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
sealed class AsyncValue<T> {}
class AsyncLoading<T> extends AsyncValue<T> {}
class AsyncError<T> extends AsyncValue<T> {}
class AsyncData<T> extends AsyncValue<T> {}
final startupProvider = Source<AsyncValue<void>>();
class View {
  String build(WidgetRef ref) => switch (ref.watch(startupProvider)) {
    AsyncLoading<void>() => 'loading',
    AsyncError<void>() => 'error',
    _ => 'home',
  };
}
''');
  }

  Future<void> test_allowsSealedUnionVariantSwitch() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class User {}
sealed class AuthState {}
class Authenticated extends AuthState { Authenticated(this.user); final User user; }
class Unauthenticated extends AuthState {}
class AuthLoading extends AuthState {}
class HomeScreen { const HomeScreen({required User user}); }
class LoginScreen { const LoginScreen(); }
class LoadingScreen { const LoadingScreen(); }
final authProvider = Source<AuthState>();
class View {
  Object build(WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return switch (auth) {
      Authenticated(:final user) => HomeScreen(user: user),
      Unauthenticated() => const LoginScreen(),
      AuthLoading() => const LoadingScreen(),
    };
  }
}
''');
  }

  Future<void> test_allowsAsyncValueVariantDestructuring() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
sealed class AsyncValue<T> {}
class AsyncData<T> extends AsyncValue<T> { AsyncData(this.value); final T value; }
class AsyncError<T> extends AsyncValue<T> { AsyncError(this.error); final Object error; }
class AsyncLoading<T> extends AsyncValue<T> {}
final myAsyncProvider = Source<AsyncValue<int>>();
class View {
  String build(WidgetRef ref) {
    final asyncData = ref.watch(myAsyncProvider);
    return switch (asyncData) {
      AsyncData(:final value) => value.toString(),
      AsyncError(:final error) => '$error',
      AsyncLoading() => 'loading',
    };
  }
}
''');
  }

  Future<void> test_reportsSealedBaseTypeFieldPattern() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
sealed class Session { const Session(this.token); final String token; }
class ActiveSession extends Session { const ActiveSession(super.token); }
final signInProvider = Source<Session>();
class View {
  String build(WidgetRef ref) => switch (ref.watch(signInProvider)) {
    Session(:final token) => token,
  };
}
''';
    await assertDiagnostics(source, [compatLint(source, 'ref.watch(signInProvider)', ruleName)]);
  }

  Future<void> test_reportsPartialObjectPatternSwitch() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class Profile { const Profile(this.name, this.age); final String name; final int age; }
final profileProvider = Source<Profile>();
class View {
  String build(WidgetRef ref) => switch (ref.watch(profileProvider)) {
    Profile(:final name) => name,
  };
}
''';
    await assertDiagnostics(source, [compatLint(source, 'ref.watch(profileProvider)', ruleName)]);
  }

  Future<void> test_reportsPartialStateReads() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class Profile { String get name => 'name'; }
class AccountState { String get name => 'name'; }
final profileProvider = Source<Profile>();
final accountStateProvider = Source<AccountState>();
class View {
  Object build(WidgetRef ref) {
    final state = ref.watch(accountStateProvider);
    return (ref.watch(profileProvider).name, state.name);
  }
}
''';
    await assertDiagnostics(source, [
      compatLint(source, 'ref.watch(accountStateProvider)', ruleName),
      compatLint(source, 'ref.watch(profileProvider)', ruleName),
    ]);
  }

  Future<void> test_allowsMutationStateFlags() async {
    await assertAllows(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
final removeTodoMutation = Mutation<void>();
class View {
  Object build(WidgetRef ref) => ref.watch(removeTodoMutation).isPending;
}
''');
  }

  Future<void> test_reportsLocalMutationStateLookalike() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class MutationState { bool get isPending => false; }
final removeTodoMutation = Source<MutationState>();
class View {
  Object build(WidgetRef ref) => ref.watch(removeTodoMutation).isPending;
}
''';
    await assertDiagnostics(source, [
      compatLint(source, 'ref.watch(removeTodoMutation)', ruleName),
    ]);
  }

  Future<void> test_conditionalWholeListClearButPartialStateWarns() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class State { const State(this.count); final int count; }
class ListPanel { ListPanel({required List<String> items, required int count}); }
final itemsProvider = Source<List<String>>();
final stateProvider = Source<State>();
class View {
  Object build(WidgetRef ref, bool loading) {
    final items = loading ? const <String>[] : ref.watch(itemsProvider);
    final state = loading ? const State(0) : ref.watch(stateProvider);
    return ListPanel(items: items, count: state.count);
  }
}
''';
    await assertDiagnostics(source, [compatLint(source, 'ref.watch(stateProvider)', ruleName)]);
  }

  Future<void> test_reportsWatchSplitAcrossLines() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Source<T> implements ProviderListenable<T> {}
class Profile { String get name => 'name'; }
final profileProvider = Source<Profile>();
class ProfileView {
  Object build(WidgetRef ref) {
    final profile = ref
        .watch(profileProvider);
    return profile.name;
  }
}
''';
    await assertDiagnostics(source, [compatLint(source, 'ref\n', ruleName)]);
  }

  Future<void> test_allowsWatchOnNonRiverpodReceiver() async {
    await assertAllows(r'''
class Profile { String get name => 'name'; }
class Watcher { Profile watch(Object source) => Profile(); }
class ProfileView {
  Object build(Watcher ref) => ref.watch(Object()).name;
}
''');
  }
}
