import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Suggests using `Align` instead of `Container` with only alignment.
///
/// The dedicated widget makes alignment intent explicit and avoids a generic
/// `Container` when no decoration, constraints, or color are needed.
class PreferAlignOverContainer extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_align_over_container',
    'Use Align widget instead of the Container widget with only the alignment parameter',
    correctionMessage: 'Replace the Container with Align so the alignment intent is explicit.',
  );

  PreferAlignOverContainer()
    : super(
        name: 'prefer_align_over_container',
        description: 'Use Align widget instead of Container when only alignment is set.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferAlignOverContainer rule;

  _Visitor(this.rule);

  static const _containerChecker = TypeChecker.fromName('Container', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (!isExpressionExactlyType(node, _containerChecker)) return;

    if (isInstanceCreationExpressionOnlyUsingParameter(
      node,
      parameter: 'alignment',
      ignoredParameters: {'key', 'child'},
    )) {
      rule.reportAtNode(node.constructorName);
    }
  }
}
