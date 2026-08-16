import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `Intl.message` placeholders omit examples.
final class PreferProvidingIntlExamples extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_providing_intl_examples',
    'Provide Intl.message examples for placeholders.',
    correctionMessage: 'Add a non-empty examples map for the placeholders.',
  );

  PreferProvidingIntlExamples()
    : super(
        code: code,
        name: 'prefer_providing_intl_examples',
        description: 'Warns when Intl.message placeholders omit examples.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferProvidingIntlExamples rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!isIntlMessageInvocation(node)) return;

    final placeholders = namedInvocationArgument(node, 'placeholders')?.argumentExpression;
    if (placeholders is! SetOrMapLiteral || !isNonEmptyMapLiteral(placeholders)) return;

    final examples = namedInvocationArgument(node, 'examples')?.argumentExpression;
    if (examples is SetOrMapLiteral && isNonEmptyMapLiteral(examples)) return;

    rule.reportAtNode(placeholders);
  }
}
