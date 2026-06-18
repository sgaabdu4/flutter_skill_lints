import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Widget-returning function or method directly calls itself.
class AvoidRecursiveWidgetCalls extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_recursive_widget_calls',
    'Avoid recursive calls from Widget-returning functions.',
    correctionMessage:
        'Return a widget instance or extract the repeated widget into a separate Widget class.',
  );

  AvoidRecursiveWidgetCalls()
    : super(
        name: 'avoid_recursive_widget_calls',
        description: 'Warns when Widget-returning functions directly call themselves.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRecursiveWidgetCalls rule;

  _Visitor(this.rule);

  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_returnsWidget(node.returnType?.type)) return;
    _checkBody(node.functionExpression.body, node.name.lexeme, node.name);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build' && !_returnsWidget(node.returnType?.type)) return;
    _checkBody(node.body, node.name.lexeme, node.name);
  }

  bool _returnsWidget(DartType? type) {
    if (type is! InterfaceType) return false;
    return _widgetChecker.isAssignableFromType(type);
  }

  void _checkBody(FunctionBody body, String functionName, Token nameToken) {
    final finder = _RecursiveCallFinder(functionName);
    body.visitChildren(finder);
    if (finder.found) {
      rule.reportAtToken(nameToken);
    }
  }
}

class _RecursiveCallFinder extends RecursiveAstVisitor<void> {
  final String functionName;
  bool found = false;

  _RecursiveCallFinder(this.functionName);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == functionName && _isSelfTarget(node.target)) {
      found = true;
      return;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;
    if (function is SimpleIdentifier && function.name == functionName) {
      found = true;
      return;
    }

    super.visitFunctionExpressionInvocation(node);
  }

  static bool _isSelfTarget(Expression? target) {
    return target == null || target is ThisExpression;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
