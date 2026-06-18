import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Avoids `Future<Future<T>>`.
class AvoidNestedFutures extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_futures',
    'Avoid nested Future types.',
    correctionMessage: 'Flatten the async contract to a single Future.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNestedFutures()
    : super(
        name: 'avoid_nested_futures',
        description: 'Avoids Future<Future<T>> type annotations.',
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

  final AvoidNestedFutures rule;

  @override
  void visitNamedType(NamedType node) {
    if (!_isDartAsyncType(node, 'Future')) return;

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) return;

    if (typeArguments.any(_containsFutureType)) {
      rule.reportAtNode(node);
    }
  }
}

bool _containsFutureType(TypeAnnotation type) {
  if (type is! NamedType) return false;
  if (_isDartAsyncType(type, 'Future')) return true;

  return type.typeArguments?.arguments.any(_containsFutureType) ?? false;
}

bool _isDartAsyncType(NamedType type, String name) {
  return type.name.lexeme == name && type.element?.library?.isDartAsync == true;
}
