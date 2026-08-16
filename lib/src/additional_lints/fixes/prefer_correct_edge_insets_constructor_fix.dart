import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/edge_insets_replacement.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Fix that replaces an EdgeInsets constructor with a simpler alternative.
class PreferCorrectEdgeInsetsConstructorFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferCorrectEdgeInsetsConstructor',
    DartFixKindPriority.standard,
    'Use simpler EdgeInsets constructor',
  );

  PreferCorrectEdgeInsetsConstructorFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  static const _edgeInsetsChecker = TypeChecker.fromName('EdgeInsets', packageName: 'flutter');

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;

    final String? constructorName;
    final ArgumentList argumentList;

    if (targetNode is InstanceCreationExpression) {
      final staticType = targetNode.staticType;
      if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
        return;
      }
      constructorName = targetNode.constructorName.name?.name;
      argumentList = targetNode.argumentList;
    } else if (targetNode is MethodInvocation) {
      final staticType = targetNode.staticType;
      if (staticType == null || !_edgeInsetsChecker.isExactlyType(staticType)) {
        return;
      }
      constructorName = targetNode.methodName.name;
      argumentList = targetNode.argumentList;
    } else {
      return;
    }

    final replacement = edgeInsetsReplacement(constructorName, argumentList);
    if (replacement == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
