import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when JSON map values are cast directly to typed collections.
class PreferCorrectJsonCasts extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_correct_json_casts',
    'Prefer correct JSON collection casts.',
    correctionMessage:
        'Cast JSON collections to dynamic/Object? containers, then parse or map the typed values.',
  );

  PreferCorrectJsonCasts()
    : super(
        name: 'prefer_correct_json_casts',
        description: 'Warns when JSON map lookups are cast directly to typed collections.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addAsExpression(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final PreferCorrectJsonCasts rule;

  @override
  void visitAsExpression(AsExpression node) {
    if (!_isJsonLookup(node.expression)) return;
    if (!_isUnsafeJsonCollectionCast(node.type)) return;

    rule.reportAtNode(node);
  }

  bool _isJsonLookup(Expression expression) {
    final unwrapped = _unwrap(expression);
    if (unwrapped is! IndexExpression) return false;

    final target = unwrapped.target;
    if (target == null) return false;
    if (_looksLikeJsonName(target)) return true;

    final type = target.staticType;
    if (type is! InterfaceType || !type.isDartCoreMap) return false;
    final arguments = type.typeArguments;
    if (arguments.length != 2) return false;

    return arguments.first.isDartCoreString && _isJsonTopValue(arguments.last);
  }

  bool _looksLikeJsonName(Expression target) {
    final unwrapped = _unwrap(target);
    return switch (unwrapped) {
      SimpleIdentifier(:final name) => name == 'json' || name.endsWith('Json'),
      _ => false,
    };
  }

  bool _isUnsafeJsonCollectionCast(TypeAnnotation type) {
    if (type is! NamedType) return false;

    return switch (type.name.lexeme) {
      'List' || 'Set' || 'Iterable' => _hasSpecificValueType(type),
      'Map' => _hasSpecificMapValueType(type),
      _ => false,
    };
  }

  bool _hasSpecificValueType(NamedType type) {
    final arguments = type.typeArguments?.arguments;
    if (arguments == null || arguments.length != 1) return false;

    return !_isJsonTopType(arguments.single.type);
  }

  bool _hasSpecificMapValueType(NamedType type) {
    final arguments = type.typeArguments?.arguments;
    if (arguments == null || arguments.length != 2) return false;

    return !_isJsonTopType(arguments.last.type);
  }

  bool _isJsonTopValue(DartType type) {
    return type is DynamicType || type.isDartCoreObject;
  }

  bool _isJsonTopType(DartType? type) {
    if (type == null) return true;
    return type is DynamicType || type.isDartCoreObject;
  }

  Expression _unwrap(Expression expression) {
    var current = expression;
    while (current is ParenthesizedExpression) {
      current = current.expression;
    }
    return current;
  }
}
