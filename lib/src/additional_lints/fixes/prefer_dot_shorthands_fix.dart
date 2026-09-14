import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Removes a repeated static type name from a contextually typed expression.
final class PreferDotShorthandsFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.preferDotShorthands',
    DartFixKindPriority.standard,
    'Use dot shorthand',
  );

  PreferDotShorthandsFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final target = node;
    final (prefix, replacement) = switch (target) {
      PrefixedIdentifier(:final prefix) => (prefix as AstNode, ''),
      PropertyAccess(target: final prefix?) => (prefix, ''),
      MethodInvocation(target: final prefix?) => (prefix, ''),
      InstanceCreationExpression(constructorName: ConstructorName(:final type, name: null)) => (
        type as AstNode,
        '.new',
      ),
      InstanceCreationExpression(constructorName: ConstructorName(:final type)) => (
        type as AstNode,
        '',
      ),
      _ => (null, ''),
    };
    if (prefix == null) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(prefix), replacement);
    });
  }
}
