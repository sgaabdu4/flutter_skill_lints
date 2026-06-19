import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when Mocktail/Mockito `thenReturn` receives async values.
final class UseThenAnswer extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_then_answer',
    'Use thenAnswer() for Futures and Streams.',
    correctionMessage: 'Return asynchronous values from thenAnswer() instead of thenReturn().',
  );

  UseThenAnswer()
    : super(
        name: 'use_then_answer',
        description: 'Warns when thenReturn() receives a Future or Stream value.',
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

  final UseThenAnswer rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'thenReturn') return;

    final arguments = node.argumentList.arguments
        .where((argument) => argument is! NamedExpression)
        .toList();
    if (arguments.length != 1) return;

    final argument = arguments.single;

    final type = argument.staticType;
    if (type == null) return;

    if (_futureChecker.isAssignableFromType(type) || _streamChecker.isAssignableFromType(type)) {
      rule.reportAtNode(node.methodName);
    }
  }
}
