import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

import '../type_checker.dart';

/// Warns when a `FutureBuilder` creates its `future` inline.
class PassExistingFutureToFutureBuilder extends AnalysisRule {
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
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
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

    final future = _namedArgument(node.argumentList, 'future');
    if (future == null || !_createsFutureInline(future)) return;

    rule.reportAtNode(future);
  }

  static Expression? _namedArgument(ArgumentList argumentList, String name) {
    for (final argument in argumentList.arguments.whereType<NamedExpression>()) {
      if (argument.name.lexeme == name) return argument.expression;
    }
    return null;
  }

  static bool _createsFutureInline(Expression expression) {
    final unwrapped = expression.unParenthesized;
    return unwrapped is MethodInvocation || unwrapped is InstanceCreationExpression;
  }
}
