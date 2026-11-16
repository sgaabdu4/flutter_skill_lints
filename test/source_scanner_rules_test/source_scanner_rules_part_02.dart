part of '../source_scanner_rules_test.dart';

final class _RiverpodEventCounterSignalForbiddenTest extends _RiverpodRuleTest {
  static Map<String, Future<void> Function(_RiverpodEventCounterSignalForbiddenTest)>
  get _allCases => caseSet<_RiverpodEventCounterSignalForbiddenTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsStatePlusOneVariant': (t) => t._reportsStatePlusOneVariant(),
      'test_reportsPayloadSignalProvider': (t) => t._reportsPayloadSignalProvider(),
      'test_reportsFunctionEventProvider': (t) => t._reportsFunctionEventProvider(),
      'test_reportsNotifierSuffixedEventClassAndNestedGenericFunction': (t) =>
          t._reportsNotifierSuffixedEventClassAndNestedGenericFunction(),
      'test_allowsEventNamesWithoutRiverpodAnnotation': (t) =>
          t._allowsEventNamesWithoutRiverpodAnnotation(),
      'test_allowsPayloadStreamName': (t) => t._allowsPayloadStreamName(),
      'test_allowsOwningNotifierStateSerial': (t) => t._allowsOwningNotifierStateSerial(),
      'test_allowsDomainCounterNotifier': (t) => t._allowsDomainCounterNotifier(),
      'test_allowsDurableStatusNotifier': (t) => t._allowsDurableStatusNotifier(),
    },
  );

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

  Future<void> _reportsStatePlusOneVariant() async {
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

  Future<void> _reportsPayloadSignalProvider() async {
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

  Future<void> _reportsFunctionEventProvider() async {
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
  Future<void> _reportsNotifierSuffixedEventClassAndNestedGenericFunction() async {
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

  Future<void> _allowsEventNamesWithoutRiverpodAnnotation() async {
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

  Future<void> _allowsPayloadStreamName() async {
    await assertAllows(r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

@Riverpod(keepAlive: true)
Stream<String> notificationTapPayloads(Ref ref) => Stream<String>.fromIterable(const <String>[]);
''');
  }

  Future<void> _allowsOwningNotifierStateSerial() async {
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

  Future<void> _allowsDomainCounterNotifier() async {
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

  Future<void> _allowsDurableStatusNotifier() async {
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

void _defineSourceScannerRulesPart02Tests() {
  analysisRuleSuite<_RiverpodEventCounterSignalForbiddenTest>(
    'RiverpodEventCounterSignalForbiddenTest',
    _RiverpodEventCounterSignalForbiddenTest.new,
    _RiverpodEventCounterSignalForbiddenTest._allCases,
  );
}
