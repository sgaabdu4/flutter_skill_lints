import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `is` checks or `as` casts repeat what static typing already proves.
class AvoidUnnecessaryTypeAssertions extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_type_assertions',
    'Avoid unnecessary type assertions.',
    correctionMessage: 'Remove the redundant type assertion.',
  );

  AvoidUnnecessaryTypeAssertions()
    : super(
        name: 'avoid_unnecessary_type_assertions',
        description: 'Warns when an is-check or as-cast is already guaranteed by static typing.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
    registry.addIsExpression(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidUnnecessaryTypeAssertions rule;

  @override
  void visitAsExpression(AsExpression node) {
    _check(node.expression.staticType, node.type.type, node);
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (node.notOperator != null) return;

    _check(node.expression.staticType, node.type.type, node);
  }

  void _check(DartType? sourceType, DartType? targetType, AstNode node) {
    if (sourceType != null &&
        targetType != null &&
        _isStaticallyAssignable(sourceType, targetType)) {
      rule.reportAtNode(node);
    }
  }
}

bool _isStaticallyAssignable(DartType source, DartType target) {
  if (_isTopOrUnknown(source)) return false;
  if (source is VoidType) return false;
  if (source.nullabilitySuffix == NullabilitySuffix.question &&
      target.nullabilitySuffix != NullabilitySuffix.question) {
    return false;
  }

  if (_sameType(source, target)) return true;
  if (target.isDartCoreObject &&
      source.nullabilitySuffix != NullabilitySuffix.question &&
      source.nullabilitySuffix != NullabilitySuffix.star) {
    return true;
  }

  if (source is! InterfaceType || target is! InterfaceType) return false;
  for (final supertype in source.element.allSupertypes) {
    if (_sameType(supertype, target)) return true;
  }

  return false;
}

bool _isTopOrUnknown(DartType type) =>
    type is DynamicType || type is InvalidType || type.isDartAsyncFutureOr;

bool _sameType(DartType source, DartType target) {
  if (source.nullabilitySuffix == NullabilitySuffix.question &&
      target.nullabilitySuffix != NullabilitySuffix.question) {
    return false;
  }
  return source.getDisplayString() == target.getDisplayString() ||
      _sameInterfaceType(source, target);
}

bool _sameInterfaceType(DartType source, DartType target) {
  if (source is! InterfaceType || target is! InterfaceType) return false;
  if (source.element != target.element) return false;
  if (source.typeArguments.length != target.typeArguments.length) return false;

  for (var index = 0; index < source.typeArguments.length; index += 1) {
    if (source.typeArguments[index].getDisplayString() !=
        target.typeArguments[index].getDisplayString()) {
      return false;
    }
  }
  return true;
}
