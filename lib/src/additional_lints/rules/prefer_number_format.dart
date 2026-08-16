import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';

/// Warns when `NumberFormat` string patterns have clearer named constructors.
final class PreferNumberFormat extends InstanceCreationExpressionRule {
  static const LintCode code = LintCode(
    'prefer_number_format',
    'Prefer a named NumberFormat constructor.',
    correctionMessage: 'Use {0} instead of a string pattern.',
  );

  PreferNumberFormat()
    : super(
        name: 'prefer_number_format',
        description: 'Warns when NumberFormat string patterns have named constructor equivalents.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferNumberFormat rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName;
    if (constructor.type.name.lexeme != 'NumberFormat') return;
    if (constructor.name != null) return;

    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) return;

    final pattern = arguments.first;
    if (pattern is! SimpleStringLiteral) return;

    final replacement = _replacementFor(pattern.value);
    if (replacement == null) return;

    rule.reportAtNode(pattern, arguments: [replacement]);
  }
}

String? _replacementFor(String pattern) {
  return switch (pattern) {
    '#,##0.###' => 'NumberFormat.decimalPattern()',
    '#,##0%' => 'NumberFormat.percentPattern()',
    '#E0' => 'NumberFormat.scientificPattern()',
    '\u00A4#,##0.00' => 'NumberFormat.currency()',
    _ => null,
  };
}
