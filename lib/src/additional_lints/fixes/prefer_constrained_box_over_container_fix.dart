import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that replaces Container(constraints: ...) with ConstrainedBox(constraints: ...).
class PreferConstrainedBoxOverContainerFix extends ReplaceConstructorNameCorrection {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferConstrainedBoxOverContainer',
    DartFixKindPriority.standard,
    'Replace with ConstrainedBox',
  );

  PreferConstrainedBoxOverContainerFix({required super.context}) : super(fixKind: _fixKind);

  @override
  String get replacement => 'ConstrainedBox';
}
