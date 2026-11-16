import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<NotifierDependencyCaptureScopeTest>(
    'NotifierDependencyCaptureScopeTest',
    NotifierDependencyCaptureScopeTest.new,
    {
      'test_allowsNullableRepositoryAcquisitionInsideTryBody': (t) =>
          t._allowsNullableRepositoryAcquisitionInsideTryBody(),
      'test_allowsNullableRecordAcquisitionAndDestructureInsideTryBody': (t) =>
          t._allowsNullableRecordAcquisitionAndDestructureInsideTryBody(),
      'test_allowsSimpleTerminalMountedBranchBeforeTryAcquisition': (t) =>
          t._allowsSimpleTerminalMountedBranchBeforeTryAcquisition(),
      'test_reportsTryAcquisitionAfterUnrelatedAwait': (t) =>
          t._reportsTryAcquisitionAfterUnrelatedAwait(),
      'test_reportsEarlyTerminalBranchThatReadsAndAwaitsRepository': (t) =>
          t._reportsEarlyTerminalBranchThatReadsAndAwaitsRepository(),
      'test_allowsSkillSaveShapeWithCatchCapture': (t) => t._allowsSkillSaveShapeWithCatchCapture(),
      'test_leavesUnguardedAwaitAfterClosureToMountedRule': (t) =>
          t._leavesUnguardedAwaitAfterClosureToMountedRule(),
      'test_allowsDirectReadAfterSafeTryCapture': (t) => t._allowsDirectReadAfterSafeTryCapture(),
      'test_allowsDirectReadInCatchBesideSafeTryCapture': (t) =>
          t._allowsDirectReadInCatchBesideSafeTryCapture(),
      'test_allowsDirectReadInFinallyBesideSafeTryCapture': (t) =>
          t._allowsDirectReadInFinallyBesideSafeTryCapture(),
      'test_allowsResolvedResourceFreeFreezedStateReadAfterMutation': (t) =>
          t._allowsResolvedResourceFreeFreezedStateReadAfterMutation(),
      'test_allowsUnannotatedStateReadAfterMutation': (t) =>
          t._allowsUnannotatedStateReadAfterMutation(),
      'test_allowsFreezedStateContainingRepositoryReadAfterMutation': (t) =>
          t._allowsFreezedStateContainingRepositoryReadAfterMutation(),
    },
  );
}

final class NotifierDependencyCaptureScopeTest extends AnalysisRuleTest {
  static const _ruleName = 'notifier_ensure_deps';

