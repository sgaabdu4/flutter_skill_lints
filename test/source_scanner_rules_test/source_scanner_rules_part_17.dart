part of '../source_scanner_rules_test.dart';

final class DialogWidgetReadOnlyAllowedTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_widget_subscribes_to_mutable_provider';
  @override
  String get needle => 'class ReadOnlyDialog';
  @override
  String get source => r'''
final entryProvider = Object();
class WidgetRef { Object read(Object p) => Object(); }
class ConsumerWidget extends Widget {}
class Widget {}

class ReadOnlyDialog extends ConsumerWidget {
  Object build(Object context, WidgetRef ref) {
    return ElevatedButton(onPressed: () { ref.read((entryProvider as dynamic).notifier).save(); });
  }
}
''';

  // No ref.watch → no diagnostic, regardless of mutation.
  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class DialogPopThenStateMutationOfContextVariantTest extends _DialogRuleTest {
  @override
  String get ruleName => 'dialog_button_pop_then_state_mutation';
  @override
  String get needle => 'ref.read(provider.notifier).save()';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}
class Navigator { static Object of(Object c) => Object(); }

class EditDialog extends ConsumerWidget {
  final ref = Object();
  void onTap(Object context) {
    Navigator.of(context).pop();
    ref.read(provider.notifier).save();
  }
}
''';

  Future<void> _allowsPopNoFollowUpInBody() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}
class Widget {}
class Navigator { static Object of(Object c) => Object(); }

class EditDialog extends ConsumerWidget {
  void onTap(Object context) {
    Navigator.of(context).pop(true);
  }
}
''');
  }
}

final class SelectUnstableRecordNamedFieldsTest extends _DialogRuleTest {
  @override
  String get ruleName => 'select_returns_unstable_record_identity';
  @override
  String get needle => '.select((s)';
  @override
  String get source => r'''
class WidgetRef { Object watch(Object p) => Object(); }
class State { Map<String, int> get tagsMap => {}; }

class DetailScreen {
  final ref = WidgetRef();
  Object build(Object context) {
    return ref.watch(provider.select((s) => (m: s.tagsMap)));
  }
}
''';

  Future<void> _allowsSelectReturnsScalarField() async {
    await assertAllows(r'''
class WidgetRef { Object watch(Object p) => Object(); }
class DetailScreen {
  final ref = WidgetRef();
  Object build(Object context) {
    return ref.watch(provider.select((s) => s.count));
  }
}
''');
  }
}

final class SelectAllowsStableRecordMapMethodTest extends _DialogRuleTest {
  @override
  String get ruleName => 'select_returns_unstable_record_identity';
  @override
  String get needle => 'class Allowed';
  @override
  String get source => r'''
class WidgetRef { Object watch(Object p) => Object(); }
class Allowed {
  Object build(Object context, WidgetRef ref) {
    return ref.watch(provider.select((s) => (s.id, s.title)));
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class BuildAssignsThisFieldTest extends _DialogRuleTest {
  @override
  String get ruleName => 'build_method_assigns_to_field';
  @override
  String get needle => 'this._cache =';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}

class Reader extends ConsumerWidget {
  Object _cache = Object();
  Object build(Object context) {
    this._cache = Object();
    return Object();
  }
}
''';
}

final class BuildAllowsAssignmentInsideClosureTest extends _DialogRuleTest {
  @override
  String get ruleName => 'build_method_assigns_to_field';
  @override
  String get needle => 'class CallbackOwner';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}

