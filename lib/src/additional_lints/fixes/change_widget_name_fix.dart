import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Generic fix that replaces a widget constructor name with another.
class ChangeWidgetNameFix extends ReplaceConstructorNameCorrection {
  final String widgetName;

  ChangeWidgetNameFix._({required super.context, required this.widgetName, required super.fixKind});

  /// Factory for creating an Align fix.
  static ChangeWidgetNameFix alignFix({required CorrectionProducerContext context}) {
    return ChangeWidgetNameFix._(
      context: context,
      widgetName: 'Align',
      fixKind: const FixKind(
        'flutter_skill_lints.fix.changeWidgetToAlign',
        DartFixKindPriority.standard,
        'Replace with Align',
      ),
    );
  }

  /// Factory for creating a Transform fix.
  static ChangeWidgetNameFix transformFix({required CorrectionProducerContext context}) {
    return ChangeWidgetNameFix._(
      context: context,
      widgetName: 'Transform',
      fixKind: const FixKind(
        'flutter_skill_lints.fix.changeWidgetToTransform',
        DartFixKindPriority.standard,
        'Replace with Transform',
      ),
    );
  }

  @override
  String get replacement => widgetName;
}
