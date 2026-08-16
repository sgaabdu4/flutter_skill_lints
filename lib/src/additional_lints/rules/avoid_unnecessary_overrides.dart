import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

/// Warns when a class or mixin overrides a member without adding
/// implementation or changing the signature.
///
/// Detects:
/// - Methods that only call `super.method(...)` with identical arguments
/// - Getters that only return `super.getter`
/// - Setters that only assign `super.setter = value`
/// - Abstract redeclarations without implementation changes
class AvoidUnnecessaryOverrides extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_overrides',
    'This override of {0} does not add any implementation.',
    correctionMessage: 'Remove this unnecessary override.',
  );

  AvoidUnnecessaryOverrides()
    : super(
        name: 'avoid_unnecessary_overrides',
        description:
            'Warns when a member override only delegates to super '
            'without additional logic.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
    registry.addMixinDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryOverrides rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _checkMembers(node.body);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _checkMembers(node.body);
  }

  void _checkMembers(ClassBody body) {
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is MethodDeclaration) {
        if (!hasOverrideAnnotation(member)) continue;
        _checkMethodDeclaration(member);
      }
    }
  }

  void _checkMethodDeclaration(MethodDeclaration member) {
    final memberName = member.name.lexeme;

    // Abstract redeclaration — no body at all (EmptyFunctionBody)
    if (!member.isComplete) {
      rule.reportAtNode(member, arguments: [memberName]);
      return;
    }

    if (member.isGetter) {
      if (_isUnnecessaryGetter(member, memberName)) {
        rule.reportAtNode(member, arguments: [memberName]);
      }
    } else if (member.isSetter) {
      if (_isUnnecessarySetter(member, memberName)) {
        rule.reportAtNode(member, arguments: [memberName]);
      }
    } else {
      if (_isOnlySuperCall(member, memberName)) {
        rule.reportAtNode(member, arguments: [memberName]);
      }
    }
  }

  /// Checks if a method only calls `super.methodName(...)` passing through
  /// all parameters in the same order.
  static bool _isOnlySuperCall(MethodDeclaration method, String methodName) {
    final expression = _singleOverrideExpression(method.body);
    if (expression == null) return false;

    if (expression is MethodInvocation) {
      return expression.target is SuperExpression &&
          expression.methodName.name == methodName &&
          _areArgsPassThrough(method.parameters, expression.argumentList);
    }

    return method.isOperator &&
        expression is BinaryExpression &&
        expression.leftOperand is SuperExpression &&
        expression.operator.lexeme == methodName &&
        _isSingleParamPassThrough(method.parameters, expression.rightOperand);
  }

  static Expression? _singleOverrideExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is! BlockFunctionBody || body.block.statements.length != 1) return null;
    final statement = body.block.statements.single;
    return switch (statement) {
      ReturnStatement(:final expression) => expression,
      ExpressionStatement(:final expression) => expression,
      _ => null,
    };
  }

  /// Checks if a binary operator's right operand is just the method's
  /// single parameter passed through.
  static bool _isSingleParamPassThrough(FormalParameterList? params, Expression operand) {
    if (params == null) return false;
    final parameters = params.parameters;
    if (parameters.length != 1) return false;
    final paramName = parameters.first.name?.lexeme;
    return paramName != null && operand is SimpleIdentifier && operand.name == paramName;
  }

  /// Checks if the arguments in the call match the method's parameters
  /// exactly (same order, same names for positional, same names for named).
  static bool _areArgsPassThrough(FormalParameterList? params, ArgumentList args) {
    if (params == null) return args.arguments.isEmpty;

    final parameters = params.parameters;
    final arguments = args.arguments;

    if (parameters.length != arguments.length) return false;

    for (var i = 0; i < parameters.length; i++) {
      if (!_argumentPassesThrough(parameters[i], arguments[i])) return false;
    }

    return true;
  }

  static bool _argumentPassesThrough(FormalParameter param, Argument arg) {
    final paramName = param.name?.lexeme;
    if (paramName == null) return false;
    if (arg is NamedArgument) {
      final expr = arg.argumentExpression;
      return arg.name.lexeme == paramName && expr is SimpleIdentifier && expr.name == paramName;
    }
    return arg is SimpleIdentifier && arg.name == paramName;
  }

  /// Checks if a getter only returns `super.getter`.
  static bool _isUnnecessaryGetter(MethodDeclaration method, String getterName) {
    final expression = _singleBodyExpression(method);
    if (expression == null) return false;

    return _isSuperPropertyAccess(expression, getterName);
  }

  /// Checks if a setter only assigns `super.setter = value`.
  static bool _isUnnecessarySetter(MethodDeclaration method, String setterName) {
    final expression = _singleBodyExpression(method);
    if (expression == null) return false;
    if (expression is! AssignmentExpression) return false;

    // Left-hand side must be super.setterName
    final lhs = expression.leftHandSide;
    if (!_isSuperPropertyAccess(lhs, setterName)) return false;

    // Right-hand side must be the setter's parameter
    final param = method.parameters?.parameters.firstOrNull;
    if (param == null) return false;
    final paramName = param.name?.lexeme;
    if (paramName == null) return false;

    final rhs = expression.rightHandSide;
    return rhs is SimpleIdentifier && rhs.name == paramName;
  }

  static Expression? _singleBodyExpression(MethodDeclaration method) {
    final body = method.body;
    if (body is ExpressionFunctionBody) return body.expression;
    if (body is! BlockFunctionBody || body.block.statements.length != 1) return null;

    final statement = body.block.statements.single;
    return switch ((method.isGetter, statement)) {
      (true, ReturnStatement(:final expression?)) => expression,
      (false, ExpressionStatement(:final expression)) => expression,
      _ => null,
    };
  }

  /// Checks if an expression is `super.name` (either PropertyAccess or
  /// PrefixedIdentifier form).
  static bool _isSuperPropertyAccess(Expression expression, String name) {
    if (expression is PropertyAccess) {
      return expression.target is SuperExpression && expression.propertyName.name == name;
    }
    return false;
  }
}
