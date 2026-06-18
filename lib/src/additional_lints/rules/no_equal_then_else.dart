import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when both branches of a conditional are the same.
class NoEqualThenElse extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_equal_then_else',
    'The then and else branches are the same.',
    correctionMessage: 'Remove the conditional or make one branch different.',
  );

  NoEqualThenElse()
    : super(
        name: 'no_equal_then_else',
        description: 'Warns when conditional branches contain the same code.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addConditionalExpression(this, visitor);
    registry.addIfStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final NoEqualThenElse rule;

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_sameSource(node.thenExpression, node.elseExpression)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    final elseStatement = node.elseStatement;
    if (elseStatement == null || elseStatement is IfStatement) return;

    final thenSource = _canonicalStatementSource(node.thenStatement);
    final elseSource = _canonicalStatementSource(elseStatement);
    if (thenSource == null || elseSource == null) return;
    if (thenSource.isEmpty || elseSource.isEmpty) return;

    if (thenSource == elseSource) {
      rule.reportAtNode(node);
    }
  }
}

String? _canonicalStatementSource(Statement statement) {
  final unwrapped = _unwrapSingleStatementBlock(statement);
  return switch (unwrapped) {
    ReturnStatement(:final expression?) => 'return ${_canonicalSource(expression)}',
    ExpressionStatement(:final expression) => _canonicalSource(expression),
    _ => null,
  };
}

Statement _unwrapSingleStatementBlock(Statement statement) {
  var current = statement;
  while (current is Block && current.statements.length == 1) {
    current = current.statements.single;
  }
  return current;
}

bool _sameSource(AstNode left, AstNode right) {
  return _canonicalSource(left) == _canonicalSource(right);
}

String _canonicalSource(AstNode node) {
  return node.toSource().replaceAll(RegExp(r'\s+'), ' ').trim();
}
