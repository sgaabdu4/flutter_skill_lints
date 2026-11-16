part of '../source_scanner_rules_test.dart';

final class _AppwriteBlockingFunctionExecutionInClientTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_AppwriteBlockingFunctionExecutionInClientTest)>
  get _allCases => caseSet<_AppwriteBlockingFunctionExecutionInClientTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_reportsOmittedXasyncInLongRunningMethod': (t) =>
          t._reportsOmittedXasyncInLongRunningMethod(),
      'test_reportsClientWaitingForBackendCompletion': (t) =>
          t._reportsClientWaitingForBackendCompletion(),
      'test_allowsUnresolvedWaitForCompletionLookalike': (t) =>
          t._allowsUnresolvedWaitForCompletionLookalike(),
      'test_allowsAsyncExecution': (t) => t._allowsAsyncExecution(),
      'test_allowsForwardingWrapperWithXasyncParameter': (t) =>
          t._allowsForwardingWrapperWithXasyncParameter(),
      'test_allowsShortInteractiveFunction': (t) => t._allowsShortInteractiveFunction(),
    },
  );

  @override
  String get ruleName => 'appwrite_blocking_function_execution_in_client';
  @override
  String get needle => 'createExecution(';
  @override
  String get source => r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await functions.createExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: false,
    );
  }
}
''';

  Future<void> _reportsOmittedXasyncInLongRunningMethod() async {
    const source = r'''
class ImportRemoteDatasource {
  Future<void> importData(String userId) async {
    await functions.createExecution(
      functionId: importDataFunctionId,
      body: userId,
    );
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'createExecution(', ruleName),
    ]);
  }

  Future<void> _reportsClientWaitingForBackendCompletion() async {
    const source = r'''
class DeleteResult {}

abstract interface class AccountRemote {
  Future<DeleteResult> deleteAccount(String userId, {bool waitForCompletion = false});
  Future<bool> startDeleteAccount(String userId);
  Future<bool> waitForAccountDeleted(String userId, {int maxAttempts = 30});
  Future<DeleteResult> refreshProfile(String userId, {bool waitForCompletion = false});
}

class AccountRepository {
  AccountRepository(this.remote);
  final AccountRemote remote;

  Future<DeleteResult> deleteAccount(String userId) async {
    final result = await remote.deleteAccount(userId, waitForCompletion: true);
    return result;
  }

  Future<bool> deleteAccountInBackground(String userId) async {
    final started = await remote.startDeleteAccount(userId);
    if (!started) return false;
    await remote.deleteAccount(userId, waitForCompletion: false);
    return remote.waitForAccountDeleted(userId, maxAttempts: 60);
  }

  Future<DeleteResult> refresh(String userId) {
    return remote.refreshProfile(userId, waitForCompletion: true);
  }
}
''';
    final analyzedSource = _analyzedSource(source, addIgnorePrefix: addIgnorePrefix);

    await assertDiagnostics(analyzedSource, [
      compatLint(analyzedSource, 'deleteAccount(userId, waitForCompletion: true);', ruleName),
    ]);
  }

  Future<void> _allowsUnresolvedWaitForCompletionLookalike() async {
    await assertAllows(r'''
class AccountRepository {
  Future<void> deleteAccount(String userId) async {
    await remote.deleteAccount(userId, waitForCompletion: true);
  }
}
''');
  }

  Future<void> _allowsAsyncExecution() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await functions.createExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: true,
    );
  }
}
''');
  }

  Future<void> _allowsForwardingWrapperWithXasyncParameter() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> deleteAccount(String userId) async {
    await _createDeleteUserExecution(
      functionId: deleteAccountFunctionId,
      body: userId,
      xasync: true,
    );
  }

  Future<void> _createDeleteUserExecution({
    required String functionId,
    String? body,
    bool? xasync,
  }) {
    return functions.createExecution(functionId: functionId, body: body, xasync: xasync);
  }
}
''');
  }

  Future<void> _allowsShortInteractiveFunction() async {
    await assertAllows(r'''
class AuthRemoteDatasource {
  Future<void> ping(String userId) async {
    await functions.createExecution(
      functionId: pingFunctionId,
      body: userId,
    );
  }
}
''');
  }
}

final class _DestructiveFailureLoggedBeforeReconcileTest extends _RuntimeBugRuleTest {
  static Map<String, Future<void> Function(_DestructiveFailureLoggedBeforeReconcileTest)>
  get _allCases => caseSet<_DestructiveFailureLoggedBeforeReconcileTest>(
    parent: _SourceRuleTest._allCases,
    own: {
      'test_allowsReconcileBeforeTelemetry': (t) => t._allowsReconcileBeforeTelemetry(),
      'test_reportsSkillTelemetryBeforeWaitForReconcile': (t) =>
          t._reportsSkillTelemetryBeforeWaitForReconcile(),
      'test_reportsTelemetryWithoutReconcileAfterAsyncStart': (t) =>
          t._reportsTelemetryWithoutReconcileAfterAsyncStart(),
      'test_allowsSkillAsyncStartThenReconcile': (t) => t._allowsSkillAsyncStartThenReconcile(),
      'test_allowsOrdinaryDestructiveTelemetry': (t) => t._allowsOrdinaryDestructiveTelemetry(),
    },
  );

