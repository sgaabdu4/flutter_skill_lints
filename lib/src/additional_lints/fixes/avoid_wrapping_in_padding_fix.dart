import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

/// Fix that removes the wrapping Padding widget and moves the padding value
/// to the child widget's padding parameter.
class AvoidWrappingInPaddingFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidWrappingInPadding',
    DartFixKindPriority.standard,
    "Move padding to the child widget's padding parameter",
  );

  AvoidWrappingInPaddingFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = _paddingTarget(node);
    if (target == null) return;
    final replacement = _paddingReplacement(target.argumentList);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(target.widget), replacement);
    });
  }

  static ({Expression widget, ArgumentList argumentList})? _paddingTarget(AstNode target) {
    return switch (target) {
      ConstructorName(parent: final InstanceCreationExpression parent) => (
        widget: parent,
        argumentList: parent.argumentList,
      ),
      SimpleIdentifier(parent: final MethodInvocation parent) => (
        widget: parent,
        argumentList: parent.argumentList,
      ),
      _ => null,
    };
  }

  static String? _paddingReplacement(ArgumentList paddingArguments) {
    final named = paddingArguments.arguments.whereType<NamedArgument>();
    final padding = named.firstWhereOrNull((argument) => argument.name.lexeme == 'padding');
    final child = named.firstWhereOrNull((argument) => argument.name.lexeme == 'child');
    if (padding == null || child == null) return null;
    final childInfo = _childInfo(child.argumentExpression);
    if (childInfo == null) return null;
    final args = _childArguments(childInfo.argumentList, paddingArguments);
    args.add('padding: ${padding.argumentExpression.toSource()}');
    return '${childInfo.prefix}(${args.join(', ')})';
  }

  static ({ArgumentList argumentList, String prefix})? _childInfo(Expression child) {
    return switch (child) {
      InstanceCreationExpression(:final argumentList, :final keyword, :final constructorName) => (
        argumentList: argumentList,
        prefix: '${keyword != null ? '${keyword.lexeme} ' : ''}${constructorName.toSource()}',
      ),
      MethodInvocation(:final argumentList, :final methodName) => (
        argumentList: argumentList,
        prefix: methodName.name,
      ),
      _ => null,
    };
  }

  static List<String> _childArguments(ArgumentList child, ArgumentList padding) {
    final args = child.arguments.map((argument) => argument.toSource()).toList();
    final key = padding.arguments.whereType<NamedArgument>().firstWhereOrNull(
      (argument) => argument.name.lexeme == 'key',
    );
    final hasKey = child.arguments.whereType<NamedArgument>().any(
      (argument) => argument.name.lexeme == 'key',
    );
    if (key != null && !hasKey) args.insert(0, key.toSource());
    return args;
  }
}
