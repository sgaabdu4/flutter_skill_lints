import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Rewrites `if (!X.mounted) return; <rest>` inside a `finally` block as
/// `if (X.mounted) { <rest> }`.
class AvoidMountedCheckInFinallyFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidMountedCheckInFinally',
    DartFixKindPriority.standard,
    "Convert to 'if (mounted) { ... }' guard",
  );

  AvoidMountedCheckInFinallyFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final ifNode = node;
    if (ifNode is! IfStatement) return;
    final parent = ifNode.parent;
    if (parent is! Block) return;

    final negated = ifNode.expression;
    if (negated is! PrefixExpression || negated.operator.type != TokenType.BANG) return;
    final positiveExprSource = _sourceOf(negated.operand);
    if (positiveExprSource == null) return;

    final statements = parent.statements;
    final ifIndex = statements.indexOf(ifNode);
    if (ifIndex == -1) return;
    final trailing = statements.sublist(ifIndex + 1);
    if (trailing.isEmpty) return; // no statements to guard — refuse fix.

    final content = unitResult.content;
    final blockIndent = _lineIndent(content, parent.offset);
    final innerIndent = '$blockIndent  ';

    final body = trailing
        .map((s) => '$innerIndent${content.substring(s.offset, s.end)}')
        .join('\n');

    final replacement = 'if ($positiveExprSource) {\n$body\n$blockIndent}';

    final replaceRange = range.startEnd(ifNode, trailing.last);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(replaceRange, replacement);
    });
  }

  String? _sourceOf(AstNode node) {
    final content = unitResult.content;
    return content.substring(node.offset, node.end);
  }

  String _lineIndent(String content, int offset) {
    var lineStart = offset;
    while (lineStart > 0 && content[lineStart - 1] != '\n') {
      lineStart--;
    }
    final buf = StringBuffer();
    for (var i = lineStart; i < offset; i++) {
      final ch = content[i];
      if (ch == ' ' || ch == '\t') {
        buf.write(ch);
      } else {
        break;
      }
    }
    return buf.toString();
  }
}
