// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_hooks_outside_build.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_misused_hooks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_watch_outside_build.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'support/flutter_hooks_stub.dart';

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
    addFlutterHookPackages(this);
    super.setUp();
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

  Future<void> test_consumerBuilder_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final provider = ProviderListenable<int>();
Widget make() => Consumer(builder: (context, ref, child) {
  ref.watch(provider);
  return const Widget();
});
''');
  }

  Future<void> test_hookConsumerBuilder_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
final provider = ProviderListenable<int>();
Widget make() => HookConsumer(builder: (context, ref) {
  ref.watch(provider);
  return const Widget();
});
''');
  }

  Future<void> test_consumerNestedCallback_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final provider = ProviderListenable<int>();
Widget make() => Consumer(builder: (context, ref, child) {
  final callback = () => ref.watch(provider);
  callback();
  return const Widget();
});
''';
    await assertDiagnostics(source, [lint(source.indexOf('ref.watch'), 19)]);
  }

  Future<void> test_outerRefInsideConsumerBuilder_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final provider = ProviderListenable<int>();
Widget make(WidgetRef ref) => Consumer(builder: (context, innerRef, child) {
  ref.watch(provider);
  return const Widget();
});
''';
    await assertDiagnostics(source, [lint(source.indexOf('ref.watch'), 19)]);
  }

  Future<void> test_unrelatedConsumerBuilder_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
class Consumer {
  Consumer({required Widget Function(WidgetRef) builder});
}
final provider = ProviderListenable<int>();
void make() => Consumer(builder: (ref) {
  ref.watch(provider);
  return const Widget();
});
''';
    await assertDiagnostics(source, [lint(source.indexOf('ref.watch'), 19)]);
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
    newPackage('flutter_web_plugins').addFile('lib/url_strategy.dart', r'''
void usePathUrlStrategy() {}
''');
    super.setUp();
  }

  Future<void> test_nonHookUsePrefixedPackageFunction_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  usePathUrlStrategy();
}
''');
  }

  Future<void> test_localUsePrefixedFunctionWithoutHooks_noLint() async {
    await assertNoDiagnostics(r'''
int useDefaultPageSize() => 20;

int pageSize() => useDefaultPageSize();
''');
  }

  Future<void> test_localCustomHookInPlainFunction_lint() async {
    const source = r'''
import 'package:flutter_hooks/flutter_hooks.dart';

int useCounter() => useState(0).value;

int counter() => useCounter();
''';

    await assertDiagnostics(source, [
      lint(source.lastIndexOf('useCounter()'), 'useCounter()'.length),
    ]);
  }

  Future<void> test_importedCustomHookInPlainFunction_lint() async {
    newFile('$testPackageLibPath/hooks.dart', r'''
import 'package:flutter_hooks/flutter_hooks.dart';

int useCounter() => useState(0).value;
''');
    const source = r'''
import 'hooks.dart';

int counter() => useCounter();
''';

    await assertDiagnostics(source, [lint(source.indexOf('useCounter()'), 'useCounter()'.length)]);
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
