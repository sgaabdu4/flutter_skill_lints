import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/hook_detection.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when hook calls are made outside a hook build context.
///
/// Hooks are valid in HookWidget/HookConsumerWidget build methods,
/// HookBuilder/HookConsumer builders, and custom hook functions whose names
/// start with `use` or `_use`.
class AvoidHooksOutsideBuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hooks_outside_build',
    'Avoid calling hooks outside hook build methods or custom hooks.',
    correctionMessage:
        'Move the hook to a HookWidget build method, HookBuilder builder, '
        'or a custom hook function named with the use prefix.',
  );

  AvoidHooksOutsideBuild()
    : super(
        name: 'avoid_hooks_outside_build',
        description:
            'Warns when hooks are called outside HookWidget build methods, '
            'HookBuilder builders, or custom hooks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addFunctionExpressionInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidHooksOutsideBuild rule;

  _Visitor(this.rule);

  static const _hookWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('HookWidget', packageName: 'flutter_hooks'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  static final _isHookName = hookNameRegex;

  @override
  void visitMethodInvocation(MethodInvocation node) => _checkInvocation(node);

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _checkInvocation(node);

  void _checkInvocation(InvocationExpression node) {
    if (!_isHookName.hasMatch(node.beginToken.lexeme)) return;
    if (_isInsideValidHookContext(node)) return;

    rule.reportAtNode(node);
  }

  bool _isInsideValidHookContext(InvocationExpression node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression) {
        if (_isHookBuilderFunction(current)) return true;
        current = current.parent;
        continue;
      }

      if (current is FunctionDeclaration) {
        return _isHookName.hasMatch(current.name.lexeme);
      }

      if (current is MethodDeclaration) {
        return _isHookBuildMethod(current);
      }

      if (current is ConstructorDeclaration) return false;

      current = current.parent;
    }
    return false;
  }

  bool _isHookBuildMethod(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return false;

    final classDecl = enclosingClassDeclaration(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null) return false;

    return _hookWidgetChecker.isSuperOf(element);
  }

  bool _isHookBuilderFunction(FunctionExpression node) {
    final parent = node.parent;
    if (parent is! NamedArgument || parent.name.lexeme != 'builder') {
      return false;
    }

    final argumentList = parent.parent;
    final creation = argumentList?.parent;
    return creation is InstanceCreationExpression && maybeHookBuilderBody(creation) == node.body;
  }
}
