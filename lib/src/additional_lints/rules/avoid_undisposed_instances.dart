import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../disposal_utils.dart';

/// Warns when a local disposable instance is created and not cleaned up in the
/// same function body.
class AvoidUndisposedInstances extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_undisposed_instances',
    "Instance '{0}' is not disposed. Call '{0}.{1}()' before it goes out of scope.",
    correctionMessage: "Call '{0}.{1}()' before leaving this function.",
  );

  AvoidUndisposedInstances()
    : super(
        name: 'avoid_undisposed_instances',
        description: 'Warns when locally created disposable instances are not cleaned up.',
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
  final AvoidUndisposedInstances rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkBody(node.functionExpression.body);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == 'dispose') return;
    _checkBody(node.body);
  }

  void _checkBody(FunctionBody body) {
    if (body is! BlockFunctionBody) return;

    final cleanupCollector = _CleanupCollector();
    body.block.accept(cleanupCollector);

    final returnedCollector = _ReturnedLocalCollector();
    body.block.accept(returnedCollector);

    final locals = _DisposableLocalCollector();
    body.block.accept(locals);

    for (final local in locals.locals) {
      if (returnedCollector.names.contains(local.name)) continue;
      if (cleanupCollector.hasCleanup(local.name, local.cleanupMethod)) continue;

      rule.reportAtToken(local.nameToken, arguments: [local.name, local.cleanupMethod]);
    }
  }
}

class _DisposableLocal {
  final String name;
  final Token nameToken;
  final String cleanupMethod;

  const _DisposableLocal({
    required this.name,
    required this.nameToken,
    required this.cleanupMethod,
  });
}

class _DisposableLocalCollector extends RecursiveAstVisitor<void> {
  final List<_DisposableLocal> locals = [];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer is! InstanceCreationExpression) {
      super.visitVariableDeclaration(node);
      return;
    }

    final name = node.name.lexeme;
    if (name == '_') {
      super.visitVariableDeclaration(node);
      return;
    }

    final type = node.declaredFragment?.element.type ?? initializer.staticType;
    final cleanupMethod = _cleanupMethod(type);
    if (cleanupMethod != null) {
      locals.add(_DisposableLocal(name: name, nameToken: node.name, cleanupMethod: cleanupMethod));
    }

    super.visitVariableDeclaration(node);
  }

  static String? _cleanupMethod(DartType? type) {
    if (type == null) return null;
    return findCleanupMethod(type);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

class _CleanupCollector extends RecursiveAstVisitor<void> {
  final Map<String, Set<String>> _calls = {};

  bool hasCleanup(String name, String methodName) {
    return _calls[name]?.contains(methodName) ?? false;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'addTearDown' || methodName == 'tearDown') {
      for (final argument in node.argumentList.arguments) {
        _collectCleanupTearOff(argument);
      }
    }
    if (cleanupMethods.contains(methodName)) {
      final target = node.realTarget;
      if (target is SimpleIdentifier) {
        _calls.putIfAbsent(target.name, () => {}).add(methodName);
      }
    }

    super.visitMethodInvocation(node);
  }

  void _collectCleanupTearOff(Expression expression) {
    if (expression is PrefixedIdentifier) {
      final cleanupMethod = expression.identifier.name;
      if (!cleanupMethods.contains(cleanupMethod)) return;
      final target = expression.prefix;
      _calls.putIfAbsent(target.name, () => {}).add(cleanupMethod);
      return;
    }
    if (expression is PropertyAccess) {
      final cleanupMethod = expression.propertyName.name;
      if (!cleanupMethods.contains(cleanupMethod)) return;
      final target = expression.target;
      if (target is SimpleIdentifier) {
        _calls.putIfAbsent(target.name, () => {}).add(cleanupMethod);
      }
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

class _ReturnedLocalCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression is SimpleIdentifier) {
      names.add(expression.name);
    }
    super.visitReturnStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
