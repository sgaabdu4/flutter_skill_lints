import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Warns when a literal Firebase Analytics event name is invalid.
class IncorrectFirebaseEventName extends AnalysisRule {
  static const LintCode code = LintCode(
    'incorrect_firebase_event_name',
    'Use a valid Firebase Analytics event name.',
    correctionMessage:
        'Event names must start with a letter, contain only letters, digits, '
        'and underscores, be 1-40 characters long, and avoid reserved prefixes.',
  );

  IncorrectFirebaseEventName()
    : super(
        name: 'incorrect_firebase_event_name',
        description: 'Warns when Firebase Analytics logEvent uses an invalid literal event name.',
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

  final IncorrectFirebaseEventName rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'logEvent') return;

    final name = _eventNameArgument(node.argumentList);
    if (name == null || _isValidFirebaseName(name.value)) return;

    rule.reportAtNode(name);
  }
}

SimpleStringLiteral? _eventNameArgument(ArgumentList argumentList) {
  for (final argument in argumentList.arguments) {
    if (argument is NamedExpression) {
      if (argument.name.lexeme != 'name') continue;
      final expression = argument.expression;
      return expression is SimpleStringLiteral ? expression : null;
    }

    return argument is SimpleStringLiteral ? argument : null;
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
