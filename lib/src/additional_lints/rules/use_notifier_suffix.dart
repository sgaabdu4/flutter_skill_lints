import 'package:analyzer/error/error.dart';

import '../class_suffix_validator.dart';

/// Warns when a Riverpod Notifier class does not use the `Notifier` suffix.
///
/// Riverpod codegen strips the suffix when creating provider names, so
/// consistent class names keep generated providers predictable.
class UseNotifierSuffix extends ClassSuffixValidator {
  static const LintCode code = LintCode(
    'use_notifier_suffix',
    'Use Notifier suffix',
    correctionMessage:
        'Rename the class to {0}Notifier so Riverpod codegen names stay predictable.',
  );

  UseNotifierSuffix()
    : super(
        name: 'use_notifier_suffix',
        description: 'Warns when a Riverpod Notifier class lacks the suffix that codegen expects.',
        requiredSuffix: 'Notifier',
        baseClassName: 'Notifier',
        packageName: 'riverpod',
      );
}
