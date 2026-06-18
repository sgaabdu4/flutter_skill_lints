import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../../ast_utils.dart';
import '../type_checker.dart';

/// Warns when `ref` is accessed inside a Riverpod `ConsumerState.dispose()`.
class AvoidRefInsideStateDispose extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_ref_inside_state_dispose',
    "Avoid using 'ref' inside ConsumerState.dispose().",
    correctionMessage:
        'Move provider cleanup into ref.onDispose(), a subscription close call, or an earlier lifecycle method.',
  );

  AvoidRefInsideStateDispose()
    : super(
        name: 'avoid_ref_inside_state_dispose',
        description: 'Warns when ConsumerState.dispose() accesses Riverpod ref.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addMethodDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidRefInsideStateDispose rule;

  static const _consumerStateChecker = TypeChecker.any([
    TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
    TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
  ]);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'dispose') return;

    final classDecl = enclosingClass(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null || !_consumerStateChecker.isSuperOf(element)) return;

    final finder = _RefAccessFinder(rule);
    node.body.visitChildren(finder);
  }
}

class _RefAccessFinder extends RecursiveAstVisitor<void> {
  _RefAccessFinder(this.rule);

  final AvoidRefInsideStateDispose rule;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'ref') {
      super.visitSimpleIdentifier(node);
      return;
    }

    final parent = node.parent;
    if (parent is PrefixedIdentifier && parent.prefix == node) return;
    if (parent is PropertyAccess && parent.target == node) return;
    if (parent is MethodInvocation && parent.target == node) return;

    rule.reportAtNode(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'ref') {
      rule.reportAtNode(node);
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(name: 'ref')) {
      rule.reportAtNode(node);
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
