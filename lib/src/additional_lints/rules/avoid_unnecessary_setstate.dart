import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when `setState` is called directly inside `initState`,
/// `didUpdateWidget`, or `build` methods in a `State` subclass.
///
/// In `initState` and `didUpdateWidget`, calling `setState` is unnecessary
/// because the framework will call `build` after these methods return anyway.
/// In `build`, calling `setState` triggers an additional rebuild which causes
/// performance issues.
///
/// For event handler callbacks (onPressed, onTap, etc.) inside `build`,
/// `setState` is allowed since those run asynchronously.
class AvoidUnnecessarySetstate extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_setstate',
    "Unnecessary call to 'setState' inside '{0}'.",
    correctionMessage: 'Mutate the state directly without calling setState in this method.',
  );

  AvoidUnnecessarySetstate()
    : super(
        code: code,
        name: 'avoid_unnecessary_setstate',
        description:
            'Warns when setState is called in initState, didUpdateWidget, '
            'or build where it is unnecessary.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessarySetstate rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  /// Lifecycle methods where setState is unnecessary.
  static const _lifecycleMethods = {'initState', 'didUpdateWidget', 'build'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'setState') return;

    // Single parent-chain walk: find lifecycle method and enclosing class.
    final (:method, :classDecl) = _findLifecycleMethodAndClass(node);
    if (method == null || classDecl == null) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    final methodName = method.name.lexeme;

    // For build method, skip setState inside event handler callbacks
    if (methodName == 'build' && _isInsideEventHandlerCallback(node)) return;

    rule.reportAtNode(node, arguments: [methodName]);
  }

  /// Walks up the AST once to find both the nearest lifecycle method and
  /// the enclosing class declaration, stopping at function boundaries.
  static ({MethodDeclaration? method, ClassDeclaration? classDecl}) _findLifecycleMethodAndClass(
    AstNode node,
  ) {
    final method = _enclosingLifecycleMethod(node);
    final classDecl = method == null ? null : enclosingClass(method);
    return (method: method, classDecl: classDecl);
  }

  static MethodDeclaration? _enclosingLifecycleMethod(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression || current is FunctionDeclaration) return null;
      if (current is MethodDeclaration) {
        return _lifecycleMethods.contains(current.name.lexeme) ? current : null;
      }
      current = current.parent;
    }
    return null;
  }

  /// Checks whether the setState call is inside a closure that is passed
  /// as a named argument (i.e., an event handler like onPressed, onTap).
  ///
  /// This allows patterns like:
  /// ```dart
  /// Widget build(BuildContext context) {
  ///   return ElevatedButton(
  ///     onPressed: () {
  ///       setState(() { ... }); // OK — this is an event handler
  ///     },
  ///     child: Text('Press'),
  ///   );
  /// }
  /// ```
  static bool _isInsideEventHandlerCallback(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      // If we hit a MethodDeclaration, we've exited the closure scope
      if (current is MethodDeclaration) return false;

      // Check if we're inside a FunctionExpression that is the value of
      // a NamedArgument (e.g., onPressed: () { ... })
      if (current is FunctionExpression) {
        final parent = current.parent;
        if (parent is NamedArgument) return true;
      }

      current = current.parent;
    }
    return false;
  }
}
