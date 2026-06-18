import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when an obvious local throwable class does not declare `toString`.
class AvoidThrowObjectsWithoutToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_throw_objects_without_tostring',
    "Thrown local class '{0}' does not declare toString().",
    correctionMessage: 'Declare toString() on thrown local error objects.',
  );

  AvoidThrowObjectsWithoutToString()
    : super(
        name: 'avoid_throw_objects_without_tostring',
        description: 'Warns when an obvious local throwable class does not declare toString().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addThrowExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidThrowObjectsWithoutToString rule;

  @override
  void visitThrowExpression(ThrowExpression node) {
    final type = node.expression.staticType;
    if (type is! InterfaceType) return;
    final className = type.element.name;
    if (className == null) return;

    final declaration = _localClassDeclaration(node, className);
    if (declaration == null || _declaresToString(declaration)) return;

    rule.reportAtNode(node.expression, arguments: [declaration.namePart.typeName.lexeme]);
  }
}

ClassDeclaration? _localClassDeclaration(AstNode node, String className) {
  final unit = node.root;
  if (unit is! CompilationUnit) return null;

  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration && declaration.namePart.typeName.lexeme == className) {
      return declaration;
    }
  }
  return null;
}

bool _declaresToString(ClassDeclaration declaration) {
  for (final member in declaration.body.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'toString') {
      return true;
    }
  }
  return false;
}
