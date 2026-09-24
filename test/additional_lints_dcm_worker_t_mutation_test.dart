// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_collection_mutating_methods.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_global_state.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_mutating_parameters.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidGlobalStateTest);
    defineReflectiveTests(AvoidMutatingParametersTest);
    defineReflectiveTests(AvoidCollectionMutatingMethodsTest);
  });
}

@reflectiveTest
final class AvoidGlobalStateTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidGlobalState();
    super.setUp();
  }

  Future<void> test_mutableStaticField_lint() async {
    const source = r'''
class Cache {
  static var values = <int>[];
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('values'), 'values'.length)]);
  }

  Future<void> test_mutableTopLevelVariable_lint() async {
    const source = r'''
var attempts = 0;
''';

    await assertDiagnostics(source, [lint(source.indexOf('attempts'), 'attempts'.length)]);
  }

  Future<void> test_finalAndLocalVariables_noLint() async {
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

@reflectiveTest
final class AvoidMutatingParametersTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addSentryFlutterPackage();
    rule = AvoidMutatingParameters();
    super.setUp();
  }

  Future<void> test_assignmentToParameter_lint() async {
    const source = r'''
void normalize(int value) {
  value = value.abs();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('value ='), 'value'.length)]);
  }

  Future<void> test_parameterPropertyWrite_lint() async {
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

  Future<void> test_parameterCascadePropertyWrite_lint() async {
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

  Future<void> test_shadowedLocalCascadeDoesNotMutateParameter() async {
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

  Future<void> test_sentryFlutterOptionsBuilderCallback_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options.transport = transport;
  });
}
''');
  }

  Future<void> test_sentryFlutterOptionsBuilderCascade_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void initialize(Object transport) {
  SentryFlutter.init((options) {
    options..transport = transport;
  });
}
''');
  }

  Future<void> test_shadowedSdkOptionsMutationInCallback_noLint() async {
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

  Future<void> test_sentryFlutterOptionsCallbackReassignment_lint() async {
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

  Future<void> test_sentryFlutterOptionsMutationOutsideBuilderCallback_lint() async {
    const source = r'''
import 'package:sentry_flutter/sentry_flutter.dart';

void configureOptions(SentryFlutterOptions options, Object transport) {
  options.transport = transport;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('transport ='), 'transport'.length)]);
  }

  Future<void> test_sentryFlutterOptionsMutationInDeferredClosure_lint() async {
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

  Future<void> test_sentryFlutterOptionsCascadeMutationInDeferredClosure_lint() async {
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

  Future<void> test_shadowedOptionsMutationInDeferredClosure_noLint() async {
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

  Future<void> test_localFakeSentryFlutterTypes_lint() async {
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

  Future<void> test_localMutation_noLint() async {
    await assertNoDiagnostics(r'''
void normalize(int value) {
  var local = value;
  local++;
}
''');
  }
}

@reflectiveTest
final class AvoidCollectionMutatingMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidCollectionMutatingMethods();
    super.setUp();
  }

  Future<void> test_globalCollectionMutation_lint() async {
    const source = r'''
final values = <int>[];

void store(int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> test_parameterCollectionMutation_lint() async {
    const source = r'''
void store(List<int> values, int value) {
  values.add(value);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('add'), 'add'.length)]);
  }

  Future<void> test_localCollectionMutation_noLint() async {
    await assertNoDiagnostics(r'''
void store(int value) {
  final values = <int>[];
  values.add(value);
}
''');
  }
}
