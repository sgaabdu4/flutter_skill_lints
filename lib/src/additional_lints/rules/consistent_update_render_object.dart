import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Checks that RenderObjectWidget constructor fields are copied during updates.
final class ConsistentUpdateRenderObject extends AnalysisRule {
  static const LintCode code = LintCode(
    'consistent_update_render_object',
    'updateRenderObject does not assign `{0}` to the render object.',
    correctionMessage: 'Assign the constructor field to the render object in updateRenderObject.',
    severity: DiagnosticSeverity.ERROR,
  );

  ConsistentUpdateRenderObject()
    : super(
        name: 'consistent_update_render_object',
        description:
            'Flags RenderObjectWidget updateRenderObject methods that omit '
            'constructor-backed field assignments.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final ConsistentUpdateRenderObject rule;

  static const _renderObjectWidgetChecker = TypeChecker.fromName(
    'RenderObjectWidget',
    packageName: 'flutter',
  );

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final element = node.declaredFragment?.element;
    if (element == null || !_renderObjectWidgetChecker.isSuperOf(element)) return;

    final fields = _constructorBackedFields(node);
    if (fields.isEmpty) return;

    final updateRenderObject = _updateRenderObjectMethod(node);
    if (updateRenderObject == null) return;

    final renderObjectParameter = _renderObjectParameterName(updateRenderObject);
    if (renderObjectParameter == null) return;

    final assigned = _RenderObjectAssignments.collect(updateRenderObject, renderObjectParameter);
    for (final entry in fields.entries) {
      if (assigned.contains(entry.key)) continue;

      rule.reportAtToken(entry.value, arguments: [entry.key]);
    }
  }
}

Map<String, Token> _constructorBackedFields(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) return const {};

  final candidateFields = <String, Token>{};
  for (final field in body.members.whereType<FieldDeclaration>()) {
    if (field.isStatic || field.externalKeyword != null) continue;

    for (final variable in field.fields.variables) {
      if (variable.initializer != null) continue;
      candidateFields[variable.name.lexeme] = variable.name;
    }
  }
  if (candidateFields.isEmpty) return const {};

  final constructorFields = <String>{};
  for (final constructor in body.members.whereType<ConstructorDeclaration>()) {
    if (constructor.factoryKeyword != null) continue;
    if (constructor.redirectedConstructor != null) continue;

    for (final parameter in constructor.parameters.parameters) {
      final fieldName = _fieldFormalName(parameter);
      if (fieldName != null) constructorFields.add(fieldName);
    }
  }

  return {
    for (final entry in candidateFields.entries)
      if (constructorFields.contains(entry.key)) entry.key: entry.value,
  };
}

String? _fieldFormalName(FormalParameter parameter) {
  final normalized = parameter is DefaultFormalParameter ? parameter.parameter : parameter;
  return switch (normalized) {
    FieldFormalParameter(:final name) => name.lexeme,
    SuperFormalParameter() => null,
    _ => null,
  };
}

MethodDeclaration? _updateRenderObjectMethod(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody) return null;

  for (final member in body.members.whereType<MethodDeclaration>()) {
    if (member.name.lexeme == 'updateRenderObject') return member;
  }

  return null;
}

String? _renderObjectParameterName(MethodDeclaration method) {
  final parameters = method.parameters?.parameters;
  if (parameters == null || parameters.length < 2) return null;

  final parameter = parameters[1];
  final normalized = parameter;
  return normalized.name?.lexeme;
}

final class _RenderObjectAssignments extends RecursiveAstVisitor<void> {
  _RenderObjectAssignments(this.renderObjectParameter);

  final String renderObjectParameter;
  final fields = <String>{};

  static Set<String> collect(MethodDeclaration method, String renderObjectParameter) {
    final collector = _RenderObjectAssignments(renderObjectParameter);
    method.body.accept(collector);
    return collector.fields;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.EQ) {
      final fieldName = _renderObjectFieldName(node.leftHandSide, renderObjectParameter);
      if (fieldName != null) fields.add(fieldName);
    }

    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}

String? _renderObjectFieldName(Expression expression, String renderObjectParameter) {
  return switch (expression.unParenthesized) {
    PrefixedIdentifier(prefix: SimpleIdentifier(name: final targetName), :final identifier)
        when targetName == renderObjectParameter =>
      identifier.name,
    PropertyAccess(target: SimpleIdentifier(name: final targetName), :final propertyName)
        when targetName == renderObjectParameter =>
      propertyName.name,
    _ => null,
  };
}
