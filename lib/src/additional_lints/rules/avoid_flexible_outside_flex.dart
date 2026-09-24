import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/flutter_widget_helpers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a Flexible or Expanded widget is used outside a Flex widget.
///
/// Stateless and stateful widgets may compose the path to the Flex parent.
/// Report only a proven incompatible render-object or scroll-view parent; a
/// constructor's source nesting alone cannot establish an extracted widget's
/// runtime parent.
class AvoidFlexibleOutsideFlex extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_flexible_outside_flex',
    '{0} has a non-Flex render-object parent.',
    correctionMessage: 'Move {0} inside a Row, Column, or Flex, or remove the wrapper.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidFlexibleOutsideFlex()
    : super(
        name: 'avoid_flexible_outside_flex',
        description:
            'Warns when a Flexible or Expanded widget is used outside '
            'a Flex widget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this, context.typeSystem));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidFlexibleOutsideFlex rule;

  _Visitor(this.rule, this.typeSystem);

  final TypeSystem typeSystem;

  static const _flexibleChecker = TypeChecker.any([
    TypeChecker.fromName('Flexible', packageName: 'flutter'),
    TypeChecker.fromName('Expanded', packageName: 'flutter'),
  ]);

  static const _flexChecker = TypeChecker.any([
    TypeChecker.fromName('Row', packageName: 'flutter'),
    TypeChecker.fromName('Column', packageName: 'flutter'),
    TypeChecker.fromName('Flex', packageName: 'flutter'),
  ]);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorType = node.constructorName.type;
    final element = constructorType.element;
    if (element == null) return;

    // Only interested in Flexible / Expanded
    if (!_flexibleChecker.isSuperOf(element)) return;

    if (!hasProvenForeignRenderParent(node, _flexChecker, typeSystem)) return;

    final widgetName = constructorType.name.lexeme;
    rule.reportAtNode(node.constructorName, arguments: [widgetName]);
  }
}
