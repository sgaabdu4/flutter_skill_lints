// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_hooks_outside_build.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_hooks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_watch_outside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRefWatchOutsideBuildTest);
    defineReflectiveTests(AvoidHooksOutsideBuildTest);
    defineReflectiveTests(AvoidMisusedHooksTest);
  });
}

abstract class _RiverpodHooksRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    _addFlutterRiverpodPackage();
    _addFlutterHooksPackage();
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

  void _addFlutterRiverpodPackage() {
    newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

class ProviderListenable<T> {}

class WidgetRef {
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
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

  void _addFlutterHooksPackage() {
    newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
import 'package:flutter/widgets.dart';

class ValueNotifier<T> {
  ValueNotifier(this.value);
  T value;
}

T useMemoized<T>(T Function() valueBuilder, [List<Object?> keys = const <Object>[]]) {
  return valueBuilder();
}

ValueNotifier<T> useState<T>(T initialData) => ValueNotifier<T>(initialData);

class HookWidget extends Widget {
  const HookWidget();
  Widget build(BuildContext context);
}

typedef HookWidgetBuilder = Widget Function(BuildContext context);

class HookBuilder extends Widget {
  const HookBuilder({required HookWidgetBuilder builder});
}
''');
  }

  void _addHooksRiverpodPackage() {
    newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HookConsumerWidget extends Widget {
  const HookConsumerWidget();
  Widget build(BuildContext context, WidgetRef ref);
}

abstract class HookConsumerState<T extends Widget> extends ConsumerState<T> {}

typedef HookConsumerBuilder = Widget Function(BuildContext context, WidgetRef ref);

class HookConsumer extends Widget {
  const HookConsumer({required HookConsumerBuilder builder});
}
''');
  }
}

@reflectiveTest
final class AvoidRefWatchOutsideBuildTest extends _RiverpodHooksRuleTest {
  @override
  void setUp() {
    rule = AvoidRefWatchOutsideBuild();
    super.setUp();
  }

  Future<void> test_consumerWidgetBuild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final provider = ProviderListenable<int>();

class Host extends ConsumerWidget {
  const Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(provider);
    return const Widget();
  }
}
''');
  }

  Future<void> test_callbackInsideBuild_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final provider = ProviderListenable<int>();

class Host extends ConsumerWidget {
  const Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void onPressed() {
      ref.watch(provider);
    }
    onPressed();
    return const Widget();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ref.watch'), 'ref.watch(provider)'.length),
    ]);
  }

  Future<void> test_consumerStateHelper_lint() async {
    const source = r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

final provider = ProviderListenable<int>();

class HostState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) => const Widget();

  int value() => ref.watch(provider);
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ref.watch'), 'ref.watch(provider)'.length),
    ]);
  }

  Future<void> test_riverpodFunctionProvider_noLint() async {
    await assertNoDiagnostics(r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class Ref {
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}

class ProviderListenable<T> {}

class UnimplementedError {}

final provider = ProviderListenable<int>();

@riverpod
int count(Ref ref) {
  return ref.watch(provider);
}
''');
  }

  Future<void> test_callbackInsideRiverpodFunctionProvider_lint() async {
    const source = r'''
class Riverpod {
  const Riverpod();
}

const riverpod = Riverpod();

class Ref {
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}

class ProviderListenable<T> {}

class UnimplementedError {}

final provider = ProviderListenable<int>();

@riverpod
int count(Ref ref) {
  int readInsideCallback() => ref.watch(provider);
  return readInsideCallback();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ref.watch'), 'ref.watch(provider)'.length),
    ]);
  }
}

@reflectiveTest
final class AvoidHooksOutsideBuildTest extends _RiverpodHooksRuleTest {
  @override
  void setUp() {
    rule = AvoidHooksOutsideBuild();
    super.setUp();
  }

  Future<void> test_hookWidgetBuild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Host extends HookWidget {
  const Host();

  @override
  Widget build(BuildContext context) {
    useState(0);
    return const Widget();
  }
}
''');
  }

  Future<void> test_customHook_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_hooks/flutter_hooks.dart';

int useCounter() => useState(0).value;
''');
  }

  Future<void> test_plainFunction_lint() async {
    const source = r'''
import 'package:flutter_hooks/flutter_hooks.dart';

int counter() => useState(0).value;
''';

    await assertDiagnostics(source, [lint(source.indexOf('useState'), 'useState(0)'.length)]);
  }

  Future<void> test_hookBuilder_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Widget build() {
  return HookBuilder(
    builder: (context) {
      useState(0);
      return const Widget();
    },
  );
}
''');
  }
}

@reflectiveTest
final class AvoidMisusedHooksTest extends _RiverpodHooksRuleTest {
  @override
  void setUp() {
    rule = AvoidMisusedHooks();
    super.setUp();
  }

  Future<void> test_topLevelHookWidgetBuild_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Host extends HookWidget {
  const Host();

  @override
  Widget build(BuildContext context) {
    useState(0);
    return const Widget();
  }
}
''');
  }

  Future<void> test_loopInBuild_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Host extends HookWidget {
  const Host();

  @override
  Widget build(BuildContext context) {
    for (var i = 0; i < 1; i++) {
      useState(i);
    }
    return const Widget();
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('useState'), 'useState(i)'.length)]);
  }

  Future<void> test_callbackInCustomHook_lint() async {
    const source = r'''
import 'package:flutter_hooks/flutter_hooks.dart';

void useRegister() {
  void callback() {
    useState(0);
  }
  callback();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('useState'), 'useState(0)'.length)]);
  }

  Future<void> test_tryBlockInHookBuilder_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Widget build() {
  return HookBuilder(
    builder: (context) {
      try {
        useState(0);
      } finally {
        print('done');
      }
      return const Widget();
    },
  );
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('useState'), 'useState(0)'.length)]);
  }
}
