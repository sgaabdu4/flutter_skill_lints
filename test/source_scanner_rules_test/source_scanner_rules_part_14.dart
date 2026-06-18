// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class DialogWidgetSubscribesToMutableProviderTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_widget_subscribes_to_mutable_provider';
  @override
  String get needle => 'ref.watch(formProvider)';
  @override
  String get source => r'''
class WidgetRef {
  Object watch(Object provider) => Object();
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  final ref = WidgetRef();

  Object build(Object context) {
    final isSaving = ref.watch(formProvider);
    ref.read(formProvider.notifier).save();
    return isSaving;
  }
}
''';

  Future<void> test_allowsNonDialogClass() async {
    await assertAllows(r'''
class WidgetRef {
  Object watch(Object provider) => Object();
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class DetailScreen extends ConsumerWidget {
  final ref = WidgetRef();
  Object build(Object context) {
    final isSaving = ref.watch(formProvider);
    ref.read(formProvider.notifier).save();
    return isSaving;
  }
}
''');
  }

  Future<void> test_allowsDialogWithSnapshotPattern() async {
    await assertAllows(r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmSummary {
  ConfirmSummary({required this.confirmed});
  final bool confirmed;
}

class ConfirmDialog extends ConsumerWidget {
  ConfirmDialog({required this.summary});
  final ConfirmSummary summary;
  final ref = WidgetRef();

  Object build(Object context) {
    final isSaving = ref.watch(formProvider);
    return isSaving;
  }
}
''');
  }

  Future<void> test_reportsConsumerStateSheetFromPath() async {
    const source = r'''
class WidgetRef {
  Object watch(Object provider) => Object();
  Object read(Object provider) => Object();
}
class ConsumerState<T> extends State<T> {}
class SessionSheet {}

class _SessionSheetState extends ConsumerState<SessionSheet> {
  final ref = WidgetRef();

  Object build(Object context) {
    final isReady = ref.watch(timerProvider.select((s) => s.isReady));
    ref.read(timerProvider.notifier).pause();
    return isReady;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);
    final filePath = '$testPackageLibPath/session_sheet.dart';
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(analyzedSource, 'ref.watch(timerProvider', ruleName),
    ]);
  }
}

@reflectiveTest
final class ModalHighFrequencyWatchNotLeafTest extends _DialogRuleTest {
  @override
  String get ruleName => 'modal_high_frequency_watch_not_leaf';
  @override
  String get needle => 'ref.watch(timerProvider.select((s) => s.seconds))';
  @override
  String get source => r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class SessionSheet extends ConsumerWidget {
  final ref = WidgetRef();

  Object build(Object context) {
    final seconds = ref.watch(timerProvider.select((s) => s.seconds));
    return seconds;
  }
}
''';

  Future<void> test_reportsMultilineSelect() async {
    const source = r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class SessionSheet extends ConsumerWidget {
  final ref = WidgetRef();

  Object build(Object context) {
    final seconds = ref.watch(
      timerProvider.select((s) => s.seconds),
    );
    return seconds;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, 'ref.watch(', ruleName)]);
  }

  Future<void> test_allowsLeafNonModalClass() async {
    await assertAllows(r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class TimerControls extends ConsumerWidget {
  final ref = WidgetRef();

  Object build(Object context) {
    final seconds = ref.watch(timerProvider.select((s) => s.seconds));
    return seconds;
  }
}
''');
  }
}

@reflectiveTest
final class DialogButtonPopThenStateMutationTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_button_pop_then_state_mutation';
  @override
  String get needle => 'ref.read(formProvider.notifier).reset()';
  @override
  String get source => r'''
class Navigator {
  static Object of(Object context) => Object();
}
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  final ref = WidgetRef();

  void onTap(Object context) {
    Navigator.of(context).pop();
    ref.read(formProvider.notifier).reset();
  }
}
''';

  Future<void> test_allowsPopWithResultNoFollowUp() async {
    await assertAllows(r'''
class Navigator {
  static Object of(Object context) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  void onTap(Object context) {
    Navigator.of(context).pop(true);
  }
}
''');
  }

  Future<void> test_allowsPostPopInNonDialogClass() async {
    await assertAllows(r'''
class Navigator {
  static Object of(Object context) => Object();
}
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class DetailScreen extends ConsumerWidget {
  final ref = WidgetRef();
  void onTap(Object context) {
    Navigator.of(context).pop();
    ref.read(formProvider.notifier).reset();
  }
}
''');
  }
}

@reflectiveTest
final class SelectReturnsUnstableRecordIdentityTest extends _DialogRuleTest {
  @override
  String get ruleName => 'select_returns_unstable_record_identity';
  @override
  String get needle => '.select((s) => (saving: s.isSaving, sets: s.itemsByCategoryId))';
  @override
  String get source => r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}

class Reader {
  final ref = WidgetRef();
  Object call() {
    return ref.watch(formProvider.select((s) => (saving: s.isSaving, sets: s.itemsByCategoryId)));
  }
}
''';

  Future<void> test_allowsPrimitiveSelect() async {
    await assertAllows(r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class Reader {
  final ref = WidgetRef();
  Object call() {
    return ref.watch(formProvider.select((s) => s.isSaving));
  }
}
''');
  }

  Future<void> test_allowsRecordOfStableFields() async {
    await assertAllows(r'''
class WidgetRef {
  Object watch(Object provider) => Object();
}
class Reader {
  final ref = WidgetRef();
  Object call() {
    return ref.watch(formProvider.select((s) => (a: s.isSaving, b: s.id)));
  }
}
''');
  }
}

