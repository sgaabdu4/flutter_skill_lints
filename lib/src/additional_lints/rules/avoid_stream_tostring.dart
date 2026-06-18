import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `toString()` is called on a Stream.
class AvoidStreamToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_stream_tostring',
    'Avoid calling toString() on a Stream.',
    correctionMessage:
        'Listen to the Stream or handle emitted values before converting to a string.',
  );

  AvoidStreamToString()
    : super(name: 'avoid_stream_tostring', description: 'Warns when Stream.toString() is used.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _streamChecker = TypeChecker.fromUrl('dart:async#Stream');

  final AvoidStreamToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final targetType = node.target?.staticType;
    if (targetType == null || !_streamChecker.isAssignableFromType(targetType)) return;

    rule.reportAtNode(node.methodName);
  }
}
