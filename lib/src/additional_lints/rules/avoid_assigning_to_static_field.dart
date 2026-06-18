import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when code assigns to a static field.
class AvoidAssigningToStaticField extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_assigning_to_static_field',
    'Avoid assigning to static fields.',
    correctionMessage: 'Keep mutable state on an instance or pass it explicitly.',
  );

  AvoidAssigningToStaticField()
    : super(
        name: 'avoid_assigning_to_static_field',
        description: 'Warns when code assigns to static fields.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidAssigningToStaticField rule;
  final Map<String, Set<String>> _staticFieldsByClass = {};
  final List<String> _classStack = [];

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final declaration in node.declarations) {
      if (declaration case final ClassDeclaration classDeclaration) {
        _collectStaticFields(classDeclaration);
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _classStack.add(node.namePart.typeName.lexeme);
    super.visitClassDeclaration(node);
    _classStack.removeLast();
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (_isVisibleForTestingMember(node)) {
      super.visitAssignmentExpression(node);
      return;
    }
    if (_staticFieldNameFromWrite(node.leftHandSide) != null) {
      rule.reportAtNode(_fieldNameNode(node.leftHandSide) ?? node.leftHandSide);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    if (_isVisibleForTestingMember(node)) {
      super.visitPostfixExpression(node);
      return;
    }
    _reportIncrement(node.operand);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (!node.operator.type.isIncrementOperator) return;
    if (_isVisibleForTestingMember(node)) {
      super.visitPrefixExpression(node);
      return;
    }
    _reportIncrement(node.operand);
    super.visitPrefixExpression(node);
  }

  void _collectStaticFields(ClassDeclaration declaration) {
    for (final member in declaration.body.members) {
      if (member is! FieldDeclaration || !member.isStatic) continue;
      final fields = _staticFieldsByClass.putIfAbsent(
        declaration.namePart.typeName.lexeme,
        () => {},
      );
      fields.addAll(member.fields.variables.map((variable) => variable.name.lexeme));
    }
  }

  void _reportIncrement(Expression operand) {
    if (_staticFieldNameFromWrite(operand) != null) {
      rule.reportAtNode(_fieldNameNode(operand) ?? operand);
    }
  }

  AstNode? _fieldNameNode(Expression expression) {
    return switch (expression) {
      SimpleIdentifier() => expression,
      PrefixedIdentifier(:final identifier) => identifier,
      PropertyAccess(:final propertyName) => propertyName,
      _ => null,
    };
  }

  String? _staticFieldNameFromWrite(Expression expression) {
    return switch (expression) {
      SimpleIdentifier(:final name) when _isStaticFieldOnCurrentClass(name) => name,
      PrefixedIdentifier(:final prefix, :final identifier)
          when _isStaticFieldOnClass(prefix.name, identifier.name) =>
        identifier.name,
      PropertyAccess(target: SimpleIdentifier(:final name), :final propertyName)
          when _isStaticFieldOnClass(name, propertyName.name) =>
        propertyName.name,
      _ => null,
    };
  }

  bool _isStaticFieldOnCurrentClass(String fieldName) {
    if (_classStack.isEmpty) return false;
    return _isStaticFieldOnClass(_classStack.last, fieldName);
  }

  bool _isStaticFieldOnClass(String className, String fieldName) {
    return _staticFieldsByClass[className]?.contains(fieldName) ?? false;
  }

  bool _isVisibleForTestingMember(AstNode node) {
    final member = node.thisOrAncestorOfType<ClassMember>();
    if (member == null) return false;
    return member.metadata.any((annotation) => annotation.name.name == 'visibleForTesting');
  }
}
