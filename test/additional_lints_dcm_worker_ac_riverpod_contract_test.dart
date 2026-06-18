// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_public_notifier_properties.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_inside_state_dispose.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_immutable_provider_arguments.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferImmutableProviderArgumentsTest);
    defineReflectiveTests(AvoidPublicNotifierPropertiesTest);
    defineReflectiveTests(AvoidRefInsideStateDisposeTest);
  });
}

abstract class _RiverpodContractRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addRiverpodPackage();
    _addRiverpodAnnotationPackage();
    _addFlutterPackage();
    _addFlutterRiverpodPackage();
    _addHooksRiverpodPackage();
    super.setUp();
  }

  void _addRiverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {}

abstract class Notifier<T> {
  Ref get ref => throw UnimplementedError();
  T get state => throw UnimplementedError();
  set state(T value) {}
}

abstract class AsyncNotifier<T> {
  Ref get ref => throw UnimplementedError();
  AsyncNotifier();
}
''');
  }

  void _addRiverpodAnnotationPackage() {
    newPackage('riverpod_annotation').addFile('lib/riverpod_annotation.dart', r'''
class Riverpod {
  const Riverpod({bool keepAlive = false});
}

const riverpod = Riverpod();

class Ref {}
''');
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
  T read<T>(ProviderListenable<T> provider) => throw UnimplementedError();
}

abstract class ConsumerState<T extends ConsumerStatefulWidget> {
  WidgetRef get ref => throw UnimplementedError();
  Widget build(BuildContext context);
  void dispose() {}
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

abstract class HookConsumerState<T extends Widget> extends ConsumerState<ConsumerStatefulWidget> {}
''');
  }
}

@reflectiveTest
final class PreferImmutableProviderArgumentsTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = PreferImmutableProviderArguments();
    super.setUp();
  }

  Future<void> test_functionProviderListArgument_lint() async {
    const source = r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int total(Ref ref, List<int> ids) => ids.length;
''';

    await assertDiagnostics(source, [lint(source.indexOf('ids'), 'ids'.length)]);
  }

  Future<void> test_notifierBuildMutableArgument_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class SearchNotifier extends Notifier<int> {
  int build(Map<String, String> filters) => filters.length;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('filters'), 'filters'.length)]);
  }

  Future<void> test_functionProviderImmutableArguments_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Filter {
  const Filter(this.term);
  final String term;
}

@riverpod
int total(Ref ref, String id, int page, Filter filter, ({String id}) record) {
  return page + id.length + filter.term.length + record.id.length;
}
''');
  }

  Future<void> test_notifierBuildImmutableArgument_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class Filter {
  const Filter(this.term);
  final String term;
}

class SearchNotifier extends Notifier<int> {
  int build(Filter filter) => filter.term.length;
}
''');
  }
}

@reflectiveTest
final class AvoidPublicNotifierPropertiesTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = AvoidPublicNotifierProperties();
    super.setUp();
  }

  Future<void> test_publicFieldAndGetter_lint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class SearchNotifier extends Notifier<int> {
  int attempts = 0;
  String get label => 'search';

  int build() => 0;
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('attempts'), 'attempts'.length),
      lint(source.indexOf('label'), 'label'.length),
    ]);
  }

  Future<void> test_privatePropertiesAndPublicMethods_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

class SearchNotifier extends Notifier<int> {
  int _attempts = 0;
  String get _label => 'search';

  int build() => 0;

  void refresh() {
    _attempts++;
  }
}
''');
  }
}

@reflectiveTest
final class AvoidRefInsideStateDisposeTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = AvoidRefInsideStateDispose();
    super.setUp();
  }

  Future<void> test_refReadInDispose_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final provider = ProviderListenable<int>();

class HostState extends ConsumerState<ConsumerStatefulWidget> {
  @override
  Widget build(BuildContext context) => const Widget();

  @override
  void dispose() {
    ref.read(provider);
    super.dispose();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('ref.read'), 'ref.read(provider)'.length),
    ]);
  }

  Future<void> test_privateSubscriptionCloseInDispose_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Subscription {
  void close() {}
}

class HostState extends ConsumerState<ConsumerStatefulWidget> {
  final _subscription = Subscription();

  @override
  Widget build(BuildContext context) => const Widget();

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
''');
  }
}
