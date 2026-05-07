import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Don't silently return when a repository field is null in mutation methods.
///
/// Why: Bans null repository early returns in mutation methods. Initialize dependencies with an
/// _ensure... helper before writes.
final class AvoidSilentRepositoryNullReturn extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_silent_repository_null_return',
    "Don't silently return when a repository field is null in mutation methods.",
    correctionMessage: 'Initialize dependencies with an _ensure... helper before writes.',
  );

  AvoidSilentRepositoryNullReturn()
    : super(
        name: 'avoid_silent_repository_null_return',
        description: 'Bans null repository early returns in mutation methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addIfStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidSilentRepositoryNullReturn rule;

  @override
  void visitIfStatement(IfStatement node) {
    final method = enclosingMethod(node);
    if (method == null || !isMutationMethodName(method.name.lexeme)) return;
    if (containsEnsureCall(method.body)) return;
    if (!_conditionChecksRepositoryNull(node.expression)) return;
    if (!containsReturn(node.thenStatement)) return;
    rule.reportAtNode(node.expression);
  }

  bool _conditionChecksRepositoryNull(Expression expression) {
    if (expression is! BinaryExpression || expression.operator.lexeme != '==') {
      return false;
    }
    return _isRepositoryField(expression.leftOperand) && expression.rightOperand is NullLiteral ||
        _isRepositoryField(expression.rightOperand) && expression.leftOperand is NullLiteral;
  }

  bool _isRepositoryField(Expression expression) {
    if (expression is SimpleIdentifier) {
      return RegExp(
        r'^_\w*(?:repo|repository)\w*$',
        caseSensitive: false,
      ).hasMatch(expression.name);
    }
    if (expression is PrefixedIdentifier) {
      return _isRepositoryName(expression.identifier.name);
    }
    if (expression is PropertyAccess) {
      return _isRepositoryName(expression.propertyName.name);
    }
    return false;
  }

  bool _isRepositoryName(String name) =>
      RegExp(r'^_?\w*(?:repo|repository)\w*$', caseSensitive: false).hasMatch(name);
}
