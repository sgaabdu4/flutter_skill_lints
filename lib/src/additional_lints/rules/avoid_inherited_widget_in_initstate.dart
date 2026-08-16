import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `initState` depends on inherited widgets.
class AvoidInheritedWidgetInInitstate extends MethodInvocationCheckRule {
  static const LintCode code = LintCode(
    'avoid_inherited_widget_in_initstate',
    'Avoid inherited widget dependencies in initState.',
    correctionMessage: 'Move inherited widget reads to didChangeDependencies or build.',
  );

  AvoidInheritedWidgetInInitstate()
    : super(
        name: 'avoid_inherited_widget_in_initstate',
        description: 'Warns when State.initState depends on inherited widgets.',
        code: code,
      );

  static const _inheritedDependencyMethods = {
    'dependOnInheritedElement',
    'dependOnInheritedWidgetOfExactType',
  };

  @override
  void checkMethodInvocation(MethodInvocation node) {
    if (!_inheritedDependencyMethods.contains(node.methodName.name)) return;
    if (!_hasContextTarget(node)) return;

    final (:method, :classDecl) = _findEnclosingInitStateAndClass(node);
    if (method == null || classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !flutterStateChecker.isSuperOf(element)) return;

    reportAtNode(node);
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
    final method = _enclosingInitStateMethod(node);
    final classDecl = method == null ? null : enclosingClass(method);
    return (method: method, classDecl: classDecl);
  }

  static MethodDeclaration? _enclosingInitStateMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression || current is FunctionDeclaration) return null;
      if (current is MethodDeclaration) {
        return current.name.lexeme == 'initState' ? current : null;
      }
      current = current.parent;
    }
    return null;
  }
}
