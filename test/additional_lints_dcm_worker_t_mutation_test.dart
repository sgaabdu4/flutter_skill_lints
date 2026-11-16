import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_mutating_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_global_state.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mutating_parameters.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/consistent_update_render_object.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidGlobalStateTest>('AvoidGlobalStateTest', AvoidGlobalStateTest.new, {
    'test_mutableStaticField_lint': (t) => t._mutableStaticFieldLint(),
    'test_mutableTopLevelVariable_lint': (t) => t._mutableTopLevelVariableLint(),
    'test_finalAndLocalVariables_noLint': (t) => t._finalAndLocalVariablesNoLint(),
  });
  analysisRuleSuite<AvoidMutatingParametersTest>(
    'AvoidMutatingParametersTest',
    AvoidMutatingParametersTest.new,
    {
      'test_updateRenderObjectWritesRenderObjectParameter_noLint': (t) =>
          t._updateRenderObjectWritesRenderObjectParameterNoLint(),
      'test_updateRenderObjectCascadeWritesRenderObjectParameter_noLint': (t) =>
          t._updateRenderObjectCascadeWritesRenderObjectParameterNoLint(),
      'test_updateRenderObjectReassignsRenderObjectParameter_lint': (t) =>
          t._updateRenderObjectReassignsRenderObjectParameterLint(),
      'test_updateRenderObjectWritesContextParameter_lint': (t) =>
          t._updateRenderObjectWritesContextParameterLint(),
      'test_otherMethodWritesRenderObjectParameter_lint': (t) =>
          t._otherMethodWritesRenderObjectParameterLint(),
      'test_updateRenderObjectOutsideRenderObjectWidget_lint': (t) =>
          t._updateRenderObjectOutsideRenderObjectWidgetLint(),
      'test_assignmentToParameter_lint': (t) => t._assignmentToParameterLint(),
      'test_parameterPropertyWrite_lint': (t) => t._parameterPropertyWriteLint(),
      'test_parameterCascadePropertyWrite_lint': (t) => t._parameterCascadePropertyWriteLint(),
      'test_shadowedLocalCascadeDoesNotMutateParameter': (t) =>
          t._shadowedLocalCascadeDoesNotMutateParameter(),
      'test_sentryFlutterOptionsBuilderCallback_noLint': (t) =>
          t._sentryFlutterOptionsBuilderCallbackNoLint(),
      'test_sentryFlutterOptionsBuilderCascade_noLint': (t) =>
          t._sentryFlutterOptionsBuilderCascadeNoLint(),
      'test_shadowedSdkOptionsMutationInCallback_noLint': (t) =>
          t._shadowedSdkOptionsMutationInCallbackNoLint(),
      'test_sentryFlutterOptionsCallbackReassignment_lint': (t) =>
          t._sentryFlutterOptionsCallbackReassignmentLint(),
      'test_sentryFlutterOptionsMutationOutsideBuilderCallback_lint': (t) =>
          t._sentryFlutterOptionsMutationOutsideBuilderCallbackLint(),
      'test_sentryFlutterOptionsMutationInDeferredClosure_lint': (t) =>
          t._sentryFlutterOptionsMutationInDeferredClosureLint(),
      'test_sentryFlutterOptionsCascadeMutationInDeferredClosure_lint': (t) =>
          t._sentryFlutterOptionsCascadeMutationInDeferredClosureLint(),
      'test_shadowedOptionsMutationInDeferredClosure_noLint': (t) =>
          t._shadowedOptionsMutationInDeferredClosureNoLint(),
      'test_localFakeSentryFlutterTypes_lint': (t) => t._localFakeSentryFlutterTypesLint(),
      'test_localMutation_noLint': (t) => t._localMutationNoLint(),
    },
  );
  analysisRuleSuite<ConsistentUpdateRenderObjectSharedWidgetTest>(
    'ConsistentUpdateRenderObjectSharedWidgetTest',
    ConsistentUpdateRenderObjectSharedWidgetTest.new,
    {
      'test_widgetThatWritesRenderObjectParameter_noLint': (t) =>
          t._widgetThatWritesRenderObjectParameterNoLint(),
    },
  );
  analysisRuleSuite<AvoidCollectionMutatingMethodsTest>(
    'AvoidCollectionMutatingMethodsTest',
    AvoidCollectionMutatingMethodsTest.new,
    {
      'test_globalCollectionMutation_lint': (t) => t._globalCollectionMutationLint(),
      'test_parameterCollectionMutation_lint': (t) => t._parameterCollectionMutationLint(),
      'test_localCollectionMutation_noLint': (t) => t._localCollectionMutationNoLint(),
    },
  );
}

