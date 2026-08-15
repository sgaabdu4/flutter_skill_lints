import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/duplicate_literal_key.dart';

/// Warns when constant collection literals repeat an element or map key.
class AvoidDuplicateCollectionElements extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_collection_elements',
    'Avoid duplicate collection elements.',
    correctionMessage: 'Remove the repeated element.',
  );

  AvoidDuplicateCollectionElements()
    : super(
        name: 'avoid_duplicate_collection_elements',
        description: 'Warns when constant collection literals repeat a simple element or map key.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry
      ..addListLiteral(this, visitor)
      ..addSetOrMapLiteral(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateCollectionElements rule;

  @override
  void visitListLiteral(ListLiteral node) {
    if (!node.isConst) return;
    _reportDuplicateExpressions(node.elements, rule);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (!node.isConst) return;

    final mapEntries = node.elements.whereType<MapLiteralEntry>().toList();
    if (mapEntries.isNotEmpty) {
      _reportDuplicateMapKeys(mapEntries, rule);
      return;
    }

    _reportDuplicateExpressions(node.elements, rule);
  }
}

void _reportDuplicateExpressions(Iterable<CollectionElement> elements, AnalysisRule rule) {
  final seen = <String>{};

  for (final element in elements) {
    if (element is! Expression) continue;

    final key = duplicateLiteralKey(element);
    if (key == null) continue;

    if (!seen.add(key)) {
      rule.reportAtNode(element);
    }
  }
}

void _reportDuplicateMapKeys(Iterable<MapLiteralEntry> entries, AnalysisRule rule) {
  final seen = <String>{};

  for (final entry in entries) {
    final key = duplicateLiteralKey(entry.key);
    if (key == null) continue;

    if (!seen.add(key)) {
      rule.reportAtNode(entry.key);
    }
  }
}
