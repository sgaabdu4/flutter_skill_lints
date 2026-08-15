import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Suggests using `ConstrainedBox` instead of `Container` with only constraints.
///
/// The dedicated widget makes constraint intent explicit and avoids a generic
/// `Container` when no decoration, padding, or color is needed.
class PreferConstrainedBoxOverContainer extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_constrained_box_over_container',
    'Use ConstrainedBox widget instead of the Container widget with only the constraints parameter.',
    correctionMessage: 'Replace the Container with ConstrainedBox so constraints are explicit.',
  );

  PreferConstrainedBoxOverContainer()
    : super(
        name: 'prefer_constrained_box_over_container',
        description: 'Use ConstrainedBox widget instead of Container when only constraints is set.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferConstrainedBoxOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
      node,
      parameter: 'constraints',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
