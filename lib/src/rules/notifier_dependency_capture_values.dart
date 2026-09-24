part of 'notifier_dependency_capture.dart';

bool _hasUsedCapturedDependencyOperation(Block block, int boundaryOffset) {
  for (final statement in block.statements) {
    if (statement is VariableDeclarationStatement &&
        statement.end <= boundaryOffset &&
        _hasUsedFinalDependencyCapture(statement, block, boundaryOffset)) {
      return true;
    }
    if (statement is PatternVariableDeclarationStatement &&
        statement.end <= boundaryOffset &&
        _hasUsedFinalRecordPatternCapture(statement, block, boundaryOffset)) {
      return true;
    }
  }
  return false;
}

bool _hasUsedFinalDependencyCapture(
  VariableDeclarationStatement statement,
  Block block,
  int boundaryOffset,
) {
  final declarations = statement.variables;
  if (declarations.keyword?.lexeme != 'final' || declarations.lateKeyword != null) return false;
  return declarations.variables.any((variable) {
    if (!_isResolvedDependencyCapture(variable.initializer)) return false;
    final element = variable.declaredFragment?.element;
    return element is LocalVariableElement &&
        _isTypedDependencyCapture(element.type) &&
        _CapturedDependencyUsageVisitor(element, boundaryOffset).isUsedIn(block);
  });
}

bool _hasUsedFinalRecordPatternCapture(
  PatternVariableDeclarationStatement statement,
  Block block,
  int boundaryOffset,
) {
  if (statement.end > boundaryOffset) return false;
  return _recordPatternResourceBindings(
    statement,
    block,
  ).any((element) => _CapturedDependencyUsageVisitor(element, boundaryOffset).isUsedIn(block));
}

List<LocalVariableElement> _recordPatternResourceBindings(
  PatternVariableDeclarationStatement statement,
  Block block,
) {
  final declaration = statement.declaration;
  if (declaration.keyword.lexeme != 'final' || declaration.pattern is! RecordPattern) {
    return const [];
  }
  final value = _recordPatternValue(declaration);
  if (value == null) return const [];
  if (!_isResolvedRecordCaptureSource(value, block)) return const [];
  final recordType = value.staticType;
  if (recordType is! RecordType) return const [];
  final pattern = declaration.pattern as RecordPattern;
  final bindings = <LocalVariableElement>[];
  for (final field in pattern.fields) {
    final name = field.effectiveName;
    final variable = field.pattern;
    if (name == null || variable is! DeclaredVariablePattern) continue;
    final element = variable.declaredFragment?.element;
    final fieldType = _namedRecordFieldType(recordType, name);
    if (element == null) continue;
    final localElement = element as LocalVariableElement;
    if (!_isRepositoryOrServiceType(localElement.type) ||
        !_isRepositoryOrServiceName(name) ||
        !_isRepositoryOrServiceType(fieldType)) {
      continue;
    }
    bindings.add(localElement);
  }
  return bindings;
}

bool _isResolvedRecordCaptureSource(Expression expression, Block block) {
  if (_isResolvedRecordCaptureExpression(expression)) return true;
  final element = _localVariableReadElement(expression, block);
  if (element == null) return false;
  for (final statement in block.statements.whereType<VariableDeclarationStatement>()) {
    if (statement.end > expression.offset ||
        statement.variables.keyword?.lexeme != 'final' ||
        statement.variables.lateKeyword != null) {
      continue;
    }
    for (final variable in statement.variables.variables) {
      if (variable.declaredFragment?.element == element) {
        return _isResolvedRecordCaptureExpression(variable.initializer);
      }
    }
  }
  return false;
}

bool _isResolvedRecordCaptureExpression(Expression? expression) {
  final type = expression?.staticType;
  if (type is! RecordType || !_hasRepositoryOrServiceRecordField(type)) return false;
  return expression is RecordLiteral ||
      expression is MethodInvocation && expression.methodName.element is MethodElement ||
      expression is AwaitExpression && _isResolvedFutureRecordAcquisition(expression);
}

Expression? _recordPatternValue(PatternVariableDeclaration declaration) {
  final expressions = declaration.childEntities.whereType<Expression>().toList();
  return expressions.length == 1 ? expressions.single : null;
}

