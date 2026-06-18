import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a `StatelessWidget` declares initialized instance fields.
class AvoidStatelessWidgetInitializedFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_stateless_widget_initialized_fields',
    'Avoid initialized instance fields in StatelessWidget classes.',
    correctionMessage: 'Pass immutable widget data through the constructor instead.',
  );

  AvoidStatelessWidgetInitializedFields()
    : super(
        name: 'avoid_stateless_widget_initialized_fields',
        description: 'Warns when StatelessWidget classes initialize instance fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidStatelessWidgetInitializedFields rule;

  static const _statelessWidgetChecker = TypeChecker.fromName(
    'StatelessWidget',
    packageName: 'flutter',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_statelessWidgetChecker.isSuperOf(element)) return;

    for (final field in node.body.members.whereType<FieldDeclaration>()) {
      if (field.isStatic) continue;

      for (final variable in field.fields.variables) {
        if (variable.initializer == null) continue;
        rule.reportAtToken(variable.name);
      }
    }
  }
}
