import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_dot_shorthands.dart';

/// Removes a repeated static type name from a contextually typed expression.
final class PreferDotShorthandsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferDotShorthands',
    DartFixKindPriority.standard,
    'Use dot shorthand',
  );

  static const _multiFixKind = FixKind(
    'flutter_skill_lints.fix.preferDotShorthands.multi',
    DartFixKindPriority.inFile,
    'Use dot shorthand everywhere in file',
  );

  PreferDotShorthandsFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _fixKind;

  @override
  FixKind get multiFixKind => _multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // File-wide correction dispatch can include diagnostics from other rules.
    if (diagnostic?.diagnosticCode.lowerCaseName != PreferDotShorthands.code.lowerCaseName) {
      return;
    }
    final target = node;
    // The rule reports named constructors only, so the type name is always
    // followed by `.name` and removing it leaves the shorthand.
    final (prefix, explicitNew) = switch (target) {
      PrefixedIdentifier(:final prefix) => (prefix as AstNode, null),
      PropertyAccess(target: final prefix?) => (prefix, null),
      MethodInvocation(target: final prefix?) => (prefix, null),
      InstanceCreationExpression(constructorName: ConstructorName(:final type, name: _?)) => (
        type as AstNode,
        target.keyword?.lexeme == 'new' ? target.keyword : null,
      ),
      _ => (null, null),
    };
    if (prefix == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        explicitNew == null ? range.node(prefix) : range.startEnd(explicitNew, prefix),
        '',
      );
    });
  }
}
