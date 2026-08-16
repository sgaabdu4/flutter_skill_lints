import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a `FutureBuilder` creates its `future` inline.
class PassExistingFutureToFutureBuilder extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'pass_existing_future_to_future_builder',
    'Pass an existing Future to FutureBuilder.',
    correctionMessage:
        'Store the Future outside build/init path churn and pass the existing Future value.',
  );

  PassExistingFutureToFutureBuilder()
    : super(
        name: 'pass_existing_future_to_future_builder',
        description: 'Warns when FutureBuilder receives an inline-created Future.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PassExistingFutureToFutureBuilder rule;

  static const _futureBuilderChecker = TypeChecker.fromName(
    'FutureBuilder',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_futureBuilderChecker.isExactly(element)) return;

    final future = namedArgumentExpression(node.argumentList, 'future');
    if (future == null || !isInlineCreatedExpression(future)) return;

    rule.reportAtNode(future);
  }
}
