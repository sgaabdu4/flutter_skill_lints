import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when code uses banned type annotations.
class AvoidBannedTypes extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_banned_types',
    "Avoid banned type '{0}'.",
    correctionMessage: 'Use a specific type or Object? at the boundary.',
  );

  AvoidBannedTypes()
    : super(
        name: 'avoid_banned_types',
        description: 'Warns when code uses banned type annotations.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addNamedType(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidBannedTypes rule;

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.lexeme;
    if (name != 'dynamic') return;
    if (_isJsonMapValueType(node)) return;

    rule.reportAtNode(node, arguments: [name]);
  }
}

bool _isJsonMapValueType(NamedType node) {
  final typeArguments = node.parent;
  if (typeArguments is! TypeArgumentList) return false;

  final arguments = typeArguments.arguments;
  if (arguments.length != 2 || arguments.last != node) return false;

  final mapType = typeArguments.parent;
  if (mapType is! NamedType || mapType.name.lexeme != 'Map') return false;

  final keyType = arguments.first;
  return keyType is NamedType && keyType.name.lexeme == 'String';
}
