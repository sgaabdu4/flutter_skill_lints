part of '../source_scanner_rules_test.dart';

final class _NotifierStoredRefFieldTest extends _NotifierRuleTest {
  static Map<String, Future<void> Function(_NotifierStoredRefFieldTest)> get _allCases =>
      caseSet<_NotifierStoredRefFieldTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsInferredRefField': (t) => t._reportsInferredRefField(),
          'test_reportsAnnotatedNotifierBeforeCodegen': (t) =>
              t._reportsAnnotatedNotifierBeforeCodegen(),
          'test_allowsRefFieldOutsideNotifier': (t) => t._allowsRefFieldOutsideNotifier(),
          'test_allowsInheritedRefAndNonRefFields': (t) => t._allowsInheritedRefAndNonRefFields(),
          'test_allowsUnrelatedRefTypeInNotifierLikeClass': (t) =>
              t._allowsUnrelatedRefTypeInNotifierLikeClass(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', _notifierRefRiverpodStub);
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
export 'package:riverpod/riverpod.dart' show Ref;

class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();
''');
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_stored_ref_field';
  @override
  String get needle => '_savedRef';
  @override
  String get source => r'''
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<int> {
  late final Ref _savedRef = ref;

  int build() => 0;
}
''';

  Future<void> _reportsInferredRefField() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod/riverpod.dart';

class OrdersNotifier extends AsyncNotifier<int> {
  late final _r = ref;

  Future<int> build() async => 0;
}
''', addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_r = ref', ruleName)]);
  }

  Future<void> _reportsAnnotatedNotifierBeforeCodegen() async {
    final analyzedSource = _analyzedSource(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class ProductEditorNotifier extends _$ProductEditorNotifier {
  Ref? _ref;

  int build() => 0;
}
''', addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [compatLint(analyzedSource, '_ref;', ruleName)]);
  }

  Future<void> _allowsRefFieldOutsideNotifier() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class CartSession {
  CartSession(this._ref);

  final Ref _ref;
}
''');
  }

  Future<void> _allowsInheritedRefAndNonRefFields() async {
    await assertAllows(r'''
import 'package:riverpod/riverpod.dart';

class CartNotifier extends Notifier<int> {
  final _pending = <int>[];

  int build() {
    final current = ref;
    return _pending.length + (identical(current, ref) ? 0 : 1);
  }
}
''');
  }

  Future<void> _allowsUnrelatedRefTypeInNotifierLikeClass() async {
    await assertAllows(r'''
class Ref {}

class Notifier<T> {}

class CartNotifier extends Notifier<int> {
  final Ref _ref = Ref();
}
''');
  }

  Future<void> _severityIsError() async {
    expect(rule.diagnosticCodes.single.severity, DiagnosticSeverity.ERROR);
  }
}

final class _NotifierTimerWithoutOnDisposeTest extends _NotifierRuleTest {
  static Map<String, Future<void> Function(_NotifierTimerWithoutOnDisposeTest)> get _allCases =>
      caseSet<_NotifierTimerWithoutOnDisposeTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsSkillDraftNotifierAsWritten': (t) => t._reportsSkillDraftNotifierAsWritten(),
          'test_allowsTimerCancelledInOnDispose': (t) => t._allowsTimerCancelledInOnDispose(),
          'test_allowsTimerOutsideNotifier': (t) => t._allowsTimerOutsideNotifier(),
          'test_allowsLocalTimerLookalike': (t) => t._allowsLocalTimerLookalike(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'notifier_timer_without_on_dispose';
  @override
  String get needle => '_debounce;';
  @override
  String get source => '''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class ProductSearch extends Notifier<List<String>> {
  Timer? _debounce;

  @override
  List<String> build() => const <String>[];

  void onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {});
  }
}
''';

  Future<void> _reportsSkillDraftNotifierAsWritten() async {
    const source = '''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class DraftNotifier extends AsyncNotifier<String> {
  Timer? _persistTimer;

  @override
  Future<String> build() async => '';

  void schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 50), () {});
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: true);
    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, '_persistTimer;', ruleName),
    ]);
  }

  Future<void> _allowsTimerCancelledInOnDispose() async {
    await assertAllows('''
import 'dart:async';
import 'package:riverpod/riverpod.dart';

class ProductSearchOk extends Notifier<List<String>> {
  Timer? _debounce;

  @override
  List<String> build() {
    ref.onDispose(() => _debounce?.cancel());
    return const <String>[];
  }
}
''');
  }

  Future<void> _allowsTimerOutsideNotifier() async {
    await assertAllows('''
import 'dart:async';

class Ticker {
  Timer? _timer;
  void stop() => _timer?.cancel();
}
''');
  }

  Future<void> _allowsLocalTimerLookalike() async {
    await assertAllows('''
import 'package:riverpod/riverpod.dart';

class Timer {}

class Stopwatch extends Notifier<int> {
  Timer? _timer;

  @override
  int build() => 0;
}
''');
  }
}

void _defineSourceScannerRulesPart10BTests() {
  analysisRuleSuite<_NotifierStoredRefFieldTest>(
    'NotifierStoredRefFieldTest',
    _NotifierStoredRefFieldTest.new,
    _NotifierStoredRefFieldTest._allCases,
  );
  analysisRuleSuite<_NotifierTimerWithoutOnDisposeTest>(
    'NotifierTimerWithoutOnDisposeTest',
    _NotifierTimerWithoutOnDisposeTest.new,
    _NotifierTimerWithoutOnDisposeTest._allCases,
  );
}
