import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Enforces the shared BuildContext extension for route-current checks.
class UseContextIsCurrentModalRoute extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_context_is_current_modal_route',
    'Use context.isCurrentModalRoute instead of inline ModalRoute current-route checks.',
    correctionMessage:
        'Move route-current logic to the BuildContext extension and call context.isCurrentModalRoute.',
    severity: DiagnosticSeverity.ERROR,
  );

  UseContextIsCurrentModalRoute()
    : super(
        name: 'use_context_is_current_modal_route',
        description: 'Use the shared BuildContext extension for ModalRoute current-route checks.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isAllowedOwner(context)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  final UseContextIsCurrentModalRoute rule;
  final List<Set<String>> _scopes = [<String>{}];

  _Visitor(this.rule);

  Set<String> get _currentScope => _scopes.last;

  @override
  void visitBlock(Block node) {
    _withScope(() => super.visitBlock(node));
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isModalRouteMethod(node, {'isCurrentOf'})) {
      rule.reportAtNode(node);
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'isCurrent' && _isCurrentRouteTarget(node.target)) {
      rule.reportAtNode(node.propertyName);
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'isCurrent' && _isModalRouteLocal(node.prefix.name)) {
      rule.reportAtNode(node.identifier);
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_isModalRouteLookup(node.initializer)) {
      _currentScope.add(node.name.lexeme);
    }

    super.visitVariableDeclaration(node);
  }

  void _withScope(void Function() visit) {
    _scopes.add(<String>{});
    try {
      visit();
    } finally {
      _scopes.removeLast();
    }
  }

  bool _isCurrentRouteTarget(Expression? target) {
    final unwrapped = _unwrap(target);

    if (_isModalRouteLookup(unwrapped)) return true;
    if (unwrapped is SimpleIdentifier) {
      return _isModalRouteLocal(unwrapped.name);
    }

    return false;
  }

  bool _isModalRouteLocal(String name) {
    for (final scope in _scopes.reversed) {
      if (scope.contains(name)) return true;
    }
    return false;
  }
}

bool _isAllowedOwner(RuleContext context) {
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return path.endsWith('/lib/core/extensions/context_extensions.dart') ||
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart');
}

bool _isModalRouteLookup(AstNode? node) {
  final unwrapped = _unwrap(node);
  return unwrapped is MethodInvocation && _isModalRouteMethod(unwrapped, {'of', 'maybeOf'});
}

bool _isModalRouteMethod(MethodInvocation node, Set<String> names) {
  return switch (node.target) {
    SimpleIdentifier(name: 'ModalRoute') => names.contains(node.methodName.name),
    _ => false,
  };
}

AstNode? _unwrap(AstNode? node) {
  while (true) {
    final current = node;
    if (current is ParenthesizedExpression) {
      node = current.expression;
      continue;
    }
    if (current is PostfixExpression && current.operator.type == TokenType.BANG) {
      node = current.operand;
      continue;
    }
    return current;
  }
}
