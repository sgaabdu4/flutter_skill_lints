part of '../source_scanner_rules_test.dart';

final class _DialogWidgetReadOnlyAllowedTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_DialogWidgetReadOnlyAllowedTest)> get _allCases =>
      caseSet<_DialogWidgetReadOnlyAllowedTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _DialogPopThenStateMutationOfContextVariantTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_DialogPopThenStateMutationOfContextVariantTest)>
  get _allCases => caseSet<_DialogPopThenStateMutationOfContextVariantTest>(
    parent: _SourceRuleTest._allCases,
    own: {'test_allowsPopNoFollowUpInBody': (t) => t._allowsPopNoFollowUpInBody()},
  );

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

final class _SelectUnstableRecordNamedFieldsTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_SelectUnstableRecordNamedFieldsTest)> get _allCases =>
      caseSet<_SelectUnstableRecordNamedFieldsTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_allowsSelectReturnsScalarField': (t) => t._allowsSelectReturnsScalarField()},
      );

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

final class _SelectAllowsStableRecordMapMethodTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_SelectAllowsStableRecordMapMethodTest)> get _allCases =>
      caseSet<_SelectAllowsStableRecordMapMethodTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _BuildAssignsThisFieldTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_BuildAssignsThisFieldTest)> get _allCases =>
      caseSet<_BuildAssignsThisFieldTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _BuildAllowsAssignmentInsideClosureTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_BuildAllowsAssignmentInsideClosureTest)>
  get _allCases => caseSet<_BuildAllowsAssignmentInsideClosureTest>(
    parent: _SourceRuleTest._allCases,
    own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );

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

final class _WidgetTeardownAwaitWithGapTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_WidgetTeardownAwaitWithGapTest)> get _allCases =>
      caseSet<_WidgetTeardownAwaitWithGapTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _WidgetTeardownAllowsNonNotifierClearTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_WidgetTeardownAllowsNonNotifierClearTest)>
  get _allCases => caseSet<_WidgetTeardownAllowsNonNotifierClearTest>(
    parent: _SourceRuleTest._allCases,
    own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
  );

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

final class _PopScopeBypassPopWithFallbackVariantTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_PopScopeBypassPopWithFallbackVariantTest)>
  get _allCases => caseSet<_PopScopeBypassPopWithFallbackVariantTest>(
    parent: _SourceRuleTest._allCases,
    own: {},
  );

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

final class _ModalHelperShowGeneralDialogTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_ModalHelperShowGeneralDialogTest)> get _allCases =>
      caseSet<_ModalHelperShowGeneralDialogTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsBareShowDialogNotInHelperPosition': (t) =>
              t._allowsBareShowDialogNotInHelperPosition(),
        },
      );

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

final class _SyncSaveAllAllowsLengthGuardTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_SyncSaveAllAllowsLengthGuardTest)> get _allCases =>
      caseSet<_SyncSaveAllAllowsLengthGuardTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _SyncSaveAllAllowsOuterDirtyGuardTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_SyncSaveAllAllowsOuterDirtyGuardTest)> get _allCases =>
      caseSet<_SyncSaveAllAllowsOuterDirtyGuardTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _NotifierPersistenceDelayedAllowedTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_NotifierPersistenceDelayedAllowedTest)> get _allCases =>
      caseSet<_NotifierPersistenceDelayedAllowedTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _WebViewVideoPlayerNoGateTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_WebViewVideoPlayerNoGateTest)> get _allCases =>
      caseSet<_WebViewVideoPlayerNoGateTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _WebViewAllowsUserOpenedGateTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_WebViewAllowsUserOpenedGateTest)> get _allCases =>
      caseSet<_WebViewAllowsUserOpenedGateTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _KeepAliveWatchesPostsCollectionTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_KeepAliveWatchesPostsCollectionTest)> get _allCases =>
      caseSet<_KeepAliveWatchesPostsCollectionTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _DatasourceRemoteSixGettersTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_DatasourceRemoteSixGettersTest)> get _allCases =>
      caseSet<_DatasourceRemoteSixGettersTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _DatasourceAllowsListReturnGettersTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_DatasourceAllowsListReturnGettersTest)> get _allCases =>
      caseSet<_DatasourceAllowsListReturnGettersTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _NotifierZeroValueAmountNoGuardTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_NotifierZeroValueAmountNoGuardTest)> get _allCases =>
      caseSet<_NotifierZeroValueAmountNoGuardTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _NotifierParamRequiresVoBytesTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_NotifierParamRequiresVoBytesTest)> get _allCases =>
      caseSet<_NotifierParamRequiresVoBytesTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _NotifierParamAllowsNonUnitStringTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_NotifierParamAllowsNonUnitStringTest)> get _allCases =>
      caseSet<_NotifierParamAllowsNonUnitStringTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _TextFieldCupertinoNoDebounceTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_TextFieldCupertinoNoDebounceTest)> get _allCases =>
      caseSet<_TextFieldCupertinoNoDebounceTest>(parent: _SourceRuleTest._allCases, own: {});

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

