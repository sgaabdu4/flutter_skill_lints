// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class TextFieldOnChangedNoDebounceTest extends _RuntimeBugRuleTest {
  @override
  void setUp() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed { const Freezed(); }
const freezed = Freezed();
''');
    super.setUp();
  }

  @override
  String get ruleName => 'text_field_on_changed_no_debounce';
  @override
  String get needle => 'TextField(\n      onChanged:';
  @override
  String get source => r'''
class TextField {
  TextField({Object? onChanged});
}
class SearchSheet {
  Object build(Object ref) {
    return TextField(
      onChanged: (v) {
        ref.read(searchProvider.notifier).setQuery(v);
      },
    );
  }
}
''';

  Future<void> test_allowsResolvedSynchronousFormUpdate() async {
    await assertAllows(_inputNotifierSource('TextField', 'void', ''));
  }

  Future<void> test_allowsCopyWithAndLocalValidation() async {
    await assertAllows(r'''
class TextField {
  const TextField({required void Function(String) onChanged});
}
class FormState {
  const FormState(this.value);
  final String value;
  FormState copyWith({String? value}) => FormState(value ?? this.value);
}
class FormNotifier {
  FormState state = const FormState('');
  void update(String value) {
    state = state.copyWith(value: value);
    final valid = value.isNotEmpty;
    if (!valid) return;
  }
}
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
class FormView {
  TextField build(Ref ref) => TextField(
    onChanged: (value) => ref.read(formProvider.notifier).update(value),
  );
}
''');
  }

  Future<void> test_allowsGeneratedFreezedCallableCopyWith() async {
    newFile('$testPackageLibPath/form_state.dart', r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'form_state.freezed.dart';
@freezed
class FormState with _$FormState {
  const FormState(this.value, this.valid);
  final String value;
  final bool valid;
}
''');
    newFile('$testPackageLibPath/form_state.freezed.dart', r'''
part of 'form_state.dart';
mixin _$FormState {
  FormStateCopyWith get copyWith => FormStateCopyWith(this as FormState);
}
class FormStateCopyWith {
  FormStateCopyWith(this.state);
  final FormState state;
  FormState call({String? value, bool? valid}) => FormState(value ?? state.value, valid ?? state.valid);
}
''');
    await assertNoDiagnosticsInFile('$testPackageLibPath/form_state.dart');
    await assertAllows(r'''
import 'form_state.dart';
class TextField { TextField({required void Function(String) onChanged}); }
class FormNotifier {
  FormState state = const FormState('', false);
  void update(String value) { state = state.copyWith(value: value, valid: value.isNotEmpty); }
}
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''');
  }

  Future<void> test_reportsCopyWithThatStartsAsyncWork() async {
    const source = r'''
import 'dart:async';
class TextField { TextField({required void Function(String) onChanged}); }
class FormState {
  const FormState(this.value);
  final String value;
  Future<void> fetch() async {}
  FormState copyWith({String? value}) {
    unawaited(fetch());
    return FormState(value ?? this.value);
  }
}
class FormNotifier {
  FormState state = const FormState('');
  void update(String value) { state = state.copyWith(value: value); }
}
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''';
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_reportsCopyWithUsingEffectfulConstructor() async {
    const source = r'''
import 'dart:async';
class TextField { TextField({required void Function(String) onChanged}); }
class FormState {
  FormState(this.value) { unawaited(fetch()); }
  final String value;
  static Future<void> fetch() async {}
  FormState copyWith({String? value}) => FormState(value ?? this.value);
}
class FormNotifier {
  FormState state = FormState('');
  void update(String value) { state = state.copyWith(value: value); }
}
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''';
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_reportsCopyWithReadingEffectfulGetter() async {
    const source = r'''
import 'dart:async';
class TextField { TextField({required void Function(String) onChanged}); }
class FormState {
  const FormState(this._value);
  final String _value;
  String get value { unawaited(fetch()); return _value; }
  static Future<void> fetch() async {}
  FormState copyWith({String? value}) => FormState(value ?? this.value);
}
class FormNotifier {
  FormState state = const FormState('');
  void update(String value) { state = state.copyWith(value: value); }
}
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''';
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_reportsReturnThatStartsAsyncWork() async {
    const source = r'''
import 'dart:async';
class TextField { TextField({required void Function(String) onChanged}); }
class Notifier {
  String state = '';
  Future<void> fetch(String value) async {}
  void startNetwork(String value) { unawaited(fetch(value)); }
  void update(String value) {
    state = value;
    if (value.isEmpty) return startNetwork(value);
  }
}
class Provider { final notifier = Notifier(); }
class Ref { Notifier read(Notifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''';
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_allowsDirectStateAssignment() async {
    await assertAllows(_inputNotifierSource('TextField', 'void', '', body: 'state = value;'));
  }

  Future<void> test_reportsSynchronousForwardingMethods() async {
    for (final (index, body) in [
      'unawaited(fetch(value));',
      'fetch(value);',
      'forward(value);',
    ].indexed) {
      final source = _inputNotifierSource('TextField', 'void', '', body: body);
      final path = '$testPackageLibPath/forward_$index.dart';
      newFile(path, source);
      await assertDiagnosticsInFile(path, [compatLint(source, 'TextField(onChanged:', ruleName)]);
    }
  }

  Future<void> test_reportsResolvedAsyncRequest() async {
    final source = _inputNotifierSource('TextField', 'Future<void>', 'async');
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_submissionWorkIsNotOnChangedWork() async {
    await assertAllows(r'''
class TextField {
  TextField({required void Function(String) onChanged, required void Function(String) onSubmitted});
}
Object build() => TextField(
  onChanged: (value) => print(value),
  onSubmitted: (value) async { await Future<void>.value(); },
);
''');
  }

  Future<void> test_onlyAsyncNeighborReports() async {
    const source = r'''
class TextField { TextField({required void Function(String) onChanged}); }
class Notifier {
  void update(String value) {}
  Future<void> fetch(String value) async {}
}
class Provider { Notifier get notifier => Notifier(); }
class Ref { Notifier read(Notifier notifier) => notifier; }
final formProvider = Provider();
List<Object> build(Ref ref) => [
  TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value)),
  TextField(onChanged: (value) => ref.read(formProvider.notifier).fetch(value)),
];
''';
    await assertDiagnostics(source, [
      compatLint(
        source,
        'TextField(onChanged: (value) => ref.read(formProvider.notifier).fetch',
        ruleName,
      ),
    ]);
  }

  Future<void> test_reportsResolvedAsyncVoidRequest() async {
    final source = _inputNotifierSource('TextField', 'void', 'async');
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  Future<void> test_allowsWithTimerInFile() async {
    await assertAllows(r'''
class TextField {
  TextField({Object? onChanged});
}
class Timer {
  Timer(Object d, Object cb);
}
class SearchSheet {
  Object? _debounce;
  Object build(Object ref) {
    return TextField(
      onChanged: (v) {
        _debounce = Timer(const Object(), () {
          ref.read(searchProvider.notifier).setQuery(v);
        });
      },
    );
  }
}
''');
  }

  Future<void> test_allowsLocalOnlyCallback() async {
    await assertAllows(r'''
class TextField {
  TextField({Object? onChanged});
}
class SearchSheet {
  Object build() {
    return TextField(onChanged: (v) => print(v));
  }
}
''');
  }

  /// #37: the issue's hand-written copyWith update and the skill's `setName`
  /// form handler (lists-forms-workflows.md) are synchronous state-only
  /// updates, as lambdas or tear-offs.
  Future<void> test_allowsIssue37SynchronousFormHandlers() async {
    await assertAllows(
      _formNotifierSource +
          r'''
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
List<Object> build(Ref ref) => [
  TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value)),
  TextField(onChanged: (value) => ref.read(formProvider.notifier).setName(value)),
  TextField(onChanged: ref.read(formProvider.notifier).setName),
];
''',
    );
  }

  /// #37: the notifier and its state live in another library (the usual
  /// widget/notifier layout); its synchronous signature is the evidence.
  Future<void> test_allowsIssue37SynchronousFormHandlersFromAnotherFile() async {
    newFile('$testPackageLibPath/form_notifier.dart', _formNotifierSource);
    await assertAllows(r'''
import 'form_notifier.dart';
class Provider { final notifier = FormNotifier(); }
class Ref { FormNotifier read(FormNotifier notifier) => notifier; }
final formProvider = Provider();
List<Object> build(Ref ref) => [
  TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value)),
  TextField(onChanged: ref.read(formProvider.notifier).setName),
];
''');
  }

  /// #37: a tear-off to an async remote request reaches async work.
  Future<void> test_reportsIssue37AsyncTearOff() async {
    const source = r'''
class TextField { TextField({required void Function(String) onChanged}); }
class SearchNotifier {
  Future<void> search(String query) async {}
}
class Provider { final notifier = SearchNotifier(); }
class Ref { SearchNotifier read(SearchNotifier notifier) => notifier; }
final searchProvider = Provider();
Object build(Ref ref) => TextField(onChanged: ref.read(searchProvider.notifier).search);
''';
    await assertDiagnostics(source, [compatLint(source, 'TextField(onChanged:', ruleName)]);
  }

  /// #37: a cross-file async notifier method reports as a lambda or tear-off.
  Future<void> test_reportsIssue37AsyncRequestFromAnotherFile() async {
    newFile('$testPackageLibPath/search_notifier.dart', r'''
class SearchNotifier {
  Future<void> search(String query) async {}
}
''');
    const source = r'''
import 'search_notifier.dart';
class TextField { TextField({required void Function(String) onChanged}); }
class Provider { final notifier = SearchNotifier(); }
class Ref { SearchNotifier read(SearchNotifier notifier) => notifier; }
final searchProvider = Provider();
List<Object> build(Ref ref) => [
  TextField(onChanged: ref.read(searchProvider.notifier).search),
  TextField(onChanged: (value) => ref.read(searchProvider.notifier).search(value)),
];
''';
    await assertDiagnostics(source, [
      compatLint(source, 'TextField(onChanged: ref', ruleName),
      compatLint(source, 'TextField(onChanged: (value)', ruleName),
    ]);
  }

  /// #37: a synchronous `void` method in another file that forwards to a
  /// Future (directly or through an unresolved generic `ref.read<T>`) still
  /// reaches async work; a state-only neighbor stays clean.
  Future<void> test_reportsCrossFileSynchronousForwarders() async {
    newFile('$testPackageLibPath/input_notifier.dart', r'''
import 'dart:async';
class Provider<T> { Provider(this.value); final T value; }
class Ref { T read<T>(Provider<T> provider) => provider.value; }
class SearchNotifier { Future<void> search(String query) async {} }
final searchProvider = Provider(SearchNotifier());
class InputNotifier {
  InputNotifier(this.ref);
  final Ref ref;
  String state = '';
  void update(String value) { state = value; }
  Future<void> fetch(String value) async {}
  void forward(String value) { unawaited(fetch(value)); }
  void updateAndSearch(String value) {
    state = value;
    unawaited(ref.read(searchProvider).search(value));
  }
}
final inputProvider = Provider(InputNotifier(Ref()));
''');
    const source = r'''
import 'input_notifier.dart';
class TextField { TextField({required void Function(String) onChanged}); }
List<Object> build(Ref ref) => [
  TextField(onChanged: (value) => ref.read(inputProvider).update(value)),
  TextField(onChanged: (value) => ref.read(inputProvider).forward(value)),
  TextField(onChanged: ref.read(inputProvider).forward),
  TextField(onChanged: (value) => ref.read(inputProvider).updateAndSearch(value)),
];
''';
    await assertDiagnostics(source, [
      compatLint(
        source,
        'TextField(onChanged: (value) => ref.read(inputProvider).forward',
        ruleName,
      ),
      compatLint(source, 'TextField(onChanged: ref.read(inputProvider).forward', ruleName),
      compatLint(
        source,
        'TextField(onChanged: (value) => ref.read(inputProvider).updateAndSearch',
        ruleName,
      ),
    ]);
  }

  /// #37: the skill's `setName` (lists-forms-workflows.md:205-210) on a
  /// Freezed state, with state, generated part and notifier in other files.
  /// The generated callable `copyWith` is synchronous.
  Future<void> test_allowsCrossFileFreezedCallableCopyWith() async {
    newFile('$testPackageLibPath/form_state.dart', r'''
import 'package:freezed_annotation/freezed_annotation.dart';
part 'form_state.freezed.dart';
@freezed
abstract class ProductFormState with _$ProductFormState {
  const factory ProductFormState({required String draftName, String? nameError}) =
      _ProductFormState;
}
''');
    newFile('$testPackageLibPath/form_state.freezed.dart', r'''
part of 'form_state.dart';
T _$identity<T>(T value) => value;
mixin _$ProductFormState {
  String get draftName;
  String? get nameError;
  $ProductFormStateCopyWith<ProductFormState> get copyWith =>
      _$ProductFormStateCopyWithImpl<ProductFormState>(this as ProductFormState, _$identity);
}
abstract mixin class $ProductFormStateCopyWith<$Res> {
  $Res call({String draftName, String? nameError});
}
class _$ProductFormStateCopyWithImpl<$Res> implements $ProductFormStateCopyWith<$Res> {
  _$ProductFormStateCopyWithImpl(this._self, this._then);
  final ProductFormState _self;
  final $Res Function(ProductFormState) _then;
  @override
  $Res call({Object? draftName, Object? nameError}) => _then(_self);
}
class _ProductFormState with _$ProductFormState implements ProductFormState {
  const _ProductFormState({required this.draftName, this.nameError});
  @override
  final String draftName;
  @override
  final String? nameError;
}
''');
    newFile('$testPackageLibPath/form_notifier.dart', r'''
import 'form_state.dart';
abstract class Notifier<S> {
  late S state;
}
class ProductFormNotifier extends Notifier<ProductFormState> {
  void setName(String value) {
    String? validationMessage;
    if (value.isEmpty) validationMessage = 'Name required';
    if (value.length < 3) validationMessage = 'Name too short';
    state = state.copyWith(draftName: value, nameError: validationMessage);
  }
}
''');
    await assertAllows(r'''
import 'form_notifier.dart';
class TextField { TextField({required void Function(String) onChanged}); }
class Provider { final notifier = ProductFormNotifier(); }
class Ref { ProductFormNotifier read(ProductFormNotifier notifier) => notifier; }
final formProvider = Provider();
List<Object> build(Ref ref) => [
  TextField(onChanged: (value) => ref.read(formProvider.notifier).setName(value)),
  TextField(onChanged: ref.read(formProvider.notifier).setName),
];
''');
  }

  /// lists-forms-workflows.md SearchNotifier DO: the notifier in another file
  /// debounces its async work, so the TextField forwarding to it is clean.
  Future<void> test_allowsCrossFileNotifierDebounce() async {
    newFile('$testPackageLibPath/search_notifier.dart', r'''
import 'dart:async';
final class Debouncer {
  Debouncer(this.duration);
  final Duration duration;
  Timer? _timer;
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
}
class SearchNotifier {
  final _debouncer = Debouncer(const Duration(milliseconds: 150));
  String state = '';
  void search(String query) {
    state = query;
    _debouncer.call(() async {
      state = await _load(query);
    });
  }
  Future<String> _load(String query) async => query;
}
''');
    await assertAllows(r'''
import 'search_notifier.dart';
class TextField { TextField({required void Function(String) onChanged}); }
class Provider { final notifier = SearchNotifier(); }
class Ref { SearchNotifier read(SearchNotifier notifier) => notifier; }
final searchProvider = Provider();
Object build(Ref ref) =>
    TextField(onChanged: (value) => ref.read(searchProvider.notifier).search(value));
''');
  }

  /// debounce-gate-batch.md:21-31 DO: Timer cancel-and-restart in the widget.
  Future<void> test_allowsSkillTimerDebounceDo() async {
    await assertAllows(r'''
import 'dart:async';
class TextField { TextField({required void Function(String) onChanged}); }
class SearchNotifier { Future<void> search(String query) async {} }
class Provider { final notifier = SearchNotifier(); }
class Ref { SearchNotifier read(SearchNotifier notifier) => notifier; }
final searchProvider = Provider();
class SearchSheet {
  SearchSheet(this.ref);
  final Ref ref;
  Timer? _debounce;
  Object build() => TextField(onChanged: (v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      ref.read(searchProvider.notifier).search(v);
    });
  });
}
''');
  }
}

const _formNotifierSource = r'''
class TextField { TextField({required void Function(String) onChanged}); }
class FormState {
  const FormState({this.draftName = '', this.nameError, this.value = ''});
  final String draftName;
  final String? nameError;
  final String value;
  FormState copyWith({String? draftName, String? nameError, String? value}) => FormState(
    draftName: draftName ?? this.draftName,
    nameError: nameError,
    value: value ?? this.value,
  );
}
class FormNotifier {
  FormState state = const FormState();
  void update(String value) {
    state = state.copyWith(value: value);
    if (value.isEmpty) return;
  }
  void setName(String value) {
    String? validationMessage;
    if (value.isEmpty) validationMessage = 'Name required';
    if (value.length < 3) validationMessage = 'Name too short';
    state = state.copyWith(draftName: value, nameError: validationMessage);
  }
}
''';

@reflectiveTest
final class SliderOnChangedNoDebounceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'slider_on_changed_no_debounce';
  @override
  String get needle => 'Slider(\n      onChanged:';
  @override
  String get source => r'''
class Slider {
  Slider({Object? onChanged});
}
class RangeSheet {
  Object build(Object ref) {
    return Slider(
      onChanged: (v) {
        ref.read(volumeProvider.notifier).setVolume(v);
      },
    );
  }
}
''';

  Future<void> test_allowsResolvedSynchronousSliderUpdate() async {
    await assertAllows(_inputNotifierSource('Slider', 'void', ''));
  }

  Future<void> test_reportsResolvedAsyncSliderRequest() async {
    final source = _inputNotifierSource('Slider', 'Future<void>', 'async');
    await assertDiagnostics(source, [compatLint(source, 'Slider(onChanged:', ruleName)]);
  }

  Future<void> test_allowsSliderWithOnlySetState() async {
    await assertAllows(r'''
class Slider {
  Slider({Object? onChanged});
}
class RangeSheet {
  double _value = 0;
  Object build() {
    return Slider(onChanged: (v) => _value = v);
  }
}
''');
  }

  Future<void> test_allowsSliderWhenFileHasTimer() async {
    await assertAllows(r'''
class Slider {
  Slider({Object? onChanged});
}
class Timer {
  Timer(Object d, Object cb);
}
class RangeSheet {
  Object? _debounce;
  Object build(Object ref) {
    return Slider(
      onChanged: (v) {
        _debounce = Timer(const Object(), () {
          ref.read(volumeProvider.notifier).setVolume(v);
        });
      },
    );
  }
}
''');
  }
}

@reflectiveTest
final class ScrollListenerNoThrottleTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'scroll_listener_no_throttle';
  @override
  String get needle => '_scrollController.addListener(';
  @override
  String get source => r'''
class FeedScreen {
  final Object _scrollController = Object();
  void init(Object ref) {
    _scrollController.addListener(() {
      ref.read(feedProvider.notifier).loadMore();
    });
  }
}
''';

  Future<void> test_allowsListenerWithLocalStateOnly() async {
    await assertAllows(r'''
class FeedScreen {
  final Object _scrollController = Object();
  double _offset = 0;
  void init() {
    _scrollController.addListener(() {
      _offset = 1;
    });
  }
}
''');
  }

  Future<void> test_allowsListenerWhenFileHasTimer() async {
    await assertAllows(r'''
class FeedScreen {
  final Object _scrollController = Object();
  Object? _throttle;
  void init(Object ref) {
    _scrollController.addListener(() {
      _throttle = Timer(const Object(), () {
        ref.read(feedProvider.notifier).loadMore();
      });
    });
  }
}
class Timer {
  Timer(Object d, Object cb);
}
''');
  }
}

// ---------------------------------------------------------------------------
// Regression suite — alternate TP shapes + edge FP guards per rule.
// Added 2026-05 to lock in detection coverage and false-positive defenses.
// ---------------------------------------------------------------------------

@reflectiveTest
final class DialogWidgetSubscribesPathBasedTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_widget_subscribes_to_mutable_provider';
  @override
  String? get path => '$testPackageLibPath/features/feedback/confirm_dialog.dart';
  @override
  String get needle => 'ref.watch(entryProvider)';
  @override
  String get source => r'''
class WidgetRef { Object read(Object p) => Object(); Object watch(Object p) => Object(); }
class ConsumerWidget extends Widget {}
class Widget {}

class ConfirmHost extends ConsumerWidget {
  final ref = WidgetRef();
  Object build(Object context) {
    final v = ref.watch(entryProvider);
    ref.read(entryProvider.notifier).save();
    return v;
  }
}
''';
}

String _inputNotifierSource(
  String inputType,
  String returnType,
  String bodyModifier, {
  String body = '',
}) =>
    '''
import 'dart:async';
class $inputType { $inputType({required void Function(String) onChanged}); }
class Notifier {
  String state = '';
  $returnType update(String value) $bodyModifier {$body}
  Future<void> fetch(String value) async {}
  void forward(String value) { unawaited(fetch(value)); }
}
class Provider { Notifier get notifier => Notifier(); }
class Ref { Notifier read(Notifier notifier) => notifier; }
final formProvider = Provider();
Object build(Ref ref) => $inputType(onChanged: (value) => ref.read(formProvider.notifier).update(value));
''';
