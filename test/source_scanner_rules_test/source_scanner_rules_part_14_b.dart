part of '../source_scanner_rules_test.dart';

final class _PopScopeBypassUsesGoNotPopTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_PopScopeBypassUsesGoNotPopTest)> get _allCases =>
      caseSet<_PopScopeBypassUsesGoNotPopTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsTypedRouteGo': (t) => t._allowsTypedRouteGo(),
          'test_allowsPopWithFallbackWithoutPrecedingModal': (t) =>
              t._allowsPopWithFallbackWithoutPrecedingModal(),
        },
      );

  @override
  String get ruleName => 'popscope_bypass_uses_go_not_pop';
  @override
  String get needle => 'context.popWithFallback(';
  @override
  String get source => r'''
class DetailRoute {
  Object go(Object context) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  Future<void> onTap(Object context) async {
    await showDialog(builder: Object());
    context.popWithFallback(DetailRoute());
  }
}
''';

  Future<void> _allowsTypedRouteGo() async {
    await assertAllows(r'''
class DetailRoute {
  Object go(Object context) => Object();
}
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  Future<void> onTap(Object context) async {
    await showDialog(builder: Object());
    DetailRoute().go(context);
  }
}
''');
  }

  Future<void> _allowsPopWithFallbackWithoutPrecedingModal() async {
    await assertAllows(r'''
class ConsumerWidget extends Widget {}

class ConfirmScreen extends ConsumerWidget {
  void onTap(Object context) {
    context.popWithFallback(Object());
  }
}
''');
  }
}

abstract class _RuntimeBugRuleTest extends _SourceRuleTest {
  @override
  List<ScannerRule> get rules => runtimeBugSourceRules;
}

final class _ModalHelperRequiresRouteSettingsTest extends _DialogRuleTest {
  static Map<String, Future<void> Function(_ModalHelperRequiresRouteSettingsTest)> get _allCases =>
      caseSet<_ModalHelperRequiresRouteSettingsTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsWithRouteSettings': (t) => t._allowsWithRouteSettings(),
          'test_allowsSheetWithRouteSettings': (t) => t._allowsSheetWithRouteSettings(),
          'test_allowsSkillShowAppSheetHelperAndCallers': (t) =>
              t._allowsSkillShowAppSheetHelperAndCallers(),
          'test_allowsSkillModalContextExtension': (t) => t._allowsSkillModalContextExtension(),
        },
      );

  @override
  void setUp() {
    _addTestingNavigationPackages();
    super.setUp();
  }

  @override
  String get ruleName => 'modal_helper_requires_route_settings';
  @override
  String get needle => 'showDialog<T>(';
  @override
  String get source => r'''
import 'package:flutter/material.dart';

Future<T?> openConfirm<T>(BuildContext context) => showDialog<T>(
  context: context,
  builder: (_) => Widget(),
);
''';

  Future<void> _allowsWithRouteSettings() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

Future<T?> openConfirm<T>(BuildContext context) => showDialog<T>(
  context: context,
  routeSettings: const RouteSettings(name: 'confirm'),
  builder: (_) => Widget(),
);
''');
  }

  Future<void> _allowsSheetWithRouteSettings() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

Future<T?> openSheet<T>(BuildContext context) => showModalBottomSheet<T>(
  context: context,
  routeSettings: const RouteSettings(name: 'confirm'),
  builder: (_) => Widget(),
);
''');
  }

  Future<void> _allowsSkillShowAppSheetHelperAndCallers() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String routeName,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    routeSettings: RouteSettings(name: routeName),
    builder: builder,
  );
}

typedef WidgetBuilder = Widget Function(BuildContext context);

Future<void> openMenu(BuildContext context) async {
  await showAppSheet<void>(context: context, routeName: 'menu', builder: (_) => Widget());
}
''');
  }

  // context-ui.md:40-52: the skill's BuildContext extension helper and caller.
  Future<void> _allowsSkillModalContextExtension() async {
    await assertAllows(r'''
import 'package:flutter/material.dart';

typedef WidgetBuilder = Widget Function(BuildContext context);

extension ModalContextX on BuildContext {
  Future<T?> showAppSheet<T>({
    required String routeName,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      routeSettings: RouteSettings(name: routeName),
      builder: builder,
    );
  }
}

Future<void> openMenu(BuildContext context) async {
  await context.showAppSheet<void>(routeName: 'menu', builder: (_) => Widget());
}
''', path: '$testPackageLibPath/core/extensions/context_extensions.dart');
  }
}

const _skillNeverConfirmDialog = r'''
class WidgetRef {
  dynamic watch(Object? provider) => null;
  dynamic read(Object? provider) => null;
}
class ConsumerWidget extends Widget {}

// NEVER — dialog hosts mutation + watches mutable record
class ConfirmDialog extends ConsumerWidget {
  ConfirmDialog({required this.id});
  final String id;

  Widget build(BuildContext context, WidgetRef ref) {
    final entity = ref.watch(entityProvider(id));
    final (:isSaving, :itemsByCategoryId) = ref.watch(
      formProvider.select((s) => (isSaving: s.isSaving, itemsByCategoryId: s.itemsByCategoryId)),
    );
    return AppPrimaryButton(
      onPressed: () async {
        final ok = await ref.read(formProvider.notifier).save(entity);
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        if (ok) context.pop();
      },
      label: itemsByCategoryId.isEmpty ? 'Exit' : 'Confirm',
    );
  }
}
''';

void _defineSourceScannerRulesPart14BTests() {
  analysisRuleSuite<_PopScopeBypassUsesGoNotPopTest>(
    'PopScopeBypassUsesGoNotPopTest',
    _PopScopeBypassUsesGoNotPopTest.new,
    _PopScopeBypassUsesGoNotPopTest._allCases,
  );
  analysisRuleSuite<_ModalHelperRequiresRouteSettingsTest>(
    'ModalHelperRequiresRouteSettingsTest',
    _ModalHelperRequiresRouteSettingsTest.new,
    _ModalHelperRequiresRouteSettingsTest._allCases,
  );
}
