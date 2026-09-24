// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotifierDependencyCaptureScopeTest);
  });
}

@reflectiveTest
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

  Future<void> test_allowsNullableRepositoryAcquisitionInsideTryBody() async {
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

  Future<void> test_allowsNullableRecordAcquisitionAndDestructureInsideTryBody() async {
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

  Future<void> test_allowsSimpleTerminalMountedBranchBeforeTryAcquisition() async {
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

  Future<void> test_reportsTryAcquisitionAfterUnrelatedAwait() async {
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

  Future<void> test_reportsEarlyTerminalBranchThatReadsAndAwaitsRepository() async {
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

  Future<void> test_reportsCatchLocalCaptureThatCannotProtectTryMainPath() async {
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

    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_reportsNestedClosureCaptureThatCannotProtectMainPath() async {
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

    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_reportsLateRepositoryReadAfterSafeTryCapture() async {
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

    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_reportsCatchResourceOperationBesideSafeTryCapture() async {
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

    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_reportsFinallyResourceOperationBesideSafeTryCapture() async {
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

    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_allowsResolvedResourceFreeFreezedStateReadAfterMutation() async {
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

  Future<void> test_reportsUnannotatedStateReadAfterMutation() async {
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
    await _expectNotifierDiagnostic(source);
  }

  Future<void> test_reportsFreezedStateContainingRepositoryAfterMutation() async {
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
    await _expectNotifierDiagnostic(source);
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
