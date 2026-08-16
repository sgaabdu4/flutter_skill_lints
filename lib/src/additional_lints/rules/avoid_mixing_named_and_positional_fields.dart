import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Reports when a record mixes positional and named fields.
class AvoidMixingNamedAndPositionalFields extends RecordRule {
  static const LintCode code = LintCode(
    'avoid_mixing_named_and_positional_fields',
    'Avoid mixing named and positional record fields.',
    correctionMessage: 'Use either named fields or positional fields consistently.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidMixingNamedAndPositionalFields()
    : super(
        name: 'avoid_mixing_named_and_positional_fields',
        description: 'Reports when a record mixes named and positional fields.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidMixingNamedAndPositionalFields rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    var hasNamed = false;
    var hasPositional = false;

    for (final field in node.fields) {
      if (field is RecordLiteralNamedField) {
        hasNamed = true;
      } else {
        hasPositional = true;
      }
    }

    if (hasNamed && hasPositional) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    final hasNamed = node.namedFields?.fields.isNotEmpty ?? false;
    if (hasNamed && node.positionalFields.isNotEmpty) {
      rule.reportAtNode(node);
    }
  }
}
