part of '../source_scanner_rules_test.dart';

final class _WidgetInfraDependencyBoundaryTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetInfraDependencyBoundaryTest)> get _allCases =>
      caseSet<_WidgetInfraDependencyBoundaryTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_reportsInfraField': (t) => t._reportsInfraField(),
          'test_reportsTypedConstructorParam': (t) => t._reportsTypedConstructorParam(),
          'test_reportsLocalInfraConstructor': (t) => t._reportsLocalInfraConstructor(),
          'test_allowsInfraWiringOutsideUiFiles': (t) => t._allowsInfraWiringOutsideUiFiles(),
          'test_allowsPrimitiveWidgetProps': (t) => t._allowsPrimitiveWidgetProps(),
        },
      );

  @override
  String get ruleName => 'widget_infra_dependency_boundary';
  @override
  String get needle => 'cacheManager: DefaultCacheManager';
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/avatar.dart';
  @override
  String get source => r'''
class DefaultCacheManager {}

class Avatar extends StatelessWidget {
  Widget build(BuildContext context) => CachedNetworkAvatar(
    url: avatarUrl,
    cacheManager: DefaultCacheManager(),
  );
}
''';

  Future<void> _reportsInfraField() async {
    final analyzedSource = _analyzedSource(r'''
class BaseCacheManager {}

class Avatar extends StatelessWidget {
  final BaseCacheManager cacheManager;

  const Avatar({required this.cacheManager});
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'BaseCacheManager cacheManager', ruleName),
    ]);
  }

  Future<void> _reportsTypedConstructorParam() async {
    final analyzedSource = _analyzedSource(r'''
class UserService {}

class Avatar extends StatelessWidget {
  const Avatar({required UserService userService});
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'UserService userService', ruleName),
    ]);
  }

  Future<void> _reportsLocalInfraConstructor() async {
    final analyzedSource = _analyzedSource(r'''
class DefaultCacheManager {}

class Avatar extends StatelessWidget {
  Widget build(BuildContext context) {
    final cacheManager = DefaultCacheManager();
    return CachedNetworkAvatar(cacheManager: cacheManager);
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'final cacheManager', ruleName),
    ]);
  }

  Future<void> _allowsInfraWiringOutsideUiFiles() async {
    await assertAllows(r'''
class BaseCacheManager {}
class DefaultCacheManager extends BaseCacheManager {}

final BaseCacheManager cacheManager = DefaultCacheManager();
''', path: '$testPackageLibPath/core/utils/cached_avatar_bytes_loader.dart');
  }

  Future<void> _allowsPrimitiveWidgetProps() async {
    await assertAllows(r'''
class Avatar extends StatelessWidget {
  final String seed;
  final double size;
  final VoidCallback? onTap;

  const Avatar({required this.seed, required this.size, this.onTap});
}
''', path: path);
  }
}

final class _WidgetTopLevelFunctionBoundaryTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetTopLevelFunctionBoundaryTest)> get _allCases =>
      caseSet<_WidgetTopLevelFunctionBoundaryTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_severityIsError': (t) => t._severityIsError(),
          'test_reportsPrivateTopLevelHelper': (t) => t._reportsPrivateTopLevelHelper(),
          'test_allowsResolvedPreviewFunction': (t) => t._allowsResolvedPreviewFunction(),
          'test_reportsFunctionUnderLookalikePreviewAnnotation': (t) =>
              t._reportsFunctionUnderLookalikePreviewAnnotation(),
          'test_allowsStaticClassApi': (t) => t._allowsStaticClassApi(),
          'test_allowsProviderFiles': (t) => t._allowsProviderFiles(),
        },
      );

  @override
  String get ruleName => 'widget_top_level_function_boundary';

  Future<void> _severityIsError() async {
    expect((rule as ScannerRule).diagnosticCode.severity, DiagnosticSeverity.ERROR);
  }

  @override
  String get needle => 'Future<void> createSquad';
  @override
  bool get lineStart => true;
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/squad_actions.dart';
  @override
  String get source => r'''
Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
''';

  Future<void> _reportsPrivateTopLevelHelper() async {
    final analyzedSource = _analyzedSource(r'''
bool _canShowAction(Object state) => true;
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'bool _canShowAction', ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsResolvedPreviewFunction() async {
    await assertAllows(r'''
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Squad actions')
Widget squadActionsPreview() => SquadActionsBar();
''', path: path);
  }

  Future<void> _reportsFunctionUnderLookalikePreviewAnnotation() async {
    final analyzedSource = _analyzedSource(r'''
class Preview {
  const Preview({String? name});
}

@Preview(name: 'Squad actions')
Widget squadActionsPreview() => SquadActionsBar();
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'Widget squadActionsPreview', ruleName, lineStart: true),
    ]);
  }

  Future<void> _allowsStaticClassApi() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
}
''', path: path);
  }

  Future<void> _allowsProviderFiles() async {
    await assertAllows(r'''
Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
''', path: '$testPackageLibPath/features/social/presentation/notifiers/squad_actions.dart');
  }
}

final class _WidgetActionsNamespaceBoundaryTest extends _UiRuleTest {
  static Map<String, Future<void> Function(_WidgetActionsNamespaceBoundaryTest)> get _allCases =>
      caseSet<_WidgetActionsNamespaceBoundaryTest>(
        parent: _SourceRuleTest._allCases,
        own: {
          'test_allowsCoordinatorActionNamespace': (t) => t._allowsCoordinatorActionNamespace(),
          'test_allowsRenderOnlyWidgetActions': (t) => t._allowsRenderOnlyWidgetActions(),
        },
      );

  @override
  String get ruleName => 'widget_actions_namespace_boundary';
  @override
  String get needle => 'class SquadActions';
  @override
  String get path => '$testPackageLibPath/features/social/presentation/widgets/squad_actions.dart';
  @override
  String get source => r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {
    ref.read(squadProvider.notifier).createSquad();
  }
}
''';

  Future<void> _allowsCoordinatorActionNamespace() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {
    ref.read(squadProvider.notifier).createSquad();
  }
}
''', path: '$testPackageLibPath/features/social/presentation/coordinators/squad_actions.dart');
  }

  Future<void> _allowsRenderOnlyWidgetActions() async {
    await assertAllows(r'''
abstract final class EmptySquadActions {
  static Widget iconButton(VoidCallback onTap) => IconButton(onPressed: onTap);
}
''', path: '$testPackageLibPath/features/social/presentation/widgets/empty_squad_actions.dart');
  }
}

final class _StorageClearPreservesMigrationStateTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_StorageClearPreservesMigrationStateTest)>
  get _allCases => caseSet<_StorageClearPreservesMigrationStateTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_allowsHardClear': (t) => t._allowsHardClear(),
      'test_allowsNonStorageBoundaryClass': (t) => t._allowsNonStorageBoundaryClass(),
    },
  );

  @override
  String get ruleName => 'storage_clear_preserves_migration_state';
  @override
  String get needle => '.clear()';
  @override
  String get source => r'''
class SettingsLocalDatasource {
  Future<void> resetAll() async {
    final lastOpenedAppVersion = await _storage.read<String>(localDataLastOpenedAppVersionKey);
    await _storage.clear();
    if (lastOpenedAppVersion != null) {
      await _storage.save(localDataLastOpenedAppVersionKey, lastOpenedAppVersion);
    }
  }
}
''';

  Future<void> _allowsHardClear() async {
    await assertAllows(r'''
class SettingsLocalDatasource {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }

  Future<void> _allowsNonStorageBoundaryClass() async {
    await assertAllows(r'''
class MemoryCache {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }
}

/// A `;`-terminated constructor has no body; the scanner must not extend its span over the following method (networking.md repository shape).
final class _DestructiveFailureAfterConstConstructorTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_DestructiveFailureAfterConstConstructorTest)>
  get _allCases => caseSet<_DestructiveFailureAfterConstConstructorTest>(
    parent: _SourceRuleTest._allCases,
    own: {},
  );

  @override
  String get ruleName => 'destructive_failure_logged_before_reconcile';
  @override
  String get needle => 'Crash.error(e, s)';
  @override
  String get source => r'''
class AccountRepository {
  const AccountRepository(this.remote);

  final Object remote;

  Future<void> deleteAccount(String userId) async {
    try {
      await remote.startDeleteAccount(userId);
    } on Exception catch (e, s) {
      Crash.error(e, s);
      await remote.waitForAccountDeleted(userId);
    }
  }
}
''';
}

void _defineSourceScannerRulesPart24Tests() {
  analysisRuleSuite<_WidgetInfraDependencyBoundaryTest>(
    'WidgetInfraDependencyBoundaryTest',
    _WidgetInfraDependencyBoundaryTest.new,
    _WidgetInfraDependencyBoundaryTest._allCases,
  );
  analysisRuleSuite<_WidgetTopLevelFunctionBoundaryTest>(
    'WidgetTopLevelFunctionBoundaryTest',
    _WidgetTopLevelFunctionBoundaryTest.new,
    _WidgetTopLevelFunctionBoundaryTest._allCases,
  );
  analysisRuleSuite<_WidgetActionsNamespaceBoundaryTest>(
    'WidgetActionsNamespaceBoundaryTest',
    _WidgetActionsNamespaceBoundaryTest.new,
    _WidgetActionsNamespaceBoundaryTest._allCases,
  );
  analysisRuleSuite<_DestructiveFailureAfterConstConstructorTest>(
    'DestructiveFailureAfterConstConstructorTest',
    _DestructiveFailureAfterConstConstructorTest.new,
    _DestructiveFailureAfterConstConstructorTest._allCases,
  );
  analysisRuleSuite<_StorageClearPreservesMigrationStateTest>(
    'StorageClearPreservesMigrationStateTest',
    _StorageClearPreservesMigrationStateTest.new,
    _StorageClearPreservesMigrationStateTest._allCases,
  );
}
