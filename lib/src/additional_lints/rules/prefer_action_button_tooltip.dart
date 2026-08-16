import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when common icon/action buttons are missing a tooltip.
class PreferActionButtonTooltip extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_action_button_tooltip',
    'Define a tooltip for action buttons.',
    correctionMessage: 'Add a tooltip that describes the button action.',
  );

  PreferActionButtonTooltip()
    : super(
        name: 'prefer_action_button_tooltip',
        description: 'Warns when action buttons omit an accessible tooltip.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferActionButtonTooltip rule;

  static const _actionButtonChecker = TypeChecker.any([
    TypeChecker.fromName('IconButton', packageName: 'flutter'),
    TypeChecker.fromName('FloatingActionButton', packageName: 'flutter'),
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  void _check(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_actionButtonChecker.isExactlyType(staticType)) {
      return;
    }

    final tooltip = argumentList.arguments.whereType<NamedArgument>().firstWhereOrNull(
      (argument) => argument.name.lexeme == 'tooltip',
    );
    if (tooltip == null || tooltip.argumentExpression is NullLiteral) {
      rule.reportAtNode(reportNode);
    }
  }
}
