import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when `ref.watch()` is used outside a widget `build()` method.
///
/// `ref.watch` subscribes the current build to provider changes. Outside build
/// it either has no rebuild target or creates a dependency in a callback/life
/// cycle method where `ref.read` or `ref.listen` is the intended operation.
class AvoidRefWatchOutsideBuild extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'avoid_ref_watch_outside_build',
    "Avoid using 'ref.watch' outside build methods.",
    correctionMessage:
        "Move the provider subscription to build(), or use 'ref.read' / "
        "'ref.listen' for one-time actions and side effects.",
  );

  AvoidRefWatchOutsideBuild()
    : super(
        code: code,
        name: 'avoid_ref_watch_outside_build',
        description:
            'Warns when ref.watch() is called outside a Riverpod widget '
            'build method.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidRefWatchOutsideBuild rule;

  _Visitor(this.rule);

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
      if (_isConsumerBuilder(function, node)) return true;
      final declaration = function.parent;
      if (declaration is FunctionDeclaration) {
        return _hasRiverpodAnnotation(declaration.metadata);
      }
    }

    return false;
  }

  bool _isConsumerBuilder(FunctionExpression function, MethodInvocation invocation) {
    final argument = function.parent;
    if (argument is! NamedArgument || argument.name.lexeme != 'builder') return false;
    final creation = argument.parent?.parent;
    if (creation is! InstanceCreationExpression) return false;
    final type = creation.staticType;
    const checker = TypeChecker.any([
      TypeChecker.fromName('Consumer', packageName: 'flutter_riverpod'),
      TypeChecker.fromName('HookConsumer', packageName: 'hooks_riverpod'),
    ]);
    if (type == null || !checker.isExactlyType(type)) return false;
    final parameters = function.parameters?.parameters;
    if (parameters == null || parameters.length < 2) return false;
    final ref = invocation.target as SimpleIdentifier;
    return ref.element == parameters[1].declaredFragment?.element;
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

    return consumerWidgetChecker.isSuperOf(element) || consumerStateChecker.isSuperOf(element);
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
