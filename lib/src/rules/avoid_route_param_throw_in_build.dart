import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't throw from route-param lookups in build().
///
/// Why: Bans throwing lookups inside a Widget `build()`: `firstWhere` with a
/// throwing or missing `orElse`, and a `throw` evaluated by the build itself.
/// Use a nullable by-id provider and render fallback UI instead.
final class AvoidRouteParamThrowInBuild extends GeneratedMethodInvocationCheckRule {
  static const LintCode code = LintCode(
    'avoid_route_param_throw_in_build',
    "Don't throw from route-param lookups in build().",
    correctionMessage: 'Use a nullable by-id provider and render fallback UI instead.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidRouteParamThrowInBuild()
    : super(
        name: 'avoid_route_param_throw_in_build',
        description:
            'Bans throwing firstWhere lookups and direct throws inside Widget build methods.',
        code: code,
      );

  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    super.registerNodeProcessors(registry, context);
    if (shouldRegister(context)) registry.addThrowExpression(this, _ThrowVisitor(this));
  }

  @override
  void checkMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'firstWhere') return;
    final method = enclosingMethod(node);
    if (method == null || !_isWidgetBuild(method)) return;
    final orElse = node.argumentList.arguments.whereType<NamedArgument>().where(
      (argument) => argument.name.lexeme == 'orElse',
    );
    if (orElse.isEmpty ? _isIterableLookup(node) : containsThrowExpression(node.argumentList)) {
      reportAtNode(node.methodName);
    }
  }

  void _checkThrow(ThrowExpression node) {
    final method = enclosingMethod(node);
    if (method == null || !_isWidgetBuild(method)) return;
    if (node.thisOrAncestorOfType<FunctionBody>() == method.body) reportAtNode(node);
  }

  static bool _isWidgetBuild(MethodDeclaration method) {
    if (method.name.lexeme != 'build') return false;
    final returnType = method.declaredFragment?.element.returnType;
    return returnType != null && _widgetChecker.isAssignableFromType(returnType);
  }

  static bool _isIterableLookup(MethodInvocation node) {
    final targetType = node.realTarget?.staticType;
    return targetType != null && _iterableChecker.isAssignableFromType(targetType);
  }
}

final class _ThrowVisitor extends SimpleAstVisitor<void> {
  _ThrowVisitor(this.rule);

  final AvoidRouteParamThrowInBuild rule;

  @override
  void visitThrowExpression(ThrowExpression node) => rule._checkThrow(node);
}
