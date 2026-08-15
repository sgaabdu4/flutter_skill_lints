import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't throw from route-param lookups in build().
///
/// Why: Bans firstWhere(... orElse: () => throw...) inside build methods. Use a nullable by-id
/// provider and render fallback UI instead.
final class AvoidRouteParamThrowInBuild extends GeneratedMethodInvocationCheckRule {
  static const LintCode code = LintCode(
    'avoid_route_param_throw_in_build',
    "Don't throw from route-param lookups in build().",
    correctionMessage: 'Use a nullable by-id provider and render fallback UI instead.',
  );

  AvoidRouteParamThrowInBuild()
    : super(
        name: 'avoid_route_param_throw_in_build',
        description: 'Bans firstWhere(... orElse: () => throw ...) inside build methods.',
        code: code,
      );

  @override
  void checkMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'firstWhere') return;
    final method = enclosingMethod(node);
    if (method == null || method.name.lexeme != 'build') return;
    if (containsThrowExpression(node.argumentList)) {
      reportAtNode(node.methodName);
    }
  }
}
