// ignore_for_file: non_constant_identifier_names

part of '../source_scanner_rules_test.dart';

@reflectiveTest
final class WidgetInfraDependencyBoundaryTest extends _UiRuleTest {
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

  Future<void> test_reportsInfraField() async {
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

  Future<void> test_reportsTypedConstructorParam() async {
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

  Future<void> test_reportsLocalInfraConstructor() async {
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

  Future<void> test_allowsInfraWiringOutsideUiFiles() async {
    await assertAllows(r'''
class BaseCacheManager {}
class DefaultCacheManager extends BaseCacheManager {}

final BaseCacheManager cacheManager = DefaultCacheManager();
''', path: '$testPackageLibPath/core/utils/cached_avatar_bytes_loader.dart');
  }

  Future<void> test_allowsPrimitiveWidgetProps() async {
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

@reflectiveTest
final class WidgetTopLevelFunctionBoundaryTest extends _UiRuleTest {
  @override
  String get ruleName => 'widget_top_level_function_boundary';

  Future<void> test_severityIsError() async {
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

  Future<void> test_reportsPrivateTopLevelHelper() async {
    final analyzedSource = _analyzedSource(r'''
bool _canShowAction(Object state) => true;
''', addIgnorePrefix: addIgnorePrefix);
    newFile(path, analyzedSource);

    await assertDiagnosticsInFile(path, [
      compatLint(analyzedSource, 'bool _canShowAction', ruleName, lineStart: true),
    ]);
  }

  Future<void> test_allowsResolvedPreviewFunction() async {
    await assertAllows(r'''
import 'package:flutter/widget_previews.dart';

@Preview(name: 'Squad actions')
Widget squadActionsPreview() => SquadActionsBar();
''', path: path);
  }

  Future<void> test_reportsFunctionUnderLookalikePreviewAnnotation() async {
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

  Future<void> test_allowsStaticClassApi() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
}
''', path: path);
  }

  Future<void> test_allowsProviderFiles() async {
    await assertAllows(r'''
Future<void> createSquad(BuildContext context, WidgetRef ref) async {}
''', path: '$testPackageLibPath/features/social/presentation/notifiers/squad_actions.dart');
  }
}

@reflectiveTest
final class WidgetActionsNamespaceBoundaryTest extends _UiRuleTest {
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

  Future<void> test_allowsCoordinatorActionNamespace() async {
    await assertAllows(r'''
abstract final class SquadActions {
  static Future<void> createSquad(BuildContext context, WidgetRef ref) async {
    ref.read(squadProvider.notifier).createSquad();
  }
}
''', path: '$testPackageLibPath/features/social/presentation/coordinators/squad_actions.dart');
  }

  Future<void> test_allowsRenderOnlyWidgetActions() async {
    await assertAllows(r'''
abstract final class EmptySquadActions {
  static Widget iconButton(VoidCallback onTap) => IconButton(onPressed: onTap);
}
''', path: '$testPackageLibPath/features/social/presentation/widgets/empty_squad_actions.dart');
  }
}

@reflectiveTest
final class StorageClearPreservesMigrationStateTest extends _RuntimeBugRuleTest {
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

  Future<void> test_allowsHardClear() async {
    await assertAllows(r'''
class SettingsLocalDatasource {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }

  Future<void> test_allowsNonStorageBoundaryClass() async {
    await assertAllows(r'''
class MemoryCache {
  Future<void> resetAll() async {
    await _storage.clear();
  }
}
''');
  }
}
