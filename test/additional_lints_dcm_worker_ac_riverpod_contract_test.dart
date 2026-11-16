import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_public_notifier_properties.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_ref_inside_state_dispose.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_immutable_provider_arguments.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/use_notifier_suffix.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferImmutableProviderArgumentsTest>(
    'PreferImmutableProviderArgumentsTest',
    PreferImmutableProviderArgumentsTest.new,
    {
      'test_functionProviderListArgument_lint': (t) => t._functionProviderListArgumentLint(),
      'test_notifierBuildMutableArgument_lint': (t) => t._notifierBuildMutableArgumentLint(),
      'test_functionProviderImmutableArguments_noLint': (t) =>
          t._functionProviderImmutableArgumentsNoLint(),
      'test_notifierBuildImmutableArgument_noLint': (t) =>
          t._notifierBuildImmutableArgumentNoLint(),
    },
  );
  analysisRuleSuite<AvoidPublicNotifierPropertiesTest>(
    'AvoidPublicNotifierPropertiesTest',
    AvoidPublicNotifierPropertiesTest.new,
    {
      'test_publicFieldAndGetter_lint': (t) => t._publicFieldAndGetterLint(),
      'test_privatePropertiesAndPublicMethods_noLint': (t) =>
          t._privatePropertiesAndPublicMethodsNoLint(),
    },
  );
  analysisRuleSuite<AvoidRefInsideStateDisposeTest>(
    'AvoidRefInsideStateDisposeTest',
    AvoidRefInsideStateDisposeTest.new,
    {
      'test_refReadInDispose_lint': (t) => t._refReadInDisposeLint(),
      'test_privateSubscriptionCloseInDispose_noLint': (t) =>
          t._privateSubscriptionCloseInDisposeNoLint(),
    },
  );
  analysisRuleSuite<UseNotifierSuffixTest>('UseNotifierSuffixTest', UseNotifierSuffixTest.new, {
    'test_generatedBaseWithoutSuffix_lint': (t) => t._generatedBaseWithoutSuffixLint(),
    'test_annotatedClassBeforeCodegen_lint': (t) => t._annotatedClassBeforeCodegenLint(),
    'test_manualNotifierWithoutSuffix_lint': (t) => t._manualNotifierWithoutSuffixLint(),
    'test_suffixedNotifiersAndNonNotifiers_noLint': (t) =>
        t._suffixedNotifiersAndNonNotifiersNoLint(),
    'test_severityIsError': (t) => t._severityIsError(),
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

abstract class AnyNotifier<StateT, ValueT> {}

abstract class $Notifier<StateT> extends AnyNotifier<StateT, StateT> {}

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

final class PreferImmutableProviderArgumentsTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = PreferImmutableProviderArguments();
    super.setUp();
  }

  Future<void> _functionProviderListArgumentLint() async {
    const source = r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int total(Ref ref, List<int> ids) => ids.length;
''';

    await assertDiagnostics(source, [lint(source.indexOf('ids'), 'ids'.length)]);
  }

  Future<void> _notifierBuildMutableArgumentLint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class SearchNotifier extends Notifier<int> {
  int build(Map<String, String> filters) => filters.length;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('filters'), 'filters'.length)]);
  }

  Future<void> _functionProviderImmutableArgumentsNoLint() async {
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

  Future<void> _notifierBuildImmutableArgumentNoLint() async {
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

final class AvoidPublicNotifierPropertiesTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = AvoidPublicNotifierProperties();
    super.setUp();
  }

  Future<void> _publicFieldAndGetterLint() async {
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

  Future<void> _privatePropertiesAndPublicMethodsNoLint() async {
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

final class AvoidRefInsideStateDisposeTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = AvoidRefInsideStateDispose();
    super.setUp();
  }

  Future<void> _refReadInDisposeLint() async {
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

  Future<void> _privateSubscriptionCloseInDisposeNoLint() async {
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

final class UseNotifierSuffixTest extends _RiverpodContractRuleTest {
  @override
  void setUp() {
    rule = UseNotifierSuffix();
    super.setUp();
  }

  Future<void> _generatedBaseWithoutSuffixLint() async {
    newFile('$testPackageLibPath/test.g.dart', r'''
part of 'test.dart';

abstract class _$Basket extends $Notifier<int> {}
''');
    const source = r'''
import 'package:riverpod/riverpod.dart';

part 'test.g.dart';

class Basket extends _$Basket {}
''';
    await assertDiagnostics(source, [lint(source.indexOf('Basket extends'), 'Basket'.length)]);
  }

  Future<void> _annotatedClassBeforeCodegenLint() async {
    const source = r'''
// ignore_for_file: extends_non_class
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(keepAlive: true)
class Basket extends _$Basket {}
''';
    await assertDiagnostics(source, [lint(source.indexOf('Basket extends'), 'Basket'.length)]);
  }

  Future<void> _manualNotifierWithoutSuffixLint() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class Counter extends Notifier<int> {}
''';
    await assertDiagnostics(source, [lint(source.indexOf('Counter'), 'Counter'.length)]);
  }

  Future<void> _suffixedNotifiersAndNonNotifiersNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart' show $Notifier;
import 'package:riverpod_annotation/riverpod_annotation.dart';

abstract class _$BasketNotifier extends $Notifier<int> {}

@riverpod
class BasketNotifier extends _$BasketNotifier {}

@riverpod
int basketTotal(Ref ref) => 0;

class Basket {}
''');
  }

  Future<void> _severityIsError() async {
    expect(UseNotifierSuffix.code.severity, DiagnosticSeverity.ERROR);
  }
}
