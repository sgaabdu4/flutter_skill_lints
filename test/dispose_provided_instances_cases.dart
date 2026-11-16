import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/dispose_provided_instances.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_DisposeProvidedInstancesTest>(
    'DisposeProvidedInstancesTest',
    _DisposeProvidedInstancesTest.new,
    {
      'reportsInstanceInProviderCallback': (t) => t._reportsInstanceInProviderCallback(),
      'reportsInstanceInNotifierBuild': (t) => t._reportsInstanceInNotifierBuild(),
      'reportsInstanceWhenOnDisposeCleansAnotherOne': (t) =>
          t._reportsInstanceWhenOnDisposeCleansAnotherOne(),
      'acceptsTearOffCleanup': (t) => t._acceptsTearOffCleanup(),
      'acceptsNullAwareTearOffCleanup': (t) => t._acceptsNullAwareTearOffCleanup(),
      'acceptsExpressionCallbackCleanup': (t) => t._acceptsExpressionCallbackCleanup(),
      'acceptsBlockCallbackCleanup': (t) => t._acceptsBlockCallbackCleanup(),
      'acceptsCleanupInNotifierBuild': (t) => t._acceptsCleanupInNotifierBuild(),
      'ignoresOtherNotifierMethods': (t) => t._ignoresOtherNotifierMethods(),
      'ignoresClassesThatAreNotNotifiers': (t) => t._ignoresClassesThatAreNotNotifiers(),
    },
  );
}

final class _DisposeProvidedInstancesTest extends AnalysisRuleTest {
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

  Future<void> _reportsInstanceInProviderCallback() async {
    final source = _providerSource('  final controller = Controller();');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> _reportsInstanceInNotifierBuild() async {
    final source = _notifierSource('''
  @override
  int build() {
    final controller = Controller();
    return 1;
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> _reportsInstanceWhenOnDisposeCleansAnotherOne() async {
    final source = _providerSource('''
  final first = Controller();
  final second = Controller();
  ref.onDispose(first.dispose);
''');
    await assertDiagnostics(source, [lint(source.indexOf('second ='), 'second'.length)]);
  }

  Future<void> _acceptsTearOffCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(controller.dispose);
'''),
  );

  Future<void> _acceptsNullAwareTearOffCleanup() => assertNoDiagnostics(
    _providerSource('''
  final Controller? controller = Controller();
  ref.onDispose(controller?.dispose);
'''),
  );

  Future<void> _acceptsExpressionCallbackCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(() => controller.dispose());
'''),
  );

  Future<void> _acceptsBlockCallbackCleanup() => assertNoDiagnostics(
    _providerSource('''
  final controller = Controller();
  ref.onDispose(() {
    controller.dispose();
  });
'''),
  );

  Future<void> _acceptsCleanupInNotifierBuild() => assertNoDiagnostics(
    _notifierSource('''
  @override
  int build() {
    final controller = Controller();
    ref.onDispose(controller.dispose);
    return 1;
  }
'''),
  );

  Future<void> _ignoresOtherNotifierMethods() => assertNoDiagnostics(
    _notifierSource('''
  @override
  int build() => 1;

  void refresh() {
    final controller = Controller();
  }
'''),
  );

  Future<void> _ignoresClassesThatAreNotNotifiers() => assertNoDiagnostics('''
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
