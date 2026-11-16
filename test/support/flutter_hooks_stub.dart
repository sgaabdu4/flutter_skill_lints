import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';

void addFlutterPackage(AnalysisRuleTest test) {
  test.newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

class BuildContext {}
''');
}

void addFlutterRiverpodPackage(AnalysisRuleTest test) {
  test.newPackage('flutter_riverpod').addFile('lib/flutter_riverpod.dart', r'''
import 'package:flutter/widgets.dart';

class ProviderListenable<T> {}

class WidgetRef {
  T watch<T>(ProviderListenable<T> provider) => throw UnimplementedError();
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}

class Consumer extends Widget {
  const Consumer({required Widget Function(BuildContext, WidgetRef, Widget?) builder});
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

void addFlutterHooksPackage(AnalysisRuleTest test) {
  test.newPackage('flutter_hooks').addFile('lib/flutter_hooks.dart', r'''
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

void addHooksRiverpodPackage(AnalysisRuleTest test) {
  test.newPackage('hooks_riverpod').addFile('lib/hooks_riverpod.dart', r'''
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

void addFlutterHookPackages(AnalysisRuleTest test) {
  addFlutterPackage(test);
  addFlutterRiverpodPackage(test);
  addFlutterHooksPackage(test);
  addHooksRiverpodPackage(test);
}