const _flutterRenderObjectLibrary = r'''
class BuildContext {
  Object? tag;
}

class Widget {
  const Widget();
}

class RenderObject {}

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget();
}

abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget();

  RenderObject createRenderObject(BuildContext context);

  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) {}
}
''';

const _renderObjectWidgetSource = r'''
import 'package:flutter/widgets.dart';

class CounterRenderObject extends RenderObject {
  int count = 0;
}

class CounterWidget extends LeafRenderObjectWidget {
  const CounterWidget({required this.count});

  final int count;

  @override
  CounterRenderObject createRenderObject(BuildContext context) =>
      CounterRenderObject()..count = count;

  @override
  void updateRenderObject(BuildContext context, CounterRenderObject renderObject) {
    renderObject.count = count;
  }
}
''';

final class AvoidGlobalStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidGlobalState();
    super.setUp();
  }

  Future<void> _mutableStaticFieldLint() async {
    const source = r'''
class Cache {
  static var values = <int>[];
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('values'), 'values'.length)]);
  }

  Future<void> _mutableTopLevelVariableLint() async {
    const source = r'''
var attempts = 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('attempts'), 'attempts'.length)]);
  }

  Future<void> _finalAndLocalVariablesNoLint() async {
    await assertNoDiagnostics(r'''
final attempts = 0;

class Cache {
  static final values = <int>[];
}

void f() {
  var local = 0;
  local++;
}
''');
  }
}

