import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a string literal is exactly the name of an in-scope local value.
class AvoidMissingInterpolation extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_missing_interpolation',
    "String literal matches the in-scope local variable '{0}'.",
    correctionMessage: 'Use interpolation when the variable value is intended.',
  );

  AvoidMissingInterpolation()
    : super(
        name: 'avoid_missing_interpolation',
        description: 'Warns when a string literal exactly matches an in-scope local variable name.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addSimpleStringLiteral(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMissingInterpolation rule;

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final name = node.value;
    if (!_isIdentifier(name)) return;
    if (!_isVisibleLocalName(node, name)) return;
    rule.reportAtNode(node, arguments: [name]);
  }
}

bool _isIdentifier(String value) {
  if (value.isEmpty) return false;
  final first = value.codeUnitAt(0);
  if (!_isIdentifierStart(first)) return false;
  for (var i = 1; i < value.length; i++) {
    if (!_isIdentifierPart(value.codeUnitAt(i))) return false;
  }
  return true;
}

bool _isIdentifierStart(int code) =>
    code == 0x5F || code >= 0x41 && code <= 0x5A || code >= 0x61 && code <= 0x7A;

bool _isIdentifierPart(int code) => _isIdentifierStart(code) || code >= 0x30 && code <= 0x39;

bool _isVisibleLocalName(SimpleStringLiteral node, String name) {
  if (node.thisOrAncestorOfType<FunctionBody>() == null) return false;
  if (_hasEnclosingParameterNamed(node, name)) return true;

  AstNode? current = node;
  while (current != null) {
    final block = current.parent;
    if (block is Block) {
      final statement = _enclosingStatementInside(current, block);
      if (statement != null && _hasPriorLocalVariable(block, statement, name)) {
        return true;
      }
    }
    current = current.parent;
  }

  return false;
}

bool _hasEnclosingParameterNamed(AstNode node, String name) {
  AstNode? current = node.parent;
  while (current != null) {
    final parameters = switch (current) {
      FunctionDeclaration(:final functionExpression) => functionExpression.parameters,
      FunctionExpression(:final parameters) => parameters,
      MethodDeclaration(:final parameters) => parameters,
      ConstructorDeclaration(:final parameters) => parameters,
      _ => null,
    };

    if (parameters?.parameters.any((parameter) => parameter.name?.lexeme == name) ?? false) {
      return true;
    }

    current = current.parent;
  }
  return false;
}

Statement? _enclosingStatementInside(AstNode node, Block block) {
  AstNode? current = node;
  while (current != null && current.parent != block) {
    current = current.parent;
  }
  return current is Statement ? current : null;
}

bool _hasPriorLocalVariable(Block block, Statement statement, String name) {
  for (final candidate in block.statements) {
    if (identical(candidate, statement)) return false;
    if (candidate is! VariableDeclarationStatement) continue;
    for (final variable in candidate.variables.variables) {
      if (variable.name.lexeme == name) return true;
    }
  }
  return false;
}
