import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assigning_notifiers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_calling_notifier_members_inside_build.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_async_value_pattern.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_consumer_widgets.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidAssigningNotifiersTest>(
    'AvoidAssigningNotifiersTest',
    _AvoidAssigningNotifiersTest.new,
    _AvoidAssigningNotifiersTest._allCases,
  );
  analysisRuleSuite<_AvoidCallingNotifierMembersInsideBuildTest>(
    'AvoidCallingNotifierMembersInsideBuildTest',
    _AvoidCallingNotifierMembersInsideBuildTest.new,
    _AvoidCallingNotifierMembersInsideBuildTest._allCases,
  );
  analysisRuleSuite<_AvoidNullableAsyncValuePatternTest>(
    'AvoidNullableAsyncValuePatternTest',
    _AvoidNullableAsyncValuePatternTest.new,
    _AvoidNullableAsyncValuePatternTest._allCases,
  );
  analysisRuleSuite<_AvoidUnnecessaryConsumerWidgetsTest>(
    'AvoidUnnecessaryConsumerWidgetsTest',
    _AvoidUnnecessaryConsumerWidgetsTest.new,
    _AvoidUnnecessaryConsumerWidgetsTest._allCases,
  );
}

abstract class _RiverpodSafetyRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    _addRiverpodPackage();
    _addFlutterRiverpodPackage();
    _addHooksRiverpodPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

class BuildContext {}
''');
  }

  void _addRiverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class Notifier<T> {
  T build();
}

abstract class AsyncNotifier<T> {
  Future<T> build();
}

sealed class AsyncValue<T> {
  const AsyncValue();
  T? get value;
}

final class AsyncData<T> extends AsyncValue<T> {
  const AsyncData(this.value);

  @override
  final T value;
}

final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();

  @override
  T? get value => null;
}

final class ProviderListenable<T> {
  const ProviderListenable();
}

extension ProviderListenableNotifier<T> on ProviderListenable<T> {
  ProviderListenable<T> get notifier => this;
}
''');
  }

  void _addFlutterRiverpodPackage() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
export 'package:riverpod/riverpod.dart';

import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';

final class WidgetRef {
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}

abstract class ConsumerWidget extends Widget {
  const ConsumerWidget();
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class ConsumerState<T extends ConsumerStatefulWidget> {
  WidgetRef get ref => throw UnimplementedError();
  Widget build(BuildContext context);
}

abstract class ConsumerStatefulWidget extends Widget {
  const ConsumerStatefulWidget();
}
''');
  }

  void _addHooksRiverpodPackage() {
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HookConsumerWidget extends Widget {
  const HookConsumerWidget();
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class HookConsumerState<T extends Widget> extends ConsumerState<T> {}
''');
  }
}

final class _AvoidAssigningNotifiersTest extends _RiverpodSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidAssigningNotifiersTest)> get _allCases =>
      caseSet<_AvoidAssigningNotifiersTest>(
        parent: const {},
        own: {
          'test_refReadNotifierAssignedToLocal_lint': (t) =>
              t._refReadNotifierAssignedToLocalLint(),
          'test_refWatchNotifierAssignedToField_lint': (t) =>
              t._refWatchNotifierAssignedToFieldLint(),
          'test_directNotifierCall_noLint': (t) => t._directNotifierCallNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidAssigningNotifiers();
    super.setUp();
  }

  Future<void> _refReadNotifierAssignedToLocalLint() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {
  void increment() {}
}

final counterProvider = ProviderListenable<CounterNotifier>();

void update(WidgetRef ref) {
  final notifier = ref.read(counterProvider.notifier);
  notifier.increment();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('notifier ='), 'notifier'.length)]);
  }

  Future<void> _refWatchNotifierAssignedToFieldLint() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {}

final counterProvider = ProviderListenable<CounterNotifier>();

class Host {
  Object? stored;

  void update(WidgetRef ref) {
    stored = ref.watch(counterProvider.notifier);
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('stored ='), 'stored'.length)]);
  }

  Future<void> _directNotifierCallNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {
  void increment() {}
}

final counterProvider = ProviderListenable<CounterNotifier>();

void update(WidgetRef ref) {
  ref.read(counterProvider.notifier).increment();
}
''');
  }
}

final class _AvoidCallingNotifierMembersInsideBuildTest extends _RiverpodSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidCallingNotifierMembersInsideBuildTest)>
  get _allCases => caseSet<_AvoidCallingNotifierMembersInsideBuildTest>(
    parent: const {},
    own: {
      'test_consumerWidgetBuildNotifierCall_lint': (t) => t._consumerWidgetBuildNotifierCallLint(),
      'test_consumerStateBuildNotifierCall_lint': (t) => t._consumerStateBuildNotifierCallLint(),
      'test_callbackInsideBuild_noLint': (t) => t._callbackInsideBuildNoLint(),
    },
  );

  @override
  void setUp() {
    rule = AvoidCallingNotifierMembersInsideBuild();
    super.setUp();
  }

  Future<void> _consumerWidgetBuildNotifierCallLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {
  void increment() {}
}

final counterProvider = ProviderListenable<CounterNotifier>();

class Host extends ConsumerWidget {
  const Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(counterProvider.notifier).increment();
    return const Widget();
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('increment'), 'increment'.length)]);
  }

  Future<void> _consumerStateBuildNotifierCallLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {
  void refresh() {}
}

final counterProvider = ProviderListenable<CounterNotifier>();

class HostState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    ref.watch(counterProvider.notifier).refresh();
    return const Widget();
  }
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('refresh'), 'refresh'.length)]);
  }

  Future<void> _callbackInsideBuildNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CounterNotifier {
  void increment() {}
}

final counterProvider = ProviderListenable<CounterNotifier>();

class Host extends ConsumerWidget {
  const Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onPressed() {
      ref.read(counterProvider.notifier).increment();
    }
    onPressed;
    return const Widget();
  }
}
''');
  }
}

