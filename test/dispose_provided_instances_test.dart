import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/dispose_provided_instances.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<DisposeProvidedInstancesTest>(
    'DisposeProvidedInstancesTest',
    DisposeProvidedInstancesTest.new,
    {
      'reportsInstanceInProviderCallback': (t) => t.reportsInstanceInProviderCallback(),
      'reportsInstanceInNotifierBuild': (t) => t.reportsInstanceInNotifierBuild(),
      'reportsInstanceWhenOnDisposeCleansAnotherOne': (t) =>
          t.reportsInstanceWhenOnDisposeCleansAnotherOne(),
      'acceptsTearOffCleanup': (t) => t.acceptsTearOffCleanup(),
      'acceptsNullAwareTearOffCleanup': (t) => t.acceptsNullAwareTearOffCleanup(),
      'acceptsExpressionCallbackCleanup': (t) => t.acceptsExpressionCallbackCleanup(),
      'acceptsBlockCallbackCleanup': (t) => t.acceptsBlockCallbackCleanup(),
      'acceptsCleanupInNotifierBuild': (t) => t.acceptsCleanupInNotifierBuild(),
      'ignoresOtherNotifierMethods': (t) => t.ignoresOtherNotifierMethods(),
      'ignoresClassesThatAreNotNotifiers': (t) => t.ignoresClassesThatAreNotNotifiers(),
    },
  );
}

final class DisposeProvidedInstancesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = DisposeProvidedInstances();
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  void onDispose(void Function()? callback) {}
}

class Provider<T> {
  Provider(T Function(Ref ref) create);
}

abstract class Notifier<T> {
  Ref get ref => Ref();
  T build();
}
''');
    super.setUp();
  }

  static String _providerSource(String body) =>
      '''
import 'package:riverpod/riverpod.dart';

class Controller {
  void dispose() {}
}

final provider = Provider<int>((ref) {
$body
  return 1;
});
''';

  static String _notifierSource(String members) =>
      '''
import 'package:riverpod/riverpod.dart';

class Controller {
  void dispose() {}
}

class N extends Notifier<int> {
$members
}
''';

  Future<void> reportsInstanceInProviderCallback() async {
    final source = _providerSource('  final controller = Controller();');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> reportsInstanceInNotifierBuild() async {
    final source = _notifierSource('''
  @override
  int build() {
    final controller = Controller();
    return 1;
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> reportsInstanceWhenOnDisposeCleansAnotherOne() async {
    final source = _providerSource('''
  final first = Controller();
  final second = Controller();
  ref.onDispose(first.dispose);
''');
    await assertDiagnostics(source, [lint(source.indexOf('second ='), 'second'.length)]);
  }

  Future<void> acceptsTearOffCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(controller.dispose);
'''),
  );

  Future<void> acceptsNullAwareTearOffCleanup() => assertNoDiagnostics(
    _providerSource('''
  final Controller? controller = Controller();
  ref.onDispose(controller?.dispose);
'''),
  );

  Future<void> acceptsExpressionCallbackCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(() => controller.dispose());
'''),
  );

  Future<void> acceptsBlockCallbackCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(() {
    controller.dispose();
  });
'''),
  );

  Future<void> acceptsCleanupInNotifierBuild() => assertNoDiagnostics(
    _notifierSource('''
  @override
  int build() {
    final controller = Controller();
    ref.onDispose(controller.dispose);
    return 1;
  }
'''),
  );

  Future<void> ignoresOtherNotifierMethods() => assertNoDiagnostics(
    _notifierSource('''
  @override
  int build() => 1;

  void refresh() {
    final controller = Controller();
  }
'''),
  );

  Future<void> ignoresClassesThatAreNotNotifiers() => assertNoDiagnostics('''
class Controller {
  void dispose() {}
}

class Plain {
  int build() {
    final controller = Controller();
    return 1;
  }
}
''');
}
