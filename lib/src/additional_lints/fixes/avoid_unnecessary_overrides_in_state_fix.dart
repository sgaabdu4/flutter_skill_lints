import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that removes an unnecessary method override from a State class.
class AvoidUnnecessaryOverridesInStateFix extends RemoveUnnecessaryOverrideCorrection {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidUnnecessaryOverridesInState',
    DartFixKindPriority.standard,
    'Remove unnecessary override',
  );

  AvoidUnnecessaryOverridesInStateFix({required super.context}) : super(fixKind: _fixKind);
}
