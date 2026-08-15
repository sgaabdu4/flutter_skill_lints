import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/function_body_rule.dart';

/// Warns when an explicit nullable return type is not needed.
class AvoidUnnecessaryNullableReturnType extends GeneratedFunctionAndMethodBodyCheckRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_nullable_return_type',
    'Avoid unnecessary nullable return types.',
    correctionMessage: 'Remove the nullable marker or return null from this function.',
  );

  AvoidUnnecessaryNullableReturnType()
    : super(
        name: 'avoid_unnecessary_nullable_return_type',
        description: 'Warns when a nullable return type has no nullable return path.',
        code: code,
      );

  @override
  void checkNonOverrideFunctionBody(TypeAnnotation? returnType, FunctionBody body) {
    _check(returnType, body);
  }

  void _check(TypeAnnotation? returnType, FunctionBody body) {
    if (returnType is! NamedType || returnType.question == null) return;
    if (!_provesNonNullReturn(body)) return;

    reportAtNode(returnType);
  }

  bool _provesNonNullReturn(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _isNonNullableExpression(body.expression);
    }
    if (body is! BlockFunctionBody) return false;

    final returns = _LocalReturnCollector(body).returns;
    if (returns.isEmpty) return false;
    if (returns.any((statement) => !_isNonNullableExpression(statement.expression))) {
      return false;
    }

    return _blockAlwaysExits(body.block);
  }

  bool _isNonNullableExpression(Expression? expression) {
    if (expression == null || expression is NullLiteral) return false;

    final type = expression.staticType;
    if (type == null) return false;

    return type.nullabilitySuffix != NullabilitySuffix.question;
  }

  bool _blockAlwaysExits(Block block) {
    final statements = block.statements;
    if (statements.isEmpty) return false;

    final last = statements.last;
    return switch (last) {
      ReturnStatement() => true,
      ExpressionStatement(expression: ThrowExpression()) => true,
      IfStatement(:final elseStatement?) =>
        _statementAlwaysExits(last.thenStatement) && _statementAlwaysExits(elseStatement),
      _ => false,
    };
  }

  bool _statementAlwaysExits(Statement statement) {
    return switch (statement) {
      ReturnStatement() => true,
      ExpressionStatement(expression: ThrowExpression()) => true,
      Block() => _blockAlwaysExits(statement),
      IfStatement(:final elseStatement?) =>
        _statementAlwaysExits(statement.thenStatement) && _statementAlwaysExits(elseStatement),
      _ => false,
    };
  }
}

final class _LocalReturnCollector extends RecursiveAstVisitor<void> {
  _LocalReturnCollector(FunctionBody body) {
    body.accept(this);
  }

  final List<ReturnStatement> returns = <ReturnStatement>[];

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitReturnStatement(ReturnStatement node) {
    returns.add(node);
  }
}
