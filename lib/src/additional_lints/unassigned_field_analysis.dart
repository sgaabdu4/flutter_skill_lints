import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Own fields assigned on the unconditional synchronous path through initState.
Set<String> initializedFlutterStateFields(ClassDeclaration declaration) {
  final element = declaration.declaredFragment?.element;
  final body = declaration.body;
  if (element == null || !flutterStateChecker.isSuperOf(element) || body is! BlockClassBody) {
    return const {};
  }
  return {
    for (final method in body.members.whereType<MethodDeclaration>())
      ..._initializedStateFields(method, element),
  };
}

Set<String> _initializedStateFields(MethodDeclaration method, InterfaceElement owner) {
  if (method.name.lexeme != 'initState' || method.isStatic) return const {};
  final implementation = method.body;
  if (implementation is! BlockFunctionBody || implementation.isAsynchronous) return const {};
  final assigned = <String>{};
  for (final statement in implementation.block.statements) {
    if (statement is VariableDeclarationStatement || statement is AssertStatement) continue;
    if (statement is! ExpressionStatement) break;
    final field = _assignedOwnField(statement.expression, owner);
    if (field != null) assigned.add(field);
  }
  return assigned;
}

String? _assignedOwnField(Expression expression, InterfaceElement owner) {
  if (expression is! AssignmentExpression || expression.operator.lexeme != '=') return null;
  final receiver = expression.leftHandSide;
  if (receiver is! SimpleIdentifier &&
      !(receiver is PropertyAccess && receiver.target is ThisExpression)) {
    return null;
  }
  final target = expression.writeElement;
  return target is SetterElement && target.variable.enclosingElement == owner
      ? target.variable.name
      : null;
}

Map<String, Token> findUnassignedFields(
  BlockClassBody body, {
  required bool Function(VariableDeclarationList) includeField,
}) {
  final fields = _unassignedFieldDeclarations(body, includeField);
  if (fields.isEmpty) return const {};

  final constructors = _usableConstructors(body);
  final unassigned = _fieldsUnassignedAcrossConstructors(fields, constructors);
  return {for (final fieldName in unassigned) fieldName: fields[fieldName]!};
}

Map<String, Token> _unassignedFieldDeclarations(
  BlockClassBody body,
  bool Function(VariableDeclarationList) includeField,
) {
  final fields = <String, Token>{};
  for (final member in body.members.whereType<FieldDeclaration>()) {
    if (member.isStatic || member.externalKeyword != null || !includeField(member.fields)) {
      continue;
    }
    for (final variable in member.fields.variables) {
      if (variable.initializer == null) fields[variable.name.lexeme] = variable.name;
    }
  }
  return fields;
}

List<ConstructorDeclaration> _usableConstructors(BlockClassBody body) {
  return body.members
      .whereType<ConstructorDeclaration>()
      .where((constructor) => constructor.factoryKeyword == null)
      .where((constructor) => constructor.redirectedConstructor == null)
      .where((constructor) => !_hasRedirectingConstructorInvocation(constructor))
      .toList();
}

Set<String> _fieldsUnassignedAcrossConstructors(
  Map<String, Token> fields,
  List<ConstructorDeclaration> constructors,
) {
  if (constructors.isEmpty) return fields.keys.toSet();
  final unassigned = <String>{};
  for (final constructor in constructors) {
    final assigned = _ConstructorAssignments.collect(constructor, fields.keys);
    unassigned.addAll(fields.keys.where((name) => !assigned.contains(name)));
  }
  return unassigned;
}

bool _hasRedirectingConstructorInvocation(ConstructorDeclaration constructor) {
  return constructor.initializers.any(
    (initializer) => initializer is RedirectingConstructorInvocation,
  );
}

final class _ConstructorAssignments extends RecursiveAstVisitor<void> {
  _ConstructorAssignments(this.fields);

  final Iterable<String> fields;
  final assigned = <String>{};

  static Set<String> collect(ConstructorDeclaration constructor, Iterable<String> fields) {
    final collector = _ConstructorAssignments(fields);
    for (final parameter in constructor.parameters.parameters) {
      collector._collectFieldFormal(parameter);
    }
    for (final initializer in constructor.initializers) {
      if (initializer case ConstructorFieldInitializer(:final fieldName)) {
        collector._add(fieldName.name);
      }
    }
    constructor.body.accept(collector);
    return collector.assigned;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.lexeme == '=') {
      final name = fieldNameFromTarget(node.leftHandSide);
      if (name != null) _add(name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _collectFieldFormal(FormalParameter parameter) {
    if (parameter case FieldFormalParameter(:final name)) {
      _add(name.lexeme);
    }
  }

  void _add(String name) {
    if (fields.contains(name)) assigned.add(name);
  }
}

String? fieldNameFromTarget(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final name) => name,
    PropertyAccess(target: ThisExpression(), :final propertyName) => propertyName.name,
    _ => null,
  };
}
