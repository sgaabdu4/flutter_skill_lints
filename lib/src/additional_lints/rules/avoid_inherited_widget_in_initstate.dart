import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `initState` depends on inherited widgets.
class AvoidInheritedWidgetInInitstate extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_inherited_widget_in_initstate',
    'Avoid inherited widget dependencies in initState.',
    correctionMessage: 'Move inherited widget reads to didChangeDependencies or build.',
  );

  AvoidInheritedWidgetInInitstate()
    : super(
        name: 'avoid_inherited_widget_in_initstate',
        description: 'Warns when State.initState depends on inherited widgets.',
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

  final AvoidInheritedWidgetInInitstate rule;

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  static const _inheritedDependencyMethods = {
    'dependOnInheritedElement',
    'dependOnInheritedWidgetOfExactType',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_inheritedDependencyMethods.contains(node.methodName.name)) return;
    if (!_hasContextTarget(node)) return;

    final (:method, :classDecl) = _findEnclosingInitStateAndClass(node);
    if (method == null || classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    rule.reportAtNode(node);
  }

  static bool _hasContextTarget(MethodInvocation node) {
    final target = node.realTarget;
    if (target is! SimpleIdentifier || target.name != 'context') return false;

    final type = target.staticType;
    if (type == null) return true;

    return const TypeChecker.fromName('BuildContext', packageName: 'flutter').isExactlyType(type);
  }

  static ({MethodDeclaration? method, ClassDeclaration? classDecl}) _findEnclosingInitStateAndClass(
    AstNode node,
  ) {
    MethodDeclaration? method;
    AstNode? current = node.parent;
    while (current != null) {
      if (method == null) {
        if (current is FunctionExpression || current is FunctionDeclaration) {
          return (method: null, classDecl: null);
        }
        if (current is MethodDeclaration) {
          if (current.name.lexeme != 'initState') {
            return (method: null, classDecl: null);
          }
          method = current;
        }
      } else if (current is ClassDeclaration) {
        return (method: method, classDecl: current);
      }
      current = current.parent;
    }
    return (method: null, classDecl: null);
  }
}
