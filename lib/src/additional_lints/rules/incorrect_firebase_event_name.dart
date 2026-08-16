import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/firebase_name_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a literal Firebase Analytics event name is invalid.
class IncorrectFirebaseEventName extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'incorrect_firebase_event_name',
    'Use a valid Firebase Analytics event name.',
    correctionMessage:
        'Event names must start with a letter, contain only letters, digits, '
        'and underscores, be 1-40 characters long, and avoid reserved prefixes.',
  );

  IncorrectFirebaseEventName()
    : super(
        code: code,
        name: 'incorrect_firebase_event_name',
        description: 'Warns when Firebase Analytics logEvent uses an invalid literal event name.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final IncorrectFirebaseEventName rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'logEvent') return;

    final name = _eventNameArgument(node.argumentList);
    if (name == null || isValidFirebaseName(name.value)) return;

    rule.reportAtNode(name);
  }
}

SimpleStringLiteral? _eventNameArgument(ArgumentList argumentList) {
  for (final argument in argumentList.arguments) {
    if (argument is NamedArgument) {
      if (argument.name.lexeme != 'name') continue;
      final expression = argument.argumentExpression;
      return expression is SimpleStringLiteral ? expression : null;
    }

    return argument is SimpleStringLiteral ? argument : null;
  }

  return null;
}
