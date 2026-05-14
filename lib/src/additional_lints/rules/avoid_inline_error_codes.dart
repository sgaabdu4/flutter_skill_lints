import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when error or status codes are written inline at call sites.
///
/// Protocol and backend error codes are shared contracts. Keeping them behind a
/// dedicated owner makes retry, fallback, logging, and migration code refer to
/// the same source of truth without forcing a specific helper API.
class AvoidInlineErrorCodes extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_inline_error_codes',
    'Error and status codes should live in a dedicated code owner.',
    correctionMessage:
        'Move raw error/status codes into a dedicated *ErrorCodes, *StatusCodes, '
        'or *ResponseCodes owner and compare against the named constant.',
  );

  AvoidInlineErrorCodes()
    : super(
        name: 'avoid_inline_error_codes',
        description:
            'Warns when raw integer error/status codes are used directly in '
            'comparisons instead of a dedicated code owner.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isExcludedContext(context)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
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
  if (context.isInTestDirectory || isGeneratedRuleContext(context)) return true;

  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return !path.contains('/lib/') || path.endsWith('_test.dart') || path.contains('/l10n/');
}

bool _isStatusCodeComparison(AstNode node) {
  final reportNode = _numericReportNode(node);
  final parent = reportNode.parent;
  if (parent is! BinaryExpression) return false;
  if (!_isComparisonOperator(parent.operator.type)) return false;

  if (_containsNode(parent.leftOperand, reportNode)) {
    return _isStatusCodeExpression(parent.rightOperand);
  }
  if (_containsNode(parent.rightOperand, reportNode)) {
    return _isStatusCodeExpression(parent.leftOperand);
  }
  return false;
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

bool _isStatusCodeExpression(Expression expression) {
  final unwrapped = expression.unParenthesized;
  if (unwrapped is SimpleIdentifier) {
    return _statusCodePropertyNames.contains(unwrapped.name.toLowerCase());
  }
  if (unwrapped is PrefixedIdentifier) {
    return _statusCodePropertyNames.contains(unwrapped.identifier.name.toLowerCase());
  }
  if (unwrapped is PropertyAccess) {
    return _statusCodePropertyNames.contains(unwrapped.propertyName.name.toLowerCase());
  }
  return false;
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

const _statusCodePropertyNames = {
  'code',
  'errorcode',
  'httpstatuscode',
  'responsecode',
  'statuscode',
};

const _dedicatedCodeOwnerSuffixes = {'ErrorCodes', 'ResponseCodes', 'StatusCodes'};

const _dedicatedCodeOwnerPathFragments = {
  '/error_codes/',
  '/response_codes/',
  '/status_codes/',
  '_error_codes.dart',
  '_response_codes.dart',
  '_status_codes.dart',
};
