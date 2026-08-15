import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `toString()` is called on a nullable value.
class AvoidNullableToString extends GeneratedMethodInvocationCheckRule {
  static const LintCode code = LintCode(
    'avoid_nullable_tostring',
    'Avoid calling toString() on nullable values.',
    correctionMessage: 'Handle the null case explicitly before converting the value to a string.',
  );

  AvoidNullableToString()
    : super(
        name: 'avoid_nullable_tostring',
        description: 'Warns when nullable values are converted with toString().',
        code: code,
      );

  @override
  void checkMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final targetType = node.target?.staticType ?? _cascadeTargetType(node);
    if (targetType?.nullabilitySuffix != NullabilitySuffix.question) return;

    reportAtNode(node.methodName);
  }
}

DartType? _cascadeTargetType(MethodInvocation node) {
  for (AstNode? current = node.parent; current != null; current = current.parent) {
    if (current is CascadeExpression) return current.target.staticType;
  }
  return null;
}
