import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't use ref or state after an await in Notifier methods without checking ref.mounted.
///
/// Why: Requires ref.mounted guards after async gaps in Riverpod Notifier methods. Add 'if
/// (!ref.mounted) return;' immediately after the await.
final class UseRefMountedAfterAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_ref_mounted_after_await',
    "Don't use ref or state after an await in Notifier methods without checking ref.mounted.",
    correctionMessage: "Add 'if (!ref.mounted) return;' immediately after the await.",
  );

  UseRefMountedAfterAwait()
    : super(
        name: 'use_ref_mounted_after_await',
        description: 'Requires ref.mounted guards after async gaps in Riverpod Notifier methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseRefMountedAfterAwait rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.body.isAsynchronous) return;
    final classNode = enclosingClass(node);
    if (classNode == null || !isNotifierClass(classNode)) return;
    final body = node.body;
    if (body is! BlockFunctionBody) return;

    final scanner = AsyncStatementScanner(
      guardTarget: 'ref',
      accessTargets: const {'ref', 'state'},
      onViolation: rule.reportAtNode,
    );
    scanner.scanBlock(body.block);
  }
}
