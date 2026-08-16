import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `useMemoized` is used to memoize a function expression.
///
/// `useCallback` is specifically designed for memoizing callbacks and is more
/// semantically correct than wrapping a function in `useMemoized`.
class PreferUseCallback extends MethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_use_callback',
    "Use 'useCallback' instead of 'useMemoized' for memoizing functions.",
    correctionMessage: "Replace 'useMemoized' with 'useCallback'.",
  );

  PreferUseCallback()
    : super(
        code: code,
        name: 'prefer_use_callback',
        description: 'Warns when useMemoized is used to memoize a function expression.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferUseCallback rule;

  _Visitor(this.rule);

  static final _isUseMemoized = RegExp(r'^_?useMemoized$');

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isUseMemoized.hasMatch(node.methodName.name)) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final factory = args.first;
    if (factory is! FunctionExpression) return;

    // Check if the factory returns a function type
    if (_returnsFunction(factory)) {
      rule.reportAtNode(node);
    }
  }

  static bool _returnsFunction(FunctionExpression factory) {
    final returnExpr = maybeGetSingleReturnExpression(factory.body);
    if (returnExpr == null) return false;
    return returnExpr.staticType is FunctionType;
  }
}
