import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `Border.all()` is used instead of `Border.fromBorderSide()`.
class AvoidBorderAll extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'avoid_border_all',
    'Prefer Border.fromBorderSide over Border.all.',
    correctionMessage: 'Replace with Border.fromBorderSide(BorderSide(...)) for const support.',
  );

  AvoidBorderAll()
    : super(
        code: code,
        name: 'avoid_border_all',
        description: 'Warns when Border.all() is used instead of Border.fromBorderSide().',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidBorderAll rule;

  _Visitor(this.rule);

  static const _borderChecker = TypeChecker.fromName('Border', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Border.all<TypeArgs>(...) is parsed as InstanceCreationExpression
    final constructorName = node.constructorName;
    if (constructorName.name?.name != 'all') return;
    final staticType = node.staticType;
    if (staticType == null || !_borderChecker.isExactlyType(staticType)) return;

    rule.reportAtNode(node);
  }
}