class CallbackOwner extends ConsumerWidget {
  int _count = 0;
  Object build(Object context) {
    return ElevatedButton(
      onPressed: () {
        _count = 1;
      },
    );
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class WidgetTeardownAwaitWithGapTest extends _DialogRuleTest {
  @override
  String get ruleName => 'widget_calls_notifier_teardown_after_await';
  @override
  String get needle => 'ref.read(provider.notifier).reset()';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}
class WidgetRef { Object read(Object p) => Object(); }

class ConfirmDialog extends ConsumerWidget {
  Future<void> handle(WidgetRef ref) async {
    await ref.read(provider.notifier).save();
    final maybe = 1;
    ref.read(provider.notifier).reset();
  }
}
''';
}

final class WidgetTeardownAllowsNonNotifierClearTest extends _DialogRuleTest {
  @override
  String get ruleName => 'widget_calls_notifier_teardown_after_await';
  @override
  String get needle => 'class TextOwner';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}
class WidgetRef { Object read(Object p) => Object(); }
class TextEditingController { void clear() {} }

class TextOwner extends ConsumerWidget {
  final TextEditingController _ctrl = TextEditingController();
  Future<void> handle(WidgetRef ref) async {
    await ref.read(provider.notifier).save();
    _ctrl.clear();
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class PopScopeBypassPopWithFallbackVariantTest extends _DialogRuleTest {
  @override
  String get ruleName => 'popscope_bypass_uses_go_not_pop';
  @override
  String get needle => 'context.popWithFallback(';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}
extension on Object { Object popWithFallback(Object route) => Object(); }

class FormNotifier extends ConsumerWidget {
  Future<void> finish(Object context) async {
    await showDialog(context, builder: (_) => Object());
    context.popWithFallback(HomeRoute());
  }
}
class HomeRoute {}
Object showDialog(Object c, {required Object builder}) => Object();
''';
}

final class ModalHelperShowGeneralDialogTest extends _DialogRuleTest {
  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'modal_helper_requires_route_settings';
  @override
  String get needle => 'showDialog<T>(';
  @override
  String get source => r'''
import 'package:flutter/material.dart';

Future<T?> openHelp<T>(BuildContext context) => showDialog<T>(
  context: context,
  barrierDismissible: true,
  builder: (_) => Widget(),
);
''';

