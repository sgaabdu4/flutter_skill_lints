import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoids `FutureOr<T>` as a function or method return type.
///
/// Effective Dart recommends returning a stable sync or async shape. Accepting
/// `FutureOr<T>` in parameters or callback return types can be useful, but
/// returning it makes callers branch or always `await`.
class AvoidFutureOrReturnType extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_futureor_return_type',
    'Avoid FutureOr as a return type.',
    correctionMessage:
        'Return Future<T> for async APIs, T for sync APIs, or Future<void> for async APIs without a value.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFutureOrReturnType()
    : super(
        name: 'avoid_futureor_return_type',
        description: 'Avoids FutureOr<T> as a public API return type.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidFutureOrReturnType rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkReturnType(node.returnType);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkReturnType(node.returnType);
  }

  void _checkReturnType(TypeAnnotation? returnType) {
    if (returnType is! NamedType) return;
    if (returnType.name.lexeme != 'FutureOr') return;
    if (returnType.element?.library?.isDartAsync != true) return;

    rule.reportAtNode(returnType);
  }
}
