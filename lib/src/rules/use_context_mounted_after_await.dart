import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't use BuildContext after an await without checking context.mounted.
///
/// Why: Requires context.mounted guards before BuildContext use after async gaps. Add 'if
/// (!context.mounted) return;' before using context after an await.
final class UseContextMountedAfterAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_context_mounted_after_await',
    "Don't use BuildContext after an await without checking context.mounted.",
    correctionMessage:
        "Capture State.context before the await, then check 'if (!context.mounted) return;'.",
  );

  UseContextMountedAfterAwait()
    : super(
        name: 'use_context_mounted_after_await',
        description: 'Requires context.mounted guards before BuildContext use after async gaps.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseContextMountedAfterAwait rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.body.isAsynchronous) return;
    _checkBody(node.body, hasContextBinding: _parametersDeclareContext(node.parameters));
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final body = node.functionExpression.body;
    if (!body.isAsynchronous) return;
    _checkBody(
      body,
      hasContextBinding: _parametersDeclareContext(node.functionExpression.parameters),
    );
  }

  void _checkBody(FunctionBody body, {required bool hasContextBinding}) {
    if (body is! BlockFunctionBody) return;
    final scanner = _ContextAsyncStatementScanner(rule, hasContextBinding: hasContextBinding);
    scanner.scanBlock(body.block);
  }

  static bool _parametersDeclareContext(FormalParameterList? parameters) {
    if (parameters == null) return false;
    return parameters.parameters.any((parameter) => parameter.name?.lexeme == 'context');
  }
}

final class _ContextAsyncStatementScanner {
  _ContextAsyncStatementScanner(this.rule, {required this.hasContextBinding});

  final UseContextMountedAfterAwait rule;
  final bool hasContextBinding;

  void scanBlock(Block block) {
    var afterAwait = false;
    var contextIsBound = hasContextBinding;

    for (final statement in block.statements) {
      if (afterAwait) {
        final unboundMountedAccess = contextIsBound ? null : _firstContextMountedAccess(statement);
        if (unboundMountedAccess != null) {
          rule.reportAtNode(unboundMountedAccess);
          afterAwait = false;
          continue;
        }

        if (contextIsBound && statementIsMountedReturnGuard(statement, 'context')) {
          afterAwait = false;
          continue;
        }

        final access = _firstContextAccess(statement);
        if (access != null) {
          rule.reportAtNode(access);
          afterAwait = false;
          continue;
        }
      }

      final nested = _NestedContextBlockScanner(this, hasContextBinding: contextIsBound);
      statement.accept(nested);

      if (_declaresContextLocal(statement)) {
        contextIsBound = true;
      }

      if (containsAwait(statement)) {
        afterAwait = true;
      }
    }
  }

  static bool _declaresContextLocal(Statement statement) {
    if (statement is! VariableDeclarationStatement) return false;
    return statement.variables.variables.any((variable) => variable.name.lexeme == 'context');
  }

  static bool _isContextMountedAccess(Expression expression) {
    if (expression is PrefixedIdentifier) {
      return expression.prefix.name == 'context' && expression.identifier.name == 'mounted';
    }
    if (expression is PropertyAccess && expression.propertyName.name == 'mounted') {
      final target = expression.target;
      if (target is SimpleIdentifier && target.name == 'context') return true;
      return _isThisContextAccess(target);
    }
    return false;
  }

  static AstNode? _firstContextMountedAccess(AstNode node) {
    final visitor = _ContextMountedAccessFinder();
    node.accept(visitor);
    return visitor.node;
  }

  static AstNode? _firstContextAccess(AstNode node) {
    final visitor = _ContextAccessFinder();
    node.accept(visitor);
    return visitor.node;
  }

  static bool _isThisContextAccess(Expression? expression) {
    return expression is PropertyAccess &&
        expression.target is ThisExpression &&
        expression.propertyName.name == 'context';
  }
}

final class _ContextMountedAccessFinder extends RecursiveAstVisitor<void> {
  AstNode? node;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (this.node != null) return;
    if (_ContextAsyncStatementScanner._isContextMountedAccess(node)) {
      this.node = node;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (this.node != null) return;
    if (_ContextAsyncStatementScanner._isContextMountedAccess(node)) {
      this.node = node;
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitBlock(Block node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _NestedContextBlockScanner extends RecursiveAstVisitor<void> {
  _NestedContextBlockScanner(this.scanner, {required this.hasContextBinding});

  final _ContextAsyncStatementScanner scanner;
  final bool hasContextBinding;

  @override
  void visitBlock(Block node) {
    _ContextAsyncStatementScanner(
      scanner.rule,
      hasContextBinding: hasContextBinding,
    ).scanBlock(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

final class _ContextAccessFinder extends RecursiveAstVisitor<void> {
  AstNode? node;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (this.node != null) return;
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'context') {
      this.node = node;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (this.node != null) return;
    if (node.prefix.name == 'context') {
      if (node.identifier.name == 'mounted') return;
      this.node = node;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (this.node != null) return;
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'context') {
      if (node.propertyName.name == 'mounted') return;
      this.node = node;
      return;
    }
    if (_ContextAsyncStatementScanner._isThisContextAccess(node)) {
      this.node = node;
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (this.node != null || node.name != 'context') return;
    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;
    if (classMemberNameIsDeclaration(node)) return;
    this.node = node;
  }

  @override
  void visitBlock(Block node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
