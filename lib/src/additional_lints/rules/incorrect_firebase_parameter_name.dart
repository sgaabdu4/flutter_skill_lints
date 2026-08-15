import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/firebase_name_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a literal Firebase Analytics parameter name is invalid.
class IncorrectFirebaseParameterName extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'incorrect_firebase_parameter_name',
    'Use a valid Firebase Analytics parameter name.',
    correctionMessage:
        'Parameter names must start with a letter, contain only letters, digits, '
        'and underscores, be 1-40 characters long, and avoid reserved prefixes.',
  );

  IncorrectFirebaseParameterName()
    : super(
        code: code,
        name: 'incorrect_firebase_parameter_name',
        description: 'Warns when Firebase Analytics logEvent uses invalid literal parameter names.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final IncorrectFirebaseParameterName rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'logEvent') return;

    final parameters = _parametersArgument(node.argumentList);
    if (parameters == null) return;

    for (final entry in parameters.elements.whereType<MapLiteralEntry>()) {
      final key = entry.key;
      if (key is! SimpleStringLiteral || isValidFirebaseName(key.value)) continue;
      rule.reportAtNode(key);
    }
  }
}

SetOrMapLiteral? _parametersArgument(ArgumentList argumentList) {
  for (final argument in argumentList.arguments.whereType<NamedArgument>()) {
    if (argument.name.lexeme != 'parameters') continue;
    final expression = argument.argumentExpression;
    return expression is SetOrMapLiteral ? expression : null;
  }

  return null;
}
