import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when a `State<T>` class is declared before its widget class.
final class KeepStateBelowItsWidget extends AnalysisRule {
  static const LintCode code = LintCode(
    'keep_state_below_its_widget',
    'Keep State classes below their StatefulWidget.',
    correctionMessage: 'Move this State class below its widget class.',
  );

  KeepStateBelowItsWidget()
    : super(
        name: 'keep_state_below_its_widget',
        description: 'Warns when a State class is declared above its StatefulWidget.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final KeepStateBelowItsWidget rule;

  static const _statefulWidgetChecker = TypeChecker.fromName(
    'StatefulWidget',
    packageName: 'flutter',
  );

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final widgetsByName = <String, ClassDeclaration>{};
    final stateClasses = <ClassDeclaration>[];

    for (final declaration in node.declarations.whereType<ClassDeclaration>()) {
      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (_statefulWidgetChecker.isSuperOf(element)) {
        widgetsByName[declaration.namePart.typeName.lexeme] = declaration;
      } else if (_stateChecker.isSuperOf(element)) {
        stateClasses.add(declaration);
      }
    }

    for (final stateClass in stateClasses) {
      final widgetName = _stateWidgetName(stateClass);
      if (widgetName == null) continue;

      final widgetClass = widgetsByName[widgetName];
      if (widgetClass == null) continue;
      if (stateClass.offset > widgetClass.offset) continue;

      rule.reportAtToken(stateClass.namePart.typeName);
    }
  }
}

String? _stateWidgetName(ClassDeclaration stateClass) {
  final superclass = stateClass.extendsClause?.superclass;
  final typeArguments = superclass?.typeArguments?.arguments;
  if (typeArguments == null || typeArguments.length != 1) return null;

  final widgetType = typeArguments.single;
  if (widgetType is! NamedType) return null;

  return widgetType.name.lexeme;
}
