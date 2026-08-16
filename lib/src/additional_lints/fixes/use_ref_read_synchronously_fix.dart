import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that adds `if (!mounted) return;` before ref.read() after an async gap.
class UseRefReadSynchronouslyFix extends SingleLocationCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.useRefReadSynchronously',
    DartFixKindPriority.standard,
    "Add 'if (!mounted) return;' guard",
  );

  UseRefReadSynchronouslyFix({required super.context}) : super(fixKind: _fixKind);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    await addGuardBeforeStatement(builder, 'if (!mounted) return;');
  }
}