@reflectiveTest
final class BuildMethodAssignsToFieldTest extends _DialogRuleTest {
  @override
  String get ruleName => 'build_method_assigns_to_field';
  @override
  String get needle => '_summary ??= Object()';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  Object? _summary;

  Object build(Object context) {
    _summary ??= Object();
    return _summary ?? Object();
  }
}
''';

  Future<void> test_allowsLocalFinal() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  Object build(Object context) {
    final summary = Object();
    return summary;
  }
}
''');
  }

  Future<void> test_allowsAssignmentOutsideBuild() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class ConfirmDialog extends ConsumerWidget {
  Object? _summary;

  void initState() {
    _summary = Object();
  }

  Object build(Object context) => _summary ?? Object();
}
''');
  }
}

@reflectiveTest
final class BuildCallsMutatingInstanceMethodTest extends _DialogRuleTest {
  @override
  String get ruleName => 'build_calls_mutating_instance_method';
  @override
  String get needle => '_syncInitialValues(model)';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}

class EditSheet extends ConsumerWidget {
  Object? _cached;

  void _syncInitialValues(Object model) {
    _cached = model;
  }

  Object build(Object context) {
    final model = Object();
    _syncInitialValues(model);
    return _cached ?? model;
  }
}
''';

  Future<void> test_allowsPureHelperFromBuild() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class EditSheet extends ConsumerWidget {
  Object _summary(Object model) {
    return model;
  }

  Object build(Object context) {
    final model = Object();
    return _summary(model);
  }
}
''');
  }

  Future<void> test_reportsControllerPropertyMutation() async {
    const source = r'''
class ConsumerWidget extends Widget {}

class EditSheet extends ConsumerWidget {
  final _controller = Object();

  void _syncInitialValues() {
    _controller.text = 'value';
  }

  Object build(Object context) {
    _syncInitialValues();
    return _controller;
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_syncInitialValues();', ruleName),
    ]);
  }

  Future<void> test_allowsMutatingHelperInsideMultilineCallback() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class EditSheet extends ConsumerWidget {
  Object? _cached;

  void _syncInitialValues(Object model) {
    _cached = model;
  }

  Object build(Object context) {
    ref.listen<Object>(provider, (_, next) {
      _syncInitialValues(next);
    });
    return Object();
  }
}
''');
  }
}

@reflectiveTest
final class WidgetCallsNotifierTeardownAfterAwaitTest extends _DialogRuleTest {
  @override
  String get ruleName => 'widget_calls_notifier_teardown_after_await';
  @override
  String get needle => 'ref.read(formProvider.notifier).reset()';
  @override
  String get source => r'''
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class SubmitButton extends ConsumerWidget {
  final ref = WidgetRef();

  Future<void> onPressed() async {
    await ref.read(formProvider.notifier).save();
    ref.read(formProvider.notifier).reset();
  }
}
''';

  Future<void> test_allowsResetWithoutAwait() async {
    await assertAllows(r'''
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}

class SubmitButton extends ConsumerWidget {
  final ref = WidgetRef();
  void onPressed() {
    ref.read(formProvider.notifier).reset();
  }
}
''');
  }

  Future<void> test_allowsResetInsideNotifier() async {
    await assertAllows(r'''
class WidgetRef {
  Object read(Object provider) => Object();
}
class Notifier {}

class FormNotifier extends Notifier {
  final ref = WidgetRef();

  Future<void> save() async {
    await ref.read(logProvider.notifier).addLog();
    ref.read(logProvider.notifier).reset();
  }
}
''');
  }
}

@reflectiveTest
final class PopScopeBypassUsesGoNotPopTest extends _DialogRuleTest {
  @override
  String get ruleName => 'popscope_bypass_uses_go_not_pop';
  @override
  String get needle => 'context.popWithFallback(';
  @override
  String get source => r'''
class DetailRoute {
  Object go(Object context) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  Future<void> onTap(Object context) async {
    await showDialog(builder: Object());
    context.popWithFallback(DetailRoute());
  }
}
''';

  Future<void> test_allowsTypedRouteGo() async {
    await assertAllows(r'''
class DetailRoute {
  Object go(Object context) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  Future<void> onTap(Object context) async {
    await showDialog(builder: Object());
    DetailRoute().go(context);
  }
}
''');
  }

  Future<void> test_allowsPopWithFallbackWithoutPrecedingModal() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  void onTap(Object context) {
    context.popWithFallback(Object());
  }
}
''');
  }
}

abstract class _RuntimeBugRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => runtimeBugSourceRules;
}

@reflectiveTest
final class ModalHelperRequiresRouteSettingsTest extends _DialogRuleTest {
  @override
  String get ruleName => 'modal_helper_requires_route_settings';
  @override
  String get needle => 'showDialog<T>(';
  @override
  String get source => r'''
Future<T?> openConfirm<T>(Object context) => showDialog<T>(
  context: context,
  builder: (_) => Object(),
);
''';

  Future<void> test_allowsWithRouteSettings() async {
    await assertAllows(r'''
Future<T?> openConfirm<T>(Object context) => showDialog<T>(
  context: context,
  routeSettings: const Object(),
  builder: (_) => Object(),
);
''');
  }

  Future<void> test_allowsSheetWithRouteSettings() async {
    await assertAllows(r'''
Future<T?> openSheet<T>(Object context) => showModalBottomSheet<T>(
  context: context,
  routeSettings: const Object(),
  builder: (_) => Object(),
);
''');
  }
}
