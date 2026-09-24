import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when Image widgets omit a semantic label without opting out.
class AvoidMissingImageAlt extends NodeRegistrationRule {
  static const LintCode code = LintCode(
    'avoid_missing_image_alt',
    'Provide a semantic label for images or explicitly exclude them from semantics.',
    correctionMessage: 'Add semanticLabel or set excludeFromSemantics: true for decorative images.',
  );

  AvoidMissingImageAlt()
    : super(
        code: code,
        name: 'avoid_missing_image_alt',
        description: 'Warns when Image widgets omit accessible alternate text.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = createVisitor();
    registry
      ..addInstanceCreationExpression(this, visitor)
      ..addDotShorthandConstructorInvocation(this, visitor)
      ..addDotShorthandInvocation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidMissingImageAlt rule;

  static const _imageChecker = TypeChecker.fromName('Image', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node.constructorName.element, node.argumentList, node.constructorName);

  @override
  void visitDotShorthandConstructorInvocation(DotShorthandConstructorInvocation node) =>
      _check(node.constructorName.element, node.argumentList, node);

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) =>
      _check(node.memberName.element, node.argumentList, node);

  void _check(Element? resolvedMember, ArgumentList argumentList, AstNode reportNode) {
    if (resolvedMember is! ConstructorElement ||
        !_imageChecker.isExactly(resolvedMember.enclosingElement)) {
      return;
    }

    final namedArguments = argumentList.arguments.whereType<NamedArgument>();
    final semanticLabel = namedArguments.firstWhereOrNull(
      (argument) => argument.name.lexeme == 'semanticLabel',
    );
    if (semanticLabel != null && semanticLabel.argumentExpression is! NullLiteral) return;

    final excludeFromSemantics = namedArguments.firstWhereOrNull(
      (argument) => argument.name.lexeme == 'excludeFromSemantics',
    );
    if (excludeFromSemantics?.argumentExpression case BooleanLiteral(value: true)) return;

    rule.reportAtNode(reportNode);
  }
}
