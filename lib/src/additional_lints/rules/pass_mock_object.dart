import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when Mocktail verification/stubbing receives a non-mock target.
final class PassMockObject extends AnalysisRule {
  static const LintCode code = LintCode(
    'pass_mock_object',
    'Pass a mock object to mocktail calls.',
    correctionMessage: 'Call when(), verify(), or verifyNever() with a mock object interaction.',
  );

  PassMockObject()
    : super(
        name: 'pass_mock_object',
        description: 'Warns when mocktail stubbing or verification targets a regular object.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PassMockObject rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isMocktailEntryPoint(node.methodName.name)) return;

    final callback = _singleCallbackArgument(node);
    if (callback == null) return;

    final target = _firstInteractionTarget(callback.body);
    if (target == null) return;

    final targetType = target.staticType;
    if (targetType is! InterfaceType) return;
    if (_isMockType(targetType)) return;

    rule.reportAtNode(target);
  }
}

bool _isMocktailEntryPoint(String name) {
  return name == 'when' || name == 'verify' || name == 'verifyNever' || name == 'untilCalled';
}

FunctionExpression? _singleCallbackArgument(MethodInvocation node) {
  final arguments = node.argumentList.arguments.where((argument) => argument is! NamedExpression);
  if (arguments.length != 1) return null;

  final argument = arguments.single;
  return argument is FunctionExpression ? argument : null;
}

Expression? _firstInteractionTarget(FunctionBody body) {
  final expression = switch (body) {
    ExpressionFunctionBody(:final expression) => expression,
    BlockFunctionBody(:final block) => _singleExpressionStatement(block.statements),
    _ => null,
  };

  return switch (expression) {
    MethodInvocation(:final target?) => target,
    PropertyAccess(:final target) => target,
    PrefixedIdentifier(:final prefix) => prefix,
    _ => null,
  };
}

Expression? _singleExpressionStatement(NodeList<Statement> statements) {
  if (statements.length != 1) return null;

  final statement = statements.single;
  return statement is ExpressionStatement ? statement.expression : null;
}

bool _isMockType(InterfaceType type) {
  if (type.element.name == 'Mock') return true;
  return type.allSupertypes.any((supertype) => supertype.element.name == 'Mock');
}
