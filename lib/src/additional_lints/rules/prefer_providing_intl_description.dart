import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `Intl.message` omits a description.
final class PreferProvidingIntlDescription extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_providing_intl_description',
    'Provide an Intl.message description.',
    correctionMessage: 'Add a desc argument that explains the message context.',
  );

  PreferProvidingIntlDescription()
    : super(
        code: code,
        name: 'prefer_providing_intl_description',
        description: 'Warns when Intl.message calls omit desc.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferProvidingIntlDescription rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isIntlMessageInvocation(node)) return;

    final desc = namedInvocationArgument(node, 'desc');
    if (desc != null && desc.argumentExpression is! NullLiteral) return;

    rule.reportAtNode(node.methodName);
  }
}