LocalVariableElement? _localVariableReadElement(Expression expression, Block block) {
  if (expression is SimpleIdentifier) {
    final element = expression.element;
    return element is LocalVariableElement ? element : null;
  }
  final name = expression.toSource();
  if (!RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(name)) return null;
  final candidates = <LocalVariableElement>{};
  for (final statement in block.statements.whereType<VariableDeclarationStatement>()) {
    if (statement.end > expression.offset || statement.variables.keyword?.lexeme != 'final') {
      continue;
    }
    for (final variable in statement.variables.variables) {
      final element = variable.declaredFragment?.element;
      if (variable.name.lexeme == name && element is LocalVariableElement) {
        candidates.add(element);
      }
    }
  }
  return candidates.length == 1 ? candidates.single : null;
}

bool _hasRepositoryOrServiceRecordField(RecordType type) => type.namedFields.any(
  (field) => _isRepositoryOrServiceName(field.name) && _isRepositoryOrServiceType(field.type),
);

bool _isTypedDependencyCapture(DartType type) =>
    _isRepositoryOrServiceType(type) ||
    type is FunctionType && type.nullabilitySuffix == NullabilitySuffix.none ||
    type is RecordType && _hasRepositoryOrServiceRecordField(type);

DartType? _namedRecordFieldType(RecordType type, String name) =>
    type.namedFields.where((field) => field.name == name).firstOrNull?.type;

Set<AwaitExpression> _usedResourceAcquisitionAwaits(Block block) {
  final ignored = <AwaitExpression>{};
  for (final statement in block.statements.whereType<VariableDeclarationStatement>()) {
    final declarations = statement.variables;
    if (declarations.keyword?.lexeme != 'final' ||
        declarations.lateKeyword != null ||
        declarations.variables.length != 1) {
      continue;
    }
    final variable = declarations.variables.single;
    final awaitExpression = variable.initializer;
    final element = variable.declaredFragment?.element;
    if (awaitExpression is! AwaitExpression ||
        element is! LocalVariableElement ||
        !_isDependencyCaptureType(element.type) ||
        !_isResolvedFutureDependencyAcquisition(awaitExpression)) {
      continue;
    }
    if (_hasUsedCapturedDependency(element, block, awaitExpression.end)) {
      ignored.add(awaitExpression);
    }
  }
  return ignored;
}

bool _hasUsedCapturedDependency(LocalVariableElement element, Block block, int boundaryOffset) {
  if (_CapturedDependencyUsageVisitor(element, boundaryOffset).isUsedIn(block)) return true;
  if (element.type is! RecordType) return false;
  for (final statement in block.statements.whereType<PatternVariableDeclarationStatement>()) {
    final value = _recordPatternValue(statement.declaration);
    if (value == null ||
        _localVariableReadElement(value, block) != element ||
        !_isResolvedRecordCaptureSource(value, block)) {
      continue;
    }
    for (final binding in _recordPatternResourceBindings(statement, block)) {
      if (_CapturedDependencyUsageVisitor(binding, boundaryOffset).isUsedIn(block)) return true;
    }
  }
  return false;
}

bool _isResolvedFutureDependencyAcquisition(AwaitExpression expression) {
  final acquisition = expression.expression;
  return acquisition is MethodInvocation &&
      _isResolvedAcquisitionCall(acquisition) &&
      _isResolvedFutureDependencyAcquisitionFromCall(acquisition);
}

bool _isResolvedFutureRecordAcquisition(AwaitExpression expression) {
  final acquisition = expression.expression;
  return acquisition is MethodInvocation &&
      _isResolvedAcquisitionCall(acquisition) &&
      _isResolvedFutureDependencyAcquisitionFromCall(acquisition) &&
      acquisition.staticType is InterfaceType &&
      (acquisition.staticType as InterfaceType).typeArguments.single is RecordType;
}

bool _isResolvedAcquisitionCall(MethodInvocation acquisition) =>
    acquisition.methodName.element is MethodElement &&
    (acquisition.target == null ||
        acquisition.target is ThisExpression ||
        _isResolvedDependencyRead(acquisition));

