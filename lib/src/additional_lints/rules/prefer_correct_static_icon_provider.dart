import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when custom IconData constants live outside a static provider class.
final class PreferCorrectStaticIconProvider extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_correct_static_icon_provider',
    'Expose IconData constants from a static const provider.',
    correctionMessage: 'Move the IconData constant to a static const field on an icon provider.',
    severity: DiagnosticSeverity.INFO,
  );

  PreferCorrectStaticIconProvider()
    : super(
        name: 'prefer_correct_static_icon_provider',
        description: 'Warns when IconData constants are not exposed from a static provider.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addTopLevelVariableDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCorrectStaticIconProvider rule;

  static const _iconDataChecker = TypeChecker.fromName('IconData', packageName: 'flutter');

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (!node.variables.isConst) return;
    if (!_declaresIconData(node.variables)) return;

    for (final variable in node.variables.variables) {
      if (_isIconDataCreation(variable.initializer)) {
        rule.reportAtOffset(variable.name.offset, variable.name.length);
      }
    }
  }

  static bool _declaresIconData(VariableDeclarationList variables) {
    final type = variables.type?.type;
    return type != null && _iconDataChecker.isExactlyType(type);
  }

  static bool _isIconDataCreation(Expression? expression) {
    if (expression is! InstanceCreationExpression) return false;

    final type = expression.staticType;
    return type != null && _iconDataChecker.isExactlyType(type);
  }
}
