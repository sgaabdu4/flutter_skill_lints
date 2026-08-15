import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a widget callback argument contains non-trivial inline logic.
final class PreferExtractingCallbacks extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_extracting_callbacks',
    'Extract non-trivial widget callbacks.',
    correctionMessage: 'Move the callback body to a named method or local variable.',
  );

  PreferExtractingCallbacks()
    : super(
        name: 'prefer_extracting_callbacks',
        description: 'Warns when widget callback arguments contain non-trivial inline logic.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferExtractingCallbacks rule;

  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null || !_widgetChecker.isAssignableFromType(type)) return;

    for (final argument in node.argumentList.arguments.whereType<NamedArgument>()) {
      if (!_isCallbackName(argument.name.lexeme)) continue;

      final expression = argument.argumentExpression;
      if (expression is FunctionExpression && _isNonTrivial(expression.body)) {
        rule.reportAtNode(expression.parameters);
      }
    }
  }

  static bool _isCallbackName(String name) {
    if (!name.startsWith('on') || name.length <= 2) return false;

    final thirdCodeUnit = name.codeUnitAt(2);
    return thirdCodeUnit >= 65 && thirdCodeUnit <= 90;
  }

  static bool _isNonTrivial(FunctionBody body) {
    return switch (body) {
      BlockFunctionBody(:final block) => _blockIsNonTrivial(block),
      ExpressionFunctionBody(:final expression) => _expressionIsNonTrivial(expression),
      EmptyFunctionBody() || NativeFunctionBody() => false,
    };
  }

  static bool _blockIsNonTrivial(Block block) {
    if (block.statements.length > 1) return true;
    if (block.statements.isEmpty) return false;

    final statement = block.statements.single;
    if (statement is ReturnStatement) {
      final expression = statement.expression;
      return expression != null && _expressionIsNonTrivial(expression);
    }

    return statement is IfStatement ||
        statement is ForStatement ||
        statement is WhileStatement ||
        statement is DoStatement ||
        statement is SwitchStatement ||
        statement is TryStatement;
  }

  static bool _expressionIsNonTrivial(Expression expression) {
    return switch (expression) {
      AwaitExpression() ||
      ConditionalExpression() ||
      CascadeExpression() ||
      ThrowExpression() => true,
      MethodInvocation() || FunctionExpressionInvocation() || SimpleIdentifier() => false,
      ParenthesizedExpression(:final expression) => _expressionIsNonTrivial(expression),
      _ => false,
    };
  }
}
