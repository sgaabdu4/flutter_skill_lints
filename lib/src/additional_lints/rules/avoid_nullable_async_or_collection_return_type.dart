import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoids nullable Future, Stream, and collection return types.
///
/// Effective Dart recommends keeping async and collection containers
/// non-nullable. Put nullability on the produced value when that is the
/// semantic contract, or return an empty collection / explicit state.
class AvoidNullableAsyncOrCollectionReturnType extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nullable_async_or_collection_return_type',
    'Avoid nullable Future, Stream, and collection return types.',
    correctionMessage:
        'Return a non-null Future/Stream/collection. Put ? on the value type, return an empty collection, or model absence explicitly.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidNullableAsyncOrCollectionReturnType()
    : super(
        name: 'avoid_nullable_async_or_collection_return_type',
        description: 'Avoids nullable Future, Stream, Iterable, List, Map, and Set returns.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;

    final visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNullableAsyncOrCollectionReturnType rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkReturnType(node.returnType);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_hasOverrideAnnotation(node.metadata)) return;
    _checkReturnType(node.returnType);
  }

  void _checkReturnType(TypeAnnotation? returnType) {
    final reported = _firstNullableAsyncOrCollection(returnType);
    if (reported == null) return;
    rule.reportAtNode(reported);
  }

  NamedType? _firstNullableAsyncOrCollection(TypeAnnotation? type) {
    if (type is! NamedType) return null;

    if (_isTargetType(type) && type.question != null) {
      return type;
    }

    final typeArguments = type.typeArguments?.arguments;
    if (typeArguments == null) return null;
    for (final typeArgument in typeArguments) {
      final nested = _firstNullableAsyncOrCollection(typeArgument);
      if (nested != null) return nested;
    }

    return null;
  }

  bool _isTargetType(NamedType type) {
    final typeName = type.name.lexeme;
    final library = type.element?.library;
    return switch (typeName) {
      'Future' || 'Stream' => library?.isDartAsync == true,
      'Iterable' || 'List' || 'Map' || 'Set' => library?.isDartCore == true,
      _ => false,
    };
  }

  bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((annotation) => annotation.name.name == 'override');
  }
}