final class _TextFieldAllowsDebouncerReferenceTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_TextFieldAllowsDebouncerReferenceTest)> get _allCases =>
      caseSet<_TextFieldAllowsDebouncerReferenceTest>(
        parent: _SourceRuleTest._allCases,
        own: {'test_reportsDiagnostic': (t) => t._reportsDiagnostic()},
      );

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

final class _SliderRangeSliderNoDebounceTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_SliderRangeSliderNoDebounceTest)> get _allCases =>
      caseSet<_SliderRangeSliderNoDebounceTest>(parent: _SourceRuleTest._allCases, own: {});

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
  analysisRuleSuite<_DialogWidgetReadOnlyAllowedTest>(
    'DialogWidgetReadOnlyAllowedTest',
    _DialogWidgetReadOnlyAllowedTest.new,
    _DialogWidgetReadOnlyAllowedTest._allCases,
  );
  analysisRuleSuite<_DialogPopThenStateMutationOfContextVariantTest>(
    'DialogPopThenStateMutationOfContextVariantTest',
    _DialogPopThenStateMutationOfContextVariantTest.new,
    _DialogPopThenStateMutationOfContextVariantTest._allCases,
  );
  analysisRuleSuite<_SelectUnstableRecordNamedFieldsTest>(
    'SelectUnstableRecordNamedFieldsTest',
    _SelectUnstableRecordNamedFieldsTest.new,
    _SelectUnstableRecordNamedFieldsTest._allCases,
  );
  analysisRuleSuite<_SelectAllowsStableRecordMapMethodTest>(
    'SelectAllowsStableRecordMapMethodTest',
    _SelectAllowsStableRecordMapMethodTest.new,
    _SelectAllowsStableRecordMapMethodTest._allCases,
  );
  analysisRuleSuite<_BuildAssignsThisFieldTest>(
    'BuildAssignsThisFieldTest',
    _BuildAssignsThisFieldTest.new,
    _BuildAssignsThisFieldTest._allCases,
  );
  analysisRuleSuite<_BuildAllowsAssignmentInsideClosureTest>(
    'BuildAllowsAssignmentInsideClosureTest',
    _BuildAllowsAssignmentInsideClosureTest.new,
    _BuildAllowsAssignmentInsideClosureTest._allCases,
  );
  analysisRuleSuite<_WidgetTeardownAwaitWithGapTest>(
    'WidgetTeardownAwaitWithGapTest',
    _WidgetTeardownAwaitWithGapTest.new,
    _WidgetTeardownAwaitWithGapTest._allCases,
  );
  analysisRuleSuite<_WidgetTeardownAllowsNonNotifierClearTest>(
    'WidgetTeardownAllowsNonNotifierClearTest',
    _WidgetTeardownAllowsNonNotifierClearTest.new,
    _WidgetTeardownAllowsNonNotifierClearTest._allCases,
  );
  analysisRuleSuite<_PopScopeBypassPopWithFallbackVariantTest>(
    'PopScopeBypassPopWithFallbackVariantTest',
    _PopScopeBypassPopWithFallbackVariantTest.new,
    _PopScopeBypassPopWithFallbackVariantTest._allCases,
  );
  analysisRuleSuite<_ModalHelperShowGeneralDialogTest>(
    'ModalHelperShowGeneralDialogTest',
    _ModalHelperShowGeneralDialogTest.new,
    _ModalHelperShowGeneralDialogTest._allCases,
  );
  analysisRuleSuite<_SyncSaveAllAllowsLengthGuardTest>(
    'SyncSaveAllAllowsLengthGuardTest',
    _SyncSaveAllAllowsLengthGuardTest.new,
    _SyncSaveAllAllowsLengthGuardTest._allCases,
  );
  analysisRuleSuite<_SyncSaveAllAllowsOuterDirtyGuardTest>(
    'SyncSaveAllAllowsOuterDirtyGuardTest',
    _SyncSaveAllAllowsOuterDirtyGuardTest.new,
    _SyncSaveAllAllowsOuterDirtyGuardTest._allCases,
  );
  analysisRuleSuite<_NotifierPersistenceDelayedAllowedTest>(
    'NotifierPersistenceDelayedAllowedTest',
    _NotifierPersistenceDelayedAllowedTest.new,
    _NotifierPersistenceDelayedAllowedTest._allCases,
  );
  analysisRuleSuite<_WebViewVideoPlayerNoGateTest>(
    'WebViewVideoPlayerNoGateTest',
    _WebViewVideoPlayerNoGateTest.new,
    _WebViewVideoPlayerNoGateTest._allCases,
  );
  analysisRuleSuite<_WebViewAllowsUserOpenedGateTest>(
    'WebViewAllowsUserOpenedGateTest',
    _WebViewAllowsUserOpenedGateTest.new,
    _WebViewAllowsUserOpenedGateTest._allCases,
  );
  analysisRuleSuite<_KeepAliveWatchesPostsCollectionTest>(
    'KeepAliveWatchesPostsCollectionTest',
    _KeepAliveWatchesPostsCollectionTest.new,
    _KeepAliveWatchesPostsCollectionTest._allCases,
  );
  analysisRuleSuite<_DatasourceRemoteSixGettersTest>(
    'DatasourceRemoteSixGettersTest',
    _DatasourceRemoteSixGettersTest.new,
    _DatasourceRemoteSixGettersTest._allCases,
  );
  analysisRuleSuite<_DatasourceAllowsListReturnGettersTest>(
    'DatasourceAllowsListReturnGettersTest',
    _DatasourceAllowsListReturnGettersTest.new,
    _DatasourceAllowsListReturnGettersTest._allCases,
  );
  analysisRuleSuite<_NotifierZeroValueAmountNoGuardTest>(
    'NotifierZeroValueAmountNoGuardTest',
    _NotifierZeroValueAmountNoGuardTest.new,
    _NotifierZeroValueAmountNoGuardTest._allCases,
  );
  analysisRuleSuite<_NotifierParamRequiresVoBytesTest>(
    'NotifierParamRequiresVoBytesTest',
    _NotifierParamRequiresVoBytesTest.new,
    _NotifierParamRequiresVoBytesTest._allCases,
  );
  analysisRuleSuite<_NotifierParamAllowsNonUnitStringTest>(
    'NotifierParamAllowsNonUnitStringTest',
    _NotifierParamAllowsNonUnitStringTest.new,
    _NotifierParamAllowsNonUnitStringTest._allCases,
  );
  analysisRuleSuite<_TextFieldCupertinoNoDebounceTest>(
    'TextFieldCupertinoNoDebounceTest',
    _TextFieldCupertinoNoDebounceTest.new,
    _TextFieldCupertinoNoDebounceTest._allCases,
  );
  analysisRuleSuite<_TextFieldAllowsDebouncerReferenceTest>(
    'TextFieldAllowsDebouncerReferenceTest',
    _TextFieldAllowsDebouncerReferenceTest.new,
    _TextFieldAllowsDebouncerReferenceTest._allCases,
  );
  analysisRuleSuite<_SliderRangeSliderNoDebounceTest>(
    'SliderRangeSliderNoDebounceTest',
    _SliderRangeSliderNoDebounceTest.new,
    _SliderRangeSliderNoDebounceTest._allCases,
  );
}
