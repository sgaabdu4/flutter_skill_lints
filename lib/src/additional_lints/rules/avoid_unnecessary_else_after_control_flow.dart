import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an `if` statement keeps an `else` after a then-branch that
/// already exits.
///
/// A then-branch exits when it ends in `return`, `throw`, `rethrow`, `break`
/// or `continue`, or in a nested `if`/`else` whose branches all exit. Ordinary
/// two-way branching (assignments, calls, collection `if`/`else`) is allowed.
class AvoidUnnecessaryElseAfterControlFlow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_else_after_control_flow',
    'Avoid else after a branch that already exits.',
    correctionMessage: 'Remove the else and keep its body at the outer level as a guard clause.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnnecessaryElseAfterControlFlow()
    : super(
        name: 'avoid_unnecessary_else_after_control_flow',
        description: 'Avoid else after return, throw, rethrow, break or continue.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addIfStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryElseAfterControlFlow rule;

  @override
  void visitIfStatement(IfStatement node) {
    final elseKeyword = node.elseKeyword;
    if (node.elseStatement == null || elseKeyword == null) return;
    if (!_exits(node.thenStatement)) return;
    rule.reportAtToken(elseKeyword);
  }
}

bool _exits(Statement statement) {
  return switch (statement) {
    Block(:final statements) => statements.isNotEmpty && _exits(statements.last),
    ReturnStatement() || BreakStatement() || ContinueStatement() => true,
    ExpressionStatement(:final expression) => switch (expression.unParenthesized) {
      ThrowExpression() || RethrowExpression() => true,
      _ => false,
    },
    IfStatement(:final thenStatement, :final elseStatement?) =>
      _exits(thenStatement) && _exits(elseStatement),
    _ => false,
  };
}
