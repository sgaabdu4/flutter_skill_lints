import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Reports positional record fields on records with three or more of them.
///
/// The skill shows positional pairs such as `(String, int) userInfo()` and
/// prefers named fields "when 3+ fields". A positional literal destructured in
/// place (`final (_, price, _) = (id, 9.99, sku);`) never exposes its fields by
/// position, so it is allowed too.
final class AvoidPositionalRecordFields extends RecordRule {
  static const LintCode code = LintCode(
    'avoid_positional_record_fields',
    'Avoid positional record fields.',
    correctionMessage: 'Use a named record shape such as ({Type fieldName}).',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidPositionalRecordFields()
    : super(
        name: 'avoid_positional_record_fields',
        description: 'Reports positional fields in record literals and record type annotations.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidPositionalRecordFields rule;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (_positionalCount(node.fields) < _namedFieldThreshold) return;
    if (_isDestructuredInPlace(node) || _isSdkFutureRecordWait(node)) return;
    for (final field in node.fields) {
      if (field is RecordLiteralNamedField) continue;
      rule.reportAtNode(field);
    }
  }

  bool _isSdkFutureRecordWait(RecordLiteral node) {
    final parent = node.parent;
    if (parent is! PropertyAccess || parent.target != node) return false;
    final accessor = parent.propertyName.element;
    if (accessor is! PropertyAccessorElement || accessor.name != 'wait') return false;
    final owner = accessor.enclosingElement;
    return owner is ExtensionElement &&
        owner.library.uri.toString() == 'dart:async' &&
        RegExp(r'^FutureRecord[2-9]$').hasMatch(owner.name ?? '');
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    if (node.positionalFields.length < _namedFieldThreshold) return;
    for (final field in node.positionalFields) {
      rule.reportAtNode(field);
    }
  }
}

const _namedFieldThreshold = 3;

int _positionalCount(NodeList<RecordLiteralField> fields) =>
    fields.where((field) => field is! RecordLiteralNamedField).length;

bool _isDestructuredInPlace(RecordLiteral node) {
  final parent = node.parent;
  return (parent is PatternVariableDeclaration && parent.expression == node) ||
      (parent is PatternAssignment && parent.expression == node);
}
