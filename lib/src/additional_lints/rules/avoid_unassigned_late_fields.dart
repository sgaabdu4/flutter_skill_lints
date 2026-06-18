import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `late` instance field is not assigned by each local
/// generative constructor.
final class AvoidUnassignedLateFields extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unassigned_late_fields',
    'Late field is not assigned in every constructor.',
    correctionMessage: 'Assign the field in every constructor or give it an initializer.',
  );

  AvoidUnassignedLateFields()
    : super(
        name: 'avoid_unassigned_late_fields',
        description: 'Warns when late fields can be left unassigned after construction.',
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

  final AvoidUnassignedLateFields rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final fields = <String, Token>{};
    for (final member in body.members.whereType<FieldDeclaration>()) {
      if (member.isStatic || member.externalKeyword != null) continue;
      if (!member.fields.isLate) continue;

      for (final variable in member.fields.variables) {
        if (variable.initializer != null) continue;
        fields[variable.name.lexeme] = variable.name;
      }
    }
    if (fields.isEmpty) return;

    final constructors = body.members
        .whereType<ConstructorDeclaration>()
        .where((constructor) => constructor.factoryKeyword == null)
        .where((constructor) => constructor.redirectedConstructor == null)
        .where((constructor) => !_hasRedirectingConstructorInvocation(constructor))
        .toList();

    final unassigned = <String>{};
    if (constructors.isNotEmpty) {
      for (final constructor in constructors) {
        final assigned = _ConstructorAssignments.collect(constructor, fields.keys);
        for (final fieldName in fields.keys) {
          if (!assigned.contains(fieldName)) {
            unassigned.add(fieldName);
          }
        }
      }
    } else {
      unassigned.addAll(fields.keys);
    }

    for (final fieldName in unassigned) {
      rule.reportAtToken(fields[fieldName]!);
    }
  }
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
      final name = _fieldNameFromTarget(node.leftHandSide);
      if (name != null) _add(name);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _collectFieldFormal(FormalParameter parameter) {
    final normalized = parameter is DefaultFormalParameter ? parameter.parameter : parameter;
    if (normalized case FieldFormalParameter(:final name)) {
      _add(name.lexeme);
    }
  }

  void _add(String name) {
    if (fields.contains(name)) assigned.add(name);
  }
}

String? _fieldNameFromTarget(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final name) => name,
    PrefixedIdentifier(prefix: ThisExpression(), :final identifier) => identifier.name,
    PropertyAccess(target: ThisExpression(), :final propertyName) => propertyName.name,
    _ => null,
  };
}