  Future<void> _allowsBareShowDialogNotInHelperPosition() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:flutter/material.dart';

Future<T?> openHelp<T>(BuildContext context) => showDialog<T>(
  context: context,
  routeSettings: const RouteSettings(name: 'confirm'),
  builder: (_) => Widget(),
);
''', addIgnorePrefix: addIgnorePrefix);
    await assertNoDiagnostics(analyzedSource);
  }
}

final class SyncSaveAllAllowsLengthGuardTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'sync_save_all_no_dirty_guard';
  @override
  String get needle => 'class GuardedByLength';
  @override
  String get source => r'''
class GuardedByLength {
  void pushItems(String userId, List<Object> items) {
    if (items.length == 0) return;
    remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class SyncSaveAllAllowsOuterDirtyGuardTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'sync_save_all_no_dirty_guard';
  @override
  String get needle => 'class OuterDirty';
  @override
  String get source => r'''
class OuterDirty {
  bool isDirty = false;
  void pushItems(String userId, List<Object> items) {
    if (isDirty) {
      remote.saveAll(userId, items.map(ItemModel.fromEntity).toList());
    }
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class NotifierPersistenceDelayedAllowedTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_persistence_no_debounce';
  @override
  String get needle => 'class DraftStateNotifier';
  @override
  String get source => r'''
class Notifier {}
class DraftStateNotifier extends Notifier {
  void _persistDraft() {
    Future.delayed(const Duration(milliseconds: 250), () => save());
  }
  void save() {}
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class WebViewVideoPlayerNoGateTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'webview_init_in_build_no_gate';
  @override
  String get needle => 'VideoPlayer(';
  @override
  String get source => r'''
class ConsumerWidget extends Widget {}
class Widget {}

class VideoCard extends ConsumerWidget {
  Object build(Object context) {
    return VideoPlayer(Object());
  }
}
''';
}

final class WebViewAllowsUserOpenedGateTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'webview_init_in_build_no_gate';
  @override
  String get needle => 'class GatedVideoCard';
  @override
  String get source => r'''
class VideoPlayer { VideoPlayer(Object controller); }
class ConsumerWidget extends Widget {}
class Widget {}

class GatedVideoCard extends ConsumerWidget {
  bool _userOpened = false;
  Object build(Object context) {
    if (_userOpened) return VideoPlayer(Object());
    return Object();
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class KeepAliveWatchesPostsCollectionTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'keepalive_watches_unbounded_collection';
  @override
  String get needle => 'ref.watch(provider.select((s) => s.posts))';
  @override
  String get source => r'''
class Riverpod { const Riverpod({bool? keepAlive}); }
class Ref {}

@Riverpod(keepAlive: true)
Object feedFeed(Ref ref) {
  return [...ref.watch(provider.select((s) => s.posts))];
}
''';
}

final class DatasourceRemoteSixGettersTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'datasource_missing_batch_loader';
  @override
  String get needle => 'class SettingsRemoteDatasource';
  @override
  String get source => r'''
abstract class SettingsRemoteDatasource {
  Future<bool> getOptIn();
  Future<bool> isPremium();
  Future<bool> hasOnboarded();
  Future<String> getNickname();
  Future<int> getThemeIndex();
  Future<int> getFontIndex();
}
''';
}

final class DatasourceAllowsListReturnGettersTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'datasource_missing_batch_loader';
  @override
  String get needle => 'class TagsLocalDatasource';
  @override
  String get source => r'''
abstract class TagsLocalDatasource {
  Future<List<String>> getTags();
  Future<List<String>> getRecent();
  Future<List<String>> getStarred();
  Future<List<String>> getArchived();
  Future<List<String>> getDrafts();
  Future<List<String>> getPinned();
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class NotifierZeroValueAmountNoGuardTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_zero_value_save_no_guard';
  @override
  String get needle => '.saveEntry(';
  @override
  String get source => r'''
class WidgetRef { Object read(Object p) => Object(); }
class EntryForm {
  void submit(WidgetRef ref, int amount, int count) {
    ref.read(provider.notifier).saveEntry(amount: amount, count: count);
  }
}
''';
}

final class NotifierParamRequiresVoBytesTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_param_requires_value_object';
  @override
  String get needle => '.saveTransfer(';
  @override
  String get source => r'''
class WidgetRef { Object read(Object p) => Object(); }
class UploadForm {
  void submit(WidgetRef ref) {
    int sizeBytes = 1024;
    ref.read(provider.notifier).saveTransfer(size: sizeBytes);
  }
}
''';
}

final class NotifierParamAllowsNonUnitStringTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'notifier_param_requires_value_object';
  @override
  String get needle => 'class NameForm';
  @override
  String get source => r'''
class WidgetRef { Object read(Object p) => Object(); }
class NameForm {
  void submit(WidgetRef ref) {
    String label = 'hello';
    ref.read(provider.notifier).saveLabel(label);
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class TextFieldCupertinoNoDebounceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'text_field_on_changed_no_debounce';
  @override
  String get needle => 'CupertinoTextField(';
  @override
  String get source => r'''
class SearchPanel {
  Object build(Object ref) {
    return CupertinoTextField(
      onChanged: (v) {
        ref.read(provider.notifier).search(v);
      },
    );
  }
}
''';
}

final class TextFieldAllowsDebouncerReferenceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'text_field_on_changed_no_debounce';
  @override
  String get needle => 'class DebouncedSearch';
  @override
  String get source => r'''
class TextField { TextField({Object? onChanged}); }
class Debouncer { void call(Object cb) {} }

class DebouncedSearch {
  final Debouncer _debouncer = Debouncer();
  Object build(Object ref) {
    return TextField(
      onChanged: (v) {
        ref.read(provider.notifier).search(v);
      },
    );
  }
}
''';

  @override
  Future<void> _reportsDiagnostic() async {
    await assertAllows(source);
  }
}

final class SliderRangeSliderNoDebounceTest extends _RuntimeBugRuleTest {
  @override
  String get ruleName => 'slider_on_changed_no_debounce';
  @override
  String get needle => 'RangeSlider(';
  @override
  String get source => r'''
class FilterPanel {
  Object build(Object ref) {
    return RangeSlider(
      onChanged: (v) {
        ref.read(provider.notifier).setRange(v);
      },
    );
  }
}
''';
}

void _defineSourceScannerRulesPart17Tests() {
  analysisRuleSuite<DialogWidgetReadOnlyAllowedTest>(
    'DialogWidgetReadOnlyAllowedTest',
    DialogWidgetReadOnlyAllowedTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DialogPopThenStateMutationOfContextVariantTest>(
    'DialogPopThenStateMutationOfContextVariantTest',
    DialogPopThenStateMutationOfContextVariantTest.new,
    {
      'test_allowsPopNoFollowUpInBody': (t) => t._allowsPopNoFollowUpInBody(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<SelectUnstableRecordNamedFieldsTest>(
    'SelectUnstableRecordNamedFieldsTest',
    SelectUnstableRecordNamedFieldsTest.new,
    {
      'test_allowsSelectReturnsScalarField': (t) => t._allowsSelectReturnsScalarField(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<SelectAllowsStableRecordMapMethodTest>(
    'SelectAllowsStableRecordMapMethodTest',
    SelectAllowsStableRecordMapMethodTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<BuildAssignsThisFieldTest>(
    'BuildAssignsThisFieldTest',
    BuildAssignsThisFieldTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<BuildAllowsAssignmentInsideClosureTest>(
    'BuildAllowsAssignmentInsideClosureTest',
    BuildAllowsAssignmentInsideClosureTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<WidgetTeardownAwaitWithGapTest>(
    'WidgetTeardownAwaitWithGapTest',
    WidgetTeardownAwaitWithGapTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<WidgetTeardownAllowsNonNotifierClearTest>(
    'WidgetTeardownAllowsNonNotifierClearTest',
    WidgetTeardownAllowsNonNotifierClearTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<PopScopeBypassPopWithFallbackVariantTest>(
    'PopScopeBypassPopWithFallbackVariantTest',
    PopScopeBypassPopWithFallbackVariantTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<ModalHelperShowGeneralDialogTest>(
    'ModalHelperShowGeneralDialogTest',
    ModalHelperShowGeneralDialogTest.new,
    {
      'test_allowsBareShowDialogNotInHelperPosition': (t) =>
          t._allowsBareShowDialogNotInHelperPosition(),
      'test_reportsDiagnostic': (t) => t._reportsDiagnostic(),
    },
  );
  analysisRuleSuite<SyncSaveAllAllowsLengthGuardTest>(
    'SyncSaveAllAllowsLengthGuardTest',
    SyncSaveAllAllowsLengthGuardTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<SyncSaveAllAllowsOuterDirtyGuardTest>(
    'SyncSaveAllAllowsOuterDirtyGuardTest',
    SyncSaveAllAllowsOuterDirtyGuardTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<NotifierPersistenceDelayedAllowedTest>(
    'NotifierPersistenceDelayedAllowedTest',
    NotifierPersistenceDelayedAllowedTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<WebViewVideoPlayerNoGateTest>(
    'WebViewVideoPlayerNoGateTest',
    WebViewVideoPlayerNoGateTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<WebViewAllowsUserOpenedGateTest>(
    'WebViewAllowsUserOpenedGateTest',
    WebViewAllowsUserOpenedGateTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<KeepAliveWatchesPostsCollectionTest>(
    'KeepAliveWatchesPostsCollectionTest',
    KeepAliveWatchesPostsCollectionTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DatasourceRemoteSixGettersTest>(
    'DatasourceRemoteSixGettersTest',
    DatasourceRemoteSixGettersTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<DatasourceAllowsListReturnGettersTest>(
    'DatasourceAllowsListReturnGettersTest',
    DatasourceAllowsListReturnGettersTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<NotifierZeroValueAmountNoGuardTest>(
    'NotifierZeroValueAmountNoGuardTest',
    NotifierZeroValueAmountNoGuardTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<NotifierParamRequiresVoBytesTest>(
    'NotifierParamRequiresVoBytesTest',
    NotifierParamRequiresVoBytesTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<NotifierParamAllowsNonUnitStringTest>(
    'NotifierParamAllowsNonUnitStringTest',
    NotifierParamAllowsNonUnitStringTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<TextFieldCupertinoNoDebounceTest>(
    'TextFieldCupertinoNoDebounceTest',
    TextFieldCupertinoNoDebounceTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<TextFieldAllowsDebouncerReferenceTest>(
    'TextFieldAllowsDebouncerReferenceTest',
    TextFieldAllowsDebouncerReferenceTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
  analysisRuleSuite<SliderRangeSliderNoDebounceTest>(
    'SliderRangeSliderNoDebounceTest',
    SliderRangeSliderNoDebounceTest.new,
    {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );
}
