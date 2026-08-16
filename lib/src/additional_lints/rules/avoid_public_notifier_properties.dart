import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when Riverpod notifiers expose public instance properties.
class AvoidPublicNotifierProperties extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_public_notifier_properties',
    'Avoid public properties on Riverpod notifiers.',
    correctionMessage:
        'Keep notifier implementation details private and expose data through provider state.',
  );

  AvoidPublicNotifierProperties()
    : super(
        name: 'avoid_public_notifier_properties',
        description: 'Warns when Notifier classes expose public fields, getters, or setters.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidPublicNotifierProperties rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!isClassAssignableTo(node, notifierChecker)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (member is FieldDeclaration) {
        _checkField(member);
      } else if (member is MethodDeclaration && member.isGetter) {
        _checkAccessor(member);
      } else if (member is MethodDeclaration && member.isSetter) {
        _checkAccessor(member);
      }
    }
  }

  void _checkField(FieldDeclaration node) {
    if (node.isStatic) return;
    for (final variable in node.fields.variables) {
      final name = variable.name.lexeme;
      if (_isPublic(name)) rule.reportAtToken(variable.name);
    }
  }

  void _checkAccessor(MethodDeclaration node) {
    if (node.isStatic) return;
    final name = node.name.lexeme;
    if (_isPublic(name)) rule.reportAtToken(node.name);
  }

  bool _isPublic(String name) => !name.startsWith('_');
}
