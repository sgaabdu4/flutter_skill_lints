import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Requires nullable platform-specific plugin implementations to be resolved
/// before their members are used.
class ResolvePlatformSpecificImplementationBeforeUse extends AnalysisRule {
  static const LintCode code = LintCode(
    'resolve_platform_specific_implementation_before_use',
    'Resolve platform-specific plugin implementations before use.',
    correctionMessage:
        'Assign resolvePlatformSpecificImplementation<T>() to a local variable or getter, handle null explicitly, then call platform-specific members.',
    severity: DiagnosticSeverity.ERROR,
  );

  ResolvePlatformSpecificImplementationBeforeUse()
    : super(
        name: 'resolve_platform_specific_implementation_before_use',
        description:
            'Avoids chaining member access directly from nullable platform-specific plugin resolution.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addMethodInvocation(this, visitor);
    registry.addPropertyAccess(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final ResolvePlatformSpecificImplementationBeforeUse rule;
  final Set<int> _reportedOffsets = <int>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final resolveCall = _resolvePlatformSpecificImplementationCall(node.target);
    if (resolveCall == null) return;
    _report(resolveCall.methodName);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final resolveCall = _resolvePlatformSpecificImplementationCall(node.target);
    if (resolveCall == null) return;
    _report(resolveCall.methodName);
  }

  void _report(AstNode node) {
    if (!_reportedOffsets.add(node.offset)) return;
    rule.reportAtNode(node);
  }
}

MethodInvocation? _resolvePlatformSpecificImplementationCall(Expression? expression) {
  AstNode? current = expression;
  while (true) {
    if (current is ParenthesizedExpression) {
      current = current.expression;
      continue;
    }
    if (current is PostfixExpression && current.operator.type == TokenType.BANG) {
      current = current.operand;
      continue;
    }
    if (current is MethodInvocation &&
        current.methodName.name == 'resolvePlatformSpecificImplementation') {
      return current;
    }
    return null;
  }
}
