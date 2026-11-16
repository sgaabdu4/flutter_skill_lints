import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/rules/notifier_source_rules.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_NotifierDependencyCaptureTest>(
    'NotifierDependencyCaptureTest',
    _NotifierDependencyCaptureTest.new,
    _NotifierDependencyCaptureTest._allCases,
  );
}

final class _NotifierDependencyCaptureTest extends AnalysisRuleTest {
  static Map<String, Future<void> Function(_NotifierDependencyCaptureTest)> get _allCases =>
      caseSet<_NotifierDependencyCaptureTest>(
        parent: const {},
        own: {
          'test_allowsResolvedOperationCapturedBeforeMutation': (t) =>
              t._allowsResolvedOperationCapturedBeforeMutation(),
          'test_allowsResolvedRepositoryCapturedBeforeMutation': (t) =>
              t._allowsResolvedRepositoryCapturedBeforeMutation(),
          'test_allowsRepositoryGetterCapturedBeforeMutation': (t) =>
              t._allowsRepositoryGetterCapturedBeforeMutation(),
          'test_allowsRepositoryReturnedBySynchronousHelper': (t) =>
              t._allowsRepositoryReturnedBySynchronousHelper(),
          'test_allowsProviderReadHelperAtAwaitAndAfterMountedGuard': (t) =>
              t._allowsProviderReadHelperAtAwaitAndAfterMountedGuard(),
          'test_reportsProviderReadHelperAfterUnguardedAwait': (t) =>
              t._reportsProviderReadHelperAfterUnguardedAwait(),
          'test_allowsNullableRepositoryReturnedByAwaitedHelperWhenPromoted': (t) =>
              t._allowsNullableRepositoryReturnedByAwaitedHelperWhenPromoted(),
          'test_allowsRepositoryCapturedFromFinalTypedRecordPattern': (t) =>
              t._allowsRepositoryCapturedFromFinalTypedRecordPattern(),
          'test_allowsOperationThroughCapturedTypedRecordField': (t) =>
              t._allowsOperationThroughCapturedTypedRecordField(),
          'test_reportsUnusedAwaitedRepositoryAcquisition': (t) =>
              t._reportsUnusedAwaitedRepositoryAcquisition(),
          'test_reportsMutableRepositoryReturnedByHelper': (t) =>
              t._reportsMutableRepositoryReturnedByHelper(),
          'test_reportsRepositoryCaptureStoredInDynamicLocal': (t) =>
              t._reportsRepositoryCaptureStoredInDynamicLocal(),
          'test_reportsLateRepositoryReturnedByHelper': (t) =>
              t._reportsLateRepositoryReturnedByHelper(),
          'test_reportsLateRepositoryCaptureAfterUnrelatedAwait': (t) =>
              t._reportsLateRepositoryCaptureAfterUnrelatedAwait(),
          'test_reportsSecondRepositoryAcquiredAfterMutation': (t) =>
              t._reportsSecondRepositoryAcquiredAfterMutation(),
          'test_reportsNullableRepositoryWithoutGuardedOperation': (t) =>
              t._reportsNullableRepositoryWithoutGuardedOperation(),
          'test_reportsNullableRepositoryForcedAtOperation': (t) =>
              t._reportsNullableRepositoryForcedAtOperation(),
          'test_reportsClassGetterThatLooksLikeRecordResourceCapture': (t) =>
              t._reportsClassGetterThatLooksLikeRecordResourceCapture(),
          'test_reportsUnusedTypedRecordCapture': (t) => t._reportsUnusedTypedRecordCapture(),
          'test_reportsSecondRepositoryGetterUsedAfterBoundary': (t) =>
              t._reportsSecondRepositoryGetterUsedAfterBoundary(),
          'test_reportsCapturedGetterReevaluatedAfterBoundary': (t) =>
              t._reportsCapturedGetterReevaluatedAfterBoundary(),
          'test_allowsNotifierOperationCapturedBeforeMutation': (t) =>
              t._allowsNotifierOperationCapturedBeforeMutation(),
          'test_allowsScalarProviderReadAfterMutationBoundary': (t) =>
              t._allowsScalarProviderReadAfterMutationBoundary(),
          'test_scalarProviderReadAloneDoesNotNeedDependencyCapture': (t) =>
              t._scalarProviderReadAloneDoesNotNeedDependencyCapture(),
          'test_allowsAnotherProviderReadAfterCapturedOperation': (t) =>
              t._allowsAnotherProviderReadAfterCapturedOperation(),
          'test_allowsSkillSaveReadAfterStateWrite': (t) => t._allowsSkillSaveReadAfterStateWrite(),
          'test_allowsSkillOptimisticUpdateAndGuardedReads': (t) =>
              t._allowsSkillOptimisticUpdateAndGuardedReads(),
          'test_allowsExplicitThisStateWriteBeforeDirectRead': (t) =>
              t._allowsExplicitThisStateWriteBeforeDirectRead(),
          'test_reportsNullableUninitializedRepository': (t) =>
              t._reportsNullableUninitializedRepository(),
          'test_reportsNullableRepositoryUsedAlongsideCapture': (t) =>
              t._reportsNullableRepositoryUsedAlongsideCapture(),
          'test_allowsDirectHelperInitializationBeforeMutation': (t) =>
              t._allowsDirectHelperInitializationBeforeMutation(),
          'test_rejectsHelperAssignmentToSameNamedFieldOnOtherObject': (t) =>
              t._rejectsHelperAssignmentToSameNamedFieldOnOtherObject(),
          'test_rejectsRepositoryResetAfterHelperInitialization': (t) =>
              t._rejectsRepositoryResetAfterHelperInitialization(),
          'test_reportsFakeEnsureHelperWithoutInitialization': (t) =>
              t._reportsFakeEnsureHelperWithoutInitialization(),
          'test_reportsConditionalPathWithoutGuaranteedInitialization': (t) =>
              t._reportsConditionalPathWithoutGuaranteedInitialization(),
          'test_doesNotTrustAppDefinedRefWithRiverpodName': (t) =>
              t._doesNotTrustAppDefinedRefWithRiverpodName(),
        },
      );

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
    rule = notifierSourceRules.singleWhere((candidate) => candidate.name == _ruleName);
    super.setUp();
  }

  Future<void> _allowsResolvedOperationCapturedBeforeMutation() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    final save = ref.read(repositoryProvider).save;
    state = Object();
    await save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsResolvedRepositoryCapturedBeforeMutation() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    final repository = ref.read(repositoryProvider);
    state = Object();
    await repository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsRepositoryGetterCapturedBeforeMutation() async {
    final source = _source(r'''
  ItemsRepository get _repository => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    final repository = _repository;
    state = Object();
    await repository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsRepositoryReturnedBySynchronousHelper() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    final repository = _captureRepository();
    state = Object();
    await repository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsProviderReadHelperAtAwaitAndAfterMountedGuard() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    state = Object();
    await _captureRepository().save();
    if (!ref.mounted) return;
    await this._captureRepository().save();
    if (!ref.mounted) return;
    state = Object();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _reportsProviderReadHelperAfterUnguardedAwait() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    state = Object();
    await _captureRepository().save();
    await _captureRepository().save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _allowsNullableRepositoryReturnedByAwaitedHelperWhenPromoted() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    final repository = await _captureRepository();
    if (!ref.mounted || repository == null) return;
    state = Object();
    await repository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsRepositoryCapturedFromFinalTypedRecordPattern() async {
    final source = _source(r'''
  ({ItemsRepository repository}) _captureRepositoryContext() =>
      (repository: ref.read(repositoryProvider));

  Future<void> saveItem() async {
    final context = _captureRepositoryContext();
    final (repository: capturedRepository) = context;
    state = Object();
    await capturedRepository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsOperationThroughCapturedTypedRecordField() async {
    final source = _source(r'''
  ({ItemsRepository repository}) _captureRepositoryContext() =>
      (repository: ref.read(repositoryProvider));

  Future<void> saveItem() async {
    final context = _captureRepositoryContext();
    state = Object();
    await context.repository.save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _reportsUnusedAwaitedRepositoryAcquisition() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    await _captureRepository();
    state = Object();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsMutableRepositoryReturnedByHelper() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    ItemsRepository repository = _captureRepository();
    state = Object();
    await repository.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsRepositoryCaptureStoredInDynamicLocal() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    final dynamic repository = _captureRepository();
    if (repository is ItemsRepository) {
      state = Object();
      await repository.save();
    }
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsLateRepositoryReturnedByHelper() async {
    final source = _source(r'''
  ItemsRepository _captureRepository() => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    late final ItemsRepository repository;
    repository = _captureRepository();
    state = Object();
    await repository.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsLateRepositoryCaptureAfterUnrelatedAwait() async {
    final source = _source(r'''
  Future<void> doUnrelatedWork() async {}
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    await doUnrelatedWork();
    final repository = await _captureRepository();
    if (repository == null) return;
    state = Object();
    await repository.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsSecondRepositoryAcquiredAfterMutation() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }
  Future<ItemsRepository> _captureOtherRepository() async {
    return ref.read(otherRepositoryProvider);
  }

  Future<void> saveItem() async {
    final repository = await _captureRepository();
    if (repository == null) return;
    state = Object();
    await repository.save();
    await (await _captureOtherRepository()).save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsNullableRepositoryWithoutGuardedOperation() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    final repository = await _captureRepository();
    state = Object();
    await repository?.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsNullableRepositoryForcedAtOperation() async {
    final source = _source(r'''
  Future<ItemsRepository?> _captureRepository() async {
    final repository = ref.read(repositoryProvider);
    return repository;
  }

  Future<void> saveItem() async {
    final repository = await _captureRepository();
    state = Object();
    await repository!.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsClassGetterThatLooksLikeRecordResourceCapture() async {
    final source = _source(
      r'''
  Future<void> saveItem() async {
    final context = RepositoryContext(ref.read(repositoryProvider));
    state = Object();
    await context.repository.save();
  }
''',
      extraDeclarations: r'''
final class RepositoryContext {
  RepositoryContext(this.repository);
  final ItemsRepository repository;
}
''',
    );

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsUnusedTypedRecordCapture() async {
    final source = _source(r'''
  ({ItemsRepository repository}) _captureRepositoryContext() =>
      (repository: ref.read(repositoryProvider));

  Future<void> saveItem() async {
    final context = _captureRepositoryContext();
    state = Object();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsSecondRepositoryGetterUsedAfterBoundary() async {
    final source = _source(r'''
  ItemsRepository get _repository => ref.read(repositoryProvider);
  ItemsRepository get _otherRepository => ref.read(otherRepositoryProvider);

  Future<void> saveItem() async {
    final repository = _repository;
    state = Object();
    await repository.save();
    await _otherRepository.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsCapturedGetterReevaluatedAfterBoundary() async {
    final source = _source(r'''
  ItemsRepository get _repository => ref.read(repositoryProvider);

  Future<void> saveItem() async {
    final repository = _repository;
    state = Object();
    await repository.save();
    await _repository.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _allowsNotifierOperationCapturedBeforeMutation() async {
    final source = _source(
      r'''
  Future<void> saveItem() async {
    final save = ref.read(itemsNotifierProvider.notifier).save;
    state = Object();
    await save();
  }
''',
      extraDeclarations: r'''
class ItemsController {
  Future<void> save() async {}
}
final itemsNotifierProvider = NotifierProvider<ItemsController>();
''',
    );

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsScalarProviderReadAfterMutationBoundary() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    final repository = ref.read(repositoryProvider);
    state = Object();
    await repository.save();
    if (!ref.mounted) return;
    if (ref.read(selectedIdProvider) == 'item') state = Object();
  }
''', extraDeclarations: "final selectedIdProvider = Provider<String>('item');");

    await assertNoDiagnostics(source);
  }

  Future<void> _scalarProviderReadAloneDoesNotNeedDependencyCapture() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    state = Object();
    ref.read(selectedIdProvider);
  }
''', extraDeclarations: "final selectedIdProvider = Provider<String>('item');");

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsAnotherProviderReadAfterCapturedOperation() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    final save = ref.read(repositoryProvider).save;
    state = Object();
    await save();
    await ref.read(otherRepositoryProvider).save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsSkillSaveReadAfterStateWrite() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    state = Object();
    await ref.read(repositoryProvider).save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsSkillOptimisticUpdateAndGuardedReads() async {
    final source = _source(r'''
  Future<void> markRead() async {
    final previous = state;
    state = Object();
    try {
      await ref.read(repositoryProvider).save();
      if (!ref.mounted) return;
      await ref.read(otherRepositoryProvider).save();
    } catch (error) {
      if (!ref.mounted) return;
      state = previous;
    }
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _allowsExplicitThisStateWriteBeforeDirectRead() async {
    final source = _source(r'''
  Future<void> saveItem() async {
    this.state = Object();
    final save = ref.read(repositoryProvider).save;
    await save();
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _reportsNullableUninitializedRepository() async {
    final source = _source(r'''
  ItemsRepository? _repository;

  Future<void> saveItem() async {
    if (_repository == null) return;
    state = Object();
    await _repository!.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsNullableRepositoryUsedAlongsideCapture() async {
    final source = _source(r'''
  ItemsRepository? _repository;

  Future<void> saveItem() async {
    final save = ref.read(repositoryProvider).save;
    state = Object();
    await save();
    await _repository!.save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _allowsDirectHelperInitializationBeforeMutation() async {
    final source = _source(r'''
  ItemsRepository? _repository;

  Future<void> saveItem() async {
    _ensureDependencies();
    state = Object();
    await _repository!.save();
  }

  void _ensureDependencies() {
    _repository ??= ref.read(repositoryProvider);
  }
''');

    await assertNoDiagnostics(source);
  }

  Future<void> _rejectsHelperAssignmentToSameNamedFieldOnOtherObject() async {
    final source = _source(r'''
  ItemsRepository? _repository;
  final _other = OtherBox();

  Future<void> saveItem() async {
    _ensureDependencies();
    state = Object();
    await _repository!.save();
  }

  void _ensureDependencies() {
    _other._repository ??= ref.read(repositoryProvider);
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _rejectsRepositoryResetAfterHelperInitialization() async {
    final source = _source(r'''
  ItemsRepository? _repository;

  Future<void> saveItem() async {
    _ensureDependencies();
    _repository = null;
    state = Object();
    await _repository!.save();
  }

  void _ensureDependencies() {
    _repository ??= ref.read(repositoryProvider);
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsFakeEnsureHelperWithoutInitialization() async {
    final source = _source(r'''
  ItemsRepository? _repository;

  Future<void> saveItem() async {
    _ensureRepository();
    state = Object();
    await _repository!.save();
  }

  void _ensureRepository() {}
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _reportsConditionalPathWithoutGuaranteedInitialization() async {
    final source = _source(r'''
  Future<void> saveItem(bool initialize) async {
    late final Future<void> Function() save;
    if (initialize) {
      save = ref.read(repositoryProvider).save;
    }
    state = Object();
    await save();
  }
''');

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _doesNotTrustAppDefinedRefWithRiverpodName() async {
    const source = r'''
import 'package:riverpod/riverpod.dart';

class FakeRef {
  ItemsRepository read(Provider<ItemsRepository> provider) => ItemsRepository();
}

class Notifier<T> {
  FakeRef get ref => FakeRef();
  T? state;
}

class ItemsRepository {
  Future<void> save() async {}
}

final repositoryProvider = Provider<ItemsRepository>(ItemsRepository());

class ItemsNotifier extends Notifier<Object> {
  Future<void> saveItem() async {
    final save = ref.read(repositoryProvider).save;
    state = Object();
    await save();
  }
}
''';

    await _expectNotifierDiagnostic(source);
  }

  Future<void> _expectNotifierDiagnostic(String source) async {
    const methodDeclaration = 'Future<void> saveItem';
    final methodOffset = source.indexOf(methodDeclaration);
    final lineStart = source.lastIndexOf('\n', methodOffset) + 1;
    final lineEnd = source.indexOf('\n', lineStart);
    await assertDiagnostics(source, [lint(lineStart, lineEnd - lineStart, name: _ruleName)]);
  }

  String _source(String members, {String extraDeclarations = ''}) =>
      '''
import 'package:riverpod/riverpod.dart';

class ItemsRepository {
  Future<void> save() async {}
}

class OtherBox {
  ItemsRepository? _repository;
}

final repositoryProvider = Provider<ItemsRepository>(ItemsRepository());
final otherRepositoryProvider = Provider<ItemsRepository>(ItemsRepository());
$extraDeclarations

class ItemsNotifier extends Notifier<Object> {
$members
}
''';
}
