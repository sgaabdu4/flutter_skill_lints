part of '../flutter_skill_rules_test.dart';

final class _AvoidPrivateWidgetClassesTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidPrivateWidgetClassesTest)> get _allCases =>
      caseSet<_AvoidPrivateWidgetClassesTest>(
        parent: const {},
        own: {
          'test_reportsPrivateStatelessWidget': (t) => t._reportsPrivateStatelessWidget(),
          'test_allowsPublicWidgetClasses': (t) => t._allowsPublicWidgetClasses(),
          'test_allowsPrivateStateSubclasses': (t) => t._allowsPrivateStateSubclasses(),
          'test_allowsPrivateWidgetClassesInTestFiles': (t) =>
              t._allowsPrivateWidgetClassesInTestFiles(),
          'test_reportsPrivateWidgetClassesInPartFiles': (t) =>
              t._reportsPrivateWidgetClassesInPartFiles(),
        },
      );

  @override
  void setUp() {
    rule = AvoidPrivateWidgetClasses();
    super.setUp();
  }

  Future<void> _reportsPrivateStatelessWidget() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class _PrivateCard extends StatelessWidget {
  const _PrivateCard();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';

    await assertDiagnostics(source, [lintFor(source, '_PrivateCard')]);
  }

  Future<void> _allowsPublicWidgetClasses() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class PublicCard extends StatelessWidget {
  const PublicCard();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  Future<void> _allowsPrivateStateSubclasses() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class PublicCard extends StatefulWidget {
  const PublicCard();
}

class _PublicCardState extends State<PublicCard> {}
''');
  }

  Future<void> _allowsPrivateWidgetClassesInTestFiles() async {
    final filePath = '$testPackageRootPath/test/widgets/widget_harness_test.dart';
    newFile(filePath, r'''
import 'package:flutter/widgets.dart';

class _Harness extends StatelessWidget {
  const _Harness();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> _reportsPrivateWidgetClassesInPartFiles() async {
    newFile('$testPackageLibPath/widgets/sheet.dart', r'''
import 'package:flutter/widgets.dart';

part 'sheet_content.dart';

class Sheet extends StatelessWidget {
  const Sheet();

  @override
  Widget build(BuildContext context) => const _SheetContent();
}
''');

    const source = r'''
part of 'sheet.dart';

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''';
    final partPath = '$testPackageLibPath/widgets/sheet_content.dart';
    newFile(partPath, source);

    await assertDiagnosticsInFile(partPath, [lintFor(source, '_SheetContent')]);
  }
}

final class _UseContextMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseContextMountedAfterAwaitTest)> get _allCases =>
      caseSet<_UseContextMountedAfterAwaitTest>(
        parent: const {},
        own: {
          'test_reportsContextAfterAwait': (t) => t._reportsContextAfterAwait(),
          'test_allowsMountedGuard': (t) => t._allowsMountedGuard(),
          'test_reportsStateContextMountedGuardAfterAwait': (t) =>
              t._reportsStateContextMountedGuardAfterAwait(),
          'test_reportsExplicitStateContextMountedGuardAfterAwait': (t) =>
              t._reportsExplicitStateContextMountedGuardAfterAwait(),
          'test_allowsCapturedStateContextMountedGuardAfterAwait': (t) =>
              t._allowsCapturedStateContextMountedGuardAfterAwait(),
          'test_reportsContextAfterAwaitInAsyncCallback': (t) =>
              t._reportsContextAfterAwaitInAsyncCallback(),
          'test_reportsContextAfterAwaitInNestedBlocks': (t) =>
              t._reportsContextAfterAwaitInNestedBlocks(),
          'test_allowsGuardsInNestedBlocksAndSkillExamples': (t) =>
              t._allowsGuardsInNestedBlocksAndSkillExamples(),
        },
      );

  @override
  void setUp() {
    rule = UseContextMountedAfterAwait();
    super.setUp();
  }

  Future<void> _reportsContextAfterAwait() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> _allowsMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  if (!context.mounted) return;
  context.pop();
}
''');
  }

  Future<void> _reportsStateContextMountedGuardAfterAwait() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {
  const Demo();
}

class DemoState extends State<Demo> {
  Future<void> load() async {
    await Future<void>.value();
    if (!context.mounted) return;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.mounted')]);
  }

  Future<void> _reportsExplicitStateContextMountedGuardAfterAwait() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {
  const Demo();
}

class DemoState extends State<Demo> {
  Future<void> load() async {
    await Future<void>.value();
    if (!this.context.mounted) return;
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'this.context.mounted')]);
  }

  Future<void> _allowsCapturedStateContextMountedGuardAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Demo extends StatefulWidget {
  const Demo();
}

class DemoState extends State<Demo> {
  Future<void> load() async {
    final context = this.context;
    await Future<void>.value();
    if (!context.mounted) return;
  }
}
''');
  }

  Future<void> _reportsContextAfterAwaitInAsyncCallback() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void showDone(BuildContext context) {}

