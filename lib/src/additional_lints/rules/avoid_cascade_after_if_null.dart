import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when a cascade expression follows an if-null (`??`) operator
/// without parentheses, which can produce unexpected results due to
/// operator precedence.
///
/// **Bad:**
/// ```dart
/// final cow = nullableCow ?? Cow()..moo();
/// ```
///
/// **Good:**
/// ```dart
/// final cow = (nullableCow ?? Cow())..moo();
/// final cow = nullableCow ?? (Cow()..moo());
/// ```
class AvoidCascadeAfterIfNull extends CascadeExpressionCheckRule {
  static const LintCode code = LintCode(
    'avoid_cascade_after_if_null',
    'Cascade after if-null operator without parentheses can produce '
        'unexpected results.',
    correctionMessage: 'Wrap the expression in parentheses to clarify precedence.',
  );

  AvoidCascadeAfterIfNull()
    : super(
        name: 'avoid_cascade_after_if_null',
        description:
            'Warns when a cascade follows an if-null operator '
            'without parentheses.',
        code: code,
      );

  @override
  void checkCascadeExpression(CascadeExpression node) {
    final target = node.target;
    if (target is BinaryExpression && target.operator.type == TokenType.QUESTION_QUESTION) {
      reportAtNode(node);
    }
  }
}
