import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Refuses Flutter next-frame deferral calls: the order of events needs a fix at its cause.
final class AvoidFrameDeferral extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_frame_deferral',
    'Avoid `{0}`, which defers work to the next frame.',
    correctionMessage:
        'Fix the order of events at its cause: drive the work from state, a listener, '
        'a controller that corrects during layout, or the event handler.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFrameDeferral()
    : super(
        name: 'avoid_frame_deferral',
        description:
            'Flags Flutter next-frame deferral: addPostFrameCallback, scheduleFrameCallback, '
            'scheduleFrame and endOfFrame.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context) || isTestSourceContext(context)) return;
    registry.addSimpleIdentifier(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _deferralNames = {
    'addPostFrameCallback',
    'scheduleFrameCallback',
    'scheduleFrame',
    'endOfFrame',
  };

  final AvoidFrameDeferral rule;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_deferralNames.contains(node.name)) return;
    if (node.thisOrAncestorOfType<CommentReference>() != null) return;
    final element = node.element;
    final library = element is MethodElement || element is GetterElement ? element?.library : null;
    if (library == null || !library.identifier.startsWith('package:flutter/')) return;
    rule.reportAtNode(node, arguments: [node.name]);
  }
}
