import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports an unlabeled `continue` that is already the last loop statement.
class AvoidUnnecessaryContinue extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_continue',
    'Avoid unnecessary continue statements.',
    correctionMessage: 'Remove the continue statement.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidUnnecessaryContinue()
    : super(
        name: 'avoid_unnecessary_continue',
        description: 'Reports continue statements that are already at the end of a loop body.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidUnnecessaryContinue rule;

  @override
  void visitDoStatement(DoStatement node) {
    _checkLoopBody(node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkLoopBody(node.body);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkLoopBody(node.body);
  }

  void _checkLoopBody(Statement body) {
    final lastStatement = switch (body) {
      Block(:final statements) when statements.isNotEmpty => statements.last,
      ContinueStatement() => body,
      _ => null,
    };

    if (lastStatement case ContinueStatement(:final label?)) return;
    if (lastStatement case ContinueStatement(:final continueKeyword)) {
      rule.reportAtToken(continueKeyword);
    }
  }
}
