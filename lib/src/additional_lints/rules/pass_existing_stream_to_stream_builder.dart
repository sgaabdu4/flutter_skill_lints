import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a `StreamBuilder` creates its `stream` inline.
class PassExistingStreamToStreamBuilder extends InstanceCreationExpressionRule {
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
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
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

    final stream = namedArgumentExpression(node.argumentList, 'stream');
    if (stream == null || !isInlineCreatedExpression(stream)) return;

    rule.reportAtNode(stream);
  }
}
