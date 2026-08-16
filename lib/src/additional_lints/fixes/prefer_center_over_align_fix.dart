import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that replaces Align(alignment: center) with Center.
class PreferCenterOverAlignFix extends SingleLocationCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferCenterOverAlign',
    DartFixKindPriority.standard,
    'Replace with Center',
  );

  PreferCenterOverAlignFix({required super.context}) : super(fixKind: _fixKind);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! ConstructorName) return;

    final instanceCreation = targetNode.parent;
    if (instanceCreation is! InstanceCreationExpression) return;

    // Find alignment argument to remove
    final alignmentArgument = instanceCreation.argumentList.arguments
        .whereType<NamedArgument>()
        .firstWhereOrNull((e) => e.name.lexeme == 'alignment');

    await builder.addDartFileEdit(file, (builder) {
      // Replace Align with Center
      builder.addSimpleReplacement(range.node(targetNode), 'Center');

      // Remove alignment argument if present
      if (alignmentArgument != null) {
        builder.addDeletion(
          range.nodeInList(instanceCreation.argumentList.arguments, alignmentArgument),
        );
      }
    });
  }
}
