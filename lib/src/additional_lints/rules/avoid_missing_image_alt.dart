import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when Image widgets omit a semantic label without opting out.
class AvoidMissingImageAlt extends InstanceAndMethodInvocationRule {
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
}

final class _Visitor extends InstanceAndMethodVisitor {
  _Visitor(this.rule);

  final AvoidMissingImageAlt rule;

  static const _imageChecker = TypeChecker.fromName('Image', packageName: 'flutter');

  @override
  void checkInstanceOrMethod(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_imageChecker.isExactlyType(staticType)) {
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
