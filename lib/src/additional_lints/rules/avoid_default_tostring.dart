import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `toString()` uses the default Object implementation.
class AvoidDefaultToString extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_default_tostring',
    "Avoid calling default Object.toString() on '{0}'.",
    correctionMessage: 'Declare a meaningful toString() or avoid converting this object directly.',
  );

  AvoidDefaultToString()
    : super(
        name: 'avoid_default_tostring',
        description: 'Warns when local classes use the default Object.toString().',
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

  final AvoidDefaultToString rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'toString') return;
    if (node.argumentList.arguments.isNotEmpty) return;

    final type = node.target?.staticType;
    if (type is! InterfaceType) return;

    final className = type.element.name;
    if (className == null) return;

    final declaration = _localClassDeclaration(node, className);
    if (declaration == null) return;
    if (!_hasOnlyDefaultToString(declaration, node.root)) return;

    rule.reportAtNode(node.methodName, arguments: [className]);
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

bool _hasOnlyDefaultToString(ClassDeclaration declaration, AstNode root) {
  if (_declaresToString(declaration)) return false;

  final superName = declaration.extendsClause?.superclass.name.lexeme;
  if (superName == null || superName == 'Object') return true;

  final superDeclaration = _localClassDeclaration(root, superName);
  if (superDeclaration == null) return false;

  return _hasOnlyDefaultToString(superDeclaration, root);
}

bool _declaresToString(ClassDeclaration declaration) {
  for (final member in declaration.body.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'toString') {
      return true;
    }
  }
  return false;
}
