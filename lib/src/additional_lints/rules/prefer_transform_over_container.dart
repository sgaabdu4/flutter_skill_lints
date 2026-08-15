import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Suggests using `Transform` instead of `Container` with only `transform`.
///
/// The dedicated widget states the layout intent directly and avoids treating
/// `Container` as a generic wrapper.
class PreferTransformOverContainer extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_transform_over_container',
    'Use Transform widget instead of the Container widget with only the transform parameter',
    correctionMessage: 'Replace the Container with Transform so the transform intent is explicit.',
  );

  PreferTransformOverContainer()
    : super(
        name: 'prefer_transform_over_container',
        description: 'Use Transform widget instead of Container when only transform is set.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferTransformOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
      node,
      parameter: 'transform',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
