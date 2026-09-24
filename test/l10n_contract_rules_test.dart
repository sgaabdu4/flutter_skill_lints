// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/l10n_contract_rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(L10nStringConcatenationTest);
    defineReflectiveTests(L10nNotifierLocalizedCopyTest);
  });
}

const _appLocalizations = r'''
import 'package:flutter/widgets.dart';

abstract class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = _Delegate();

  String get title;
  String get subtitle;
  String itemCount(int count);
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
}
''';

abstract class _L10nRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}
class Text extends Widget {
  const Text(String data);
}
abstract class LocalizationsDelegate<T> {
  const LocalizationsDelegate();
}
''');
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class AnyNotifier<StateT, ValueT> {
  StateT get state => throw UnimplementedError();
  set state(StateT value) {}
}
abstract class Notifier<StateT> extends AnyNotifier<StateT, StateT> {
  StateT build();
}
abstract class AsyncNotifier<StateT> extends AnyNotifier<Object, StateT> {
  Future<StateT> build();
}
final class AsyncData<T> {
  const AsyncData(T value);
}
''');
    newFile('$testPackageLibPath/l10n/app_localizations.dart', _appLocalizations);
    super.setUp();
  }
}

@reflectiveTest
final class L10nStringConcatenationTest extends _L10nRuleTest {
  @override
  void setUp() {
    rule = L10nStringConcatenation();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(L10nStringConcatenation.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_reportsPlusConcatenation() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:test/l10n/app_localizations.dart';

Widget header(AppLocalizations l10n) => Text(l10n.title + l10n.subtitle);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('l10n.title +'), 'l10n.title + l10n.subtitle'.length),
    ]);
  }

  Future<void> test_reportsInterpolationWithOtherText() async {
    const source = r'''
import 'package:flutter/widgets.dart';
import 'package:test/l10n/app_localizations.dart';

Widget header(AppLocalizations l10n, int count) => Text('${l10n.title}: $count items');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'\${l10n"), r"'${l10n.title}: $count items'".length),
    ]);
  }

  Future<void> test_allowsPlaceholderMessage() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
import 'package:test/l10n/app_localizations.dart';

Widget header(AppLocalizations l10n, int count) => Text(l10n.itemCount(count));
''');
  }

  Future<void> test_allowsConcatenationWithoutLocalizedStrings() async {
    await assertNoDiagnostics(r'''
String label(String first, String last) => first + ' ' + last + '${first.length}';
''');
  }

  Future<void> test_allowsLookalikeClassWithoutDelegate() async {
    await assertNoDiagnostics(r'''
class AppLocalizations {
  String get title => 'Title';
}

String label(AppLocalizations l10n) => l10n.title + '!';
''');
  }
}

@reflectiveTest
final class L10nNotifierLocalizedCopyTest extends _L10nRuleTest {
  @override
  void setUp() {
    rule = L10nNotifierLocalizedCopy();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(L10nNotifierLocalizedCopy.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_reportsCopyReturnedFromBuildAndAssignedToState() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class GreetingNotifier extends Notifier<String> {
  @override
  String build() => 'Welcome back!';

  void saved(bool ok) => state = ok ? 'Your order was saved' : '';
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Welcome back!'"), "'Welcome back!'".length),
      lint(source.indexOf("'Your order was saved'"), "'Your order was saved'".length),
    ]);
  }

  Future<void> test_reportsAsyncDataAndLabelledStateCopy() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final class Banner {
  const Banner({required this.message, required this.code});
  final String message;
  final String code;
}

class BannerNotifier extends AsyncNotifier<Banner> {
  @override
  Future<Banner> build() async {
    return const Banner(message: 'Sync failed', code: 'sync_failed');
  }

  void retry() => state = const AsyncData(Banner(message: 'Retrying', code: 'retry'));
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf("'Sync failed'"), "'Sync failed'".length),
      lint(source.indexOf("'Retrying'"), "'Retrying'".length),
    ]);
  }

  Future<void> test_reportsLocalizedReadInNotifier() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';
import 'package:test/l10n/app_localizations.dart';

class TitleNotifier extends Notifier<String> {
  TitleNotifier(this.l10n);
  final AppLocalizations l10n;

  @override
  String build() => l10n.title;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('title;'), 'title'.length)]);
  }

  Future<void> test_allowsSemanticState() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

enum InviteStatus { pending, accepted }

class InviteNotifier extends Notifier<InviteStatus> {
  @override
  InviteStatus build() => InviteStatus.pending;

  void accept() {
    final reason = 'Accepted by user';
    state = InviteStatus.accepted;
  }
}
''');
  }

  Future<void> test_allowsCopyOutsideNotifiers() async {
    await assertNoDiagnostics(r'''
class GreetingFormatter {
  String build() => 'Welcome back!';
}
''');
  }
}
