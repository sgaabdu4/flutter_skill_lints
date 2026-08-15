import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when widget classes declare public implementation members.
final class PreferWidgetPrivateMembers extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'prefer_widget_private_members',
    'Prefer private members in widget classes.',
    correctionMessage: 'Make this widget member private.',
  );

  PreferWidgetPrivateMembers()
    : super(
        name: 'prefer_widget_private_members',
        description:
            'Warns when widget classes declare public fields, getters, setters, or methods.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferWidgetPrivateMembers rule;

  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

  static const _frameworkMembers = {'build', 'createState'};

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_widgetChecker.isSuperOf(element)) return;

    final constructorBackedFields = _constructorBackedFieldNames(node);
    for (final member in node.body.members) {
      if (member is FieldDeclaration) {
        _checkField(member, constructorBackedFields);
      } else if (member is MethodDeclaration) {
        _checkMethod(member);
      }
    }
  }

  void _checkField(FieldDeclaration field, Set<String> constructorBackedFields) {
    if (field.isStatic) return;

    for (final variable in field.fields.variables) {
      if (_isPrivateName(variable.name.lexeme)) continue;
      if (_isConstructorBackedApiField(field, variable, constructorBackedFields)) {
        continue;
      }
      rule.reportAtToken(variable.name);
    }
  }

  void _checkMethod(MethodDeclaration method) {
    if (method.isStatic) return;
    if (hasOverrideAnnotation(method)) return;

    final name = method.name.lexeme;
    if (_isPrivateName(name) || _frameworkMembers.contains(name)) return;

    rule.reportAtToken(method.name);
  }
}

bool _isPrivateName(String name) => name.startsWith('_');

bool _isConstructorBackedApiField(
  FieldDeclaration field,
  VariableDeclaration variable,
  Set<String> constructorBackedFields,
) {
  return field.fields.isFinal &&
      !field.fields.isLate &&
      variable.initializer == null &&
      constructorBackedFields.contains(variable.name.lexeme);
}

Set<String> _constructorBackedFieldNames(ClassDeclaration node) {
  final names = <String>{};
  for (final member in node.body.members) {
    if (member is! ConstructorDeclaration) continue;
    if (member.factoryKeyword != null) continue;
    _addFieldFormalNames(names, member);
    _addConstructorInitializerNames(names, member);
  }
  return names;
}

void _addFieldFormalNames(Set<String> names, ConstructorDeclaration constructor) {
  for (final parameter in constructor.parameters.parameters) {
    final fieldFormal = _fieldFormalParameter(parameter);
    if (fieldFormal != null) names.add(fieldFormal.name.lexeme);
  }
}

void _addConstructorInitializerNames(Set<String> names, ConstructorDeclaration constructor) {
  final parameterNames = {
    for (final parameter in constructor.parameters.parameters)
      if (parameter.name case final name?) name.lexeme,
  };
  for (final initializer in constructor.initializers) {
    if (initializer is! ConstructorFieldInitializer) continue;
    final expression = initializer.expression.unParenthesized;
    if (expression is SimpleIdentifier && parameterNames.contains(expression.name)) {
      names.add(initializer.fieldName.name);
    }
  }
}

FieldFormalParameter? _fieldFormalParameter(FormalParameter parameter) {
  return switch (parameter) {
    FieldFormalParameter() => parameter,
    _ => null,
  };
}
