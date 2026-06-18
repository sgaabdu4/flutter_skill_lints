import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Avoids async container types nested across `Future` and `Stream`.
class AvoidNestedStreamsAndFutures extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nested_streams_and_futures',
    'Avoid nested Stream and Future types.',
    correctionMessage: 'Expose one async boundary and flatten the produced value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNestedStreamsAndFutures()
    : super(
        name: 'avoid_nested_streams_and_futures',
        description: 'Avoids Future<Stream<T>>, Stream<Future<T>>, and Stream<Stream<T>>.',
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

  final AvoidNestedStreamsAndFutures rule;

  @override
  void visitNamedType(NamedType node) {
    if (!_isDartAsyncType(node, 'Future') && !_isDartAsyncType(node, 'Stream')) {
      return;
    }

    final typeArguments = node.typeArguments?.arguments;
    if (typeArguments == null) return;

    for (final typeArgument in typeArguments) {
      if (typeArgument is! NamedType) continue;
      if (_isDartAsyncType(node, 'Future') && _isDartAsyncType(typeArgument, 'Future')) {
        continue;
      }
      if (_isDartAsyncType(typeArgument, 'Future') || _isDartAsyncType(typeArgument, 'Stream')) {
        rule.reportAtNode(node);
        return;
      }
    }
  }
}

bool _isDartAsyncType(NamedType type, String name) {
  return type.name.lexeme == name && type.element?.library?.isDartAsync == true;
}
