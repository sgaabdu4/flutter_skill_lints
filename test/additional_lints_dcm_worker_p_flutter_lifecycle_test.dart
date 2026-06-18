// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_late_context.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_existing_future_to_future_builder.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/pass_existing_stream_to_stream_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidLateContextTest);
    defineReflectiveTests(PassExistingFutureToFutureBuilderTest);
    defineReflectiveTests(PassExistingStreamToStreamBuilderTest);
  });
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

@reflectiveTest
final class AvoidLateContextTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = AvoidLateContext();
    super.setUp();
  }

  Future<void> test_lateBuildContextField_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late BuildContext context;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('context;'), 'context'.length)]);
  }

  Future<void> test_lateBuildContextLocal_lint() async {
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

  Future<void> test_eagerBuildContext_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f(BuildContext context) {
  final current = context;
  print(current);
}
''');
  }

  Future<void> test_lateNonContext_noLint() async {
    await assertNoDiagnostics(r'''
void f() {
  late final int value;
  value = 1;
  print(value);
}
''');
  }
}

@reflectiveTest
final class PassExistingFutureToFutureBuilderTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = PassExistingFutureToFutureBuilder();
    super.setUp();
  }

  Future<void> test_methodInvocationFuture_lint() async {
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

  Future<void> test_futureConstructor_lint() async {
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

  Future<void> test_existingFuture_noLint() async {
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

@reflectiveTest
final class PassExistingStreamToStreamBuilderTest extends _FlutterLifecycleRuleTest {
  @override
  void setUp() {
    rule = PassExistingStreamToStreamBuilder();
    super.setUp();
  }

  Future<void> test_methodInvocationStream_lint() async {
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

  Future<void> test_streamConstructor_lint() async {
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

  Future<void> test_existingStream_noLint() async {
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
