// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_assigning_notifiers.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_calling_notifier_members_inside_build.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_nullable_async_value_pattern.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAssigningNotifiersTest);
    defineReflectiveTests(AvoidCallingNotifierMembersInsideBuildTest);
    defineReflectiveTests(AvoidNullableAsyncValuePatternTest);
  });
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

@reflectiveTest
final class AvoidAssigningNotifiersTest extends _RiverpodSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidAssigningNotifiers();
    super.setUp();
  }

  Future<void> test_refReadNotifierAssignedToLocal_lint() async {
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

  Future<void> test_refWatchNotifierAssignedToField_lint() async {
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

  Future<void> test_directNotifierCall_noLint() async {
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

@reflectiveTest
final class AvoidCallingNotifierMembersInsideBuildTest extends _RiverpodSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidCallingNotifierMembersInsideBuild();
    super.setUp();
  }

  Future<void> test_consumerWidgetBuildNotifierCall_lint() async {
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

  Future<void> test_consumerStateBuildNotifierCall_lint() async {
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

  Future<void> test_callbackInsideBuild_noLint() async {
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

@reflectiveTest
final class AvoidNullableAsyncValuePatternTest extends _RiverpodSafetyRuleTest {
  @override
  void setUp() {
    rule = AvoidNullableAsyncValuePattern();
    super.setUp();
  }

  Future<void> test_asyncValueNullableValuePattern_lint() async {
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

  Future<void> test_asyncDataPattern_noLint() async {
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

  Future<void> test_unrelatedValuePattern_noLint() async {
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
