import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';

/// Fix that replaces `Future<void> Function()` with `AsyncCallback`.
class PreferAsyncCallbackFix extends SingleLocationCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferAsyncCallback',
    DartFixKindPriority.standard,
    "Replace with 'AsyncCallback'",
  );

  PreferAsyncCallbackFix({required super.context}) : super(fixKind: _fixKind);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final targetNode = node;
    if (targetNode is! GenericFunctionType) return;

    final isNullable = targetNode.question != null;
    final replacement = isNullable ? 'AsyncCallback?' : 'AsyncCallback';

    await builder.addDartFileEdit(file, (builder) {
      builder.importLibrary(Uri.parse('package:flutter/foundation.dart'));
      builder.addSimpleReplacement(range.node(targetNode), replacement);
    });
  }
}
