import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Fix that replaces a duplicated expression with the existing variable name.
class UseExistingVariableFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.useExistingVariable',
    DartFixKindPriority.standard,
    'Replace with existing variable',
  );

  UseExistingVariableFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! Expression) return;

    final variableName = _findMatchingVariable(targetNode);
    if (variableName == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), variableName);
    });
  }

  /// Walks up to the enclosing block and finds the final/const variable
  /// whose initializer matches the target expression's source.
  static String? _findMatchingVariable(Expression expression) {
    final block = _enclosingBlock(expression.parent);
    if (block == null) return null;
    final expressionSource = expression.toSource();
    for (final statement in block.statements) {
      if (statement.offset >= expression.offset) break;
      final name = _matchingVariableName(statement, expressionSource);
      if (name != null) return name;
    }
    return null;
  }

  static Block? _enclosingBlock(AstNode? node) {
    var current = node;
    while (current != null && current is! Block) {
      current = current.parent;
    }
    return current as Block?;
  }

  static String? _matchingVariableName(AstNode statement, String expressionSource) {
    if (statement is! VariableDeclarationStatement) return null;
    final variables = statement.variables;
    if (!variables.isFinal && !variables.isConst) return null;
    for (final variable in variables.variables) {
      if (variable.initializer?.toSource() == expressionSource) {
        return variable.name.lexeme;
      }
    }
    return null;
  }
}
