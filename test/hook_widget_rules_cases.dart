import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conditional_hooks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_hook_widgets.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_hooks_stub.dart';

void main() {
  analysisRuleSuite<_AvoidUnnecessaryHookWidgetsTest>(
    'AvoidUnnecessaryHookWidgetsTest',
    _AvoidUnnecessaryHookWidgetsTest.new,
    {
      'reportsHookWidgetWithoutHooks': (t) => t._reportsHookWidgetWithoutHooks(),
      'reportsHookConsumerWidgetWithoutHooks': (t) => t._reportsHookConsumerWidgetWithoutHooks(),
      'reportsHookBuilderWithoutHooks': (t) => t._reportsHookBuilderWithoutHooks(),
      'acceptsHookWidgetWithHooks': (t) => t._acceptsHookWidgetWithHooks(),
      'acceptsHookBuilderWithHooks': (t) => t._acceptsHookBuilderWithHooks(),
      'ignoresOtherWidgetClasses': (t) => t._ignoresOtherWidgetClasses(),
    },
  );
  analysisRuleSuite<_AvoidConditionalHooksTest>(
    'AvoidConditionalHooksTest',
    _AvoidConditionalHooksTest.new,
    {
      'reportsHookInIfBranchOfHookWidget': (t) => t._reportsHookInIfBranchOfHookWidget(),
      'reportsHookInIfBranchOfHookConsumerWidget': (t) =>
          t._reportsHookInIfBranchOfHookConsumerWidget(),
      'reportsHookInHookBuilder': (t) => t._reportsHookInHookBuilder(),
      'acceptsUnconditionalHooks': (t) => t._acceptsUnconditionalHooks(),
      'ignoresOtherWidgetClasses': (t) => t._ignoresOtherWidgetClasses(),
    },
  );
}

const _hooksImports = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
''';

const _consumerImports = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
''';

const _consumerHooksImports = '''
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
''';

final class _AvoidUnnecessaryHookWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryHookWidgets();
    addFlutterHookPackages(this);
    super.setUp();
  }

  Future<void> _reportsHookWidgetWithoutHooks() async {
    const source =
        '''
${_hooksImports}class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) => const Widget();
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('HookWidget {'), 'HookWidget'.length)]);
  }

  Future<void> _reportsHookConsumerWidgetWithoutHooks() async {
    const source =
        '''
${_consumerImports}class W extends HookConsumerWidget {
  const W();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Widget();
}
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('HookConsumerWidget {'), 'HookConsumerWidget'.length),
    ]);
  }

  Future<void> _reportsHookBuilderWithoutHooks() async {
    const source =
        '''
${_hooksImports}Widget f() => HookBuilder(builder: (context) => const Widget());
''';
    await assertDiagnostics(source, [lint(source.indexOf('HookBuilder('), 'HookBuilder'.length)]);
  }

  Future<void> _acceptsHookWidgetWithHooks() => assertNoDiagnostics('''
${_hooksImports}class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return const Widget();
  }
}
''');

  Future<void> _acceptsHookBuilderWithHooks() => assertNoDiagnostics('''
${_hooksImports}Widget f() => HookBuilder(builder: (context) {
  useState(0);
  return const Widget();
});
''');

  Future<void> _ignoresOtherWidgetClasses() => assertNoDiagnostics('''
${_hooksImports}abstract class W extends HookWidget {
  const W();
}

class P extends Widget {
  const P();

  Widget build(BuildContext context) => const Widget();
}
''');
}

final class _AvoidConditionalHooksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConditionalHooks();
    addFlutterHookPackages(this);
    super.setUp();
  }

  Future<void> _reportsHookInIfBranchOfHookWidget() async {
    const source =
        '''
${_hooksImports}bool flag() => true;

class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) {
    if (flag()) {
      useState(0);
    }
    return const Widget();
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('useState(0)'), 'useState(0)'.length)]);
  }

  Future<void> _reportsHookInIfBranchOfHookConsumerWidget() async {
    const source =
        '''
${_consumerHooksImports}bool flag() => true;

class W extends HookConsumerWidget {
  const W();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (flag()) {
      useState(0);
    }
    return const Widget();
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('useState(0)'), 'useState(0)'.length)]);
  }

  Future<void> _reportsHookInHookBuilder() async {
    const source =
        '''
${_hooksImports}Widget f(bool flag) => HookBuilder(builder: (context) {
  if (flag) {
    useState(0);
  }
  return const Widget();
});
''';
    await assertDiagnostics(source, [lint(source.indexOf('useState(0)'), 'useState(0)'.length)]);
  }

  Future<void> _acceptsUnconditionalHooks() => assertNoDiagnostics('''
${_hooksImports}class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return const Widget();
  }
}
''');

  Future<void> _ignoresOtherWidgetClasses() => assertNoDiagnostics('''
${_hooksImports}bool flag() => true;

class P extends Widget {
  const P();

  Widget build(BuildContext context) {
    if (flag()) {
      useState(0);
    }
    return const Widget();
  }
}
''');
}
