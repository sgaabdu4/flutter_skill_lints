import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/test_callback_utils.dart';

/// Warns when a test callback contains no assertion.
final class MissingTestAssertion extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'missing_test_assertion',
    'Add an assertion to this test.',
    correctionMessage: 'Call expect(), expectLater(), or fail() so the test verifies behavior.',
  );

  MissingTestAssertion()
    : super(
        code: code,
        name: 'missing_test_assertion',
        description: 'Warns when a test callback contains no assertion call.',
      );

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    final lib = path.indexOf('/lib/');
    final test = path.indexOf('/test/');
    final rootEnd = lib >= 0 ? lib : test;
    registry.addMethodInvocation(
      this,
      _Visitor(this, rootEnd < 0 ? '' : path.substring(0, rootEnd)),
    );
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.projectRoot);

  final MissingTestAssertion rule;
  final String projectRoot;
  final Map<String, CompilationUnit> parsedHelpers = {};

  static const _testFunctions = {'test', 'testWidgets'};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_testFunctions.contains(node.methodName.name)) return;

    final callback = testCallbackArgument(node);
    if (callback == null) return;

    final finder = _AssertionFinder(projectRoot: projectRoot, parsedHelpers: parsedHelpers);
    callback.body.accept(finder);
    if (!finder.hasAssertion) {
      rule.reportAtNode(node.methodName);
    }
  }
}

final class _AssertionFinder extends RecursiveAstVisitor<void> {
  _AssertionFinder({
    this.remainingDepth = 2,
    this.assertionScope,
    required this.projectRoot,
    required this.parsedHelpers,
    this.shadowedAssertions = const {},
  });

  final int remainingDepth;
  final Scope? assertionScope;
  final String projectRoot;
  final Map<String, CompilationUnit> parsedHelpers;
  final Set<String> shadowedAssertions;
  static const _assertionFunctions = {
    'expect',
    'expectLater',
    'fail',
    'verify',
    'verifyInOrder',
    'verifyNever',
  };
  static const _assertionCallbackWrappers = {'fakeAsync'};

  bool hasAssertion = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    return;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_assertionFunctions.contains(node.methodName.name) &&
        (assertionScope == null || _isResolvedAssertion(node))) {
      hasAssertion = true;
      return;
    }

    if (_assertionCallbackWrappers.contains(node.methodName.name) &&
        (assertionScope == null || _isResolvedFakeAsync(node)) &&
        _callbackArgumentHasAssertion(node)) {
      hasAssertion = true;
      return;
    }

    if (remainingDepth > 0 && _resolvedHelperHasAssertion(node.methodName.element)) {
      hasAssertion = true;
      return;
    }

    super.visitMethodInvocation(node);
  }

  bool _isResolvedAssertion(MethodInvocation node) {
    if (node.target != null || shadowedAssertions.contains(node.methodName.name)) return false;
    final element = assertionScope?.lookup(node.methodName.name).getter;
    if (element is! TopLevelFunctionElement) return false;
    final declarationPath = element.firstFragment.libraryFragment.source.fullName.replaceAll(
      '\\',
      '/',
    );
    if (!declarationPath.contains('/lib/')) return false;
    final library = element.library.identifier;
    return library.startsWith('package:test_api/') ||
        library.startsWith('package:flutter_test/') ||
        library.startsWith('package:mocktail/') ||
        library.startsWith('package:mockito/');
  }

  bool _isResolvedFakeAsync(MethodInvocation node) {
    if (node.target != null || shadowedAssertions.contains(node.methodName.name)) return false;
    final element = assertionScope?.lookup(node.methodName.name).getter;
    return element is TopLevelFunctionElement &&
        element.library.identifier.startsWith('package:fake_async/');
  }

  bool _resolvedHelperHasAssertion(Element? element) {
    if (element is! ExecutableElement || element.isAbstract || element.isExternal) return false;
    final fragment = element.firstFragment;
    final offset = fragment.nameOffset;
    if (offset == null) return false;
    final source = fragment.libraryFragment.source;
    final sourcePath = source.fullName.replaceAll('\\', '/');
    if (projectRoot.isEmpty || !sourcePath.startsWith('$projectRoot/')) return false;
    final unit = parsedHelpers.putIfAbsent(
      sourcePath,
      () => parseString(content: source.contents.data, throwIfDiagnostics: false).unit,
    );
    AstNode? declaration = unit.nodeCovering(offset: offset);
    while (declaration != null &&
        declaration is! FunctionDeclaration &&
        declaration is! MethodDeclaration) {
      declaration = declaration.parent;
    }
    final body = switch (declaration) {
      FunctionDeclaration(:final functionExpression) => functionExpression.body,
      MethodDeclaration(:final body) => body,
      _ => null,
    };
    if (body == null) return false;
    final shadowed = <String>{};
    declaration?.accept(_ShadowedAssertionCollector(shadowed));
    final finder = _AssertionFinder(
      remainingDepth: remainingDepth - 1,
      assertionScope: fragment.libraryFragment.scope,
      projectRoot: projectRoot,
      parsedHelpers: parsedHelpers,
      shadowedAssertions: shadowed,
    );
    body.accept(finder);
    return finder.hasAssertion;
  }

  bool _callbackArgumentHasAssertion(MethodInvocation node) {
    for (final argument in node.argumentList.arguments) {
      if (argument is NamedArgument) continue;
      if (argument case final FunctionExpression callback) {
        final finder = _AssertionFinder(
          remainingDepth: remainingDepth,
          assertionScope: assertionScope,
          projectRoot: projectRoot,
          parsedHelpers: parsedHelpers,
          shadowedAssertions: shadowedAssertions,
        );
        callback.body.accept(finder);
        return finder.hasAssertion;
      }
    }
    return false;
  }
}

final class _ShadowedAssertionCollector extends RecursiveAstVisitor<void> {
  _ShadowedAssertionCollector(this.names);
  final Set<String> names;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    names.add(node.name.lexeme);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitRegularFormalParameter(RegularFormalParameter node) {
    if (node.name != null) names.add(node.name!.lexeme);
    super.visitRegularFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    names.add(node.name.lexeme);
    super.visitFunctionDeclaration(node);
  }
}
