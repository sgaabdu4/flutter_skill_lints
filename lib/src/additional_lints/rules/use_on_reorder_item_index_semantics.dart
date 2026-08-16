import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when `ReorderableListView` / `SliverReorderableList` code mixes old
/// `onReorder` index semantics with new `onReorderItem` index semantics.
///
/// `onReorderItem` already reports the post-removal target index. Do not add
/// one before forwarding, and do not subtract one in downstream reorder
/// handlers.
class UseOnReorderItemIndexSemantics extends AnalysisRule {
  static const LintCode code = LintCode(
    'use_on_reorder_item_index_semantics',
    'Use onReorderItem index semantics directly.',
    correctionMessage:
        '`onReorderItem` already adjusts `newIndex`; pass it through and remove legacy index math.',
    severity: DiagnosticSeverity.ERROR,
  );

  UseOnReorderItemIndexSemantics()
    : super(
        name: 'use_on_reorder_item_index_semantics',
        description:
            'Rejects deprecated onReorder usage and legacy oldIndex/newIndex adjustment with onReorderItem.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addNamedArgument(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseOnReorderItemIndexSemantics rule;
  final Set<int> _reportedOffsets = <int>{};

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme == 'onReorder' && _isFrameworkReorderableArgument(node)) {
      _reportNamedArgument(node);
      return;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (_isOnReorderItemCallback(node) && _hasOldAndNewIndexParams(node.parameters?.parameters)) {
      _checkBody(node.body);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isReorderName(node.name.lexeme) &&
        _hasOldAndNewIndexParams(node.functionExpression.parameters?.parameters)) {
      _checkBody(node.functionExpression.body);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isReorderName(node.name.lexeme) && _hasOldAndNewIndexParams(node.parameters?.parameters)) {
      _checkBody(node.body);
    }
  }

  void _checkBody(FunctionBody body) {
    final finder = _LegacyIndexMathFinder(_report);
    body.visitChildren(finder);
  }

  void _report(AstNode node) {
    if (!_reportedOffsets.add(node.offset)) return;
    rule.reportAtNode(node);
  }

  void _reportNamedArgument(NamedArgument node) {
    if (!_reportedOffsets.add(node.name.offset)) return;
    rule.reportAtOffset(node.name.offset, node.name.length);
  }
}

final class _LegacyIndexMathFinder extends RecursiveAstVisitor<void> {
  const _LegacyIndexMathFinder(this.report);

  final void Function(AstNode node) report;

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (_isOldBeforeNewCondition(node.condition) &&
        (_isNewIndexPlusOne(node.thenExpression) || _isNewIndexPlusOne(node.elseExpression))) {
      report(node);
      return;
    }
    super.visitConditionalExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_isOldBeforeNewCondition(node.expression) && _adjustsNewIndexDown(node.thenStatement)) {
      report(node);
      return;
    }
    super.visitIfStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}

  @override
  void visitMethodDeclaration(MethodDeclaration node) {}
}

bool _isOnReorderItemCallback(FunctionExpression node) {
  final parent = node.parent;
  return parent is NamedArgument && parent.name.lexeme == 'onReorderItem';
}

bool _hasOldAndNewIndexParams(NodeList<FormalParameter>? parameters) {
  if (parameters == null) return false;
  final names = {for (final parameter in parameters) parameter.name?.lexeme};
  return names.contains('oldIndex') && names.contains('newIndex');
}

bool _isReorderName(String name) => name.toLowerCase().contains('reorder');

bool _isFrameworkReorderableArgument(NamedArgument node) {
  final parent = node.parent;
  if (parent is! ArgumentList) return false;
  final owner = parent.parent;
  if (owner is! InstanceCreationExpression) return false;

  final typeName = owner.constructorName.type.name.lexeme;
  return switch (typeName) {
    'ReorderableList' || 'ReorderableListView' || 'SliverReorderableList' => true,
    _ => false,
  };
}

bool _isOldBeforeNewCondition(Expression expression) {
  final unwrapped = _unwrap(expression);
  if (unwrapped is! BinaryExpression) return false;

  final left = _identifierName(unwrapped.leftOperand);
  final right = _identifierName(unwrapped.rightOperand);
  final operator = unwrapped.operator.lexeme;

  return left == 'oldIndex' && operator == '<' && right == 'newIndex' ||
      left == 'newIndex' && operator == '>' && right == 'oldIndex';
}

bool _isNewIndexPlusOne(Expression expression) {
  final unwrapped = _unwrap(expression);
  if (unwrapped is! BinaryExpression || unwrapped.operator.lexeme != '+') return false;

  return _identifierName(unwrapped.leftOperand) == 'newIndex' &&
          _isIntegerOne(unwrapped.rightOperand) ||
      _isIntegerOne(unwrapped.leftOperand) && _identifierName(unwrapped.rightOperand) == 'newIndex';
}

bool _adjustsNewIndexDown(Statement statement) {
  return switch (statement) {
    Block(:final statements) => statements.any(_adjustsNewIndexDown),
    ExpressionStatement(:final expression) => _isNewIndexDecrement(expression),
    _ => false,
  };
}

bool _isNewIndexDecrement(Expression expression) {
  final unwrapped = _unwrap(expression);
  if (unwrapped is AssignmentExpression) {
    if (_identifierName(unwrapped.leftHandSide) != 'newIndex') return false;
    if (unwrapped.operator.lexeme == '-=') return _isIntegerOne(unwrapped.rightHandSide);
    return unwrapped.operator.lexeme == '=' && _isNewIndexMinusOne(unwrapped.rightHandSide);
  }
  if (unwrapped is PostfixExpression || unwrapped is PrefixExpression) {
    return unwrapped.toSource() == 'newIndex--' || unwrapped.toSource() == '--newIndex';
  }
  return false;
}

bool _isNewIndexMinusOne(Expression expression) {
  final unwrapped = _unwrap(expression);
  if (unwrapped is! BinaryExpression || unwrapped.operator.lexeme != '-') return false;
  return _identifierName(unwrapped.leftOperand) == 'newIndex' &&
      _isIntegerOne(unwrapped.rightOperand);
}

bool _isIntegerOne(Expression expression) {
  final unwrapped = _unwrap(expression);
  return unwrapped is IntegerLiteral && unwrapped.value == 1;
}

String? _identifierName(Expression expression) {
  final unwrapped = _unwrap(expression);
  return switch (unwrapped) {
    SimpleIdentifier(:final name) => name,
    _ => null,
  };
}

Expression _unwrap(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}
