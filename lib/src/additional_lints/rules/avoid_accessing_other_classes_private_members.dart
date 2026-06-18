import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when code reaches into another object's private member.
class AvoidAccessingOtherClassesPrivateMembers extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_accessing_other_classes_private_members',
    "Avoid accessing private member '{0}' from another class.",
    correctionMessage: 'Expose a public API on the owning class instead.',
  );

  AvoidAccessingOtherClassesPrivateMembers()
    : super(
        name: 'avoid_accessing_other_classes_private_members',
        description: 'Warns when a private member of another class is used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPrefixedIdentifier(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidAccessingOtherClassesPrivateMembers rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target == null || _isOwnReceiver(target)) return;
    _check(node.methodName);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isOwnReceiver(node.prefix)) return;
    _check(node.identifier);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target == null || _isOwnReceiver(target)) return;
    _check(node.propertyName);
  }

  void _check(SimpleIdentifier identifier) {
    final name = identifier.name;
    if (!_isPrivateMemberName(name)) return;
    rule.reportAtNode(identifier, arguments: [name]);
  }
}

bool _isPrivateMemberName(String name) => name.length > 1 && name.startsWith('_');

bool _isOwnReceiver(Expression receiver) {
  final unwrapped = receiver.unParenthesized;
  return unwrapped is ThisExpression || unwrapped is SuperExpression;
}
