import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when catch clauses in the same try statement use identical bodies.
class AvoidIdenticalExceptionHandlingBlocks extends TryStatementCheckRule {
  static const LintCode code = LintCode(
    'avoid_identical_exception_handling_blocks',
    'Avoid identical exception handling blocks.',
    correctionMessage: 'Merge the catches or make each handler specific.',
  );

  AvoidIdenticalExceptionHandlingBlocks()
    : super(
        name: 'avoid_identical_exception_handling_blocks',
        description: 'Warns when catch clauses in the same try statement use identical bodies.',
        code: code,
      );

  @override
  void checkTryStatement(TryStatement node) {
    final seenBodies = <String>{};

    for (final catchClause in node.catchClauses) {
      final signature = _bodySignature(catchClause.body);
      if (signature == null) continue;

      if (!seenBodies.add(signature)) {
        reportAtNode(catchClause.body);
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
