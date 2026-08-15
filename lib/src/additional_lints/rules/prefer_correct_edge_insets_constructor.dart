import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/edge_insets_replacement.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when an `EdgeInsets` constructor can be replaced with a simpler one.
///
/// Detects cases where:
/// - `EdgeInsets.fromLTRB` can be `EdgeInsets.all`, `.symmetric`, `.only`, or `.zero`
/// - `EdgeInsets.only` can be `EdgeInsets.all`, `.symmetric`, or `.zero`
/// - `EdgeInsets.symmetric` can be `EdgeInsets.all` or `.zero`
/// - `EdgeInsets.all(0)` can be `EdgeInsets.zero`
class PreferCorrectEdgeInsetsConstructor extends InstanceAndMethodInvocationRule {
  static const LintCode code = LintCode(
    'prefer_correct_edge_insets_constructor',
    'Use a simpler EdgeInsets constructor.',
    correctionMessage: 'Replace with {0}.',
  );

  PreferCorrectEdgeInsetsConstructor()
    : super(
        code: code,
        name: 'prefer_correct_edge_insets_constructor',
        description: 'Warns when an EdgeInsets constructor can be replaced with a simpler one.',
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferCorrectEdgeInsetsConstructor rule;

  _Visitor(this.rule);

  static const _edgeInsetsChecker = TypeChecker.fromName('EdgeInsets', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final staticType = node.staticType;
    if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final constructorName = node.constructorName.name?.name;
    _check(node, constructorName, node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final staticType = node.staticType;
    if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
      return;
    }

    final target = node.target;
    if (target is! SimpleIdentifier) return;

    final constructorName = node.methodName.name;
    _check(node, constructorName, node.argumentList);
  }

  void _check(Expression node, String? constructorName, ArgumentList argumentList) {
    final replacement = edgeInsetsReplacement(constructorName, argumentList);
    if (replacement != null) {
      rule.reportAtNode(node, arguments: [replacement]);
    }
  }
}
