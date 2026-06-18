import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when `ref.watch()` is used outside a widget `build()` method.
///
/// `ref.watch` subscribes the current build to provider changes. Outside build
/// it either has no rebuild target or creates a dependency in a callback/life
/// cycle method where `ref.read` or `ref.listen` is the intended operation.
class AvoidRefWatchOutsideBuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_ref_watch_outside_build',
    "Avoid using 'ref.watch' outside build methods.",
    correctionMessage:
        "Move the provider subscription to build(), or use 'ref.read' / "
        "'ref.listen' for one-time actions and side effects.",
  );

  AvoidRefWatchOutsideBuild()
    : super(
        name: 'avoid_ref_watch_outside_build',
        description:
            'Warns when ref.watch() is called outside a Riverpod widget '
            'build method.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRefWatchOutsideBuild rule;

  _Visitor(this.rule);

  static const _consumerWidgetChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
  ]);

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isRefWatch(node)) return;
    if (_isInsideValidBuild(node)) return;

    rule.reportAtNode(node);
  }

  bool _isRefWatch(MethodInvocation node) {
    if (node.methodName.name != 'watch') return false;
    return node.target is SimpleIdentifier && (node.target as SimpleIdentifier).name == 'ref';
  }

  bool _isInsideValidBuild(MethodInvocation node) {
    final function = _enclosingFunctionBoundary(node);
    if (function == null) return false;

    if (function is MethodDeclaration) {
      return _isValidBuildMethod(function) || _isRiverpodBuildMethod(function);
    }

    if (function is FunctionDeclaration) {
      return _hasRiverpodAnnotation(function.metadata);
    }

    if (function is FunctionExpression) {
      final declaration = function.parent;
      if (declaration is FunctionDeclaration) {
        return _hasRiverpodAnnotation(declaration.metadata);
      }
    }

    return false;
  }

  AstNode? _enclosingFunctionBoundary(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionExpression ||
          current is FunctionDeclaration ||
          current is MethodDeclaration ||
          current is ConstructorDeclaration) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  bool _isValidBuildMethod(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return false;

    final classDecl = enclosingClassDeclaration(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null) return false;

    return _consumerWidgetChecker.isSuperOf(element) || _consumerStateChecker.isSuperOf(element);
  }

  bool _isRiverpodBuildMethod(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return false;
    final classDecl = enclosingClassDeclaration(node);
    if (classDecl == null) return false;
    return _hasRiverpodAnnotation(classDecl.metadata);
  }

  bool _hasRiverpodAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((annotation) {
      final name = annotation.name.name;
      return name == 'riverpod' || name == 'Riverpod';
    });
  }
}
