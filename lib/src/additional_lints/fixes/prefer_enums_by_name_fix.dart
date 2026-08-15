import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/enum_name_access.dart';

/// Fix that replaces `.firstWhere((e) => e.name == value)` with `.byName(value)`.
class PreferEnumsByNameFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferEnumsByName',
    DartFixKindPriority.standard,
    'Replace with .byName()',
  );

  PreferEnumsByNameFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! MethodInvocation) return;
    final candidate = enumByNameCandidate(targetNode);
    if (candidate == null) return;

    // Extract the value being compared (the non-param.name side)
    final String valueSource;
    if (isEnumNameAccess(candidate.body.leftOperand, candidate.parameterName)) {
      valueSource = candidate.body.rightOperand.toSource();
    } else if (isEnumNameAccess(candidate.body.rightOperand, candidate.parameterName)) {
      valueSource = candidate.body.leftOperand.toSource();
    } else {
      return;
    }

    final replacement = '${candidate.target.toSource()}.byName($valueSource)';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
