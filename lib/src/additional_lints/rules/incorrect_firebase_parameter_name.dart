import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Warns when a literal Firebase Analytics parameter name is invalid.
class IncorrectFirebaseParameterName extends AnalysisRule {
  static const LintCode code = LintCode(
    'incorrect_firebase_parameter_name',
    'Use a valid Firebase Analytics parameter name.',
    correctionMessage:
        'Parameter names must start with a letter, contain only letters, digits, '
        'and underscores, be 1-40 characters long, and avoid reserved prefixes.',
  );

  IncorrectFirebaseParameterName()
    : super(
        name: 'incorrect_firebase_parameter_name',
        description: 'Warns when Firebase Analytics logEvent uses invalid literal parameter names.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final IncorrectFirebaseParameterName rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'logEvent') return;

    final parameters = _parametersArgument(node.argumentList);
    if (parameters == null) return;

    for (final entry in parameters.elements.whereType<MapLiteralEntry>()) {
      final key = entry.key;
      if (key is! SimpleStringLiteral || _isValidFirebaseName(key.value)) continue;
      rule.reportAtNode(key);
    }
  }
}

SetOrMapLiteral? _parametersArgument(ArgumentList argumentList) {
  for (final argument in argumentList.arguments.whereType<NamedExpression>()) {
    if (argument.name.lexeme != 'parameters') continue;
    final expression = argument.expression;
    return expression is SetOrMapLiteral ? expression : null;
  }

  return null;
}

bool _isValidFirebaseName(String name) {
  if (name.isEmpty || name.length > 40) return false;
  if (_hasReservedPrefix(name)) return false;
  return RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(name);
}

bool _hasReservedPrefix(String name) {
  final normalized = name.toLowerCase();
  return normalized.startsWith('firebase_') ||
      normalized.startsWith('google_') ||
      normalized.startsWith('ga_');
}
