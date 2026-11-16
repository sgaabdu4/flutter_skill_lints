import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';

/// Fix that replaces RichText with Text.rich.
class PreferTextRichFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferTextRich',
    DartFixKindPriority.standard,
    'Replace with Text.rich',
  );

  PreferTextRichFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final replacementNode = reportedWidgetExpression(node);
    final ArgumentList argumentList;
    if (replacementNode is InstanceCreationExpression) {
      argumentList = replacementNode.argumentList;
    } else if (replacementNode is MethodInvocation) {
      argumentList = replacementNode.argumentList;
    } else {
      return;
    }
    final arguments = argumentList.arguments;

    // Find the `text` argument (the TextSpan)
    final textArgument = arguments.whereType<NamedArgument>().firstWhereOrNull(
      (e) => e.name.lexeme == 'text',
    );

    if (textArgument == null) return;

    // Build the replacement: Text.rich(textSpan, otherArgs...)
    final textSpanSource = textArgument.argumentExpression.toSource();

    // Collect other arguments (excluding `text`)
    final otherArgs = <String>[];
    for (final arg in arguments) {
      if (arg == textArgument) continue;
      otherArgs.add(arg.toSource());
    }

    final buffer = StringBuffer('Text.rich(');
    buffer.write(textSpanSource);
    for (final other in otherArgs) {
      buffer.write(', ');
      buffer.write(other);
    }
    buffer.write(')');

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(replacementNode), buffer.toString());
    });
  }
}
