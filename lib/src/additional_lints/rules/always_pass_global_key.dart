import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a widget creates a `GlobalKey` in its constructor or build path.
class AlwaysPassGlobalKey extends AnalysisRule {
  static const LintCode code = LintCode(
    'always_pass_global_key',
    'Pass GlobalKey from the caller instead of creating it here.',
    correctionMessage: 'Create the GlobalKey outside the widget and pass it through the key slot.',
  );

  AlwaysPassGlobalKey()
    : super(
        name: 'always_pass_global_key',
        description:
            'Warns when a GlobalKey is created inside a widget constructor '
            'or build() method.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AlwaysPassGlobalKey rule;

  static const _globalKeyChecker = TypeChecker.fromName('GlobalKey', packageName: 'flutter');
  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.constructorName.type.element;
    if (element == null || !_globalKeyChecker.isExactly(element)) return;
    if (!_isInsideWidgetConstructorOrBuild(node)) return;

    rule.reportAtNode(node);
  }

  static bool _isInsideWidgetConstructorOrBuild(AstNode node) {
    for (AstNode? current = node.parent; current != null; current = current.parent) {
      if (current is MethodDeclaration && current.name.lexeme == 'build') {
        return _isInsideWidgetClass(current);
      }

      if (current is ConstructorDeclaration) {
        return _isInsideWidgetClass(current);
      }

      if (current is FunctionDeclaration || current is FunctionExpression) return false;
    }
    return false;
  }

  static bool _isInsideWidgetClass(ClassMember member) {
    final parent = member.parent;
    if (parent is! BlockClassBody) return false;
    final classDeclaration = parent.parent;
    if (classDeclaration is! ClassDeclaration) return false;

    final element = classDeclaration.declaredFragment?.element;
    return element != null && _widgetChecker.isSuperOf(element);
  }
}
