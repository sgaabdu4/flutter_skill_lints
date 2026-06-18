import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `toString()` override directly calls itself.
class AvoidRecursiveToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_recursive_tostring',
    'Avoid recursive toString() implementations.',
    correctionMessage: 'Build the string from fields instead of calling toString() on this object.',
  );

  AvoidRecursiveToString()
    : super(
        name: 'avoid_recursive_tostring',
        description: 'Warns when toString() directly calls itself.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidRecursiveToString rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'toString') return;
    if (node.isGetter || node.parameters?.parameters.isNotEmpty == true) return;

    final finder = _RecursiveToStringFinder();
    node.body.visitChildren(finder);
    final recursiveNode = finder.recursiveNode;
    if (recursiveNode == null) return;

    rule.reportAtNode(recursiveNode);
  }
}

final class _RecursiveToStringFinder extends RecursiveAstVisitor<void> {
  AstNode? recursiveNode;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (recursiveNode != null) return;
    if (node.methodName.name == 'toString' &&
        node.argumentList.arguments.isEmpty &&
        _isSelfTarget(node.target)) {
      recursiveNode = node.methodName;
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (recursiveNode != null) return;
    if (node.expression is ThisExpression) {
      recursiveNode = node.expression;
      return;
    }

    super.visitInterpolationExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  static bool _isSelfTarget(Expression? target) {
    return target == null || target is ThisExpression;
  }
}
