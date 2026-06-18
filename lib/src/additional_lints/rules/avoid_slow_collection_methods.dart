import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Reports collection chains with a cheaper direct predicate form.
class AvoidSlowCollectionMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_slow_collection_methods',
    'Use .{0}() instead of .where().{1}.',
    correctionMessage: 'Use the direct predicate method to avoid a filtered iterable.',
    severity: DiagnosticSeverity.INFO,
  );

  AvoidSlowCollectionMethods()
    : super(
        name: 'avoid_slow_collection_methods',
        description: 'Reports slow collection method chains with direct alternatives.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addPropertyAccess(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidSlowCollectionMethods rule;

  _Visitor(this.rule);

  static const _iterableChecker = TypeChecker.fromUrl('dart:core#Iterable');

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node case PropertyAccess(
      propertyName: SimpleIdentifier(name: final property && ('isEmpty' || 'isNotEmpty')),
      target: MethodInvocation(
        target: Expression(staticType: final targetType?),
        methodName: SimpleIdentifier(name: 'where'),
        argumentList: ArgumentList(arguments: [_]),
      ),
    ) when _iterableChecker.isAssignableFromType(targetType)) {
      rule.reportAtNode(node, arguments: [property == 'isNotEmpty' ? 'any' : 'every', property]);
    }
  }
}