class Tap extends StatelessWidget {
  const Tap({required this.onTap, required this.onLongPress});
  final Future<void> Function() onTap;
  final Future<void> Function() onLongPress;
  @override
  Widget build(BuildContext context) => this;
}

class Demo extends StatelessWidget {
  const Demo();

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: () async {
        await Future<void>.value();
        showDone(context);
      },
      onLongPress: () async {
        await Future<void>.value();
        if (!context.mounted) return;
        showDone(context);
      },
    );
  }
}
''';
    await assertDiagnostics(source, [lint(source.indexOf('context);'), 7)]);
  }

  Future<void> _reportsContextAfterAwaitInNestedBlocks() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void showDone(BuildContext context) {}

Future<void> afterIf(BuildContext context, bool ok) async {
  await Future<void>.value();
  if (ok) {
    showDone(context /* if */);
  }
}

Future<void> insideTry(BuildContext context) async {
  try {
    await Future<void>.value();
    showDone(context /* try */);
  } catch (_) {
    showDone(context /* catch */);
  }
}

Future<void> nextIteration(BuildContext context, List<int> ids) async {
  for (final _ in ids) {
    showDone(context /* loop */);
    await Future<void>.value();
  }
}

Future<void> awaitInBranch(BuildContext context, bool ok) async {
  if (ok) {
    await Future<void>.value();
  }
  showDone(context /* branch */);
}

class Demo extends StatefulWidget {
  const Demo();
}

class DemoState extends State<Demo> {
  Future<void> load(bool ok) async {
    await Future<void>.value();
    if (ok) {
      if (!context.mounted) return;
    }
  }

  Future<void> swapToStateMounted() async {
    await Future<void>.value();
    if (!mounted) return;
    showDone(context /* state */);
  }
}
''';
    await assertDiagnostics(source, [
      for (final marker in ['if', 'try', 'catch', 'loop', 'branch'])
        lint(source.indexOf('context /* $marker */'), 7),
      lintFor(source, 'context.mounted'),
      lint(source.indexOf('context /* state */'), 7),
    ]);
  }

  Future<void> _allowsGuardsInNestedBlocksAndSkillExamples() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void showDone(BuildContext context) {}
void showSheet({required BuildContext context}) {}
Future<bool?> confirm() async => true;

enum CreateChoice { exercise, workout }

Future<CreateChoice?> pick() async => null;

Future<void> openCreateSheet(BuildContext context) async {
  final choice = await pick();
  if (!context.mounted || choice != CreateChoice.exercise) return;
  showDone(context);
}

Future<void> confirmDelete(BuildContext context) async {
  final confirmed = await confirm();
  if (confirmed != true || !context.mounted) return;
  showDone(context);
}

Future<void> positiveGuard(BuildContext context) async {
  final ok = await confirm();
  if (ok == true && context.mounted) {
    showDone(context);
  }
}

Future<void> guardedTry(BuildContext context) async {
  try {
    await Future<void>.value();
    if (!context.mounted) return;
    showDone(context);
  } catch (_) {
    if (!context.mounted) return;
    showDone(context);
  }
}

Future<void> guardedLoop(BuildContext context, List<int> ids) async {
  for (final _ in ids) {
    await Future<void>.value();
    if (!context.mounted) return;
    showDone(context);
  }
}

