import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a `SafeArea` has no enabled edges or directly wraps another one.
class AvoidUnnecessarySafeArea extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_safe_area',
    'Avoid unnecessary SafeArea widgets.',
    correctionMessage: 'Remove the redundant SafeArea.',
  );

  AvoidUnnecessarySafeArea()
    : super(
        name: 'avoid_unnecessary_safe_area',
        description: 'Warns when SafeArea has no enabled edges or directly wraps another SafeArea.',
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

  final AvoidUnnecessarySafeArea rule;

  static const _safeAreaChecker = TypeChecker.fromName('SafeArea', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node.methodName);
  }

  void _check(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_safeAreaChecker.isExactlyType(staticType)) {
      return;
    }

    if (_allEdgesDisabled(argumentList) || _hasSafeAreaChild(argumentList)) {
      rule.reportAtNode(reportNode);
    }
  }

  static bool _allEdgesDisabled(ArgumentList argumentList) {
    const edgeParameters = {'left', 'top', 'right', 'bottom'};
    final edges = <String, bool>{};

    for (final argument in argumentList.arguments.whereType<NamedExpression>()) {
      final name = argument.name.lexeme;
      if (!edgeParameters.contains(name)) continue;

      final expression = argument.expression;
      if (expression is! BooleanLiteral) return false;
      edges[name] = expression.value;
    }

    return edgeParameters.every((name) => edges[name] == false);
  }

  static bool _hasSafeAreaChild(ArgumentList argumentList) {
    final child = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'child')
        ?.expression;
    final childType = child?.staticType;
    return childType != null && _safeAreaChecker.isExactlyType(childType);
  }
}
