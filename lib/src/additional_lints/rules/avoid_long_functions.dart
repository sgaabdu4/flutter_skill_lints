import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a function body spans too many source lines.
final class AvoidLongFunctions extends AnalysisRule {
  static const int maxLines = 80;

  static const LintCode code = LintCode(
    'avoid_long_functions',
    'Avoid functions longer than 80 lines.',
    correctionMessage: 'Split the function into smaller named steps.',
  );

  AvoidLongFunctions()
    : super(
        name: 'avoid_long_functions',
        description: 'Warns when function, method, and constructor bodies exceed 80 lines.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, isTestFile: _isTestFile(context));
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, {required this.isTestFile});

  final AvoidLongFunctions rule;
  final bool isTestFile;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final body = node.body;
    if (body is EmptyFunctionBody) return;

    _check(body, node.name ?? node.beginToken);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (isTestFile && node.name.lexeme == 'main') return;

    final body = node.functionExpression.body;
    if (body is EmptyFunctionBody) return;
    if (isTestFile && _isTestRegistrationBody(body)) return;

    _check(body, node.name);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) return;
    if (isTestFile && _isTestFrameworkCallback(node)) return;

    final body = node.body;
    if (body is EmptyFunctionBody) return;

    _check(body, body.beginToken);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final body = node.body;
    if (body is EmptyFunctionBody) return;

    _check(body, node.name);
  }

  void _check(FunctionBody body, Token reportToken) {
    if (_lineCount(body) <= AvoidLongFunctions.maxLines) return;

    rule.reportAtToken(reportToken);
  }
}

bool _isTestFile(RuleContext context) {
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return path.contains('/test/') || path.endsWith('_test.dart');
}

const _testFrameworkFunctions = {
  'group',
  'test',
  'testWidgets',
  'setUp',
  'setUpAll',
  'tearDown',
  'tearDownAll',
};

bool _isTestFrameworkCallback(FunctionExpression node) {
  final parent = node.parent;
  if (parent is! ArgumentList) return false;

  final invocation = parent.parent;
  if (invocation is! MethodInvocation) return false;

  return _testFrameworkFunctions.contains(invocation.methodName.name);
}

bool _isTestRegistrationBody(FunctionBody body) {
  if (body is! BlockFunctionBody) return false;

  final statements = body.block.statements;
  if (statements.isEmpty) return false;

  for (final statement in statements) {
    if (statement is! ExpressionStatement) return false;
    final expression = statement.expression;
    if (expression is! MethodInvocation) return false;
    if (!_testFrameworkFunctions.contains(expression.methodName.name)) return false;
  }
  return true;
}

int _lineCount(AstNode node) {
  final root = node.root;
  if (root is! CompilationUnit) return 0;

  final lineInfo = root.lineInfo;
  final startLine = lineInfo.getLocation(node.offset).lineNumber;
  final endLine = lineInfo.getLocation(node.end).lineNumber;
  return endLine - startLine + 1;
}
