part of '../source_scanner_rules_test.dart';

final class _DialogWidgetSubscribesToMutableProviderTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_DialogWidgetSubscribesToMutableProviderTest)>
  get _allCases => caseSet<_DialogWidgetSubscribesToMutableProviderTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsMultilineWatchFromSkillNeverExample': (t) =>
          t._reportsMultilineWatchFromSkillNeverExample(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsNonDialogClass': (t) => t._allowsNonDialogClass(),
      'test_allowsDialogWithSnapshotPattern': (t) => t._allowsDialogWithSnapshotPattern(),
      'test_reportsConsumerStateSheetFromPath': (t) => t._reportsConsumerStateSheetFromPath(),
    },
  );

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

  Future<void> _reportsMultilineWatchFromSkillNeverExample() async {
    final analyzedSource = _analyzedSource(_skillNeverConfirmDialog, addIgnorePrefix: true);
    final filePath = '$testPackageLibPath/features/confirm/presentation/confirm_dialog.dart';
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [compatLint(analyzedSource, 'ref.watch(\n', ruleName)]);
  }

  Future<void> _severityIsError() async {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsNonDialogClass() async {
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

  Future<void> _allowsDialogWithSnapshotPattern() async {
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

  Future<void> _reportsConsumerStateSheetFromPath() async {
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

final class _ModalHighFrequencyWatchNotLeafTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_ModalHighFrequencyWatchNotLeafTest)> get _allCases =>
      caseSet<_ModalHighFrequencyWatchNotLeafTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsMultilineSelect': (t) => t._reportsMultilineSelect(),
          'test_allowsLeafNonModalClass': (t) => t._allowsLeafNonModalClass(),
        },
      );

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

  Future<void> _reportsMultilineSelect() async {
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

  Future<void> _allowsLeafNonModalClass() async {
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

final class _DialogButtonPopThenStateMutationTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_DialogButtonPopThenStateMutationTest)> get _allCases =>
      caseSet<_DialogButtonPopThenStateMutationTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsPopWithResultNoFollowUp': (t) => t._allowsPopWithResultNoFollowUp(),
          'test_allowsPostPopInNonDialogClass': (t) => t._allowsPostPopInNonDialogClass(),
          'test_reportsSecondPopAfterRootNavigatorPop': (t) =>
              t._reportsSecondPopAfterRootNavigatorPop(),
          'test_reportsTypedRoutePushAfterSheetPop': (t) => t._reportsTypedRoutePushAfterSheetPop(),
          'test_allowsSeparateButtonPopsWithResults': (t) =>
              t._allowsSeparateButtonPopsWithResults(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

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

  Future<void> _allowsPopWithResultNoFollowUp() async {
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

  Future<void> _allowsPostPopInNonDialogClass() async {
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

  Future<void> _reportsSecondPopAfterRootNavigatorPop() async {
    const source = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmDialog extends Widget {
  Future<void> onConfirm(BuildContext context, Future<bool> save) async {
    final ok = await save;
    Navigator.of(context, rootNavigator: true).pop();
    if (ok) context.pop();
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'context.pop();', ruleName),
    ]);
  }

  Future<void> _reportsTypedRoutePushAfterSheetPop() async {
    const source = r'''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreateExerciseRoute extends GoRouteData {
  const CreateExerciseRoute();
}

class MenuSheet extends Widget {
  Future<void> onCreateTapped(BuildContext context) async {
    Navigator.of(context).pop();
    await const CreateExerciseRoute().push<String>(context);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'const CreateExerciseRoute().push', ruleName),
    ]);
  }

  Future<void> _allowsSeparateButtonPopsWithResults() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

enum CreateChoice { exercise }

class ChoiceSheet extends Widget {
  void Function() cancel(BuildContext context) => () => Navigator.of(context).pop();
  void Function() confirm(BuildContext context) =>
      () => Navigator.of(context).pop(CreateChoice.exercise);
}
''');
  }
}

final class _SelectReturnsUnstableRecordIdentityTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_SelectReturnsUnstableRecordIdentityTest)>
  get _allCases => caseSet<_SelectReturnsUnstableRecordIdentityTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsMultilineSelectFromSkillNeverExample': (t) =>
          t._reportsMultilineSelectFromSkillNeverExample(),
      'test_resolvedGettersDecideRecordFieldIdentity': (t) =>
          t._resolvedGettersDecideRecordFieldIdentity(),
      'test_severityIsError': (t) => t._severityIsError(),
      'test_allowsPrimitiveSelect': (t) => t._allowsPrimitiveSelect(),
      'test_allowsRecordOfStableFields': (t) => t._allowsRecordOfStableFields(),
    },
  );

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

  Future<void> _reportsMultilineSelectFromSkillNeverExample() async {
    final analyzedSource = _analyzedSource(_skillNeverConfirmDialog, addIgnorePrefix: true);
    final filePath = '$testPackageLibPath/features/confirm/presentation/confirm_dialog.dart';
    newFile(filePath, analyzedSource);

    await assertDiagnosticsInFile(filePath, [
      compatLint(
        analyzedSource,
        '.select((s) => (isSaving: s.isSaving, itemsByCategoryId: s.itemsByCategoryId)),',
        ruleName,
      ),
    ]);
  }

  Future<void> _resolvedGettersDecideRecordFieldIdentity() async {
    const source = r'''
class FormState {
  FormState({required this.isSaving, required this.tagsMap, required this.items});
  final bool isSaving;
  final Map<String, int> tagsMap;
  final List<String> items;
  Set<String> get selected => items.toSet();
}

class Provider<T> {
  Provider<R> select<R>(R Function(T state) selector) => Provider<R>();
}

class WidgetRef {
  external T watch<T>(Provider<T> provider);
}

final formProvider = Provider<FormState>();

class Reader {
  Reader(this.ref);
  final WidgetRef ref;

  Object build() {
    final stable = ref.watch(formProvider.select((s) => (saving: s.isSaving, tags: s.tagsMap)));
    final fresh = ref.watch(formProvider.select((s) => (saving: s.isSaving, picked: s.selected)));
    return (stable, fresh);
  }
}
''';

    await assertDiagnostics(source, [
      compatLint(source, '.select((s) => (saving: s.isSaving, picked: s.selected)));', ruleName),
    ]);
  }

  Future<void> _severityIsError() async {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _allowsPrimitiveSelect() async {
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

  Future<void> _allowsRecordOfStableFields() async {
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

final class _BuildMethodAssignsToFieldTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_BuildMethodAssignsToFieldTest)> get _allCases =>
      caseSet<_BuildMethodAssignsToFieldTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsLocalFinal': (t) => t._allowsLocalFinal(),
          'test_allowsAssignmentOutsideBuild': (t) => t._allowsAssignmentOutsideBuild(),
        },
      );

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

  Future<void> _allowsLocalFinal() async {
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

  Future<void> _allowsAssignmentOutsideBuild() async {
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

final class _BuildCallsMutatingInstanceMethodTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_BuildCallsMutatingInstanceMethodTest)> get _allCases =>
      caseSet<_BuildCallsMutatingInstanceMethodTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsArrowEventCallback': (t) => t._allowsArrowEventCallback(),
          'test_reportsImmediateArrowInvocation': (t) => t._reportsImmediateArrowInvocation(),
          'test_reportsImmediateBlockInvocation': (t) => t._reportsImmediateBlockInvocation(),
          'test_reportsImmediateCallAfterCallbackOnSameLine': (t) =>
              t._reportsImmediateCallAfterCallbackOnSameLine(),
          'test_reportsImmediateCallInvocation': (t) => t._reportsImmediateCallInvocation(),
          'test_allowsPureHelperFromBuild': (t) => t._allowsPureHelperFromBuild(),
          'test_reportsControllerPropertyMutation': (t) => t._reportsControllerPropertyMutation(),
          'test_allowsMutatingHelperInsideMultilineCallback': (t) =>
              t._allowsMutatingHelperInsideMultilineCallback(),
        },
      );

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

  Future<void> _allowsArrowEventCallback() async {
    await assertAllows(r'''
class EditSheet extends Widget {
  Object? _cached;
  void _change(Object value) {
    _cached = value;
  }
  Object build(Object context) {
    return Button(onPressed: () => _change(context));
  }
}
''');
  }

  Future<void> _reportsImmediateArrowInvocation() async {
    final source = _analyzedSource(r'''
class EditSheet extends Widget {
  Object? _cached;
  void _change(Object value) {
    _cached = value;
  }
  Object build(Object context) {
    (() => _change(context))();
    return Object();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, '_change(context)', ruleName)]);
  }

  Future<void> _reportsImmediateBlockInvocation() async {
    final source = _analyzedSource(r'''
class EditSheet extends Widget {
  Object? _cached;
  void _change(Object value) {
    _cached = value;
  }
  Object build(Object context) {
    (() {
      _change(context);
    })();
    return Object();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, '_change(context)', ruleName)]);
  }

  Future<void> _reportsImmediateCallAfterCallbackOnSameLine() async {
    final source = _analyzedSource(r'''
class EditSheet extends Widget {
  Object? _cached;
  void _change(Object value) {
    _cached = value;
  }
  Object build(Object context) {
    Button(onPressed: () => _change(context)); _change(Object());
    return Object();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, '_change(Object())', ruleName)]);
  }

  Future<void> _reportsImmediateCallInvocation() async {
    final source = _analyzedSource(r'''
class EditSheet extends Widget {
  Object? _cached;
  void _change(Object value) {
    _cached = value;
  }
  Object build(Object context) {
    (() => _change(context)).call();
    return Object();
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, '_change(context)', ruleName)]);
  }

  Future<void> _allowsPureHelperFromBuild() async {
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

  Future<void> _reportsControllerPropertyMutation() async {
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

  Future<void> _allowsMutatingHelperInsideMultilineCallback() async {
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

final class _WidgetCallsNotifierTeardownAfterAwaitTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_WidgetCallsNotifierTeardownAfterAwaitTest)>
  get _allCases => caseSet<_WidgetCallsNotifierTeardownAfterAwaitTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_allowsResetWithoutAwait': (t) => t._allowsResetWithoutAwait(),
      'test_reportsGoNavigationChainedOffAwaitedMutation': (t) =>
          t._reportsGoNavigationChainedOffAwaitedMutation(),
      'test_allowsNavigationNotChainedOffNotifierMutation': (t) =>
          t._allowsNavigationNotChainedOffNotifierMutation(),
      'test_allowsResetInsideNotifier': (t) => t._allowsResetInsideNotifier(),
    },
  );

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

  Future<void> _allowsResetWithoutAwait() async {
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

  Future<void> _reportsGoNavigationChainedOffAwaitedMutation() async {
    final analyzedSource = _analyzedSource(r'''
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}
class BuildContext { bool get mounted => true; }
extension on BuildContext { void go(String location) {} }
class OrdersRoute { const OrdersRoute(); void go(BuildContext context) {} }

class SubmitButton extends ConsumerWidget {
  final ref = WidgetRef();

  Future<void> onPressed(BuildContext context) async {
    await ref.read(formProvider.notifier).save();
    if (!context.mounted) return;
    context.go('/orders');
  }

  Future<void> onSaved(BuildContext context) async {
    await ref.read(formProvider.notifier).save();
    if (!context.mounted) return;
    const OrdersRoute().go(context);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, ".go('/orders')", ruleName),
      compatLint(analyzedSource, '.go(context);', ruleName),
    ]);
  }

  Future<void> _allowsNavigationNotChainedOffNotifierMutation() async {
    await assertAllows(r'''
class WidgetRef {
  Object read(Object provider) => Object();
}
class ConsumerWidget extends Widget {}
class BuildContext { bool get mounted => true; }
extension on BuildContext {
  void go(String location) {}
  Future<void> push(String location) async {}
}
class Shell { void goBranch(int index) {} }
Future<bool?> showDialog(BuildContext context) async => true;

class SubmitButton extends ConsumerWidget {
  final ref = WidgetRef();
  final shell = Shell();

  Future<void> onSaved(BuildContext context) async {
    await ref.read(formProvider.notifier).save();
    if (!context.mounted) return;
    await context.push('/orders/new');
  }

  Future<void> onConfirmed(BuildContext context) async {
    final confirmed = await showDialog(context);
    if (confirmed != true || !context.mounted) return;
    context.go('/orders');
  }

  Future<void> onTab(BuildContext context) async {
    await showDialog(context);
    shell.goBranch(1);
  }

  Widget build(BuildContext context) => Column(children: [
    Button(onPressed: () async {
      await ref.read(formProvider.notifier).save();
    }),
    Button(onPressed: () => context.go('/orders')),
  ]);
}
''');
  }

  Future<void> _allowsResetInsideNotifier() async {
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

void _defineSourceScannerRulesPart14Tests() {
  analysisRuleSuite<_DialogWidgetSubscribesToMutableProviderTest>(
    'DialogWidgetSubscribesToMutableProviderTest',
    _DialogWidgetSubscribesToMutableProviderTest.new,
    _DialogWidgetSubscribesToMutableProviderTest._allCases,
  );
  analysisRuleSuite<_ModalHighFrequencyWatchNotLeafTest>(
    'ModalHighFrequencyWatchNotLeafTest',
    _ModalHighFrequencyWatchNotLeafTest.new,
    _ModalHighFrequencyWatchNotLeafTest._allCases,
  );
  analysisRuleSuite<_DialogButtonPopThenStateMutationTest>(
    'DialogButtonPopThenStateMutationTest',
    _DialogButtonPopThenStateMutationTest.new,
    _DialogButtonPopThenStateMutationTest._allCases,
  );
  analysisRuleSuite<_SelectReturnsUnstableRecordIdentityTest>(
    'SelectReturnsUnstableRecordIdentityTest',
    _SelectReturnsUnstableRecordIdentityTest.new,
    _SelectReturnsUnstableRecordIdentityTest._allCases,
  );
  analysisRuleSuite<_BuildMethodAssignsToFieldTest>(
    'BuildMethodAssignsToFieldTest',
    _BuildMethodAssignsToFieldTest.new,
    _BuildMethodAssignsToFieldTest._allCases,
  );
  analysisRuleSuite<_BuildCallsMutatingInstanceMethodTest>(
    'BuildCallsMutatingInstanceMethodTest',
    _BuildCallsMutatingInstanceMethodTest.new,
    _BuildCallsMutatingInstanceMethodTest._allCases,
  );
  analysisRuleSuite<_WidgetCallsNotifierTeardownAfterAwaitTest>(
    'WidgetCallsNotifierTeardownAfterAwaitTest',
    _WidgetCallsNotifierTeardownAfterAwaitTest.new,
    _WidgetCallsNotifierTeardownAfterAwaitTest._allCases,
  );
}
