import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import '../ast_node_analysis.dart';

/// Warns when executable code uses raw string or numeric literals instead of
/// named constants, value objects, or semantic helpers.
class AvoidMagicLiterals extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_magic_literals',
    'Avoid magic string and numeric literals in executable code.',
    correctionMessage:
        'Move contract strings into a dedicated keys/schema/codec/request owner, '
        'and move numeric thresholds, grid sizes, or windows into named constants, '
        'value objects, or semantic helpers. Do not appease this rule with names '
        'that only encode the literal type or value.',
  );

  AvoidMagicLiterals()
    : super(
        name: 'avoid_magic_literals',
        description:
            'Warns when executable code uses raw string or numeric literals '
            'instead of named constants, value objects, or semantic helpers.',
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
  final AvoidMagicLiterals rule;

  _Visitor(this.rule);

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (_shouldReportString(node, node.value)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    if (_shouldReportInterpolation(node)) {
      rule.reportAtNode(node);
    }
    super.visitStringInterpolation(node);
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (final expression in _dateFormatPatternExpressions(node)) {
      if (expression is SimpleStringLiteral || expression is StringInterpolation) continue;
      rule.reportAtNode(expression);
    }

    super.visitArgumentList(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final value = _signedIntValue(node);
    if (value == null ||
        _isAllowedNumber(value) ||
        _isAllowedLiteralContext(node) ||
        !_shouldReportNumber(node)) {
      return;
    }

    rule.reportAtNode(_numericReportNode(node));
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    final value = _signedDoubleValue(node);
    if (_isAllowedNumber(value) || _isAllowedLiteralContext(node) || !_shouldReportNumber(node)) {
      return;
    }

    rule.reportAtNode(_numericReportNode(node));
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (_isAppeasementLiteralConstant(node) && !_isExcludedGeneratedLiteralContext(node)) {
      rule.reportAtToken(node.name);
    }
    super.visitVariableDeclaration(node);
  }
}

bool _isExcludedContext(RuleContext context) {
  if (context.isInTestDirectory || isGeneratedRuleContext(context)) return true;

  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return !path.contains('/lib/') ||
      path.endsWith('_test.dart') ||
      path.endsWith('_constants.dart') ||
      path.endsWith('_keys.dart') ||
      path.endsWith('_schema.dart') ||
      path.endsWith('_strings.dart') ||
      path.endsWith('_theme.dart') ||
      path.endsWith('_tokens.dart') ||
      _isDedicatedCodeOwnerPath(path) ||
      path.contains('/constants/') ||
      path.contains('/extensions/') ||
      path.contains('/core/theme/') ||
      path.contains('/l10n/');
}

bool _shouldReportString(StringLiteral node, String value) {
  if (value.trim().isEmpty) return false;
  if (_isAllowedLiteralContext(node)) return false;

  return _isStringKeyContext(node) || _isStringBoundaryArgument(node);
}

bool _shouldReportInterpolation(StringInterpolation node) {
  if (_isAllowedLiteralContext(node)) return false;

  final hasRawText = node.elements.whereType<InterpolationString>().any(
    (element) => element.value.trim().isNotEmpty,
  );

  return hasRawText && (_isStringKeyContext(node) || _isStringBoundaryArgument(node));
}

bool _shouldReportNumber(AstNode node) {
  return _isNumericBoundaryArgument(node) ||
      (_isNumericComparison(node) && !_isStatusCodeComparison(node));
}

bool _isAllowedLiteralContext(AstNode node) {
  return _isInDirective(node) ||
      _isInAnnotation(node) ||
      _isInConstVariableInitializer(node) ||
      _isDirectVariableInitializer(node) ||
      _isInDefaultFormalParameter(node) ||
      _isInEnumConstant(node);
}

bool _isInDirective(AstNode node) => node.thisOrAncestorOfType<Directive>() != null;

bool _isInAnnotation(AstNode node) => node.thisOrAncestorOfType<Annotation>() != null;

bool _isInEnumConstant(AstNode node) =>
    node.thisOrAncestorOfType<EnumConstantDeclaration>() != null;

bool _isInDefaultFormalParameter(AstNode node) {
  final parameter = node.thisOrAncestorOfType<DefaultFormalParameter>();
  final defaultValue = parameter?.defaultValue;
  return defaultValue != null && _containsNode(defaultValue, node);
}

bool _isInConstVariableInitializer(AstNode node) {
  final declaration = node.thisOrAncestorOfType<VariableDeclaration>();
  if (declaration == null) return false;

  final initializer = declaration.initializer;
  if (initializer == null || !_containsNode(initializer, node)) return false;

  final parent = declaration.parent;
  return parent is VariableDeclarationList && parent.keyword?.keyword == Keyword.CONST;
}

bool _isDirectVariableInitializer(AstNode node) {
  final declaration = node.thisOrAncestorOfType<VariableDeclaration>();
  if (declaration == null) return false;

  final initializer = declaration.initializer;
  if (initializer == null) return false;

  final reportNode = node is IntegerLiteral || node is DoubleLiteral
      ? _numericReportNode(node)
      : node;
  return identical(initializer, reportNode);
}

bool _containsNode(AstNode root, AstNode node) {
  AstNode? current = node;
  while (current != null) {
    if (identical(current, root)) return true;
    current = current.parent;
  }
  return false;
}

int? _signedIntValue(IntegerLiteral node) {
  final value = node.value;
  if (value == null) return null;

  return _hasUnaryMinus(node) ? -value : value;
}

double _signedDoubleValue(DoubleLiteral node) {
  final value = node.value;
  return _hasUnaryMinus(node) ? -value : value;
}

bool _hasUnaryMinus(AstNode node) {
  final parent = node.parent;
  return parent is PrefixExpression && parent.operator.type == TokenType.MINUS;
}

bool _isAllowedNumber(num value) => value == -1 || value == 0 || value == 1;

bool _isStringKeyContext(AstNode node) {
  final parent = node.parent;
  return parent is IndexExpression && identical(parent.index, node) ||
      parent is MapLiteralEntry && identical(parent.key, node);
}

bool _isStringBoundaryArgument(AstNode node) {
  final argumentList = _enclosingArgumentList(node);
  if (argumentList == null) return false;

  final namedExpression = node.thisOrAncestorOfType<NamedExpression>();
  if (namedExpression != null && _containsNode(namedExpression.expression, node)) {
    final label = namedExpression.name.lexeme.toLowerCase();
    if (_stringOwnershipNames.any(label.contains)) return true;
  }

  final ownerName = _argumentOwnerName(argumentList).toLowerCase();
  if (ownerName == 'dateformat') return true;

  return _stringOwnershipNames.any(ownerName.contains);
}

Iterable<Expression> _dateFormatPatternExpressions(ArgumentList argumentList) sync* {
  final ownerName = _argumentOwnerName(argumentList).toLowerCase();

  if (ownerName == 'formatted') {
    for (final argument in argumentList.arguments) {
      if (argument is NamedExpression && argument.name.lexeme == 'pattern') {
        yield argument.expression;
      }
    }
    return;
  }

  if (ownerName != 'dateformat') return;

  for (final argument in argumentList.arguments) {
    if (argument is NamedExpression) {
      if (argument.name.lexeme == 'pattern') yield argument.expression;
      continue;
    }
    if (argument is Expression) {
      yield argument;
      return;
    }
  }
}

bool _isNumericBoundaryArgument(AstNode node) {
  final argumentList = _enclosingArgumentList(node);
  if (argumentList == null) return false;

  final namedExpression = node.thisOrAncestorOfType<NamedExpression>();
  if (namedExpression != null && _containsNode(namedExpression.expression, node)) {
    final label = namedExpression.name.lexeme.toLowerCase();
    if (_matchesNumericOwnershipName(label)) return true;
  }

  final ownerName = _argumentOwnerName(argumentList).toLowerCase();
  return _numericMethodNames.contains(ownerName);
}

bool _isNumericComparison(AstNode node) {
  final reportNode = _numericReportNode(node);
  final parent = reportNode.parent;
  if (parent is! BinaryExpression) return false;

  return switch (parent.operator.type) {
    TokenType.EQ_EQ ||
    TokenType.BANG_EQ ||
    TokenType.GT ||
    TokenType.GT_EQ ||
    TokenType.LT ||
    TokenType.LT_EQ => true,
    _ => false,
  };
}

bool _isStatusCodeComparison(AstNode node) {
  final reportNode = _numericReportNode(node);
  final parent = reportNode.parent;
  if (parent is! BinaryExpression) return false;

  if (_containsNode(parent.leftOperand, reportNode)) {
    return _isStatusCodeExpression(parent.rightOperand);
  }
  if (_containsNode(parent.rightOperand, reportNode)) {
    return _isStatusCodeExpression(parent.leftOperand);
  }
  return false;
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

bool _isAppeasementLiteralConstant(VariableDeclaration node) {
  final name = node.name.lexeme.replaceFirst(RegExp(r'^_+'), '');

  final initializer = node.initializer;
  final hasLiteralInitializer =
      initializer is IntegerLiteral ||
      initializer is DoubleLiteral ||
      initializer is SimpleStringLiteral ||
      initializer is BooleanLiteral;

  if (!hasLiteralInitializer) return false;

  return _generatedLiteralConstantName.hasMatch(name) ||
      _nameRepeatsIntegerLiteralValue(name, initializer);
}

bool _nameRepeatsIntegerLiteralValue(String name, Expression? initializer) {
  final value = _integerInitializerValue(initializer);
  if (value == null || _isAllowedNumber(value)) return false;

  final valueText = value.abs().toString();
  final normalizedName = name.replaceAll('_', '').toLowerCase();
  if (_allowedValueNameFragments.any(normalizedName.contains)) return false;

  return _integerNameTokens(name).contains(valueText);
}

int? _integerInitializerValue(Expression? expression) {
  if (expression is IntegerLiteral) return expression.value;
  if (expression is PrefixExpression && expression.operator.type == TokenType.MINUS) {
    final operand = expression.operand;
    if (operand is IntegerLiteral) {
      final value = operand.value;
      if (value != null) return -value;
    }
  }
  return null;
}

Set<String> _integerNameTokens(String name) {
  return RegExp(r'\d+').allMatches(name).map((match) => match.group(0)!).toSet();
}

bool _isExcludedGeneratedLiteralContext(VariableDeclaration node) {
  return _isInDirective(node) ||
      _isInAnnotation(node) ||
      _isInEnumConstant(node) ||
      _isDedicatedCodeOwnerClass(node);
}

ArgumentList? _enclosingArgumentList(AstNode node) {
  final argumentList = node.thisOrAncestorOfType<ArgumentList>();
  if (argumentList == null || !_containsNode(argumentList, node)) return null;
  return argumentList;
}

String _argumentOwnerName(ArgumentList argumentList) {
  final parent = argumentList.parent;
  if (parent is MethodInvocation) return parent.methodName.name;
  if (parent is InstanceCreationExpression) {
    return parent.constructorName.type.name.lexeme;
  }
  if (parent is FunctionExpressionInvocation) return parent.function.toSource();
  return '';
}

AstNode _numericReportNode(AstNode node) {
  final parent = node.parent;
  if (parent is PrefixExpression && parent.operator.type == TokenType.MINUS) {
    return parent;
  }
  return node;
}

const _stringOwnershipNames = {
  'bucket',
  'collection',
  'database',
  'directory',
  'document',
  'environment',
  'file',
  'id',
  'key',
  'location',
  'pattern',
  'path',
  'prefix',
  'route',
  'suffix',
  'table',
  'topic',
  'type',
};

const _numericOwnershipNames = {
  'attempt',
  'count',
  'day',
  'delay',
  'hour',
  'interval',
  'limit',
  'max',
  'maxvalue',
  'millisecond',
  'min',
  'minvalue',
  'minute',
  'month',
  'retry',
  'second',
  'threshold',
  'timeout',
  'week',
  'window',
  'year',
};

bool _matchesNumericOwnershipName(String label) => _numericOwnershipNames.contains(label);

const _numericMethodNames = {
  'calendardaysbefore',
  'daysbefore',
  'generate',
  'limit',
  'skip',
  'sublist',
  'substring',
  'take',
};

const _statusCodePropertyNames = {
  'code',
  'errorcode',
  'httpstatuscode',
  'responsecode',
  'statuscode',
};

bool _isDedicatedCodeOwnerClass(AstNode node) {
  final className = node.thisOrAncestorOfType<ClassDeclaration>()?.namePart.typeName.lexeme;
  return className != null && _dedicatedCodeOwnerSuffixes.any(className.endsWith);
}

bool _isDedicatedCodeOwnerPath(String path) {
  return _dedicatedCodeOwnerPathFragments.any(path.contains);
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

final _generatedLiteralConstantName = RegExp(r'^k(?:Int|Double|Num|String|Bool)(?:_|[A-Z0-9]).+');

const _allowedValueNameFragments = {
  'a11y',
  'base64',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'http2',
  'http3',
  'i18n',
  'ipv4',
  'ipv6',
  'l10n',
  'md5',
  'oauth2',
  's3',
  'sha1',
  'sha224',
  'sha256',
  'sha384',
  'sha512',
  'utf8',
  'v2',
  'v3',
};
