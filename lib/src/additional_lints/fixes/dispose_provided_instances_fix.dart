import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/disposal_utils.dart';

/// Fix that adds `ref.onDispose(instance.dispose)` after the variable
/// declaration of a disposable instance inside a Riverpod provider or
/// Notifier build().
class DisposeProvidedInstancesFix extends SingleLocationCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.disposeProvidedInstances',
    DartFixKindPriority.standard,
    'Add ref.onDispose() call',
  );

  DisposeProvidedInstancesFix({required super.context}) : super(fixKind: _fixKind);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final disposable = disposableVariable(node);
    if (disposable == null) return;

    final statement = nearestNode<Statement>(disposable.declaration);
    if (statement == null) return;

    final onDisposeCall = 'ref.onDispose(${disposable.fieldName}.${disposable.cleanupMethod})';

    // Determine indentation from the variable declaration statement
    final content = unitResult.content;
    final lineStart = _findLineStart(content, statement.offset);
    final indent = content.substring(lineStart, statement.offset);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(statement.end, '\n$indent$onDisposeCall;');
    });
  }

  static int _findLineStart(String content, int offset) {
    var i = offset - 1;
    while (i >= 0 && content[i] != '\n') {
      i--;
    }
    return i + 1;
  }
}
