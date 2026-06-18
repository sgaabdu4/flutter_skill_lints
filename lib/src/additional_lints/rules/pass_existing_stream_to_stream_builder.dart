import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

import '../type_checker.dart';

/// Warns when a `StreamBuilder` creates its `stream` inline.
class PassExistingStreamToStreamBuilder extends AnalysisRule {
  static const LintCode code = LintCode(
    'pass_existing_stream_to_stream_builder',
    'Pass an existing Stream to StreamBuilder.',
    correctionMessage:
        'Store the Stream outside build/init path churn and pass the existing Stream value.',
  );

  PassExistingStreamToStreamBuilder()
    : super(
        name: 'pass_existing_stream_to_stream_builder',
        description: 'Warns when StreamBuilder receives an inline-created Stream.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PassExistingStreamToStreamBuilder rule;

  static const _streamBuilderChecker = TypeChecker.fromName(
    'StreamBuilder',
    packageName: 'flutter',
  );

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_streamBuilderChecker.isExactly(element)) return;

    final stream = _namedArgument(node.argumentList, 'stream');
    if (stream == null || !_createsStreamInline(stream)) return;

    rule.reportAtNode(stream);
  }

  static Expression? _namedArgument(ArgumentList argumentList, String name) {
    for (final argument in argumentList.arguments.whereType<NamedExpression>()) {
      if (argument.name.lexeme == name) return argument.expression;
    }
    return null;
  }

  static bool _createsStreamInline(Expression expression) {
    final unwrapped = expression.unParenthesized;
    return unwrapped is MethodInvocation || unwrapped is InstanceCreationExpression;
  }
}
