import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a Future is explicitly ignored with `.ignore()`.
class AvoidFutureIgnore extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_future_ignore',
    'Avoid ignoring a Future with ignore().',
    correctionMessage: 'Handle the Future result or use unawaited() with an explicit reason.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFutureIgnore()
    : super(name: 'avoid_future_ignore', description: 'Warns when Future.ignore() is used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

  final AvoidFutureIgnore rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'ignore') return;
    if (node.argumentList.arguments.isNotEmpty) return;
    final targetType = node.target?.staticType;
    if (targetType == null || !_futureChecker.isAssignableFromType(targetType)) return;
    rule.reportAtNode(node.methodName);
  }
}
