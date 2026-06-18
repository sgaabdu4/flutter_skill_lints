import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../ast_node_analysis.dart';

/// Warns when Intl message names do not match the owning class member.
final class PreferIntlName extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_intl_name',
    'Prefer class-member Intl names.',
    correctionMessage: 'Use the ClassName_memberName pattern for the Intl name.',
  );

  PreferIntlName()
    : super(
        name: 'prefer_intl_name',
        description: 'Warns when Intl name arguments do not match their class member.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferIntlName rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isIntlInvocation(node)) return;

    final nameLiteral = _nameArgument(node);
    if (nameLiteral == null) return;

    final expectedName = _expectedName(node);
    if (expectedName == null || nameLiteral.value == expectedName) return;

    rule.reportAtNode(nameLiteral);
  }
}

bool _isIntlInvocation(MethodInvocation node) {
  final target = node.target;
  return target is SimpleIdentifier &&
      target.name == 'Intl' &&
      _intlMethods.contains(node.methodName.name);
}

const _intlMethods = {'message', 'plural', 'gender', 'select'};

SimpleStringLiteral? _nameArgument(MethodInvocation node) {
  for (final argument in node.argumentList.arguments.whereType<NamedExpression>()) {
    if (argument.name.lexeme != 'name') continue;

    final expression = argument.expression;
    return expression is SimpleStringLiteral ? expression : null;
  }

  return null;
}

String? _expectedName(MethodInvocation node) {
  final className = node.thisOrAncestorOfType<ClassDeclaration>()?.namePart.typeName.lexeme;
  if (className == null) return null;

  final memberName = _memberName(node);
  return memberName == null ? null : '${className}_$memberName';
}

String? _memberName(MethodInvocation node) {
  final variable = node.thisOrAncestorOfType<VariableDeclaration>();
  if (variable != null && _containsNode(variable.initializer, node)) {
    final field = variable.thisOrAncestorOfType<FieldDeclaration>();
    if (field != null) return variable.name.lexeme;
  }

  final method = node.thisOrAncestorOfType<MethodDeclaration>();
  if (method != null && method.thisOrAncestorOfType<ClassDeclaration>() != null) {
    return method.name.lexeme;
  }

  return null;
}

bool _containsNode(AstNode? root, AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (identical(current, root)) return true;
    current = current.parent;
  }
  return false;
}
