import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a `State` class contains method overrides that only call the
/// super implementation without any additional logic.
class AvoidUnnecessaryOverridesInState extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_overrides_in_state',
    'This method override only calls super.{0}() without additional logic.',
    correctionMessage: 'Remove this unnecessary override.',
  );

  AvoidUnnecessaryOverridesInState()
    : super(
        name: 'avoid_unnecessary_overrides_in_state',
        description:
            'Warns when a State class contains method overrides that only '
            'call super without additional logic.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryOverridesInState rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = flutterStateBody(node);
    if (body == null) return;

    for (final member in body.members) {
      if (member is! MethodDeclaration) continue;
      if (!hasOverrideAnnotation(member)) continue;

      final methodName = member.name.lexeme;

      if (_isOnlySuperCall(member, methodName)) {
        rule.reportAtNode(member, arguments: [methodName]);
      }
    }
  }

  /// Checks if the method body only contains a call to super.methodName().
  static bool _isOnlySuperCall(MethodDeclaration method, String methodName) {
    final body = method.body;

    // Expression body: => super.methodName();
    if (body is ExpressionFunctionBody) {
      return _isSuperMethodCall(body.expression, methodName);
    }

    // Block body: { super.methodName(); }
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.length != 1) return false;

      final statement = statements.first;
      if (statement is! ExpressionStatement) return false;

      return _isSuperMethodCall(statement.expression, methodName);
    }

    return false;
  }

  static bool _isSuperMethodCall(Expression expression, String methodName) {
    if (expression is! MethodInvocation) return false;

    return expression.target is SuperExpression &&
        expression.methodName.name == methodName &&
        expression.argumentList.arguments.isEmpty;
  }
}