final class AvoidMutatingParametersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addSentryFlutterPackage();
    newPackage('flutter').addFile('lib/widgets.dart', _flutterRenderObjectLibrary);
    rule = AvoidMutatingParameters();
    super.setUp();
  }

  Future<void> _updateRenderObjectWritesRenderObjectParameterNoLint() async {
    await assertNoDiagnostics(_renderObjectWidgetSource);
  }

  Future<void> _updateRenderObjectCascadeWritesRenderObjectParameterNoLint() async {
    await assertNoDiagnostics(
      _renderObjectWidgetSource.replaceFirst(
        'renderObject.count = count;',
        'renderObject..count = count;',
      ),
    );
  }

  Future<void> _updateRenderObjectReassignsRenderObjectParameterLint() async {
    final source = _renderObjectWidgetSource.replaceFirst(
      'renderObject.count = count;',
      'renderObject = CounterRenderObject();\n    renderObject.count = count;',
    );

    await assertDiagnostics(source, [
      lint(source.indexOf('renderObject = '), 'renderObject'.length),
    ]);
  }

  Future<void> _updateRenderObjectWritesContextParameterLint() async {
    final source = _renderObjectWidgetSource.replaceFirst(
      'renderObject.count = count;',
      'context.tag = count;',
    );

    await assertDiagnostics(source, [lint(source.indexOf('tag ='), 'tag'.length)]);
  }

  Future<void> _otherMethodWritesRenderObjectParameterLint() async {
    final source = _renderObjectWidgetSource.replaceFirst(
      '  @override\n  void updateRenderObject',
      '  void configure(BuildContext context, CounterRenderObject renderObject) {\n'
          '    renderObject.count = count;\n'
          '  }\n\n'
          '  @override\n  void updateRenderObject',
    );

    final write = source.indexOf('renderObject.count = count') + 'renderObject.'.length;
    await assertDiagnostics(source, [lint(write, 'count'.length)]);
  }

  Future<void> _updateRenderObjectOutsideRenderObjectWidgetLint() async {
    const source = r'''
class Holder {
  int count = 0;
}

class Updater {
  void updateRenderObject(Object context, Holder renderObject) {
    renderObject.count = 1;
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('count = 1'), 'count'.length)]);
  }

  Future<void> _assignmentToParameterLint() async {
    const source = r'''
void normalize(int value) {
  value = value.abs();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value ='), 'value'.length)]);
  }

  Future<void> _parameterPropertyWriteLint() async {
    const source = r'''
class User {
  String name = '';
}

void rename(User user) {
  user.name = 'Ada';
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('name ='), 'name'.length)]);
  }

  Future<void> _parameterCascadePropertyWriteLint() async {
    const source = r'''
class User {
  String name = '';
}

void rename(User user) {
  user..name = 'Ada';
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('name ='), 'name'.length)]);
  }

  Future<void> _shadowedLocalCascadeDoesNotMutateParameter() async {
    const source = r'''
class Options {
  int value = 0;
}

void configure(Options options) {
  {
    final options = Options();
    options..value = 1;
  }
}
''';

    await assertNoDiagnostics(source);
  }

  Future<void> _sentryFlutterOptionsBuilderCallbackNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options.transport = transport;
  });
}
''');
  }

  Future<void> _sentryFlutterOptionsBuilderCascadeNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options..transport = transport;
  });
}
''');
  }

  Future<void> _shadowedSdkOptionsMutationInCallbackNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    if (true) {
      final options = SentryFlutterOptions();
      options..transport = transport;
    }
  });
}
''');
  }

  Future<void> _sentryFlutterOptionsCallbackReassignmentLint() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options = SentryFlutterOptions();
    options.transport = transport;
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('options ='), 'options'.length)]);
  }

  Future<void> _sentryFlutterOptionsMutationOutsideBuilderCallbackLint() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void configureOptions(SentryFlutterOptions options, Object transport) {
  options.transport = transport;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('transport ='), 'transport'.length)]);
  }

  Future<void> _sentryFlutterOptionsMutationInDeferredClosureLint() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void scheduleLater(void Function() callback) {}

void initialize(Object transport) {
  SentryFlutter.init((options) {
    scheduleLater(() {
      options.transport = transport;
    });
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('transport ='), 'transport'.length)]);
  }

  Future<void> _sentryFlutterOptionsCascadeMutationInDeferredClosureLint() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void scheduleLater(void Function() callback) {}

void initialize(Object transport) {
  SentryFlutter.init((options) {
    scheduleLater(() {
      options..transport = transport;
    });
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('transport ='), 'transport'.length)]);
  }

  Future<void> _shadowedOptionsMutationInDeferredClosureNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void scheduleLater(void Function() callback) {}

void initialize(Object transport) {
  SentryFlutter.init((options) {
    scheduleLater(() {
      final options = SentryFlutterOptions();
      options.transport = transport;
    });
  });
}
''');
  }

  Future<void> _localFakeSentryFlutterTypesLint() async {
    const source = r'''
import 'dart:async';

typedef FlutterOptionsConfiguration = FutureOr<void> Function(SentryFlutterOptions);

class SentryFlutterOptions {
  Object? transport;
}

class SentryFlutter {
  static Future<void> init(FlutterOptionsConfiguration optionsConfiguration) async {}
}

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options.transport = transport;
  });
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('transport ='), 'transport'.length)]);
  }

  void _addSentryFlutterPackage() {
    final sentryFlutter = newPackage('sentry_flutter');
    sentryFlutter.addFile('lib/src/sentry_flutter_options.dart', r'''
class SentryFlutterOptions {
  Object? transport;
}
''');
    sentryFlutter.addFile('lib/src/sentry_flutter.dart', r'''
import 'dart:async';
import 'sentry_flutter_options.dart';

typedef FlutterOptionsConfiguration = FutureOr<void> Function(SentryFlutterOptions);

mixin SentryFlutter {
  static Future<void> init(FlutterOptionsConfiguration optionsConfiguration) async {}
}
''');
    sentryFlutter.addFile('lib/sentry_flutter.dart', r'''
export 'src/sentry_flutter.dart';
export 'src/sentry_flutter_options.dart';
''');
  }

  Future<void> _localMutationNoLint() async {
    await assertNoDiagnostics(r'''
void normalize(int value) {
  var local = value;
  local++;
}
''');
  }
}

final class ConsistentUpdateRenderObjectSharedWidgetTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', _flutterRenderObjectLibrary);
    rule = ConsistentUpdateRenderObject();
    super.setUp();
  }

  Future<void> _widgetThatWritesRenderObjectParameterNoLint() async {
    await assertNoDiagnostics(_renderObjectWidgetSource);
  }
}

final class AvoidCollectionMutatingMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMutatingMethods();
    super.setUp();
  }

  Future<void> _globalCollectionMutationLint() async {
    const source = r'''
final values = <int>[];

void store(int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> _parameterCollectionMutationLint() async {
    const source = r'''
void store(List<int> values, int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> _localCollectionMutationNoLint() async {
    await assertNoDiagnostics(r'''
void store(int value) {
  final values = <int>[];
  values.add(value);
}
''');
  }
}
