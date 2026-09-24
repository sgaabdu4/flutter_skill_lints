part of '../riverpod_source_rules.dart';

final class _ScalarWatchVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>{};

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'watch' && node.target?.toSource() == 'ref') {
      final type = node.staticType;
      if (type != null &&
          (type.isDartCoreBool ||
              type.isDartCoreString ||
              type.isDartCoreInt ||
              type.isDartCoreDouble ||
              type.isDartCoreNum ||
              type.element is EnumElement)) {
        offsets.add(node.offset);
      }
      if (_consumesWholeWatch(node)) offsets.add(node.offset);
    }
    super.visitMethodInvocation(node);
  }
}

bool _consumesWholeWatch(MethodInvocation watch) {
  AstNode value = watch;
  while (_wholeValueWrapper(value.parent, value)) {
    value = value.parent!;
  }
  final parent = value.parent;
  if (parent is VariableDeclaration && _isOnlyUsedWhole(parent)) return true;
  return _isWholeValueUse(watch);
}

bool _wholeValueWrapper(AstNode? parent, AstNode value) =>
    parent is ParenthesizedExpression && parent.expression == value ||
    parent is ConditionalExpression &&
        (parent.thenExpression == value || parent.elseExpression == value);

bool _isOnlyUsedWhole(VariableDeclaration declaration) {
  final element = declaration.declaredFragment?.element;
  if (element == null) return false;
  AstNode? scope = declaration.parent;
  while (scope != null && scope is! MethodDeclaration) {
    scope = scope.parent;
  }
  if (scope == null) return false;
  final uses = _VariableUses(element);
  scope.accept(uses);
  return uses.found && uses.allWhole;
}

final class _VariableUses extends RecursiveAstVisitor<void> {
  _VariableUses(this.element);

  final Element element;
  bool found = false;
  bool allWhole = true;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element != element) return;
    found = true;
    if (!_isWholeValueUse(node)) allWhole = false;
  }
}

bool _isWholeValueUse(Expression value) {
  final parent = value.parent;
  if (parent is ForEachParts && parent.iterable == value) return true;
  if (parent is MethodInvocation &&
      parent.target == value &&
      parent.methodName.name == 'when' &&
      _hasCompleteAsyncValueDispatch(parent)) {
    return true;
  }
  if (parent is NamedArgument || parent is ArgumentList) {
    final arguments = parent is NamedArgument ? parent.parent : parent;
    if (arguments is ArgumentList && arguments.parent is InstanceCreationExpression) {
      return true;
    }
  }
  if (parent is SwitchExpression && parent.expression == value) {
    return parent.cases.every((branch) {
      final pattern = branch.guardedPattern.pattern;
      return pattern is WildcardPattern || pattern is ObjectPattern && pattern.fields.isEmpty;
    });
  }
  if (parent is ReturnStatement && value.staticType?.isDartCoreList == true) return true;
  return false;
}

bool _hasCompleteAsyncValueDispatch(MethodInvocation invocation) {
  final method = invocation.methodName.element;
  final owner = method?.enclosingElement;
  final ownerLibrary = owner?.library?.uri.toString() ?? '';
  if (method?.name != 'when' ||
      (owner?.name != 'AsyncValue' && owner?.name != 'AsyncValueExtensions') ||
      !(ownerLibrary.startsWith('package:riverpod/') ||
          ownerLibrary.startsWith('package:flutter_riverpod/'))) {
    return false;
  }
  final branches = invocation.argumentList.arguments
      .whereType<NamedArgument>()
      .map((argument) => argument.name.lexeme)
      .toSet();
  return branches.containsAll(const {'data', 'loading', 'error'});
}

const _providerOrFamily = TypeChecker.fromName('ProviderOrFamily', packageName: 'riverpod');

bool _isRiverpodPackageLibrary(LibraryElement? library) {
  final uri = library?.uri.toString() ?? '';
  return uri.startsWith('package:riverpod/') ||
      uri.startsWith('package:flutter_riverpod/') ||
      uri.startsWith('package:hooks_riverpod/');
}

/// A provider class declared by Riverpod itself, as opposed to a generated provider class.
bool _isRiverpodProviderClass(Element? element) =>
    element is InterfaceElement &&
    _isRiverpodPackageLibrary(element.library) &&
    _providerOrFamily.isSuperOf(element);

