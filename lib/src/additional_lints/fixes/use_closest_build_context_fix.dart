import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Fix that renames the inner closure's BuildContext parameter to match the
/// outer context name, so the closest BuildContext is used.
class UseClosestBuildContextFix extends ResolvedCorrectionProducer {
  static const _fixKind = FixKind(
    'flutter_skill_lints.fix.useClosestBuildContext',
    DartFixKindPriority.standard,
    'Rename inner parameter to use the closest BuildContext',
  );

  UseClosestBuildContextFix({required super.context});

  @override
  CorrectionApplicability get applicability => CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  static const _buildContextChecker = TypeChecker.fromName('BuildContext', packageName: 'flutter');

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // The reported node is the SimpleIdentifier referencing the outer context
    final targetNode = node;
    if (targetNode is! SimpleIdentifier) return;

    final outerContextName = targetNode.name;

    // Walk up to find the enclosing function expression with a BuildContext param
    final closureParam = _findEnclosingBuildContextParam(targetNode);
    if (closureParam == null) return;

    final paramName = closureParam.name;
    if (paramName == null) return;

    // Rename the inner parameter to the outer context name
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(paramName), outerContextName);
    });
  }

  /// Walk up the AST to find the nearest FunctionExpression ancestor
  /// that has a BuildContext parameter.
  FormalParameter? _findEnclosingBuildContextParam(AstNode node) {
    final function = _enclosingFunctionExpression(node);
    if (function == null) return null;
    return _buildContextParameter(function);
  }

  FunctionExpression? _enclosingFunctionExpression(AstNode node) {
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (current is FunctionExpression) return current;
      if (current is MethodDeclaration) return null;
    }
    return null;
  }

  FormalParameter? _buildContextParameter(FunctionExpression function) {
    for (final parameter in function.parameters?.parameters ?? const <FormalParameter>[]) {
      if (_isBuildContextType(parameter)) return parameter;
    }
    return null;
  }

  static bool _isBuildContextType(FormalParameter param) {
    final type = param.type?.type;
    if (type == null) return false;
    return _buildContextChecker.isExactlyType(type);
  }
}
