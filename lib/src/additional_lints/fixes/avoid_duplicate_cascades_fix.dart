import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Fix that removes the duplicate cascade section.
class AvoidDuplicateCascadesFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidDuplicateCascades',
    DartFixKindPriority.standard,
    'Remove duplicate cascade section',
  );

  AvoidDuplicateCascadesFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final section = node;
    if (section is! Expression) return;

    final cascade = section.parent;
    if (cascade is! CascadeExpression) return;

    final sections = cascade.cascadeSections;
    final sectionIndex = sections.indexOf(section);
    if (sectionIndex < 0) return;

    final content = unitResult.content;

    final int deleteStart;
    if (sectionIndex > 0) {
      deleteStart = sections[sectionIndex - 1].end;
    } else {
      deleteStart = cascade.target.end;
    }
    var deleteEnd = section.end;

    if (sectionIndex < sections.length - 1) {
      // Not the last section — just delete up to section end
      deleteEnd = section.end;
    } else {
      // Last section — trim trailing whitespace up to semicolon
      while (deleteEnd < content.length &&
          (content[deleteEnd] == ' ' || content[deleteEnd] == '\t')) {
        deleteEnd++;
      }
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(SourceRange(deleteStart, deleteEnd - deleteStart));
    });
  }
}
