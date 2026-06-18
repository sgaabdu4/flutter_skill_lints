// ignore_for_file: non_constant_identifier_names

part of '../flutter_skill_rules_test.dart';

@reflectiveTest
final class AvoidPrivateWidgetClassesTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidPrivateWidgetClasses();
    super.setUp();
  }

  Future<void> test_reportsPrivateStatelessWidget() async {
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

  Future<void> test_allowsPublicWidgetClasses() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class PublicCard extends StatelessWidget {
  const PublicCard();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');
  }

  Future<void> test_allowsPrivateStateSubclasses() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class PublicCard extends StatefulWidget {
  const PublicCard();
}

class _PublicCardState extends State<PublicCard> {}
''');
  }

  Future<void> test_allowsPrivateWidgetClassesInTestFiles() async {
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

  Future<void> test_reportsPrivateWidgetClassesInPartFiles() async {
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

@reflectiveTest
final class UseRefMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseRefMountedAfterAwait();
    super.setUp();
  }

  Future<void> test_reportsRefAfterAwait() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    ref.read(provider);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.read(provider)')]);
  }

  Future<void> test_allowsGuardedRefAfterAwait() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

class TodosNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> load() async {
    await Future<void>.value();
    if (!ref.mounted) return;
    ref.read(provider);
  }
}
''');
  }
}

@reflectiveTest
final class UseContextMountedAfterAwaitTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseContextMountedAfterAwait();
    super.setUp();
  }

  Future<void> test_reportsContextAfterAwait() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> test_allowsMountedGuard() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<void> close(BuildContext context) async {
  await Future<void>.value();
  if (!context.mounted) return;
  context.pop();
}
''');
  }

  Future<void> test_reportsStateContextMountedGuardAfterAwait() async {
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

  Future<void> test_reportsExplicitStateContextMountedGuardAfterAwait() async {
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

  Future<void> test_allowsCapturedStateContextMountedGuardAfterAwait() async {
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
}

@reflectiveTest
final class AvoidLegacyRiverpodApisTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidLegacyRiverpodApis();
    super.setUp();
  }

  Future<void> test_reportsLegacyProvider() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final counterProvider = StateProvider<int>((ref) => 0);
''';
    await assertDiagnostics(source, [lintFor(source, 'StateProvider<int>')]);
  }

  Future<void> test_allowsUnifiedRef() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

int load(Ref ref) => ref.read(Object());
''');
  }
}

@reflectiveTest
final class AvoidDynamicExceptJsonMapsTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidDynamicExceptJsonMaps();
    super.setUp();
  }

  Future<void> test_reportsBareDynamic() async {
    const source = r'''
dynamic value;
Map<String, dynamic> json = {};
''';
    await assertDiagnostics(source, [lintFor(source, 'dynamic')]);
  }

  Future<void> test_allowsJsonMapDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;
''');
  }

  Future<void> test_allowsJsonMapCastDynamic() async {
    await assertNoDiagnostics(r'''
Map<String, Object?> normalize(Map<String, Object?> json) {
  return json.cast<String, dynamic>();
}

Map<String, dynamic> emptyPrefs() {
  return const <String, Object?>{}.cast<String, dynamic>();
}
''');
  }

  Future<void> test_reportsUntypedRuntimeBoundaryDynamic() async {
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

  Future<void> test_allowsGeneratedLocalizationsDynamic() async {
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

@reflectiveTest
final class AvoidNullBangTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidNullBang();
    super.setUp();
  }

  Future<void> test_reportsNullBang() async {
    const source = r'''
void f(String? value) {
  value!;
}
''';
    await assertDiagnostics(source, [lintFor(source, '!')]);
  }

  Future<void> test_allowsNullCheck() async {
    await assertNoDiagnostics(r'''
void f(String? value) {
  if (value case final text?) {
    text.length;
  }
}
''');
  }
}

@reflectiveTest
final class AvoidWidgetBuildHelpersTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidWidgetBuildHelpers();
    super.setUp();
  }

  Future<void> test_reportsBuildHelper() async {
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

  Future<void> test_allowsNamedWidgetClass() async {
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

@reflectiveTest
final class AvoidShrinkWrapTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidShrinkWrap();
    super.setUp();
  }

  Future<void> test_reportsShrinkWrapTrue() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final widget = ListView(shrinkWrap: true);
''';
    await assertDiagnostics(source, [lintFor(source, 'shrinkWrap: true')]);
  }

  Future<void> test_allowsDefaultListView() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final widget = ListView();
''');
  }
}

@reflectiveTest
final class GuardContextPopTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = GuardContextPop();
    super.setUp();
  }

  Future<void> test_reportsUnguardedPop() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void close(BuildContext context) {
  context.pop();
}
''';
    await assertDiagnostics(source, [lintFor(source, 'context.pop()')]);
  }

  Future<void> test_allowsCanPopGuardWithTypedFallback() async {
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

@reflectiveTest
final class UseRefInvalidateTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseRefInvalidate();
    super.setUp();
  }

  Future<void> test_reportsIgnoredRefresh() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  ref.refresh(provider);
}
''';
    await assertDiagnostics(source, [lintFor(source, 'ref.refresh(provider)')]);
  }

  Future<void> test_allowsUsedRefreshResult() async {
    await assertNoDiagnostics(r'''
import 'package:riverpod/riverpod.dart';

final provider = Object();

void reset(Ref ref) {
  final value = ref.refresh(provider);
  value.hashCode;
}
''');
  }
}

@reflectiveTest
final class UseSealedFreezedClassesTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = UseSealedFreezedClasses();
    super.setUp();
  }

  Future<void> test_reportsAbstractFreezed() async {
    const source = r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
abstract class User {}
''';
    await assertDiagnostics(source, [lintFor(source, 'abstract')]);
  }

  Future<void> test_allowsSealedFreezed() async {
    await assertNoDiagnostics(r'''
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
sealed class User {}
''');
  }
}

@reflectiveTest
final class AvoidRouteParamThrowInBuildTest extends _FlutterSkillRuleTest {
  @override
  void setUp() {
    rule = AvoidRouteParamThrowInBuild();
    super.setUp();
  }

  Future<void> test_reportsFirstWhereThrowInBuild() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => throw 'missing',
    );
    return Text(item);
  }
}
''';
    await assertDiagnostics(source, [lintFor(source, 'firstWhere')]);
  }

  Future<void> test_allowsFallbackValue() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Screen extends StatelessWidget {
  const Screen();

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    final item = items.firstWhere(
      (candidate) => candidate == 'missing',
      orElse: () => 'fallback',
    );
    return Text(item);
  }
}
''');
  }
}