  @override
  String get ruleName => 'destructive_failure_logged_before_reconcile';
  @override
  String get needle => 'Crash.error(e, s)';
  @override
  String get source => r'''
class AuthNotifier {
  Future<void> deleteAccount() async {
    try {
      await repository.deleteAccount();
    } catch (e, s) {
      Crash.error(e, s);
      await _reconcileDeletedAccountState();
    }
  }

  Future<void> _reconcileDeletedAccountState() async {}
}
''';

  Future<void> _allowsReconcileBeforeTelemetry() async {
    await assertAllows(r'''
class AuthNotifier {
  Future<void> deleteAccount() async {
    try {
      await repository.deleteAccount();
    } catch (e, s) {
      final reconciled = await _reconcileDeletedAccountState();
      if (!reconciled) {
        Crash.error(e, s);
      }
    }
  }

  Future<bool> _reconcileDeletedAccountState() async => true;
}
''');
  }

  // networking.md "Long-Running Remote Work" WRONG: reports before reconcile.
  Future<void> _reportsSkillTelemetryBeforeWaitForReconcile() async {
    final source = _analyzedSource(r'''
class DeleteResult {
  const DeleteResult.ok();
  const DeleteResult.timedOut();
}

class AccountRepository {
  Future<DeleteResult> deleteAccount(String userId) async {
    try {
      return await remote.startDeleteAccount(userId);
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'deleteAccount');
      final deleted = await remote.waitForAccountDeleted(userId, maxAttempts: 60);
      return deleted ? .ok() : .timedOut();
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [compatLint(source, 'Crash.error', ruleName)]);
  }

  Future<void> _reportsTelemetryWithoutReconcileAfterAsyncStart() async {
    final source = _analyzedSource(r'''
class AccountRepository {
  Future<bool> deleteAccount(String userId) async {
    try {
      await remote.startDeleteAccount(userId);
      return true;
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'startDelete');
      return false;
    }
  }

  Future<bool> removeWorkspace(String workspaceId) async {
    try {
      await functions.createExecution(functionId: workspaceFunctionId, xasync: true);
      return true;
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      return false;
    }
  }
}
''', addIgnorePrefix: addIgnorePrefix);
    await assertDiagnostics(source, [
      compatLint(source, 'Crash.error', ruleName),
      compatLint(source, 'Sentry.captureException', ruleName),
    ]);
  }

  Future<void> _allowsSkillAsyncStartThenReconcile() async {
    await assertAllows(r'''
class DeleteResult {
  const DeleteResult.ok();
  const DeleteResult.timedOut();
}

class AccountRepository {
  Future<DeleteResult> deleteAccount(String userId) async {
    final started = await remote.startDeleteAccount(userId);
    if (!started.ok) return started;
    final deleted = await remote.waitForAccountDeleted(userId, maxAttempts: 60);
    return deleted ? .ok() : .timedOut();
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await functions.createExecution(functionId: deleteAccountFunctionId, xasync: true);
      return await waitForDeleted(userId, maxAttempts: 60);
    } catch (e, s) {
      final deleted = await _reconcileDeletedState();
      if (!deleted) Crash.error(e, s);
      return deleted;
    }
  }
}
''');
  }

  Future<void> _allowsOrdinaryDestructiveTelemetry() async {
    await assertAllows(r'''
class ProductNotifier {
  Future<void> deleteProduct(String id) async {
    try {
      await ref.read(productRepositoryProvider).delete(id);
    } on Exception catch (e, s) {
      state = state.copyWith(error: AppErrorMapper.from(e));
      Crash.error(e, s, reason: 'ProductNotifier.deleteProduct');
    }
  }

  Future<void> cancelSession() async {
    try {
      startTimer();
      await session.close();
    } on Exception catch (e, s) {
      Crash.error(e, s, reason: 'cancelSession');
    }
  }
}
''');
  }
}

void _defineSourceScannerRulesPart15BTests() {
  analysisRuleSuite<_AppwriteBlockingFunctionExecutionInClientTest>(
    'AppwriteBlockingFunctionExecutionInClientTest',
    _AppwriteBlockingFunctionExecutionInClientTest.new,
    _AppwriteBlockingFunctionExecutionInClientTest._allCases,
  );
  analysisRuleSuite<_DestructiveFailureLoggedBeforeReconcileTest>(
    'DestructiveFailureLoggedBeforeReconcileTest',
    _DestructiveFailureLoggedBeforeReconcileTest.new,
    _DestructiveFailureLoggedBeforeReconcileTest._allCases,
  );
}
