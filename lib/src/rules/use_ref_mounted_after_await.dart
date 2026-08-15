import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't use ref or state after an await in Notifier methods without checking ref.mounted.
///
/// Why: Requires ref.mounted guards after async gaps in Riverpod Notifier methods. Add 'if
/// (!ref.mounted) return;' immediately after the await.
final class UseRefMountedAfterAwait extends GeneratedMethodDeclarationCheckRule {
  static const LintCode code = LintCode(
    'use_ref_mounted_after_await',
    "Don't use ref or state after an await in Notifier methods without checking ref.mounted.",
    correctionMessage: "Add 'if (!ref.mounted) return;' immediately after the await.",
  );

  UseRefMountedAfterAwait()
    : super(
        name: 'use_ref_mounted_after_await',
        description: 'Requires ref.mounted guards after async gaps in Riverpod Notifier methods.',
        code: code,
      );

  @override
  @override
  void checkMethodDeclaration(MethodDeclaration node) {
    if (!node.body.isAsynchronous) return;
    final classNode = enclosingClass(node);
    if (classNode == null || !isNotifierClass(classNode)) return;
    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final scanner = AsyncStatementScanner(
      guardTarget: 'ref',
      accessTargets: const {'ref', 'state'},
      onViolation: reportAtNode,
    );
    scanner.scanBlock(body.block);
  }
}