Future<void> namedArgumentLabel(BuildContext context, BuildContext sheetContext) async {
  await Future<void>.value();
  if (!sheetContext.mounted) return;
  showSheet(context: sheetContext);
}
''');
  }
}

final class _AvoidLegacyRiverpodApisTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidLegacyRiverpodApisTest)> get _allCases =>
      caseSet<_AvoidLegacyRiverpodApisTest>(
        parent: const {},
        own: {
          'test_reportsLegacyProvider': (t) => t._reportsLegacyProvider(),
          'test_allowsUnifiedRef': (t) => t._allowsUnifiedRef(),
          'test_reportsLegacyImportAndStateNotifier': (t) =>
              t._reportsLegacyImportAndStateNotifier(),
          'test_reportsRiverpodLegacyImport': (t) => t._reportsRiverpodLegacyImport(),
          'test_reportsRefAliasAndLegacyRefTypes': (t) => t._reportsRefAliasAndLegacyRefTypes(),
          'test_allowsUserTypesNamedLikeRiverpodApis': (t) =>
              t._allowsUserTypesNamedLikeRiverpodApis(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

  @override
  void setUp() {
    rule = AvoidLegacyRiverpodApis();
    super.setUp();
  }

  Future<void> _reportsLegacyProvider() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final counterProvider = StateProvider<int>((ref) => 0);
''';
    await assertDiagnostics(source, [lintFor(source, 'StateProvider<int>')]);
  }

  Future<void> _allowsUnifiedRef() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

int load(Ref ref) => ref.read(Object());
''');
  }

  Future<void> _reportsLegacyImportAndStateNotifier() async {
    const source = r'''
import 'package:flutter_riverpod/legacy.dart';

class Counter extends StateNotifier<int> {
  Counter() : super(0);
}
''';
    await assertDiagnostics(source, [
      lintFor(source, "'package:flutter_riverpod/legacy.dart'"),
      lintFor(source, 'StateNotifier<int>'),
    ]);
  }

  Future<void> _reportsRiverpodLegacyImport() async {
    const source = r'''
import 'package:riverpod/legacy.dart';

StateNotifier<int>? counter;
''';
    await assertDiagnostics(source, [
      lintFor(source, "'package:riverpod/legacy.dart'"),
      lintFor(source, 'StateNotifier<int>?'),
    ]);
  }

  Future<void> _reportsRefAliasAndLegacyRefTypes() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

typedef GreetingRef = Ref;

String greeting(GreetingRef ref) => 'Hello';
String legacy(AutoDisposeRef ref) => 'Hello';
''';
    await assertDiagnostics(source, [
      lintForLast(source, 'GreetingRef'),
      lintFor(source, 'AutoDisposeRef'),
    ]);
  }

  Future<void> _allowsUserTypesNamedLikeRiverpodApis() async {
    await assertNoDiagnostics(r'''
class Provider<T> {
  Provider(T value);
}

class ImageRef {}

class StateNotifier<T> {}

final provider = Provider<int>(1);
ImageRef? image;
StateNotifier<int>? notifier;
''');
  }

  Future<void> _severityIsError() async {
    expect(AvoidLegacyRiverpodApis.code.severity, DiagnosticSeverity.ERROR);
  }
}

final class _AvoidDynamicExceptJsonMapsTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidDynamicExceptJsonMapsTest)> get _allCases =>
      caseSet<_AvoidDynamicExceptJsonMapsTest>(
        parent: const {},
        own: {
          'test_reportsBareDynamic': (t) => t._reportsBareDynamic(),
          'test_allowsJsonMapDynamic': (t) => t._allowsJsonMapDynamic(),
          'test_allowsJsonMapCastDynamic': (t) => t._allowsJsonMapCastDynamic(),
          'test_allowsJsonMapLiteralDynamic': (t) => t._allowsJsonMapLiteralDynamic(),
          'test_reportsNonJsonLiteralDynamic': (t) => t._reportsNonJsonLiteralDynamic(),
          'test_reportsUntypedRuntimeBoundaryDynamic': (t) =>
              t._reportsUntypedRuntimeBoundaryDynamic(),
          'test_allowsGeneratedLocalizationsDynamic': (t) =>
              t._allowsGeneratedLocalizationsDynamic(),
        },
      );

  @override
  void setUp() {
    rule = AvoidDynamicExceptJsonMaps();
    super.setUp();
  }

  Future<void> _reportsBareDynamic() async {
    const source = r'''
dynamic value;
Map<String, dynamic> json = {};
''';
    await assertDiagnostics(source, [lintFor(source, 'dynamic')]);
  }

  Future<void> _allowsJsonMapDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;
