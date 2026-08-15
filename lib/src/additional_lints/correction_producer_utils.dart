import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:flutter_skill_lints/src/additional_lints/override_fix_utils.dart';

abstract class SingleLocationCorrectionProducer extends ResolvedCorrectionProducer {
  SingleLocationCorrectionProducer({required super.context, required FixKind fixKind})
    : _fixKind = fixKind;

  final FixKind _fixKind;

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  Future<void> addGuardBeforeStatement(ChangeBuilder builder, String guard) async {
    final statement = _nearestStatement(node);
    if (statement == null) return;

    final content = unitResult.content;
    var lineStart = statement.offset;
    while (lineStart > 0 && content[lineStart - 1] != '\n') {
      lineStart--;
    }
    final indent = content.substring(lineStart, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.offset, '$guard\n$indent');
    });
  }
}

Statement? _nearestStatement(AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (current is Statement) return current;
    current = current.parent;
  }
  return null;
}

abstract class RemoveConstructorCorrection extends SingleLocationCorrectionProducer {
  RemoveConstructorCorrection({required super.context, required super.fixKind});

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ConstructorDeclaration) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(range.node(targetNode));
    });
  }
}

abstract class RemoveUnnecessaryOverrideCorrection extends SingleLocationCorrectionProducer {
  RemoveUnnecessaryOverrideCorrection({required super.context, required super.fixKind});

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodDeclaration) return;

    final deletionRange = methodOverrideDeletionRange(targetNode, unitResult.content);
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(deletionRange);
    });
  }
}

abstract class ReplaceConstructorNameCorrection extends SingleLocationCorrectionProducer {
  ReplaceConstructorNameCorrection({required super.context, required super.fixKind});

  String get replacement;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ConstructorName) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
