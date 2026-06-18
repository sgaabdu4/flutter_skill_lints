import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../async_guard_utils.dart';
import '../type_checker.dart';

/// Warns when `setState()` is called after an async gap without a mounted
/// guard.
class UseSetstateSynchronously extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_setstate_synchronously',
    "Avoid calling 'setState' after an await point without checking mounted.",
    correctionMessage:
        "Add 'if (!context.mounted) return;' before calling 'setState' after an await.",
  );

  UseSetstateSynchronously()
    : super(
        name: 'use_setstate_synchronously',
        description: 'Warns when setState is called after an await point without a mounted guard.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final UseSetstateSynchronously rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final enclosingBody = node.parent;
    if (enclosingBody is! BlockClassBody) return;
    final classDecl = enclosingBody.parent;
    if (classDecl is! ClassDeclaration) return;

    final element = classDecl.declaredFragment?.element;
    if (element == null || !_stateChecker.isSuperOf(element)) return;

    if (node.body.isAsynchronous && node.body is BlockFunctionBody) {
      final body = node.body as BlockFunctionBody;
      _checkStatements(body.block.statements);
    }

    final callbackFinder = _AsyncCallbackFinder(rule);
    node.body.visitChildren(callbackFinder);
  }

  void _checkStatements(NodeList<Statement> statements) {
    _StatementChecker(rule).check(statements);
  }
}

class _AsyncCallbackFinder extends RecursiveAstVisitor<void> {
  final UseSetstateSynchronously rule;

  _AsyncCallbackFinder(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (!node.body.isAsynchronous) {
      super.visitFunctionExpression(node);
      return;
    }

    final body = node.body;
    if (body is BlockFunctionBody) {
      _StatementChecker(rule).check(body.block.statements);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

class _StatementChecker {
  final UseSetstateSynchronously rule;

  _StatementChecker(this.rule);

  void check(NodeList<Statement> statements) {
    var seenAwait = false;

    for (final statement in statements) {
      if (!seenAwait) {
        seenAwait = containsAwait(statement);
        continue;
      }

      if (isMountedGuardWithReturn(statement)) {
        seenAwait = false;
        continue;
      }

      final finder = _SetStateFinder(rule);
      statement.accept(finder);

      if (containsAwait(statement)) {
        seenAwait = true;
      }
    }
  }
}

class _SetStateFinder extends RecursiveAstVisitor<void> {
  final UseSetstateSynchronously rule;

  _SetStateFinder(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState' && _isImplicitOrThisTarget(node.target)) {
      rule.reportAtNode(node.methodName);
      return;
    }

    super.visitMethodInvocation(node);
  }

  static bool _isImplicitOrThisTarget(Expression? target) {
    return target == null || target is ThisExpression;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
