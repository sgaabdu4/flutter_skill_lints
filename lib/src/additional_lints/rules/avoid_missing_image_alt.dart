import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when Image widgets omit a semantic label without opting out.
class AvoidMissingImageAlt extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_missing_image_alt',
    'Provide a semantic label for images or explicitly exclude them from semantics.',
    correctionMessage: 'Add semanticLabel or set excludeFromSemantics: true for decorative images.',
  );

  AvoidMissingImageAlt()
    : super(
        name: 'avoid_missing_image_alt',
        description: 'Warns when Image widgets omit accessible alternate text.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidMissingImageAlt rule;

  static const _imageChecker = TypeChecker.fromName('Image', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node.methodName);
  }

  void _check(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_imageChecker.isExactlyType(staticType)) {
      return;
    }

    final namedArguments = argumentList.arguments.whereType<NamedExpression>();
    final semanticLabel = namedArguments.firstWhereOrNull(
      (argument) => argument.name.lexeme == 'semanticLabel',
    );
    if (semanticLabel != null && semanticLabel.expression is! NullLiteral) return;

    final excludeFromSemantics = namedArguments.firstWhereOrNull(
      (argument) => argument.name.lexeme == 'excludeFromSemantics',
    );
    if (excludeFromSemantics?.expression case BooleanLiteral(value: true)) return;

    rule.reportAtNode(reportNode);
  }
}
