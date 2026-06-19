import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when Mockito-style `thenReturn` receives a Future or Stream.
final class AvoidThenReturnWithFuture extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_then_return_with_future',
    'Avoid returning Futures or Streams from thenReturn().',
    correctionMessage: 'Use thenAnswer() for asynchronous values.',
  );

  AvoidThenReturnWithFuture()
    : super(
        name: 'avoid_then_return_with_future',
        description: 'Warns when thenReturn() receives a Future or Stream expression.',
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

  static const _futureChecker = TypeChecker.fromUrl('dart:async#Future');
  static const _streamChecker = TypeChecker.fromUrl('dart:async#Stream');

  final AvoidThenReturnWithFuture rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'thenReturn') return;

    final args = node.argumentList.arguments
        .where((argument) => argument is! NamedExpression)
        .toList();
    if (args.length != 1) return;

    final argument = args.single;

    final type = argument.staticType;
    if (type == null) return;

    if (_futureChecker.isAssignableFromType(type) || _streamChecker.isAssignableFromType(type)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
