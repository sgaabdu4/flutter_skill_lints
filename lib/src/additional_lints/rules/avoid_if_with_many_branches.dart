import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when one `if` / `else if` chain has more than three branches.
class AvoidIfWithManyBranches extends AnalysisRule {
  static const int maxBranches = 3;

  static const LintCode code = LintCode(
    'avoid_if_with_many_branches',
    'Avoid if statements with more than three branches.',
    correctionMessage: 'Extract the decision or use a clearer dispatch structure.',
  );

  AvoidIfWithManyBranches()
    : super(
        name: 'avoid_if_with_many_branches',
        description: 'Warns when an if chain has more than three branches.',
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

  final AvoidIfWithManyBranches rule;

  @override
  void visitIfStatement(IfStatement node) {
    if (_isElseIf(node)) return;

    if (_branchCount(node) > AvoidIfWithManyBranches.maxBranches) {
      rule.reportAtToken(node.ifKeyword);
    }
  }
}

bool _isElseIf(IfStatement node) {
  final parent = node.parent;
  return parent is IfStatement && parent.elseStatement == node;
}

int _branchCount(IfStatement node) {
  var count = 0;
  IfStatement? current = node;

  while (current != null) {
    count++;

    final elseStatement = current.elseStatement;
    if (elseStatement is IfStatement) {
      current = elseStatement;
      continue;
    }

    if (elseStatement != null) {
      count++;
    }

    current = null;
  }

  return count;
}
