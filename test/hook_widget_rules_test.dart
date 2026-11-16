import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_conditional_hooks.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_unnecessary_hook_widgets.dart';

import 'analysis_rule_suite.dart';
import 'support/flutter_hooks_stub.dart';

void main() {
  analysisRuleSuite<AvoidUnnecessaryHookWidgetsTest>(
    'AvoidUnnecessaryHookWidgetsTest',
    AvoidUnnecessaryHookWidgetsTest.new,
    {
      'reportsHookWidgetWithoutHooks': (t) => t.reportsHookWidgetWithoutHooks(),
      'reportsHookConsumerWidgetWithoutHooks': (t) => t.reportsHookConsumerWidgetWithoutHooks(),
      'reportsHookBuilderWithoutHooks': (t) => t.reportsHookBuilderWithoutHooks(),
      'acceptsHookWidgetWithHooks': (t) => t.acceptsHookWidgetWithHooks(),
      'acceptsHookBuilderWithHooks': (t) => t.acceptsHookBuilderWithHooks(),
      'ignoresOtherWidgetClasses': (t) => t.ignoresOtherWidgetClasses(),
    },
  );
  analysisRuleSuite<AvoidConditionalHooksTest>(
    'AvoidConditionalHooksTest',
    AvoidConditionalHooksTest.new,
    {
      'reportsHookInIfBranchOfHookWidget': (t) => t.reportsHookInIfBranchOfHookWidget(),
      'reportsHookInIfBranchOfHookConsumerWidget': (t) =>
          t.reportsHookInIfBranchOfHookConsumerWidget(),
      'reportsHookInHookBuilder': (t) => t.reportsHookInHookBuilder(),
      'acceptsUnconditionalHooks': (t) => t.acceptsUnconditionalHooks(),
      'ignoresOtherWidgetClasses': (t) => t.ignoresOtherWidgetClasses(),
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

final class AvoidUnnecessaryHookWidgetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidUnnecessaryHookWidgets();
    addFlutterHookPackages(this);
    super.setUp();
  }

  Future<void> reportsHookWidgetWithoutHooks() async {
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

  Future<void> reportsHookConsumerWidgetWithoutHooks() async {
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

  Future<void> reportsHookBuilderWithoutHooks() async {
    const source =
        '''
${_hooksImports}Widget f() => HookBuilder(builder: (context) => const Widget());
''';
    await assertDiagnostics(source, [lint(source.indexOf('HookBuilder('), 'HookBuilder'.length)]);
  }

  Future<void> acceptsHookWidgetWithHooks() => assertNoDiagnostics('''
${_hooksImports}class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return const Widget();
  }
}
''');

  Future<void> acceptsHookBuilderWithHooks() => assertNoDiagnostics('''
${_hooksImports}Widget f() => HookBuilder(builder: (context) {
  useState(0);
  return const Widget();
});
''');

  Future<void> ignoresOtherWidgetClasses() => assertNoDiagnostics('''
${_hooksImports}abstract class W extends HookWidget {
  const W();
}

class P extends Widget {
  const P();

  Widget build(BuildContext context) => const Widget();
}
''');
}

final class AvoidConditionalHooksTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidConditionalHooks();
    addFlutterHookPackages(this);
    super.setUp();
  }

  Future<void> reportsHookInIfBranchOfHookWidget() async {
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

  Future<void> reportsHookInIfBranchOfHookConsumerWidget() async {
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

  Future<void> reportsHookInHookBuilder() async {
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

  Future<void> acceptsUnconditionalHooks() => assertNoDiagnostics('''
${_hooksImports}class W extends HookWidget {
  const W();

  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return const Widget();
  }
}
''');

  Future<void> ignoresOtherWidgetClasses() => assertNoDiagnostics('''
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
