import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when positional record fields are accessed with `$1`, `$2`, etc.
class AvoidPositionalRecordFieldAccess extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_positional_record_field_access',
    'Avoid positional record field access.',
    correctionMessage: 'Destructure the record or use named fields.',
  );

  AvoidPositionalRecordFieldAccess()
    : super(
        name: 'avoid_positional_record_field_access',
        description: 'Warns when positional record fields are accessed directly.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry
      ..addPrefixedIdentifier(this, visitor)
      ..addPropertyAccess(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  static final RegExp _positionalFieldName = RegExp(r'^\$[1-9]\d*$');

  _Visitor(this.rule);

  final AvoidPositionalRecordFieldAccess rule;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isPositionalFieldName(node.identifier.name) && _isRecordType(node.prefix.staticType)) {
      rule.reportAtToken(node.identifier.token);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isPositionalFieldName(node.propertyName.name) &&
        _isRecordType(node.realTarget.staticType)) {
      rule.reportAtToken(node.propertyName.token);
    }
  }

  bool _isPositionalFieldName(String name) => _positionalFieldName.hasMatch(name);

  bool _isRecordType(DartType? type) => type is RecordType;
}
