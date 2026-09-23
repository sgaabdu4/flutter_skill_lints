import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> freezedExtendedSourceRules = [
  /// Freezed classes with custom members need a private constructor.
  ///
  /// Why: Flags Freezed classes with custom getters/methods but no private constructor. Add
  /// const ClassName._(); before custom getters or methods.
  scannerRule(
    code: const LintCode(
      'freezed_missing_private_constructor',
      'Freezed classes with custom members need a private constructor.',
      correctionMessage: 'Add const ClassName._(); before custom getters or methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Freezed classes with custom getters/methods but no private constructor so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final isFreezed = declaration.metadata.any(
          (annotation) =>
              const {'freezed', 'Freezed'}.contains(annotation.name.name.split('.').last),
        );
        final body = declaration.body;
        if (!isFreezed || body is! BlockClassBody) continue;
        if (body.members.whereType<ConstructorDeclaration>().any(
          (member) => member.name?.lexeme == '_',
        )) {
          continue;
        }
        final hasImplementation = body.members.whereType<MethodDeclaration>().any(
          (member) => !member.isStatic && member.body is! EmptyFunctionBody,
        );
        if (hasImplementation) {
          final location = context.unit.lineInfo.getLocation(declaration.classKeyword.offset);
          reporter.report(context, location.lineNumber - 1, 0);
        }
      }
    },
  ),
];
