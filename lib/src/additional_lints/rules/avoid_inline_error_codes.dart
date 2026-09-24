import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when error or status codes are written inline at call sites.
///
/// Protocol and backend error codes are shared contracts. Keeping them behind a
/// dedicated owner makes retry, fallback, logging, and migration code refer to
/// the same source of truth without forcing a specific helper API.
class AvoidInlineErrorCodes extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'avoid_inline_error_codes',
    'Error and status codes should live in a dedicated code owner.',
    correctionMessage:
        'Move raw error/status codes into a dedicated *ErrorCodes, *StatusCodes, '
        'or *ResponseCodes owner and compare against the named constant.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidInlineErrorCodes()
    : super(
        name: 'avoid_inline_error_codes',
        description:
            'Warns when raw integer error/status codes are used directly in '
            'comparisons instead of a dedicated code owner.',
        code: code,
      );

  @override
  bool shouldRegister(RuleContext context) => !_isExcludedContext(context);

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidInlineErrorCodes rule;

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (_isDedicatedCodeOwnerContext(node)) return;
    if (_isStatusCodeComparison(node)) {
      rule.reportAtNode(_numericReportNode(node));
    }
  }
}

bool _isExcludedContext(RuleContext context) {
  return isExcludedProductionSource(context);
}

bool _isStatusCodeComparison(AstNode node) {
  final reportNode = _numericReportNode(node);
  final parent = reportNode.parent;
  if (parent is! BinaryExpression) return false;
  if (!_isComparisonOperator(parent.operator.type)) return false;

  final Expression codeOperand;
  if (_containsNode(parent.leftOperand, reportNode)) {
    codeOperand = parent.rightOperand;
  } else if (_containsNode(parent.rightOperand, reportNode)) {
    codeOperand = parent.leftOperand;
  } else {
    return false;
  }
  return isStatusCodeExpression(codeOperand) && !_isExceptionCode(codeOperand);
}

/// Whether [expression] reads a code from a caught exception (`e.code` where `e` is a
/// dart:core [Exception]), as in the skill's retry classification `e.code == 429`.
bool _isExceptionCode(Expression expression) {
  final receiver = switch (expression.unParenthesized) {
    PrefixedIdentifier(:final prefix) => prefix,
    PropertyAccess(:final realTarget) => realTarget,
    _ => null,
  };
  final type = receiver?.staticType;
  if (type is! InterfaceType) return false;
  return [type, ...type.element.allSupertypes].any(
    (candidate) => candidate.element.name == 'Exception' && candidate.element.library.isDartCore,
  );
}

bool _isComparisonOperator(TokenType type) {
  return switch (type) {
    TokenType.EQ_EQ ||
    TokenType.BANG_EQ ||
    TokenType.GT ||
    TokenType.GT_EQ ||
    TokenType.LT ||
    TokenType.LT_EQ => true,
    _ => false,
  };
}

bool _isDedicatedCodeOwnerContext(AstNode node) {
  final className = node.thisOrAncestorOfType<ClassDeclaration>()?.namePart.typeName.lexeme;
  if (className != null && _dedicatedCodeOwnerSuffixes.any(className.endsWith)) {
    return true;
  }

  final unit = node.root;
  final path = unit is CompilationUnit
      ? unit.declaredFragment?.source.fullName.replaceAll('\\', '/') ?? ''
      : '';
  return _dedicatedCodeOwnerPathFragments.any(path.contains);
}

bool _containsNode(AstNode root, AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (identical(current, root)) return true;
    current = current.parent;
  }
  return false;
}

AstNode _numericReportNode(AstNode node) {
  final parent = node.parent;
  if (parent is PrefixExpression && parent.operator.type == TokenType.MINUS) {
    return parent;
  }
  return node;
}

const _dedicatedCodeOwnerSuffixes = {'ErrorCodes', 'ResponseCodes', 'StatusCodes'};

const _dedicatedCodeOwnerPathFragments = {
  '/error_codes/',
  '/response_codes/',
  '/status_codes/',
  '_error_codes.dart',
  '_response_codes.dart',
  '_status_codes.dart',
};
