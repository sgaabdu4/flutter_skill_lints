import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a parameter list has more than four parameters.
class AvoidLongParameterList extends AnalysisRule {
  static const int maxParameters = 4;

  static const LintCode code = LintCode(
    'avoid_long_parameter_list',
    'Avoid parameter lists with more than four parameters.',
    correctionMessage: 'Group related inputs into a named type or split the API.',
  );

  AvoidLongParameterList()
    : super(
        name: 'avoid_long_parameter_list',
        description: 'Warns when a function, method, or constructor has more than four parameters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addFormalParameterList(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidLongParameterList rule;

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (_isFreezedConstructorParameterList(node)) return;
    if (_isWidgetConstructorParameterList(node)) return;
    if (_isOverrideMethodParameterList(node)) return;
    if (_isZoneSpecificationHandleUncaughtErrorCallback(node)) return;

    if (node.parameters.length > AvoidLongParameterList.maxParameters) {
      rule.reportAtNode(node);
    }
  }
}

const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

bool _isOverrideMethodParameterList(FormalParameterList node) {
  final parent = node.parent;
  if (parent is! MethodDeclaration) return false;
  return parent.metadata.any(_isOverrideAnnotation);
}

bool _isOverrideAnnotation(Annotation annotation) {
  return annotation.name.name == 'override';
}

bool _isFreezedConstructorParameterList(FormalParameterList node) {
  final parent = node.parent;
  if (parent is! ConstructorDeclaration) return false;
  return isInFreezedClass(parent);
}

bool _isWidgetConstructorParameterList(FormalParameterList node) {
  final parent = node.parent;
  if (parent is! ConstructorDeclaration) return false;

  final classDeclaration = parent.thisOrAncestorOfType<ClassDeclaration>();
  if (classDeclaration == null) return false;

  final element = classDeclaration.declaredFragment?.element;
  return element != null && _widgetChecker.isSuperOf(element);
}

bool _isZoneSpecificationHandleUncaughtErrorCallback(FormalParameterList node) {
  final parent = node.parent;
  if (parent is! FunctionExpression) return false;

  final namedExpression = parent.parent;
  if (namedExpression is! NamedArgument) return false;
  if (namedExpression.name.lexeme != 'handleUncaughtError') return false;

  final argumentList = namedExpression.parent;
  final invocation = argumentList?.parent;
  return invocation is InstanceCreationExpression &&
      invocation.constructorName.type.toSource() == 'ZoneSpecification';
}
