import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_context.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_existing_future_to_future_builder.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_existing_stream_to_stream_builder.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidLateContextTest>(
    'AvoidLateContextTest',
    _AvoidLateContextTest.new,
    _AvoidLateContextTest._allCases,
  );
  analysisRuleSuite<_PassExistingFutureToFutureBuilderTest>(
    'PassExistingFutureToFutureBuilderTest',
    _PassExistingFutureToFutureBuilderTest.new,
    _PassExistingFutureToFutureBuilderTest._allCases,
  );
  analysisRuleSuite<_PassExistingStreamToStreamBuilderTest>(
    'PassExistingStreamToStreamBuilderTest',
    _PassExistingStreamToStreamBuilderTest.new,
    _PassExistingStreamToStreamBuilderTest._allCases,
  );
}

abstract class _FlutterLifecycleRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

class BuildContext {}

class AsyncSnapshot<T> {}

typedef AsyncWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
);

class FutureBuilder<T> extends Widget {
  const FutureBuilder({
    Future<T>? future,
    required AsyncWidgetBuilder<T> builder,
  });
}

class StreamBuilder<T> extends Widget {
  const StreamBuilder({
    Stream<T>? stream,
    required AsyncWidgetBuilder<T> builder,
  });
}
''');
  }
}

final class _AvoidLateContextTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_AvoidLateContextTest)> get _allCases =>
      caseSet<_AvoidLateContextTest>(
        parent: const {},
        own: {
          'test_lateBuildContextField_lint': (t) => t._lateBuildContextFieldLint(),
          'test_lateBuildContextLocal_lint': (t) => t._lateBuildContextLocalLint(),
          'test_eagerBuildContext_noLint': (t) => t._eagerBuildContextNoLint(),
          'test_lateNonContext_noLint': (t) => t._lateNonContextNoLint(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLateContext();
    super.setUp();
  }

  Future<void> _lateBuildContextFieldLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late BuildContext context;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('context;'), 'context'.length)]);
  }

  Future<void> _lateBuildContextLocalLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void f() {
  late final BuildContext context;
  context = BuildContext();
  print(context);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('context;'), 'context'.length)]);
  }

  Future<void> _eagerBuildContextNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f(BuildContext context) {
  final current = context;
  print(current);
}
''');
  }

  Future<void> _lateNonContextNoLint() async {
    await assertNoDiagnostics(r'''
void f() {
  late final int value;
  value = 1;
  print(value);
}
''');
  }
}

final class _PassExistingFutureToFutureBuilderTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_PassExistingFutureToFutureBuilderTest)> get _allCases =>
      caseSet<_PassExistingFutureToFutureBuilderTest>(
        parent: const {},
        own: {
          'test_methodInvocationFuture_lint': (t) => t._methodInvocationFutureLint(),
          'test_futureConstructor_lint': (t) => t._futureConstructorLint(),
          'test_existingFuture_noLint': (t) => t._existingFutureNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PassExistingFutureToFutureBuilder();
    super.setUp();
  }

  Future<void> _methodInvocationFutureLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<int> load() async => 1;

Widget build() {
  return FutureBuilder<int>(
    future: load(),
    builder: (context, snapshot) => const Widget(),
  );
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('load()'), 'load()'.length)]);
  }

  Future<void> _futureConstructorLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FutureBuilder<int>(
    future: Future<int>.value(1),
    builder: (context, snapshot) => const Widget(),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Future<int>.value(1)'), 'Future<int>.value(1)'.length),
    ]);
  }

  Future<void> _existingFutureNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final future = Future<int>.value(1);

Widget build() {
  return FutureBuilder<int>(
    future: future,
    builder: (context, snapshot) => const Widget(),
  );
}
''');
  }
}

final class _PassExistingStreamToStreamBuilderTest extends _FlutterLifecycleRuleTest {
  static Map<String, Future<void> Function(_PassExistingStreamToStreamBuilderTest)> get _allCases =>
      caseSet<_PassExistingStreamToStreamBuilderTest>(
        parent: const {},
        own: {
          'test_methodInvocationStream_lint': (t) => t._methodInvocationStreamLint(),
          'test_streamConstructor_lint': (t) => t._streamConstructorLint(),
          'test_existingStream_noLint': (t) => t._existingStreamNoLint(),
        },
      );

  @override
  void setUp() {
    rule = PassExistingStreamToStreamBuilder();
    super.setUp();
  }

  Future<void> _methodInvocationStreamLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Stream<int> watch() async* {
  yield 1;
}

Widget build() {
  return StreamBuilder<int>(
    stream: watch(),
    builder: (context, snapshot) => const Widget(),
  );
}
''';

    await assertDiagnostics(source, [lint(source.lastIndexOf('watch()'), 'watch()'.length)]);
  }

  Future<void> _streamConstructorLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return StreamBuilder<int>(
    stream: Stream<int>.value(1),
    builder: (context, snapshot) => const Widget(),
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Stream<int>.value(1)'), 'Stream<int>.value(1)'.length),
    ]);
  }

  Future<void> _existingStreamNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final stream = Stream<int>.value(1);

Widget build() {
  return StreamBuilder<int>(
    stream: stream,
    builder: (context, snapshot) => const Widget(),
  );
}
''');
  }
}
