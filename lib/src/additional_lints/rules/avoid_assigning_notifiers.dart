import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a Riverpod notifier is assigned to a variable or field.
///
/// Keeping notifier instances around makes it easier to use a stale notifier
/// after provider disposal. Read the notifier at the call site instead.
class AvoidAssigningNotifiers extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_assigning_notifiers',
    'Avoid assigning Riverpod notifiers.',
    correctionMessage:
        'Call the notifier member directly from ref.read(provider.notifier), '
        'or pass a callback instead of storing the notifier.',
  );

  AvoidAssigningNotifiers()
    : super(
        name: 'avoid_assigning_notifiers',
        description: 'Warns when ref.read/watch(provider.notifier) is assigned.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addVariableDeclaration(this, visitor);
    registry.addAssignmentExpression(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAssigningNotifiers rule;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer == null) return;
    if (!_isNotifierRead(initializer)) return;

    rule.reportAtOffset(node.name.offset, node.name.length);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (!_isNotifierRead(node.rightHandSide)) return;

    rule.reportAtNode(node.leftHandSide);
  }
}

bool _isNotifierRead(Expression expression) {
  final unwrapped = expression.unParenthesized;
  if (unwrapped is! MethodInvocation) return false;
  if (unwrapped.methodName.name case final name when name != 'read' && name != 'watch') {
    return false;
  }
  final target = unwrapped.target;
  if (target is! SimpleIdentifier || target.name != 'ref') return false;
  if (unwrapped.argumentList.arguments.length != 1) return false;

  final argument = unwrapped.argumentList.arguments.single;
  if (argument is! Expression) return false;
  return _isNotifierSelector(argument);
}

bool _isNotifierSelector(Expression expression) {
  final unwrapped = expression.unParenthesized;
  return switch (unwrapped) {
    PrefixedIdentifier(:final identifier) => identifier.name == 'notifier',
    PropertyAccess(:final propertyName) => propertyName.name == 'notifier',
    _ => false,
  };
}