bool _isResolvedDependencyOperation(Expression? initializer) {
  if (_isResolvedRepositoryGetter(initializer)) return true;
  if (initializer is MethodInvocation &&
      _isResolvedDependencyRead(initializer) &&
      _isMutationDependencyRead(initializer)) {
    return _isNonNullableInterfaceType(initializer.staticType) &&
        _isRepositoryOrServiceType(initializer.staticType);
  }
  if (initializer is! PropertyAccess ||
      initializer.target is! MethodInvocation ||
      !_isResolvedDependencyRead(initializer.target as MethodInvocation) ||
      !_isMutationDependencyRead(initializer.target as MethodInvocation)) {
    return false;
  }
  final type = initializer.staticType;
  final read = initializer.target as MethodInvocation;
  final isRepositoryOperation = _isRepositoryOrServiceType(read.staticType);
  final isNotifierOperation = _isResolvedNotifierProviderRead(read);
  return initializer.propertyName.element is ExecutableElement &&
      type is FunctionType &&
      type.nullabilitySuffix == NullabilitySuffix.none &&
      (isRepositoryOperation || isNotifierOperation);
}

bool _isResolvedDependencyCapture(Expression? expression) {
  if (_isResolvedDependencyOperation(expression) ||
      _isResolvedRepositoryGetter(expression) ||
      _isResolvedRecordCaptureExpression(expression)) {
    return true;
  }
  if (expression is AwaitExpression) {
    final type = expression.staticType;
    return _isResolvedFutureDependencyAcquisition(expression) &&
        type != null &&
        _isDependencyCaptureType(type);
  }
  if (expression is! MethodInvocation ||
      expression.methodName.element is! MethodElement ||
      !_isRepositoryOrServiceType(expression.staticType)) {
    return false;
  }
  return !_isRepositoryOrServiceType(expression.target?.staticType);
}

bool _isResolvedRepositoryGetter(Expression? expression) {
  final element = _repositoryGetterElement(expression);
  final type = expression?.staticType;
  return element != null && _isNonNullableInterfaceType(type) && _isRepositoryOrServiceType(type);
}

GetterElement? _repositoryGetterElement(Expression? expression) {
  final element = switch (expression) {
    SimpleIdentifier() => expression.element,
    PropertyAccess() => expression.propertyName.element,
    _ => null,
  };
  return element is GetterElement && element.isOriginDeclaration ? element : null;
}

final class _RepositoryAcquisitionAfterBoundaryVisitor extends RecursiveAstVisitor<void> {
  _RepositoryAcquisitionAfterBoundaryVisitor(this.boundaryOffset);

  final int boundaryOffset;
  bool hasUse = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (node.offset >= boundaryOffset && _isResolvedFutureDependencyAcquisition(node)) {
      hasUse = true;
    }
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final targetType = node.target?.staticType;
    if (node.offset >= boundaryOffset &&
        node.methodName.element is MethodElement &&
        _isRepositoryOrServiceType(node.staticType) &&
        !_isRepositoryOrServiceType(targetType) &&
        (node.target == null || node.target is ThisExpression)) {
      hasUse = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

final class _CapturedDependencyUsageVisitor extends RecursiveAstVisitor<void> {
  _CapturedDependencyUsageVisitor(this.dependency, this.boundaryOffset);

  final LocalVariableElement dependency;
  final int boundaryOffset;
  bool _isUsed = false;

  bool isUsedIn(Block block) {
    block.accept(this);
    return _isUsed;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final function = node.function;
    if (node.offset >= boundaryOffset &&
        function is SimpleIdentifier &&
        dependency.type is FunctionType &&
        (dependency.type as FunctionType).nullabilitySuffix == NullabilitySuffix.none &&
        function.element == dependency) {
      _isUsed = true;
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.offset >= boundaryOffset &&
        !node.isNullAware &&
        node.methodName.element is ExecutableElement &&
        _isUsedResourceReceiver(node.target)) {
      _isUsed = true;
    }
    super.visitMethodInvocation(node);
  }

  bool _isUsedResourceReceiver(Expression? receiver) {
    if (receiver is SimpleIdentifier && receiver.element == dependency) {
      return _isNonNullableInterfaceType(receiver.staticType) &&
          _isRepositoryOrServiceType(receiver.staticType);
    }
    if (receiver is PropertyAccess &&
        !receiver.isNullAware &&
        receiver.target is SimpleIdentifier &&
        (receiver.target as SimpleIdentifier).element == dependency &&
        _isNonNullableInterfaceType(receiver.staticType)) {
      return _isCapturedRecordRepositoryField(receiver);
    }
    return false;
  }

  bool _isCapturedRecordRepositoryField(PropertyAccess receiver) {
    final recordType = receiver.target?.staticType;
    if (recordType is! RecordType || !_isRepositoryOrServiceName(receiver.propertyName.name)) {
      return false;
    }
    return _isRepositoryOrServiceType(
      _namedRecordFieldType(recordType, receiver.propertyName.name),
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}
