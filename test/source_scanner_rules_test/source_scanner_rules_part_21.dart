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
}

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
