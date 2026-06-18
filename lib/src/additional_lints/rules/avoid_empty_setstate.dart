import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `setState` is called with an empty callback.
class AvoidEmptySetstate extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_empty_setstate',
    'Avoid empty setState callbacks.',
    correctionMessage: 'Remove the setState call or add the missing state mutation.',
  );

  AvoidEmptySetstate()
    : super(
        name: 'avoid_empty_setstate',
        description: 'Warns when setState is called with an empty callback.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidEmptySetstate rule;

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;
    if (!_isInsideState(node)) return;

    final callback = node.argumentList.arguments.firstOrNull;
    if (callback is! FunctionExpression) return;

    final body = callback.body;
    if (body is! BlockFunctionBody || body.block.statements.isNotEmpty) {
      return;
    }

    rule.reportAtNode(node);
  }

  static bool _isInsideState(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        final element = current.declaredFragment?.element;
        return element != null && _stateChecker.isSuperOf(element);
      }
      current = current.parent;
    }
    return false;
  }
}