final class _AvoidNullableAsyncValuePatternTest extends _RiverpodSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidNullableAsyncValuePatternTest)> get _allCases =>
      caseSet<_AvoidNullableAsyncValuePatternTest>(
        parent: const {},
        own: {
          'test_asyncValueNullableValuePattern_lint': (t) =>
              t._asyncValueNullableValuePatternLint(),
          'test_nullableValueCorrection_keepsDataDuringReload': (t) =>
              t._nullableValueCorrectionKeepsDataDuringReload(),
          'test_asyncDataPattern_noLint': (t) => t._asyncDataPatternNoLint(),
          'test_unrelatedValuePattern_noLint': (t) => t._unrelatedValuePatternNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNullableAsyncValuePattern();
    super.setUp();
  }

  Future<void> _asyncValueNullableValuePatternLint() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

String label(AsyncValue<String> value) {
  return switch (value) {
    AsyncValue(:final value?) => value,
    _ => '',
  };
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('final value?'), 'final value?'.length)]);
  }

  Future<void> _nullableValueCorrectionKeepsDataDuringReload() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

String label(AsyncValue<String> value) {
  return switch (value) {
    AsyncValue(:final value?) => value,
    _ => '',
  };
}
''';

    await assertDiagnostics(source, [
      lint(
        source.indexOf('final value?'),
        'final value?'.length,
        correctionContains:
            'Use AsyncValue(hasValue: true, :final requireValue) '
            '(or :final requireValue? for nullable T) to keep data during a reload, '
            'or handle AsyncLoading and AsyncError branches explicitly.',
      ),
    ]);
  }

  Future<void> _asyncDataPatternNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

String label(AsyncValue<String> value) {
  return switch (value) {
    AsyncData(:final value) => value,
    _ => '',
  };
}
''');
  }

  Future<void> _unrelatedValuePatternNoLint() async {
    await assertNoDiagnostics(r'''
class Box<T> {
  const Box(this.value);
  final T? value;
}

String label(Box<String> box) {
  return switch (box) {
    Box(:final value?) => value,
    _ => '',
  };
}
''');
  }
}

final class _AvoidUnnecessaryConsumerWidgetsTest extends _RiverpodSafetyRuleTest {
  static Map<String, Future<void> Function(_AvoidUnnecessaryConsumerWidgetsTest)> get _allCases =>
      caseSet<_AvoidUnnecessaryConsumerWidgetsTest>(
        parent: const {},
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_providerFreePageUnderScreens_noLint': (t) =>
              t._providerFreePageUnderScreensNoLint(),
          'test_unusedRefOutsideScreens_lint': (t) => t._unusedRefOutsideScreensLint(),
          'test_privateConsumerWidgetUnderScreens_lint': (t) =>
              t._privateConsumerWidgetUnderScreensLint(),
          'test_pageReadingRefUnderScreens_noLint': (t) => t._pageReadingRefUnderScreensNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidUnnecessaryConsumerWidgets();
    super.setUp();
  }

  static const _staticPage = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Widget();
}
''';

  Future<void> _severityIsError() async {
    expect(AvoidUnnecessaryConsumerWidgets.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _providerFreePageUnderScreensNoLint() async {
    final filePath = '$testPackageLibPath/features/about/presentation/screens/about_screen.dart';
    newFile(filePath, _staticPage);

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _unusedRefOutsideScreensLint() async {
    final filePath = '$testPackageLibPath/features/about/presentation/widgets/about_screen.dart';
    newFile(filePath, _staticPage);

    await assertDiagnosticsInFile(filePath, [
      lint(_staticPage.indexOf('AboutScreen extends'), 'AboutScreen'.length),
    ]);
  }

  Future<void> _privateConsumerWidgetUnderScreensLint() async {
    final filePath = '$testPackageLibPath/features/about/presentation/screens/about_screen.dart';
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _AboutHeader extends ConsumerWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Widget();
}

const header = _AboutHeader();
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      lint(source.indexOf('_AboutHeader extends'), '_AboutHeader'.length),
    ]);
  }

  Future<void> _pageReadingRefUnderScreensNoLint() async {
    final filePath = '$testPackageLibPath/features/about/presentation/screens/about_screen.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final titleProvider = ProviderListenable<Widget>();

class AboutScreen extends ConsumerWidget {
  const AboutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(titleProvider);
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }
}
