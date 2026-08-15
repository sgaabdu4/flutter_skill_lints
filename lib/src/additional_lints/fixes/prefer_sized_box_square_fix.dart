import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

/// Fix that replaces `SizedBox(width: x, height: x)` with
/// `SizedBox.square(dimension: x)`.
class PreferSizedBoxSquareFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferSizedBoxSquare',
    DartFixKindPriority.standard,
    'Replace with SizedBox.square',
  );

  PreferSizedBoxSquareFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final creationExpr = _creationExpression(node);
    if (creationExpr == null) return;
    final argumentList = _argumentList(creationExpr);
    if (argumentList == null) return;
    final replacement = _squareReplacement(creationExpr, argumentList);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(creationExpr), replacement);
    });
  }

  static Expression? _creationExpression(AstNode target) {
    if (target is ConstructorName) {
      final parent = target.parent;
      return parent is InstanceCreationExpression ? parent : null;
    }
    if (target is SimpleIdentifier && target.parent is MethodInvocation) {
      return target.parent! as MethodInvocation;
    }
    return null;
  }

  static ArgumentList? _argumentList(Expression expression) {
    return switch (expression) {
      InstanceCreationExpression(:final argumentList) => argumentList,
      MethodInvocation(:final argumentList) => argumentList,
      _ => null,
    };
  }

  static String? _squareReplacement(Expression expression, ArgumentList argumentList) {
    final widthArg = argumentList.arguments.whereType<NamedArgument>().firstWhereOrNull(
      (argument) => argument.name.lexeme == 'width',
    );
    if (widthArg == null) return null;

    final otherArgs = [
      for (final argument in argumentList.arguments)
        if (!_isSizeArgument(argument)) argument.toSource(),
    ];
    otherArgs.add('dimension: ${widthArg.argumentExpression.toSource()}');
    final constPrefix = expression is InstanceCreationExpression && expression.keyword != null
        ? '${expression.keyword!.lexeme} '
        : '';
    return '${constPrefix}SizedBox.square(${otherArgs.join(', ')})';
  }

  static bool _isSizeArgument(Argument argument) {
    if (argument is! NamedArgument) return false;
    return argument.name.lexeme == 'width' || argument.name.lexeme == 'height';
  }
}
