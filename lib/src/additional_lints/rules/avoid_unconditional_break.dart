import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports an unlabeled `break` that unconditionally exits a loop or switch.
class AvoidUnconditionalBreak extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unconditional_break',
    'Avoid unconditional break statements.',
    correctionMessage: 'Remove the break or the unreachable body.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidUnconditionalBreak()
    : super(
        name: 'avoid_unconditional_break',
        description: 'Reports break statements that are first in a loop or switch body.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addSwitchStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnconditionalBreak rule;

  @override
  void visitDoStatement(DoStatement node) {
    _checkLoopBody(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkLoopBody(node.body);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    for (final member in node.members) {
      final statements = member.statements;
      if (statements.isEmpty) continue;
      _checkBreak(statements.first);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkLoopBody(node.body);
  }

  void _checkLoopBody(Statement body) {
    final firstStatement = switch (body) {
      Block(:final statements) when statements.isNotEmpty => statements.first,
      BreakStatement() => body,
      _ => null,
    };

    if (firstStatement != null) {
      _checkBreak(firstStatement);
    }
  }

  void _checkBreak(Statement statement) {
    if (statement case BreakStatement(label: != null)) return;
    if (statement case BreakStatement(:final breakKeyword)) {
      rule.reportAtToken(breakKeyword);
    }
  }
}
