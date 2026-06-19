import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `late final` variable or field is assigned more than once in
/// the same local body.
final class AvoidLateFinalReassignment extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_late_final_reassignment',
    'Late final value is reassigned.',
    correctionMessage: 'Assign a late final value only once, or use a non-final variable.',
  );

  AvoidLateFinalReassignment()
    : super(
        name: 'avoid_late_final_reassignment',
        description: 'Warns when late final variables or fields are assigned more than once.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
    registry.addFunctionDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidLateFinalReassignment rule;
  final List<Map<String, int>> _lateFinalFields = [];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = node.body;
    if (body is! BlockClassBody) return;

    final fields = <String, int>{};
    for (final member in body.members.whereType<FieldDeclaration>()) {
      if (member.isStatic || !member.fields.isLate || !member.fields.isFinal) continue;
      for (final variable in member.fields.variables) {
        fields[variable.name.lexeme] = variable.initializer == null ? 0 : 1;
      }
    }

    _lateFinalFields.add(fields);
    for (final member in body.members) {
      if (member is ConstructorDeclaration) {
        _checkConstructor(member);
      } else if (member is MethodDeclaration) {
        _checkBody(member.body);
      }
    }
    _lateFinalFields.removeLast();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkBody(node.functionExpression.body);
  }

  void _checkConstructor(ConstructorDeclaration node) {
    final initialCounts = Map<String, int>.of(_lateFinalFields.last);
    for (final parameter in node.parameters.parameters) {
      final normalized = parameter;
      if (normalized case FieldFormalParameter(:final name)) {
        initialCounts[name.lexeme] = (initialCounts[name.lexeme] ?? 0) + 1;
        if ((initialCounts[name.lexeme] ?? 0) > 1) rule.reportAtToken(name);
      }
    }
    for (final initializer in node.initializers) {
      if (initializer case ConstructorFieldInitializer(:final fieldName)) {
        final name = fieldName.name;
        if (!initialCounts.containsKey(name)) continue;
        initialCounts[name] = (initialCounts[name] ?? 0) + 1;
        if ((initialCounts[name] ?? 0) > 1) rule.reportAtToken(fieldName.token);
      }
    }
    _checkBody(node.body, fieldCounts: initialCounts);
  }

  void _checkBody(FunctionBody body, {Map<String, int>? fieldCounts}) {
    if (body is! BlockFunctionBody) return;

    final checker = _BodyChecker(
      rule,
      fieldCounts: fieldCounts ?? (_lateFinalFields.isEmpty ? const {} : _lateFinalFields.last),
    );
    body.block.accept(checker);
  }
}

final class _BodyChecker extends RecursiveAstVisitor<void> {
  _BodyChecker(this.rule, {required Map<String, int> fieldCounts})
    : fieldCounts = Map<String, int>.of(fieldCounts);

  final AvoidLateFinalReassignment rule;
  final Map<String, int> fieldCounts;
  final localCounts = <String, int>{};
  final localNames = <String>{};

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (!node.isLate || !node.isFinal) {
      for (final variable in node.variables) {
        localNames.add(variable.name.lexeme);
      }
      super.visitVariableDeclarationList(node);
      return;
    }

    for (final variable in node.variables) {
      final name = variable.name.lexeme;
      localNames.add(name);
      localCounts[name] = variable.initializer == null ? 0 : 1;
    }
    super.visitVariableDeclarationList(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.lexeme == '=') {
      _recordWrite(node.leftHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type.isIncrementOperator) {
      _recordWrite(node.operand);
    }
    super.visitPrefixExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (node.operator.type.isIncrementOperator) {
      _recordWrite(node.operand);
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void _recordWrite(Expression target) {
    final localName = _simpleName(target);
    if (localName != null && localCounts.containsKey(localName)) {
      _increment(localCounts, localName, target);
      return;
    }
    if (localName != null && localNames.contains(localName)) return;

    final fieldName = _fieldNameFromTarget(target);
    if (fieldName != null && fieldCounts.containsKey(fieldName)) {
      _increment(fieldCounts, fieldName, target);
    }
  }

  void _increment(Map<String, int> counts, String name, Expression target) {
    counts[name] = (counts[name] ?? 0) + 1;
    if ((counts[name] ?? 0) > 1) {
      rule.reportAtNode(_nameNode(target) ?? target);
    }
  }
}

String? _simpleName(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final name) => name,
    _ => null,
  };
}

String? _fieldNameFromTarget(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier(:final name) => name,
    PropertyAccess(target: ThisExpression(), :final propertyName) => propertyName.name,
    _ => null,
  };
}

AstNode? _nameNode(Expression expression) {
  return switch (expression.unParenthesized) {
    SimpleIdentifier() => expression,
    PrefixedIdentifier(:final identifier) => identifier,
    PropertyAccess(:final propertyName) => propertyName,
    _ => null,
  };
}