''');
  }

  Future<void> _allowsJsonMapCastDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, Object?> normalize(Map<String, Object?> json) {
  return json.cast<String, dynamic>();
}

Map<String, dynamic> emptyPrefs() {
  return const <String, Object?>{}.cast<String, dynamic>();
}
''');
  }

  // hive-persistence.md:56: `<String, dynamic>{}` is a JSON map literal.
  Future<void> _allowsJsonMapLiteralDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> normalizePersistedMap(Map<Object?, Object?> raw) {
  final normalized = <String, dynamic>{};
  for (final entry in raw.entries) {
    normalized['${entry.key}'] = entry.value;
  }
  return normalized;
}
''');
  }

  Future<void> _reportsNonJsonLiteralDynamic() async {
    const source = r'''
final byId = <int, dynamic>{};
final items = <dynamic>[];
''';
    await assertDiagnostics(source, [
      lint(source.indexOf('dynamic>{'), 'dynamic'.length),
      lint(source.indexOf('dynamic>['), 'dynamic'.length),
    ]);
  }

  Future<void> _reportsUntypedRuntimeBoundaryDynamic() async {
    final filePath = '$testPackageRootPath/functions/shared/lib/http.dart';
    const source = r'''
Object handle(dynamic req, dynamic context) {
  final dynamic body = req.bodyJson;
  return context.res.json(body);
}
''';
    newFile(filePath, source);

    await assertDiagnosticsInFile(filePath, [
      lint(source.indexOf('dynamic req'), 'dynamic'.length),
      lint(source.indexOf('dynamic context'), 'dynamic'.length),
      lint(source.indexOf('dynamic body'), 'dynamic'.length),
    ]);
  }

  Future<void> _allowsGeneratedLocalizationsDynamic() async {
    final filePath = '$testPackageLibPath/l10n/app_localizations.dart';
    const source = r'''
class LocalizationsDelegate<T> {}

abstract class AppLocalizations {
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[];
}
''';
    newFile(filePath, source);

    await assertNoDiagnosticsInFile(filePath);
  }
}

final class _AvoidNullBangTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidNullBangTest)> get _allCases =>
      caseSet<_AvoidNullBangTest>(
        parent: const {},
        own: {
          'test_reportsNullBang': (t) => t._reportsNullBang(),
          'test_allowsNullCheck': (t) => t._allowsNullCheck(),
        },
      );

  @override
  void setUp() {
    rule = AvoidNullBang();
    super.setUp();
  }

  Future<void> _reportsNullBang() async {
    const source = r'''
void f(String? value) {
  value!;
}
''';
    await assertDiagnostics(source, [lintFor(source, '!')]);
  }

  Future<void> _allowsNullCheck() async {
    await assertNoDiagnostics(r'''
void f(String? value) {
  if (value case final text?) {
    text.length;
  }
}
''');
  }
}

final class _AvoidWidgetBuildHelpersTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidWidgetBuildHelpersTest)> get _allCases =>
      caseSet<_AvoidWidgetBuildHelpersTest>(
        parent: const {},
        own: {
          'test_reportsBuildHelper': (t) => t._reportsBuildHelper(),
          'test_allowsNamedWidgetClass': (t) => t._allowsNamedWidgetClass(),
        },
      );

  @override
  void setUp() {
    rule = AvoidWidgetBuildHelpers();
    super.setUp();
  }

  Future<void> _reportsBuildHelper() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) => _buildTitle();

  Widget _buildTitle() => const SizedBox();
}
''';
    await assertDiagnostics(source, [lintForLast(source, '_buildTitle')]);
  }

  Future<void> _allowsNamedWidgetClass() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class ScreenTitle extends StatelessWidget {
  const ScreenTitle();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }
}

final class _AvoidShrinkWrapTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_AvoidShrinkWrapTest)> get _allCases =>
      caseSet<_AvoidShrinkWrapTest>(
        parent: const {},
        own: {
          'test_reportsShrinkWrapTrue': (t) => t._reportsShrinkWrapTrue(),
          'test_allowsDefaultListView': (t) => t._allowsDefaultListView(),
        },
      );

  @override
  void setUp() {
    rule = AvoidShrinkWrap();
    super.setUp();
  }

  Future<void> _reportsShrinkWrapTrue() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final widget = ListView(shrinkWrap: true);
