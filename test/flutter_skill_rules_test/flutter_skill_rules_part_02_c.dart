part of '../flutter_skill_rules_test.dart';

final class _UseUnawaitedForFireAndForgetFuturesTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseUnawaitedForFireAndForgetFuturesTest)>
  get _allCases => caseSet<_UseUnawaitedForFireAndForgetFuturesTest>(
    parent: const {},
    own: {
      'test_reportsFutureDroppedFromVoidCallback': (t) => t._reportsFutureDroppedFromVoidCallback(),
      'test_reportsFutureDroppedFromNullableNamedVoidCallback': (t) =>
          t._reportsFutureDroppedFromNullableNamedVoidCallback(),
      'test_allowsFutureFromNamedFutureCallback': (t) => t._allowsFutureFromNamedFutureCallback(),
      'test_allowsUnawaitedFutureFromVoidCallback': (t) =>
          t._allowsUnawaitedFutureFromVoidCallback(),
      'test_allowsAwaitedFutureFromAsyncCallback': (t) => t._allowsAwaitedFutureFromAsyncCallback(),
    },
  );

  @override
  void setUp() {
    rule = UseUnawaitedForFireAndForgetFutures();
    super.setUp();
  }

  Future<void> _reportsFutureDroppedFromVoidCallback() async {
    const source = r'''
import 'dart:async';

typedef VoidCallback = void Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(VoidCallback onPressed) {}

void example() {
  build(() {
    showDialogBottomSheet<void>();
  });
}
''';

    await assertDiagnostics(source, [lintFor(source, 'showDialogBottomSheet<void>()')]);
  }

  Future<void> _reportsFutureDroppedFromNullableNamedVoidCallback() async {
    const source = r'''
Future<void> trackTap() async {}

class TextButton {
  const TextButton({this.onPressed});

  final void Function()? onPressed;
}

TextButton example() {
  return TextButton(
    onPressed: () {
      trackTap();
    },
  );
}
''';

    await assertDiagnostics(source, [lintForLast(source, 'trackTap()')]);
  }

  Future<void> _allowsFutureFromNamedFutureCallback() async {
    await assertNoDiagnostics(r'''
Future<void> trackTap() async {}

class AsyncButton {
  const AsyncButton({this.onPressed});

  final Future<void> Function()? onPressed;
}

AsyncButton example() {
  return AsyncButton(
    onPressed: () {
      return trackTap();
    },
  );
}
''');
  }

  Future<void> _allowsUnawaitedFutureFromVoidCallback() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

typedef VoidCallback = void Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(VoidCallback onPressed) {}

void example() {
  build(() {
    unawaited(showDialogBottomSheet<void>());
  });
}
''');
  }

  Future<void> _allowsAwaitedFutureFromAsyncCallback() async {
    await assertNoDiagnostics(r'''
typedef AsyncCallback = Future<void> Function();

Future<void> showDialogBottomSheet<T>() async {}

void build(AsyncCallback onPressed) {}

void example() {
  build(() async {
    await showDialogBottomSheet<void>();
  });
}
''');
  }
}

void _defineFlutterSkillRulesPart02CTests() {
  analysisRuleSuite<_UseUnawaitedForFireAndForgetFuturesTest>(
    'UseUnawaitedForFireAndForgetFuturesTest',
    _UseUnawaitedForFireAndForgetFuturesTest.new,
    _UseUnawaitedForFireAndForgetFuturesTest._allCases,
  );
}
