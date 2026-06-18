import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a try statement is nested in another try statement.
class AvoidNestedTryStatements extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_try_statements',
    'Avoid nested try statements.',
    correctionMessage: 'Extract the inner operation or handle errors in one place.',
  );

  AvoidNestedTryStatements()
    : super(
        name: 'avoid_nested_try_statements',
        description: 'Warns when a try statement is nested in another try statement.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addTryStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNestedTryStatements rule;

  @override
  void visitTryStatement(TryStatement node) {
    if (_hasEnclosingTryStatement(node)) {
      rule.reportAtNode(node);
    }
  }
}

bool _hasEnclosingTryStatement(TryStatement node) {
  AstNode? parent = node.parent;

  while (parent != null) {
    if (parent is TryStatement) return true;
    if (parent is FunctionBody) return false;
    parent = parent.parent;
  }

  return false;
}