''';
    await assertDiagnostics(source, [lintFor(source, 'shrinkWrap: true')]);
  }

  Future<void> _allowsDefaultListView() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final widget = ListView();
''');
  }
}

final class _GuardContextPopTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_GuardContextPopTest)> get _allCases =>
      caseSet<_GuardContextPopTest>(
        parent: const {},
        own: {
          'test_reportsUnguardedPop': (t) => t._reportsUnguardedPop(),
          'test_allowsCanPopGuardWithTypedFallback': (t) => t._allowsCanPopGuardWithTypedFallback(),
        },
      );

  @override
  void setUp() {
    rule = GuardContextPop();
    super.setUp();
  }

  Future<void> _reportsUnguardedPop() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void close(BuildContext context) {
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> _allowsCanPopGuardWithTypedFallback() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class ProductListRoute {
  const ProductListRoute();
  void go(BuildContext context) {}
}

void close(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  const ProductListRoute().go(context);
}
''');
  }
}

final class _UseRefInvalidateTest extends _FlutterSkillRuleTest {
  static Map<String, Future<void> Function(_UseRefInvalidateTest)> get _allCases =>
      caseSet<_UseRefInvalidateTest>(
        parent: const {},
        own: {
          'test_reportsIgnoredRefresh': (t) => t._reportsIgnoredRefresh(),
          'test_allowsUsedRefreshResult': (t) => t._allowsUsedRefreshResult(),
          'test_severityIsError': (t) => t._severityIsError(),
        },
      );

  @override
  void setUp() {
    rule = UseRefInvalidate();
    super.setUp();
  }

  Future<void> _reportsIgnoredRefresh() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  ref.refresh(provider);
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.refresh(provider)')]);
  }

  Future<void> _allowsUsedRefreshResult() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  final value = ref.refresh(provider);
  value.hashCode;
}
''');
  }

  Future<void> _severityIsError() async {
    expect(UseRefInvalidate.code.severity, DiagnosticSeverity.ERROR);
  }
}

void _defineFlutterSkillRulesPart01Tests() {
  analysisRuleSuite<_UseContextMountedAfterAwaitTest>(
    'UseContextMountedAfterAwaitTest',
    _UseContextMountedAfterAwaitTest.new,
    _UseContextMountedAfterAwaitTest._allCases,
  );
  analysisRuleSuite<_AvoidLegacyRiverpodApisTest>(
    'AvoidLegacyRiverpodApisTest',
    _AvoidLegacyRiverpodApisTest.new,
    _AvoidLegacyRiverpodApisTest._allCases,
  );
  analysisRuleSuite<_AvoidDynamicExceptJsonMapsTest>(
    'AvoidDynamicExceptJsonMapsTest',
    _AvoidDynamicExceptJsonMapsTest.new,
    _AvoidDynamicExceptJsonMapsTest._allCases,
  );
  analysisRuleSuite<_AvoidNullBangTest>(
    'AvoidNullBangTest',
    _AvoidNullBangTest.new,
    _AvoidNullBangTest._allCases,
  );
  analysisRuleSuite<_AvoidPrivateWidgetClassesTest>(
    'AvoidPrivateWidgetClassesTest',
    _AvoidPrivateWidgetClassesTest.new,
    _AvoidPrivateWidgetClassesTest._allCases,
  );
  analysisRuleSuite<_AvoidWidgetBuildHelpersTest>(
    'AvoidWidgetBuildHelpersTest',
    _AvoidWidgetBuildHelpersTest.new,
    _AvoidWidgetBuildHelpersTest._allCases,
  );
  analysisRuleSuite<_AvoidShrinkWrapTest>(
    'AvoidShrinkWrapTest',
    _AvoidShrinkWrapTest.new,
    _AvoidShrinkWrapTest._allCases,
  );
  analysisRuleSuite<_GuardContextPopTest>(
    'GuardContextPopTest',
    _GuardContextPopTest.new,
    _GuardContextPopTest._allCases,
  );
  analysisRuleSuite<_UseRefInvalidateTest>(
    'UseRefInvalidateTest',
    _UseRefInvalidateTest.new,
    _UseRefInvalidateTest._allCases,
  );
}
