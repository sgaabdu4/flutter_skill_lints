import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when catch clauses in the same try statement use identical bodies.
class AvoidIdenticalExceptionHandlingBlocks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_identical_exception_handling_blocks',
    'Avoid identical exception handling blocks.',
    correctionMessage: 'Merge the catches or make each handler specific.',
  );

  AvoidIdenticalExceptionHandlingBlocks()
    : super(
        name: 'avoid_identical_exception_handling_blocks',
        description: 'Warns when catch clauses in the same try statement use identical bodies.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addTryStatement(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidIdenticalExceptionHandlingBlocks rule;

  @override
  void visitTryStatement(TryStatement node) {
    final seenBodies = <String>{};

    for (final catchClause in node.catchClauses) {
      final signature = _bodySignature(catchClause.body);
      if (signature == null) continue;

      if (!seenBodies.add(signature)) {
        rule.reportAtNode(catchClause.body);
      }
    }
  }
}

String? _bodySignature(Block body) {
  if (body.statements.isEmpty) return null;

  return body.statements
      .map((statement) => statement.toSource().replaceAll(RegExp(r'\s+'), ' ').trim())
      .join(';');
}