Element? _leftmostElement(Expression? expression) => switch (expression) {
  SimpleIdentifier(:final element) => element,
  PrefixedIdentifier(:final prefix, :final identifier) =>
    prefix.element is PrefixElement ? identifier.element : prefix.element,
  PropertyAccess(:final target) => _leftmostElement(target),
  _ => null,
};

/// Constructor calls and static builder calls (`Provider.family(...)`) on Riverpod provider classes.
final class _ManualProviderCreationFinder extends RecursiveAstVisitor<void> {
  final nodes = <Expression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_isRiverpodProviderClass(node.constructorName.type.element)) nodes.add(node);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isRiverpodProviderClass(_leftmostElement(node.target))) nodes.add(node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_isRiverpodProviderClass(_leftmostElement(node.function))) nodes.add(node);
    super.visitFunctionExpressionInvocation(node);
  }
}

int _unitLineIndex(SourceScannerContext context, int offset) =>
    context.unit.lineInfo.getLocation(offset).lineNumber - 1;

void _reportResolvedManualProviders(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  Set<int> reportedLines,
) {
  final finder = _ManualProviderCreationFinder();
  context.unit.accept(finder);
  for (final node in finder.nodes) {
    final owner = node.thisOrAncestorMatching(
      (candidate) =>
          candidate is TopLevelVariableDeclaration ||
          candidate is FieldDeclaration ||
          candidate is VariableDeclarationStatement ||
          candidate is FunctionDeclaration ||
          candidate is MethodDeclaration,
    );
    final ownerLine = owner is AnnotatedNode
        ? _unitLineIndex(context, owner.firstTokenAfterCommentAndMetadata.offset)
        : owner == null
        ? null
        : _unitLineIndex(context, owner.offset);
    final location = context.unit.lineInfo.getLocation(node.offset);
    final line = location.lineNumber - 1;
    if (reportedLines.contains(ownerLine) || !reportedLines.add(line)) continue;
    reporter.report(context, line, location.columnNumber - 1);
  }
}

/// Top-level or static declarations whose value is an existing provider.
void _reportProviderAliases(ScannerRuleReporter reporter, SourceScannerContext context) {
  void check(Token name, Expression? value) {
    final expression = value?.unParenthesized;
    if (expression == null || !_isProviderAliasValue(expression)) return;
    final location = context.unit.lineInfo.getLocation(name.offset);
    reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
  }

  for (final declaration in context.unit.declarations) {
    switch (declaration) {
      case TopLevelVariableDeclaration(:final variables):
        for (final variable in variables.variables) {
          check(variable.name, variable.initializer);
        }
      case FunctionDeclaration(isGetter: true, :final name, :final functionExpression):
        check(name, _expressionBodyValue(functionExpression.body));
      case ClassDeclaration(:final body) || MixinDeclaration(:final body):
        _checkStaticMembers(body, check);
      default:
        break;
    }
  }
}

void _checkStaticMembers(ClassBody body, void Function(Token, Expression?) check) {
  if (body is! BlockClassBody) return;
  for (final member in body.members) {
    if (member is FieldDeclaration && member.isStatic) {
      for (final variable in member.fields.variables) {
        check(variable.name, variable.initializer);
      }
    } else if (member is MethodDeclaration && member.isStatic && member.isGetter) {
      check(member.name, _expressionBodyValue(member.body));
    }
  }
}

Expression? _expressionBodyValue(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is! BlockFunctionBody || body.block.statements.length != 1) return null;
  final statement = body.block.statements.single;
  return statement is ReturnStatement ? statement.expression : null;
}

/// A reference to (or family call on) an existing provider variable, not a new provider.
bool _isProviderAliasValue(Expression expression) {
  final type = expression.staticType;
  if (type is! InterfaceType || !_providerOrFamily.isAssignableFromType(type)) return false;
  final source = switch (expression) {
    FunctionExpressionInvocation(:final function) => function,
    MethodInvocation(:final target?, methodName: SimpleIdentifier(name: 'call')) => target,
    MethodInvocation(target: null, :final methodName) => methodName,
    _ => expression,
  };
  final element = switch (source) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final element) => element,
    _ => null,
  };
  return element is PropertyAccessorElement && element.variable is TopLevelVariableElement;
}
