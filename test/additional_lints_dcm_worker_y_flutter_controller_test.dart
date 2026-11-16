import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/always_pass_global_key.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_disposing_late_fields.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidDisposingLateFieldsTest>(
    'AvoidDisposingLateFieldsTest',
    _AvoidDisposingLateFieldsTest.new,
    _AvoidDisposingLateFieldsTest._allCases,
  );
  analysisRuleSuite<_AlwaysPassGlobalKeyTest>(
    'AlwaysPassGlobalKeyTest',
    _AlwaysPassGlobalKeyTest.new,
    _AlwaysPassGlobalKeyTest._allCases,
  );
}

abstract class _FlutterControllerRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}

class BuildContext {}

class Key {
  const Key();
}

class GlobalKey extends Key {
  GlobalKey();
}

class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => const Widget();
}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}

class State<T extends StatefulWidget> {
  void initState() {}
  void dispose() {}
}

class TextEditingController {
  void dispose() {}
}

class FocusNode {
  void dispose() {}
}

class TextField extends Widget {
  const TextField({TextEditingController? controller});
}

class TextFormField extends Widget {
  const TextFormField({TextEditingController? controller});
}

class EditableText extends Widget {
  const EditableText({
    required FocusNode focusNode,
    TextEditingController? controller,
  });
}

class DropdownButton<T> extends Widget {
  const DropdownButton({T? value});
}
''');
  }
}

final class _AvoidDisposingLateFieldsTest extends _FlutterControllerRuleTest {
  static Map<String, Future<void> Function(_AvoidDisposingLateFieldsTest)> get _allCases =>
      caseSet<_AvoidDisposingLateFieldsTest>(
        parent: const {},
        own: {
          'test_flutterInitStateAndDispose_noLint': (t) => t._flutterInitStateAndDisposeNoLint(),
          'test_conditionalLifecycleDisposalStillReports_lint': (t) =>
              t._conditionalLifecycleDisposalStillReportsLint(),
          'test_lateFieldDisposed_lint': (t) => t._lateFieldDisposedLint(),
          'test_thisPrefixedLateFieldDisposed_lint': (t) => t._thisPrefixedLateFieldDisposedLint(),
          'test_lateInitializerCanBeDisposed_noLint': (t) =>
              t._lateInitializerCanBeDisposedNoLint(),
          'test_conditionalConstructorDoesNotProveDisposalSafe_lint': (t) =>
              t._conditionalConstructorDoesNotProveDisposalSafeLint(),
          'test_eagerFieldDisposed_noLint': (t) => t._eagerFieldDisposedNoLint(),
          'test_lateFieldUsedOutsideDispose_noLint': (t) => t._lateFieldUsedOutsideDisposeNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDisposingLateFields();
    super.setUp();
  }

  Future<void> _flutterInitStateAndDisposeNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Host extends State<StatefulWidget> {
  bool enabled = true;
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
''');
  }

  Future<void> _conditionalLifecycleDisposalStillReportsLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
class Host extends State<StatefulWidget> {
  bool enabled = true;
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    if (enabled) controller = TextEditingController();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('controller.dispose()'), 20)]);
  }

  Future<void> _lateFieldDisposedLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late final TextEditingController controller;

  void dispose() {
    controller.dispose();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('controller.dispose()'), 'controller.dispose()'.length),
    ]);
  }

  Future<void> _thisPrefixedLateFieldDisposedLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late TextEditingController controller;

  void dispose() {
    this.controller.dispose();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('this.controller.dispose()'), 'this.controller.dispose()'.length),
    ]);
  }

  Future<void> _lateInitializerCanBeDisposedNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class Host {
  late final controller = TextEditingController();
  void dispose() { controller.dispose(); }
}
''');
  }

  Future<void> _conditionalConstructorDoesNotProveDisposalSafeLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';
class Host {
  late final TextEditingController controller;
  Host(bool enabled) { if (enabled) controller = TextEditingController(); }
  void dispose() { controller.dispose(); }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('controller.dispose()'), 20)]);
  }

  Future<void> _eagerFieldDisposedNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host {
  final controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}
''');
  }

  Future<void> _lateFieldUsedOutsideDisposeNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host {
  late final TextEditingController controller;

  void close() {
    controller.dispose();
  }
}
''');
  }
}

final class _AlwaysPassGlobalKeyTest extends _FlutterControllerRuleTest {
  static Map<String, Future<void> Function(_AlwaysPassGlobalKeyTest)> get _allCases =>
      caseSet<_AlwaysPassGlobalKeyTest>(
        parent: const {},
        own: {
          'test_globalKeyCreatedInBuild_lint': (t) => t._globalKeyCreatedInBuildLint(),
          'test_globalKeyCreatedInWidgetConstructor_lint': (t) =>
              t._globalKeyCreatedInWidgetConstructorLint(),
          'test_globalKeyPassedThroughConstructor_noLint': (t) =>
              t._globalKeyPassedThroughConstructorNoLint(),
          'test_globalKeyCreatedOutsideWidget_noLint': (t) =>
              t._globalKeyCreatedOutsideWidgetNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AlwaysPassGlobalKey();
    super.setUp();
  }

  Future<void> _globalKeyCreatedInBuildLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host extends StatelessWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context) {
    return Widget(key: GlobalKey());
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('GlobalKey()'), 'GlobalKey()'.length)]);
  }

  Future<void> _globalKeyCreatedInWidgetConstructorLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host extends Widget {
  Host() : super(key: GlobalKey());
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('GlobalKey()'), 'GlobalKey()'.length)]);
  }

  Future<void> _globalKeyPassedThroughConstructorNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host extends Widget {
  const Host({GlobalKey? key}) : super(key: key);
}
''');
  }

  Future<void> _globalKeyCreatedOutsideWidgetNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final key = GlobalKey();

class Host extends Widget {
  Host() : super(key: key);
}
''');
  }
}
