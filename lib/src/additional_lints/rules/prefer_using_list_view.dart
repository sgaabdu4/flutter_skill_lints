import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a scroll view wraps a same-axis dynamic multi-child widget.
class PreferUsingListView extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_using_list_view',
    'Prefer using ListView instead of SingleChildScrollView with {0}.',
    correctionMessage: 'Use a ListView with children or ListView.builder.',
  );

  PreferUsingListView()
    : super(
        name: 'prefer_using_list_view',
        description: 'Warns when SingleChildScrollView wraps a same-axis dynamic child list.',
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

enum _ScrollAxis { vertical, horizontal }

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferUsingListView rule;

  static const _singleChildScrollViewChecker = TypeChecker.fromName(
    'SingleChildScrollView',
    packageName: 'flutter',
  );
  static const _columnChecker = TypeChecker.fromName('Column', packageName: 'flutter');
  static const _rowChecker = TypeChecker.fromName('Row', packageName: 'flutter');
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _check(node.staticType, node.argumentList, node.constructorName);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node.staticType, node.argumentList, node.methodName);
  }

  void _check(DartType? staticType, ArgumentList argumentList, AstNode reportNode) {
    if (staticType == null || !_singleChildScrollViewChecker.isExactlyType(staticType)) {
      return;
    }

    final scrollAxis = _scrollAxis(argumentList);
    final child = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'child')
        ?.expression;
    if (child == null) return;

    final childName = switch ((scrollAxis, child.staticType)) {
      (_ScrollAxis.vertical, final type?) when _columnChecker.isExactlyType(type) => 'Column',
      (_ScrollAxis.horizontal, final type?) when _rowChecker.isExactlyType(type) => 'Row',
      _ => null,
    };
    if (childName == null) return;
    if (!_hasDynamicChildren(child)) return;

    rule.reportAtNode(reportNode, arguments: [childName]);
  }

  static bool _hasDynamicChildren(Expression child) {
    final childArguments = switch (child) {
      InstanceCreationExpression(:final argumentList) => argumentList.arguments,
      MethodInvocation(:final argumentList) => argumentList.arguments,
      _ => null,
    };
    final children = childArguments
        ?.whereType<NamedExpression>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'children')
        ?.expression;
    return _isDynamicChildList(children);
  }

  static bool _isDynamicChildList(Expression? expression) {
    if (expression is ListLiteral) {
      return expression.elements.any(
        (element) => element is ForElement || element is SpreadElement,
      );
    }
    if (expression is MethodInvocation && expression.methodName.name == 'toList') {
      final target = expression.target;
      return target is MethodInvocation && target.methodName.name == 'map';
    }
    return false;
  }

  static _ScrollAxis _scrollAxis(ArgumentList argumentList) {
    final scrollDirection = argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'scrollDirection')
        ?.expression;
    if (scrollDirection is PrefixedIdentifier &&
        scrollDirection.prefix.name == 'Axis' &&
        scrollDirection.identifier.name == 'horizontal') {
      return _ScrollAxis.horizontal;
    }
    if (scrollDirection is PropertyAccess && scrollDirection.propertyName.name == 'horizontal') {
      return _ScrollAxis.horizontal;
    }
    return _ScrollAxis.vertical;
  }
}
