import 'package:flutter_skill_lints/src/additional_lints/fixes/always_remove_listener_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/always_remove_listener.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<AlwaysRemoveListenerTest>(
    'AlwaysRemoveListenerTest',
    AlwaysRemoveListenerTest.new,
    {
      'reportsListenerNeverRemoved': (t) => t.reportsListenerNeverRemoved(),
      'reportsListenersInEveryLifecycleMethod': (t) => t.reportsListenersInEveryLifecycleMethod(),
      'reportsListenerRemovedForOtherCallback': (t) => t.reportsListenerRemovedForOtherCallback(),
      'reportsListenerRemovedFromOtherTarget': (t) => t.reportsListenerRemovedFromOtherTarget(),
      'acceptsListenerRemovedInDispose': (t) => t.acceptsListenerRemovedInDispose(),
      'acceptsListenersOutsideLifecycleMethods': (t) => t.acceptsListenersOutsideLifecycleMethods(),
      'acceptsListenersInsideCallbacks': (t) => t.acceptsListenersInsideCallbacks(),
      'ignoresClassesThatAreNotState': (t) => t.ignoresClassesThatAreNotState(),
      'addsDisposeMethodWhenMissing': (t) => t.addsDisposeMethodWhenMissing(),
      'addsRemovalBeforeSuperDispose': (t) => t.addsRemovalBeforeSuperDispose(),
      'addsRemovalToDisposeWithoutSuperCall': (t) => t.addsRemovalToDisposeWithoutSuperCall(),
      'addsUnqualifiedRemoval': (t) => t.addsUnqualifiedRemoval(),
    },
  );
}

final class AlwaysRemoveListenerTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = AlwaysRemoveListener();
    super.setUp();
  }

  static String _source(String members) =>
      '''
import 'package:flutter/widgets.dart';

class Notifier {
  void addListener(void Function() listener) {}
  void removeListener(void Function() listener) {}
}

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  final controller = Notifier();
  final other = Notifier();

  void _onChange() {}
  void _onOther() {}
$members
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> _expectReported(String members, List<String> calls) {
    final source = _source(members);
    return assertDiagnostics(source, [
      for (final call in calls) lint(source.indexOf(call), call.length),
    ]);
  }

  Future<void> reportsListenerNeverRemoved() => _expectReported(
    '''
  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
  }
''',
    ['controller.addListener(_onChange)'],
  );

  Future<void> reportsListenersInEveryLifecycleMethod() => _expectReported(
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void didChangeDependencies() {
    controller.addListener(_onOther);
  }

  @override
  void didUpdateWidget(W oldWidget) {
    other.addListener(_onChange);
  }
''',
    [
      'controller.addListener(_onChange)',
      'controller.addListener(_onOther)',
      'other.addListener(_onChange)',
    ],
  );

  Future<void> reportsListenerRemovedForOtherCallback() => _expectReported(
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onOther);
    super.dispose();
  }
''',
    ['controller.addListener(_onChange)'],
  );

  Future<void> reportsListenerRemovedFromOtherTarget() => _expectReported(
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    other.removeListener(_onChange);
    super.dispose();
  }
''',
    ['controller.addListener(_onChange)'],
  );

  Future<void> acceptsListenerRemovedInDispose() => assertNoDiagnostics(
    _source('''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    super.dispose();
  }
'''),
  );

  Future<void> acceptsListenersOutsideLifecycleMethods() => assertNoDiagnostics(
    _source('''
  void attach() {
    controller.addListener(_onChange);
  }
'''),
  );

  Future<void> acceptsListenersInsideCallbacks() => assertNoDiagnostics(
    _source('''
  @override
  void initState() {
    void later() {
      controller.addListener(_onChange);
    }
    final callback = () => other.addListener(_onChange);
  }
'''),
  );

  Future<void> ignoresClassesThatAreNotState() => assertNoDiagnostics('''
class Notifier {
  void addListener(void Function() listener) {}
}

class Holder {
  final controller = Notifier();

  void initState() {
    controller.addListener(() {});
  }
}
''');

  Future<void> _expectFix(String members, String expectedMembers) => expectFix(
    _source(members),
    (context) => AlwaysRemoveListenerFix(context: context),
    expected: _source(expectedMembers),
  );

  Future<void> addsDisposeMethodWhenMissing() => expectFix(
    _source('''
  @override
  void initState() {
    controller.addListener(_onChange);
  }
'''),
    (context) => AlwaysRemoveListenerFix(context: context),
    expected:
        _source('''
  @override
  void initState() {
    controller.addListener(_onChange);
  }
''').replaceFirst(
          "Text('a');\n}",
          "Text('a');\n\n  @override\n  void dispose() {\n"
              '    controller.removeListener(_onChange);\n    super.dispose();\n  }\n}',
        ),
  );

  Future<void> addsRemovalBeforeSuperDispose() => _expectFix(
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    other.removeListener(_onOther);
    super.dispose();
  }
''',
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    other.removeListener(_onOther);
    controller.removeListener(_onChange);
    super.dispose();
  }
''',
  );

  Future<void> addsRemovalToDisposeWithoutSuperCall() => _expectFix(
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    other.removeListener(_onOther);
  }
''',
    '''
  @override
  void initState() {
    controller.addListener(_onChange);
  }

  @override
  void dispose() {
    other.removeListener(_onOther);
    controller.removeListener(_onChange);
  }
''',
  );

  Future<void> addsUnqualifiedRemoval() => expectFix(
    '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  void addListener(void Function() listener) {}
  void removeListener(void Function() listener) {}
  void _onChange() {}

  @override
  void initState() {
    addListener(_onChange);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''',
    (context) => AlwaysRemoveListenerFix(context: context),
    expected: '''
import 'package:flutter/widgets.dart';

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
  void addListener(void Function() listener) {}
  void removeListener(void Function() listener) {}
  void _onChange() {}

  @override
  void initState() {
    addListener(_onChange);
  }

  @override
  void dispose() {
    removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text('a');
}
''',
  );
}
