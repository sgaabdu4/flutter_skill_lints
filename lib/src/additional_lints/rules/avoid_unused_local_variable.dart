import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a local variable is never read.
final class AvoidUnusedLocalVariable extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unused_local_variable',
    'Local variable is never read.',
    correctionMessage: 'Remove the variable or use its value.',
  );

  AvoidUnusedLocalVariable()
    : super(
        name: 'avoid_unused_local_variable',
        description: 'Warns when local variables are declared but never read.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addConstructorDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor)
      ..addFunctionExpression(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnusedLocalVariable rule;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _check(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _check(node.functionExpression.body);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return;
    _check(node.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _check(node.body);
  }

  void _check(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final collector = LocalVariableUsageCollector();
    body.block.accept(collector);

    for (final variable in collector.variables.values) {
      if (variable.isRead || variable.isWildcard) continue;
      rule.reportAtToken(variable.name);
    }
  }
}

final class LocalVariableUsageCollector extends RecursiveAstVisitor<void> {
  final Map<Object, LocalVariableState> variables = {};
  int _nestedFunctionDepth = 0;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_nestedFunctionDepth == 0 && _isLocalVariable(node)) {
      final key = localVariableKey(node);
      if (key != null) {
        variables[key] = LocalVariableState(node.name, hasValue: node.initializer != null);
      }
    }
    super.visitVariableDeclaration(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) return;

    final key = node.element;
    final variable = key == null ? null : variables[key];
    if (variable == null) return;

    if (node.inGetterContext()) {
      variable.isRead = true;
    }
    if (node.inSetterContext()) {
      variable.hasValue = true;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _visitNestedFunctionBody(node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _visitNestedFunctionBody(node.functionExpression.body);
  }

  void _visitNestedFunctionBody(FunctionBody body) {
    _nestedFunctionDepth++;
    body.accept(this);
    _nestedFunctionDepth--;
  }
}

final class LocalVariableState {
  LocalVariableState(this.name, {required this.hasValue});

  final Token name;
  bool hasValue;
  bool isRead = false;

  bool get isWildcard => name.lexeme.startsWith('_');
}

Object? localVariableKey(VariableDeclaration node) {
  return node.declaredFragment?.element;
}

bool _isLocalVariable(VariableDeclaration node) {
  final parent = node.parent;
  return parent is VariableDeclarationList &&
      (parent.parent is VariableDeclarationStatement || parent.parent is ForPartsWithDeclarations);
}
