import 'package:flutter_skill_lints/src/additional_lints/fixes/dispose_fields_fix.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/dispose_fields.dart';

import 'analysis_rule_suite.dart';
import 'fix_test_support.dart';
import 'support/flutter_widgets_stub.dart';

void main() {
  analysisRuleSuite<_DisposeFieldsTest>('DisposeFieldsTest', _DisposeFieldsTest.new, {
    'reportsFieldsWithCleanupMethods': (t) => t._reportsFieldsWithCleanupMethods(),
    'reportsFieldWhenOnlyAnotherMethodIsCalled': (t) =>
        t._reportsFieldWhenOnlyAnotherMethodIsCalled(),
    'reportsFieldCleanedUpOnlyInsideClosure': (t) => t._reportsFieldCleanedUpOnlyInsideClosure(),
    'acceptsFieldsCleanedUpInDispose': (t) => t._acceptsFieldsCleanedUpInDispose(),
    'acceptsThisQualifiedCleanup': (t) => t._acceptsThisQualifiedCleanup(),
    'ignoresStaticFieldsAndFieldsWithoutCleanup': (t) =>
        t._ignoresStaticFieldsAndFieldsWithoutCleanup(),
    'ignoresClassesThatAreNotState': (t) => t._ignoresClassesThatAreNotState(),
    'addsDisposeMethodWhenMissing': (t) => t._addsDisposeMethodWhenMissing(),
    'addsCleanupBeforeSuperDispose': (t) => t._addsCleanupBeforeSuperDispose(),
    'addsCleanupToDisposeWithoutSuperCall': (t) => t._addsCleanupToDisposeWithoutSuperCall(),
    'usesTheCleanupMethodOfTheFieldType': (t) => t._usesTheCleanupMethodOfTheFieldType(),
  });
}

final class _DisposeFieldsTest extends FixRuleTest {
  @override
  void setUp() {
    addFlutterWidgets(this);
    rule = DisposeFields();
    super.setUp();
  }

  static String _source(String members) =>
      '''
import 'package:flutter/widgets.dart';

class Controller {
  void dispose() {}
}

class Subscription {
  void cancel() {}
}

class Sink {
  void close() {}
}

class W extends StatefulWidget {
  const W();
}

class S extends State<W> {
$members
  @override
  Widget build(BuildContext context) => Text('a');
}
''';

  Future<void> _reportsFieldsWithCleanupMethods() async {
    final source = _source('''
  final controller = Controller();
  final subscription = Subscription();
  final sink = Sink();
''');
    await assertDiagnostics(source, [
      lint(source.indexOf('controller ='), 'controller'.length),
      lint(source.indexOf('subscription ='), 'subscription'.length),
      lint(source.indexOf('sink ='), 'sink'.length),
    ]);
  }

  Future<void> _reportsFieldWhenOnlyAnotherMethodIsCalled() async {
    final source = _source('''
  final controller = Controller();

  @override
  void dispose() {
    controller.toString();
    super.dispose();
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> _reportsFieldCleanedUpOnlyInsideClosure() async {
    final source = _source('''
  final controller = Controller();

  @override
  void dispose() {
    final later = () => controller.dispose();
    super.dispose();
  }
''');
    await assertDiagnostics(source, [lint(source.indexOf('controller ='), 'controller'.length)]);
  }

  Future<void> _acceptsFieldsCleanedUpInDispose() => assertNoDiagnostics(
    _source('''
  final controller = Controller();
  final subscription = Subscription();

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();
    super.dispose();
  }
'''),
  );

  Future<void> _acceptsThisQualifiedCleanup() => assertNoDiagnostics(
    _source('''
  final controller = Controller();

  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }
'''),
  );

  Future<void> _ignoresStaticFieldsAndFieldsWithoutCleanup() => assertNoDiagnostics(
    _source('''
  static final shared = Controller();
  final count = 1;
'''),
  );

  Future<void> _ignoresClassesThatAreNotState() => assertNoDiagnostics('''
class Controller {
  void dispose() {}
}

class Holder {
  final controller = Controller();
}
''');

  Future<void> _expectFix(String members, String expectedMembers) => expectFix(
    _source(members),
    (context) => DisposeFieldsFix(context: context),
    expected: _source(expectedMembers),
  );

  Future<void> _addsDisposeMethodWhenMissing() => expectFix(
    _source('  final controller = Controller();\n'),
    (context) => DisposeFieldsFix(context: context),
    expected: _source('  final controller = Controller();\n').replaceFirst(
      "Text('a');\n}",
      "Text('a');\n\n  @override\n  void dispose() {\n"
          '    controller.dispose();\n    super.dispose();\n  }\n}',
    ),
  );

  Future<void> _addsCleanupBeforeSuperDispose() => _expectFix(
    '''
  final controller = Controller();
  final sink = Sink();

  @override
  void dispose() {
    sink.close();
    super.dispose();
  }
''',
    '''
  final controller = Controller();
  final sink = Sink();

  @override
  void dispose() {
    sink.close();
    controller.dispose();
    super.dispose();
  }
''',
  );

  Future<void> _addsCleanupToDisposeWithoutSuperCall() => _expectFix(
    '''
  final controller = Controller();
  final sink = Sink();

  @override
  void dispose() {
    sink.close();
  }
''',
    '''
  final controller = Controller();
  final sink = Sink();

  @override
  void dispose() {
    sink.close();
    controller.dispose();
  }
''',
  );

  Future<void> _usesTheCleanupMethodOfTheFieldType() => _expectFix(
    '''
  final subscription = Subscription();

  @override
  void dispose() {
    super.dispose();
  }
''',
    '''
  final subscription = Subscription();

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
''',
  );
}
