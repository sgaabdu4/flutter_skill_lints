import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

import 'package:flutter_skill_lints/src/additional_lints/correction_producer_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/disposal_utils.dart';

/// Fix that adds the appropriate cleanup call (dispose/close/cancel)
/// for an undisposed field in the dispose() method.
class DisposeFieldsFix extends SingleLocationCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.disposeFields',
    DartFixKindPriority.standard,
    'Add disposal call in dispose()',
  );

  DisposeFieldsFix({required super.context}) : super(fixKind: _fixKind);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The diagnostic is reported at the variable name token.
    // The node is the SimpleIdentifier inside a VariableDeclaration.
    final disposable = disposableVariable(node);
    if (disposable == null) return;

    final disposeCall = '${disposable.fieldName}.${disposable.cleanupMethod}()';

    final disposeContext = findDisposeContext(node);
    if (disposeContext == null) return;

    await builder.addDartFileEdit(file, (builder) {
      addCleanupToDispose(builder, disposeContext.body, disposeContext.disposeMethod, disposeCall);
    });
  }
}
