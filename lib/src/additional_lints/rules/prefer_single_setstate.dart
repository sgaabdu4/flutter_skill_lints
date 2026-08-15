import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/async_guard_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart' show isEnclosedClassAssignableTo;

/// Warns when a method in a `State` subclass contains multiple `setState` calls
/// that could be merged into a single invocation.
///
/// Multiple `setState` calls cause redundant rebuilds. Merging them into one
/// call is more efficient and keeps state mutations grouped together.
class PreferSingleSetstate extends MethodDeclarationRule {
  static const LintCode code = LintCode(
    'prefer_single_setstate',
    'Multiple setState calls should be merged into a single call.',
    correctionMessage: 'Merge all setState calls into one.',
  );

  PreferSingleSetstate()
    : super(
        name: 'prefer_single_setstate',
        description:
            'Warns when multiple setState calls in the same method could '
            'be merged into a single invocation.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleSetstate rule;

  _Visitor(this.rule);

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Verify we're inside a State subclass
    if (!isEnclosedClassAssignableTo(node, _stateChecker)) return;

    // Collect mergeable setState calls in this method (not inside nested closures).
    final collector = _SetStateCollector();
    node.body.accept(collector);

    for (final call in collector.violations) {
      rule.reportAtNode(call);
    }
  }
}

/// Collects `setState` calls at the current method level,
/// stopping at function boundaries (closures, local functions).
class _SetStateCollector extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> violations = [];

  @override
  void visitBlock(Block node) {
    var segmentSetStateCount = 0;

    for (final statement in node.statements) {
      final directSetState = _directSetState(statement);
      if (directSetState != null) {
        if (segmentSetStateCount > 0) {
          violations.add(directSetState);
        }
        segmentSetStateCount += 1;
      } else {
        statement.accept(this);
      }

      if (_isControlFlowBoundary(statement) || containsAwait(statement)) {
        segmentSetStateCount = 0;
      }
    }
  }

  // Stop at nested function boundaries — setState inside closures
  // belongs to a different logical scope.
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  MethodInvocation? _directSetState(Statement statement) {
    if (statement is! ExpressionStatement) return null;
    final expression = statement.expression;
    if (expression is MethodInvocation && expression.methodName.name == 'setState') {
      return expression;
    }
    return null;
  }

  bool _isControlFlowBoundary(Statement statement) {
    return statement is ReturnStatement ||
        statement is BreakStatement ||
        statement is ContinueStatement ||
        statement is ExpressionStatement && statement.expression is ThrowExpression;
  }
}
