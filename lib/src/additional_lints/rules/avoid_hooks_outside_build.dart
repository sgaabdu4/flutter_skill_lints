import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/hook_detection.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when hook calls are made outside a hook build context.
///
/// Hooks are valid in HookWidget/HookConsumerWidget build methods,
/// HookBuilder/HookConsumer builders, and custom hook functions whose names
/// start with `use` or `_use`.
///
/// A call counts as a hook only when it resolves to `package:flutter_hooks` or
/// `package:hooks_riverpod`, or to a `use` function that itself calls hooks, so
/// `use`-prefixed APIs such as `usePathUrlStrategy()` are not reported.
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
    if (!_isResolvedHookCall(node, <Element>{})) return;
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

const _hookPackages = {'flutter_hooks', 'hooks_riverpod'};

bool _isHookPackageUri(Uri? uri) {
  if (uri == null || uri.scheme != 'package' || uri.pathSegments.isEmpty) return false;
  return _hookPackages.contains(uri.pathSegments.first);
}

bool _isResolvedHookCall(InvocationExpression node, Set<Element> visiting) {
  final element = switch (node) {
    MethodInvocation(:final methodName) => methodName.element,
    FunctionExpressionInvocation(function: final Identifier function) => function.element,
    _ => null,
  };
  if (element == null || !hookNameRegex.hasMatch(element.name ?? '')) return false;

  final library = element.library;
  if (library == null) return false;
  if (_isHookPackageUri(library.uri)) return true;
  if (!visiting.add(element)) return false;

  final localBody = _LocalDeclarationBodyFinder.find(node.root, element);
  if (localBody != null) {
    return _HookCallFinder.containsHookCall(localBody, visiting);
  }

  return library.fragments
      .expand((fragment) => fragment.libraryImports)
      .any((import) => _isHookPackageUri(import.importedLibrary?.uri));
}

final class _LocalDeclarationBodyFinder extends RecursiveAstVisitor<void> {
  _LocalDeclarationBodyFinder(this.element);

  final Element element;
  FunctionBody? body;

  static FunctionBody? find(AstNode root, Element element) {
    final finder = _LocalDeclarationBodyFinder(element);
    root.accept(finder);
    return finder.body;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.declaredFragment?.element == element) {
      body = node.functionExpression.body;
      return;
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.declaredFragment?.element == element) {
      body = node.body;
      return;
    }
    super.visitMethodDeclaration(node);
  }
}

final class _HookCallFinder extends RecursiveAstVisitor<void> {
  _HookCallFinder(this.visiting);

  final Set<Element> visiting;
  bool found = false;

  static bool containsHookCall(FunctionBody body, Set<Element> visiting) {
    final finder = _HookCallFinder(visiting);
    body.accept(finder);
    return finder.found;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _check(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _check(node);
    super.visitFunctionExpressionInvocation(node);
  }

  void _check(InvocationExpression node) {
    if (found || !hookNameRegex.hasMatch(node.beginToken.lexeme)) return;
    found = _isResolvedHookCall(node, visiting);
  }
}
