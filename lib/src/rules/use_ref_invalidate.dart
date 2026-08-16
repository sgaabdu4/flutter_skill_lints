import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Use ref.invalidate when the result of ref.refresh is ignored.
///
/// Why: Bans ref.refresh when its return value is unused. Replace the ignored ref.refresh(...)
/// call with ref.invalidate(...).
final class UseRefInvalidate extends GeneratedExpressionStatementCheckRule {
  static const LintCode code = LintCode(
    'use_ref_invalidate',
    'Use ref.invalidate when the result of ref.refresh is ignored.',
    correctionMessage: 'Replace the ignored ref.refresh(...) call with ref.invalidate(...).',
  );

  UseRefInvalidate()
    : super(
        name: 'use_ref_invalidate',
        description: 'Bans ref.refresh when its return value is unused.',
        code: code,
      );

  @override
  void checkExpressionStatement(ExpressionStatement node) {
    final expression = node.expression;
    if (expression is AwaitExpression) {
      final inner = expression.expression;
      if (inner is MethodInvocation && isTargetMethodInvocation(inner, 'ref', 'refresh')) {
        reportAtNode(inner);
      }
      return;
    }
    if (expression is MethodInvocation && isTargetMethodInvocation(expression, 'ref', 'refresh')) {
      reportAtNode(expression);
    }
  }
}