  @override
  void setUp() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
abstract class ProviderListenable<T extends Object> {}
class Provider<T extends Object> extends ProviderListenable<T> {
  Provider(this.value);
  final T value;
}
class NotifierProvider<T extends Object> extends ProviderListenable<T> {
  ProviderListenable<T> get notifier => throw UnimplementedError();
}
class Ref {
  T read<T extends Object>(ProviderListenable<T> provider) => throw UnimplementedError();
  bool get mounted => true;
}
class Notifier<T> {
  Ref get ref => Ref();
  T? state;
}
''');
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}
const freezed = Freezed();
''');
    rule = notifierSourceRules.singleWhere((candidate) => candidate.name == _ruleName);
    super.setUp();
  }

  Future<void> _allowsNullableRepositoryAcquisitionInsideTryBody() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    try {
      final repository = await _captureRepository();
      if (!ref.mounted || repository == null) return;
      state = Object();
      await repository.save();
    } catch (_) {
      state = Object();
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsNullableRecordAcquisitionAndDestructureInsideTryBody() async {
    final source = _source(r'''
  Future<({String accountId, ItemsRepository repository})?> _captureContext() async {
    final repository = ref.read(repositoryProvider);
    return (accountId: 'account', repository: repository);
  }

  Future<void> saveItem() async {
    try {
      final mutation = await _captureContext();
      if (!ref.mounted || mutation == null) return;
      final (accountId: _, repository: capturedRepository) = mutation;
      state = Object();
      await capturedRepository.save();
    } catch (_) {
      state = Object();
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsSimpleTerminalMountedBranchBeforeTryAcquisition() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    try {
      if (!ref.mounted) {
        state = Object();
        return;
      }
      final repository = await _captureRepository();
      if (repository == null) return;
      state = Object();
      await repository.save();
    } catch (_) {}
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _reportsTryAcquisitionAfterUnrelatedAwait() async {
    final source = _source(r'''
  Future<void> _doUnrelatedWork() async {}
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    await _doUnrelatedWork();
    try {
      final repository = await _captureRepository();
      if (repository == null) return;
      state = Object();
      await repository.save();
    } catch (_) {}
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsEarlyTerminalBranchThatReadsAndAwaitsRepository() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem(bool failEarly) async {
    try {
      if (failEarly) {
        state = Object();
        await ref.read(repositoryProvider).save();
        return;
      }
      final repository = await _captureRepository();
      if (repository == null) return;
      state = Object();
      await repository.save();
    } catch (_) {}
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _allowsSkillSaveShapeWithCatchCapture() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    try {
      state = Object();
      await ref.read(repositoryProvider).save();
    } catch (_) {
      final repository = ref.read(repositoryProvider);
      state = Object();
      await repository.save();
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _leavesUnguardedAwaitAfterClosureToMountedRule() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    final callback = () async {
      final repository = ref.read(repositoryProvider);
      state = Object();
      await repository.save();
    };
    await callback();
    state = Object();
    await ref.read(repositoryProvider).save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsDirectReadAfterSafeTryCapture() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    try {
      final repository = ref.read(repositoryProvider);
      state = Object();
      await repository.save();
    } catch (_) {}
    state = Object();
    final otherRepository = ref.read(otherRepositoryProvider);
    await otherRepository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsDirectReadInCatchBesideSafeTryCapture() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    try {
      final repository = ref.read(repositoryProvider);
      state = Object();
      await repository.save();
    } catch (_) {
      state = Object();
      await ref.read(otherRepositoryProvider).save();
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsDirectReadInFinallyBesideSafeTryCapture() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    try {
      final repository = ref.read(repositoryProvider);
      state = Object();
      await repository.save();
    } finally {
      await ref.read(otherRepositoryProvider).save();
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsResolvedResourceFreeFreezedStateReadAfterMutation() async {
    final source = _source(
      r'''
  Future<void> saveItem() async {
    final repository = ref.read(repositoryProvider);
    state = Object();
    await repository.save();
    if (ref.read(viewStateProvider).label.isEmpty) state = Object();
  }
''',
      extraDeclarations: r'''
@freezed
final class ViewState {
  const ViewState(this.label);
  final String label;
}
final viewStateProvider = Provider<ViewState>(const ViewState('ready'));
''',
    );

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsUnannotatedStateReadAfterMutation() async {
    final source = _source(
      r'''
  Future<void> saveItem() async {
    final repository = ref.read(repositoryProvider);
    state = Object();
    await repository.save();
    if (ref.read(fakeStateProvider).label.isEmpty) state = Object();
  }
''',
      extraDeclarations: r'''
final class FakeState {
  const FakeState(this.label);
  final String label;
}
final fakeStateProvider = Provider<FakeState>(const FakeState('ready'));
''',
    );
    await assertNoDiagnostics(source);
  }

  Future<void> _allowsFreezedStateContainingRepositoryReadAfterMutation() async {
    final source = _source(
      r'''
  Future<void> saveItem() async {
    final repository = ref.read(repositoryProvider);
    state = Object();
    await repository.save();
    ref.read(repositoryStateProvider);
  }
''',
      extraDeclarations: r'''
@freezed
final class RepositoryState {
  const RepositoryState(this.repository);
  final ItemsRepository repository;
}
final repositoryStateProvider = Provider<RepositoryState>(
  RepositoryState(ItemsRepository()),
);
''',
    );
    await assertNoDiagnostics(source);
  }

  Future<void> _expectNotifierDiagnostic(String source) async {
    const methodDeclaration = 'Future<void> saveItem';
    final methodOffset = source.indexOf(methodDeclaration);
    final lineStart = source.lastIndexOf('\n', methodOffset) + 1;
    final lineEnd = source.indexOf('\n', lineStart);
    await assertDiagnostics(source, [lint(lineStart, lineEnd - lineStart, name: _ruleName)]);
  }

  String _source(String members, {String extraDeclarations = ''}) {
    final freezedImport = extraDeclarations.contains('@freezed')
        ? "import 'package:freezed_annotation/freezed_annotation.dart';\n"
        : '';
    return '''
$freezedImport
import 'package:riverpod/riverpod.dart';

class ItemsRepository {
  Future<void> save() async {}
}

final repositoryProvider = Provider<ItemsRepository>(ItemsRepository());
final otherRepositoryProvider = Provider<ItemsRepository>(ItemsRepository());
$extraDeclarations

class ItemsNotifier extends Notifier<Object> {
$members
}
''';
  }
}
