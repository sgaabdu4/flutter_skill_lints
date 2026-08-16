import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that removes the constructor from a Notifier subclass.
class AvoidNotifierConstructorsFix extends RemoveConstructorCorrection {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.avoidNotifierConstructors',
    DartFixKindPriority.standard,
    'Remove constructor',
  );

  AvoidNotifierConstructorsFix({required super.context}) : super(fixKind: _fixKind);
}
