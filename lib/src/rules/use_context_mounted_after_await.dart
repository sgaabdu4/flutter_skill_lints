import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class UseContextMountedAfterAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_context_mounted_after_await',
    "Don't use BuildContext after an await without checking context.mounted.",
    correctionMessage: "Add 'if (!context.mounted) return;' before using context after an await.",
  );

  UseContextMountedAfterAwait()
    : super(
        name: 'use_context_mounted_after_await',
        description: 'Requires context.mounted guards before BuildContext use after async gaps.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseContextMountedAfterAwait rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.body.isAsynchronous) return;
    _checkBody(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final body = node.functionExpression.body;
    if (!body.isAsynchronous) return;
    _checkBody(body);
  }

  void _checkBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return;
    final scanner = AsyncStatementScanner(
      guardTarget: 'context',
      accessTargets: const {'context'},
      onViolation: rule.reportAtNode,
    );
    scanner.scanBlock(body.block);
  }
}
