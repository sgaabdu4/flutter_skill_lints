import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../ast_node_analysis.dart';
import '../type_checker.dart';

/// Warns when a Column or Row has exactly one concrete child.
final class AvoidSingleChildColumnOrRow extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_single_child_column_or_row',
    'Avoid using {0} with a single child.',
    correctionMessage: 'Remove the {0} or replace it with a single-child widget.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidSingleChildColumnOrRow()
    : super(
        name: 'avoid_single_child_column_or_row',
        description: 'Warns when Column or Row has exactly one concrete child.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidSingleChildColumnOrRow rule;

  static const _columnChecker = TypeChecker.fromName('Column', packageName: 'flutter');
  static const _rowChecker = TypeChecker.fromName('Row', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;
    if (type == null) return;

    final widgetName = switch (type) {
      final t when _columnChecker.isExactlyType(t) => 'Column',
      final t when _rowChecker.isExactlyType(t) => 'Row',
      _ => null,
    };
    if (widgetName == null) return;

    final children = node.argumentList.arguments
        .whereType<NamedExpression>()
        .firstWhereOrNull((argument) => argument.name.lexeme == 'children')
        ?.expression;
    if (children is! ListLiteral || !_hasExactlyOneConcreteChild(children)) return;

    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }

  static bool _hasExactlyOneConcreteChild(ListLiteral list) {
    if (list.elements.length != 1) return false;

    return switch (list.elements.single) {
      Expression() => true,
      NullAwareElement() => true,
      IfElement() || ForElement() || SpreadElement() || MapLiteralEntry() => false,
    };
  }
}
