import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Suggests using `Padding` instead of `Container` with only padding or margin.
///
/// Dedicated layout widgets make spacing intent explicit and avoid a generic
/// `Container` when decoration, constraints, or color are not needed.
class PreferPaddingOverContainer extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_padding_over_container',
    'Use Padding widget instead of the Container widget with only the padding or margin parameter',
    correctionMessage: 'Replace the Container with Padding so the spacing intent is explicit.',
  );

  PreferPaddingOverContainer()
    : super(
        name: 'prefer_padding_over_container',
        description: 'Use Padding widget instead of Container when only padding or margin is set.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferPaddingOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
          node,
          parameter: 'margin',
          ignoredParameters: {'key', 'child'},
        ) ||
        isInstanceCreationExpressionOnlyUsingParameter(
          node,
          parameter: 'padding',
          ignoredParameters: {'key', 'child'},
        )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
