import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

part 'notifier_dependency_capture_values.dart';

/// Reports when a mutation notifier method misses safe dependency capture.
bool notifierNeedsDependencyEnsure(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  var hasDependency = false;
  var hasNullRepositoryReturn = false;
  for (var i = method.start; i <= method.end; i++) {
    final line = context.source.masked[i];
    hasDependency = hasDependency || _hasMutationDependency(line);
    hasNullRepositoryReturn = hasNullRepositoryReturn || _hasNullRepositoryReturn(line);
  }
  hasDependency = hasDependency || _hasResolvedMutationDependencyRead(context, classSpan, method);
  if (!context.isMutationMethod(method.name) || (!hasDependency && !hasNullRepositoryReturn)) {
    return false;
  }
  final missingCapture =
      hasNullRepositoryReturn ||
      !_hasResolvedDependencyCaptureBeforeMutation(context, classSpan, method);
  return missingCapture && !_usesConstructorInjectedDependencies(context, classSpan, method);
}

bool _hasResolvedDependencyCaptureBeforeMutation(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  final resolvedMethod = _resolvedNotifierMethod(context, classSpan, method);
  if (resolvedMethod == null) return false;
  final methodBlock = resolvedMethod.block;
  final scopes = _dependencyCaptureScopes(methodBlock);
  final ignoredAcquisitionAwaits = <AwaitExpression>{};
  for (final scope in scopes) {
    ignoredAcquisitionAwaits.addAll(_usedResourceAcquisitionAwaits(scope.block));
  }
  final methodBoundaryOffset =
      _mutationBoundary(methodBlock, ignoredAcquisitionAwaits) ?? methodBlock.endToken.offset;
  if (!_dependenciesReadyAtMutation(
    resolvedMethod.declaration,
    methodBlock,
    methodBoundaryOffset,
  )) {
    return false;
  }

  for (final scope in scopes) {
    if (scope.tryOffset != null &&
        _mutationBoundary(methodBlock, ignoredAcquisitionAwaits, scope.tryOffset) != null) {
      continue;
    }
    final block = scope.block;
    final scopeAcquisitionAwaits = _usedResourceAcquisitionAwaits(block);
    final boundaryOffset =
        _mutationBoundary(block, scopeAcquisitionAwaits) ?? block.endToken.offset;
    if (!_dependenciesReadyAtMutation(resolvedMethod.declaration, block, boundaryOffset)) {
      continue;
    }
    if (_hasUsedCapturedDependencyOperation(block, boundaryOffset) ||
        _hasInitializedNullableDependency(block, boundaryOffset)) {
      return true;
    }
  }
  return false;
}

List<({Block block, int? tryOffset})> _dependencyCaptureScopes(Block methodBlock) {
  final scopes = <({Block block, int? tryOffset})>[(block: methodBlock, tryOffset: null)];
  final collector = _TryBodyCollector(scopes);
  methodBlock.accept(collector);
  return scopes;
}

({ClassDeclaration declaration, Block block})? _resolvedNotifierMethod(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  final declaration = context.unit.declarations
      .whereType<ClassDeclaration>()
      .where((candidate) => candidate.namePart.typeName.lexeme == classSpan.name)
      .firstOrNull;
  if (declaration == null) return null;
  final body = _findMethodDeclaration(declaration, method.name)?.body;
  if (body is! BlockFunctionBody) return null;
  return (declaration: declaration, block: body.block);
}

int? _mutationBoundary(
  Block block, [
  Set<AwaitExpression> ignoredAwaits = const {},
  int? endOffset,
]) {
  final visitor = _NotifierMutationBoundaryVisitor(ignoredAwaits, endOffset);
  block.accept(visitor);
  return visitor.firstBoundaryOffset;
}

bool _dependenciesReadyAtMutation(ClassDeclaration declaration, Block block, int boundaryOffset) {
  final readVisitor = _DependencyReadAfterBoundaryVisitor(boundaryOffset);
  block.accept(readVisitor);
  if (readVisitor.hasRead) return false;
  final getterVisitor = _RepositoryGetterUseAfterBoundaryVisitor(boundaryOffset);
  block.accept(getterVisitor);
  if (getterVisitor.hasUse) return false;
  final resourceVisitor = _RepositoryAcquisitionAfterBoundaryVisitor(boundaryOffset);
  block.accept(resourceVisitor);
  if (resourceVisitor.hasUse) return false;

  final nullableFields = _NullableDependencyFieldUseVisitor(boundaryOffset);
  block.accept(nullableFields);
  final initializedFields = _directlyInitializedDependencyFieldsBeforeMutation(
    declaration,
    block,
    boundaryOffset,
  );
  if (!initializedFields.containsAll(nullableFields.fields)) return false;
  if (initializedFields.isEmpty) return true;

  final fieldWrites = _DependencyFieldWriteVisitor();
  block.accept(fieldWrites);
  return !fieldWrites.fields.any(initializedFields.contains);
}

bool _hasInitializedNullableDependency(Block block, int boundaryOffset) {
  final fields = _NullableDependencyFieldUseVisitor(boundaryOffset);
  block.accept(fields);
  return fields.fields.isNotEmpty;
}

Set<FieldElement> _directlyInitializedDependencyFieldsBeforeMutation(
  ClassDeclaration declaration,
  Block block,
  int boundaryOffset,
) {
  final initialized = <FieldElement>{};
  for (final statement in block.statements) {
    if (statement.end > boundaryOffset || statement is! ExpressionStatement) continue;
    final helper = _synchronousZeroArgumentDependencyInitializer(statement, declaration);
    if (helper == null) continue;
    initialized.addAll(_directDependencyAssignments(helper, declaration));
  }
  return initialized;
}

MethodDeclaration? _synchronousZeroArgumentDependencyInitializer(
  ExpressionStatement statement,
  ClassDeclaration declaration,
) {
  final invocation = statement.expression;
  if (invocation is! MethodInvocation ||
      (invocation.target != null && invocation.target is! ThisExpression) ||
      invocation.argumentList.arguments.isNotEmpty) {
    return null;
  }
  final method = invocation.methodName.element;
  if (method is! MethodElement ||
      method.isStatic ||
      method.returnType is! VoidType ||
      method.enclosingElement?.name != declaration.namePart.typeName.lexeme) {
    return null;
  }
  final name = method.name;
  if (name == null) return null;
  final helper = _findMethodDeclaration(declaration, name);
  if (helper == null || helper.body.isAsynchronous || helper.body.isGenerator) return null;
  if (helper.parameters?.parameters.isNotEmpty ?? false) return null;
  return helper;
}

Set<FieldElement> _directDependencyAssignments(MethodDeclaration helper, ClassDeclaration owner) {
  final assignments = _straightLineAssignments(helper.body);
  if (assignments == null) return const {};
  if (assignments.isEmpty) return const {};

  final initialized = <FieldElement>{};
  for (final assignment in assignments) {
    final field = _directDependencyAssignmentField(assignment, owner);
    if (field == null) return const {};
    initialized.add(field);
  }
  return initialized;
}

List<AssignmentExpression>? _straightLineAssignments(FunctionBody body) {
  if (body is ExpressionFunctionBody && body.expression is AssignmentExpression) {
    return [body.expression as AssignmentExpression];
  }
  if (body is! BlockFunctionBody) return null;

  final assignments = <AssignmentExpression>[];
  for (final statement in body.block.statements) {
    if (statement is! ExpressionStatement || statement.expression is! AssignmentExpression) {
      return null;
    }
    assignments.add(statement.expression as AssignmentExpression);
  }
  return assignments;
}

FieldElement? _directDependencyAssignmentField(
  AssignmentExpression assignment,
  ClassDeclaration owner,
) {
  if (assignment.operator.lexeme != '=' && assignment.operator.lexeme != '??=') return null;
  final left = assignment.leftHandSide;
  if (!_isUnqualifiedOrThisFieldTarget(left)) return null;
  final field = _fieldElementFromElement(assignment.writeElement);
  final type = assignment.rightHandSide.staticType;
  if (field == null ||
      !identical(field.enclosingElement, owner.declaredFragment?.element) ||
      !_isRepositoryOrServiceName(field.name) ||
      field.isStatic ||
      !_isResolvedDependencyRead(assignment.rightHandSide) ||
      type is! InterfaceType ||
      type.nullabilitySuffix != NullabilitySuffix.none) {
    return null;
  }
  return field;
}

bool _isNonNullableInterfaceType(DartType? type) =>
    type is InterfaceType && type.nullabilitySuffix == NullabilitySuffix.none;

bool _isRepositoryOrServiceType(DartType? type) =>
    type is InterfaceType && _isRepositoryOrServiceName(type.element.name);

bool _isCoreScalarValueType(DartType? type) {
  if (type is! InterfaceType) return false;
  final library = type.element.library.uri;
  return library.scheme == 'dart' &&
      library.pathSegments.firstOrNull == 'core' &&
      const {'String', 'bool', 'num', 'int', 'double', 'BigInt'}.contains(type.element.name);
}

bool _isResolvedDependencyRead(Expression? expression) {
  if (expression is! MethodInvocation) return false;
  final receiver = expression.target;
  if (receiver is! SimpleIdentifier || receiver.name != 'ref') return false;

  final receiverElement = receiver.element;
  final receiverType = receiver.staticType;
  final readElement = expression.methodName.element;
  final readEnclosingElement = readElement?.enclosingElement;
  if (receiverElement is! PropertyAccessorElement ||
      receiverElement.name != 'ref' ||
      receiverType is! InterfaceType ||
      receiverType.element.name != 'Ref' ||
      !_isRiverpodElement(receiverType.element) ||
      readElement is! MethodElement ||
      readElement.name != 'read' ||
      readEnclosingElement?.name != 'Ref' ||
      readElement.library.uri.scheme != 'package' ||
      readElement.library.uri.pathSegments.isEmpty ||
      !{'riverpod', 'flutter_riverpod'}.contains(readElement.library.uri.pathSegments.first)) {
    return false;
  }
  return true;
}

bool _isMutationDependencyRead(MethodInvocation invocation) {
  final receiver = invocation.target;
  return receiver is SimpleIdentifier &&
      receiver.name == 'ref' &&
      invocation.methodName.name == 'read' &&
      !_isCoreScalarValueType(invocation.staticType) &&
      !_isResourceFreeFreezedDataType(invocation.staticType);
}

bool _isResourceFreeFreezedDataType(DartType? type) {
  if (type is! InterfaceType || !isFreezedInterfaceType(type)) return false;
  return !_freezedTypeContainsDependency(type, <InterfaceElement>{});
}

bool _freezedTypeContainsDependency(InterfaceType type, Set<InterfaceElement> visited) {
  final element = type.element;
  if (type.typeArguments.any((argument) => _containsDependencyType(argument, visited))) {
    return true;
  }
  if (!visited.add(element)) return false;
  final members = <DartType>[
    ...element.fields.where((field) => !field.isStatic).map((field) => field.type),
    ...element.getters.where((getter) => !getter.isStatic).map((getter) => getter.returnType),
  ];
  return members.any((member) => _containsDependencyType(member, visited));
}

bool _containsDependencyType(DartType type, Set<InterfaceElement> visited) {
  if (type is InterfaceType) return _interfaceContainsDependency(type, visited);
  if (type is RecordType) return _recordContainsDependency(type, visited);
  return true;
}

bool _interfaceContainsDependency(InterfaceType type, Set<InterfaceElement> visited) {
  if (_isRepositoryOrServiceType(type)) return true;
  if (type.element is EnumElement) return false;
  if (_isCoreType(type)) return _coreTypeContainsDependency(type, visited);
  if (isFreezedInterfaceType(type)) return _freezedTypeContainsDependency(type, visited);
  return true;
}

bool _isCoreType(InterfaceType type) {
  final uri = type.element.library.uri;
  return uri.scheme == 'dart' && uri.pathSegments.firstOrNull == 'core';
}

bool _coreTypeContainsDependency(InterfaceType type, Set<InterfaceElement> visited) =>
    {'Object', 'Function'}.contains(type.element.name) ||
    _hasDependencyType(type.typeArguments, visited);

bool _recordContainsDependency(RecordType type, Set<InterfaceElement> visited) =>
    type.positionalFields.any((field) => _containsDependencyType(field.type, visited)) ||
    type.namedFields.any((field) => _containsDependencyType(field.type, visited));

bool _hasDependencyType(Iterable<DartType> types, Set<InterfaceElement> visited) =>
    types.any((type) => _containsDependencyType(type, visited));

bool _isResolvedNotifierProviderRead(MethodInvocation invocation) {
  if (!_isResolvedDependencyRead(invocation) || invocation.argumentList.arguments.length != 1) {
    return false;
  }
  final argument = invocation.argumentList.arguments.single;
  final Expression? argumentExpression;
  if (argument is NamedArgument) {
    argumentExpression = argument.argumentExpression;
  } else if (argument is Expression) {
    argumentExpression = argument;
  } else {
    return false;
  }
  final DartType? providerType;
  final Element? notifierAccessor;
  if (argumentExpression is PropertyAccess && argumentExpression.propertyName.name == 'notifier') {
    final providerTarget = argumentExpression.target;
    providerType = providerTarget?.staticType;
    notifierAccessor = argumentExpression.propertyName.element;
  } else if (argumentExpression is PrefixedIdentifier &&
      argumentExpression.identifier.name == 'notifier') {
    providerType = argumentExpression.prefix.staticType;
    notifierAccessor = argumentExpression.identifier.element;
  } else {
    return false;
  }
  return providerType is InterfaceType &&
      _isRiverpodElement(providerType.element) &&
      notifierAccessor is GetterElement &&
      notifierAccessor.name == 'notifier' &&
      notifierAccessor.library.uri.scheme == 'package' &&
      notifierAccessor.library.uri.pathSegments.isNotEmpty &&
      {'riverpod', 'flutter_riverpod'}.contains(notifierAccessor.library.uri.pathSegments.first);
}

MethodDeclaration? _findMethodDeclaration(ClassDeclaration declaration, String name) {
  for (final method in declaration.body.members.whereType<MethodDeclaration>()) {
    if (method.name.lexeme == name) return method;
  }
  return null;
}

bool _hasResolvedMutationDependencyRead(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  final block = _resolvedNotifierMethod(context, classSpan, method)?.block;
  if (block == null) return false;
  final visitor = _MutationDependencyReadVisitor();
  block.accept(visitor);
  return visitor.hasDependency;
}

bool _isRiverpodElement(InterfaceElement element) {
  final uri = element.library.uri;
  return uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      {'riverpod', 'flutter_riverpod'}.contains(uri.pathSegments.first);
}

final class _DependencyReadAfterBoundaryVisitor extends RecursiveAstVisitor<void> {
  _DependencyReadAfterBoundaryVisitor(this.boundaryOffset);

  final int boundaryOffset;
  bool hasRead = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.offset >= boundaryOffset && _isMutationDependencyRead(node)) {
      hasRead = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

final class _TryBodyCollector extends RecursiveAstVisitor<void> {
  _TryBodyCollector(this.scopes);

  final List<({Block block, int? tryOffset})> scopes;

  @override
  void visitTryStatement(TryStatement node) {
    scopes.add((block: node.body, tryOffset: node.offset));
    node.body.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

final class _MutationDependencyReadVisitor extends RecursiveAstVisitor<void> {
  bool hasDependency = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isMutationDependencyRead(node)) hasDependency = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

final class _NullableDependencyFieldUseVisitor extends RecursiveAstVisitor<void> {
  _NullableDependencyFieldUseVisitor(this.boundaryOffset);

  final int boundaryOffset;
  final Set<FieldElement> fields = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final field = _fieldElement(node);
    if (node.offset >= boundaryOffset &&
        field != null &&
        _isRepositoryOrServiceName(field.name) &&
        (field.isLate || field.type.nullabilitySuffix != NullabilitySuffix.none)) {
      fields.add(field);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

final class _RepositoryGetterUseAfterBoundaryVisitor extends RecursiveAstVisitor<void> {
  _RepositoryGetterUseAfterBoundaryVisitor(this.boundaryOffset);

  final int boundaryOffset;
  bool hasUse = false;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    final isRecordField =
        parent is PropertyAccess &&
        identical(parent.propertyName, node) &&
        parent.target?.staticType is RecordType;
    if (node.offset >= boundaryOffset && !isRecordField && _isResolvedRepositoryGetter(node)) {
      hasUse = true;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

FieldElement? _fieldElement(SimpleIdentifier identifier) {
  return _fieldElementFromElement(identifier.element);
}

FieldElement? _fieldElementFromElement(Element? element) {
  if (element is FieldElement) return element;
  if (element is PropertyAccessorElement) {
    final variable = element.variable;
    if (variable is FieldElement) return variable;
  }
  return null;
}

bool _isUnqualifiedOrThisFieldTarget(Expression target) =>
    target is SimpleIdentifier || target is PropertyAccess && target.target is ThisExpression;

final class _DependencyFieldWriteVisitor extends RecursiveAstVisitor<void> {
  final Set<FieldElement> fields = {};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (_isUnqualifiedOrThisFieldTarget(node.leftHandSide)) {
      final field = _fieldElementFromElement(node.writeElement);
      if (field != null && _isRepositoryOrServiceName(field.name)) fields.add(field);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}
}

bool _isRepositoryOrServiceName(String? name) =>
    name != null &&
    RegExp(
      r'(?:repo|repository|service|datasource|dataSource)',
      caseSensitive: false,
    ).hasMatch(name);

final class _NotifierMutationBoundaryVisitor extends RecursiveAstVisitor<void> {
  _NotifierMutationBoundaryVisitor([this.ignoredAwaits = const {}, this.endOffset]);

  final Set<AwaitExpression> ignoredAwaits;
  final int? endOffset;
  int? firstBoundaryOffset;

  @override
  void visitIfStatement(IfStatement node) {
    node.expression.accept(this);
    if (!_isSimpleTerminalStateBranch(node.thenStatement, node.expression)) {
      node.thenStatement.accept(this);
    }
    final elseStatement = node.elseStatement;
    if (elseStatement != null && !_isSimpleTerminalStateBranch(elseStatement, node.expression)) {
      elseStatement.accept(this);
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final target = node.leftHandSide;
    if ((target is SimpleIdentifier && target.name == 'state') ||
        (target is PropertyAccess &&
            target.target is ThisExpression &&
            target.propertyName.name == 'state')) {
      _record(node.offset);
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (!ignoredAwaits.contains(node)) _record(node.offset);
    super.visitAwaitExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {}

  void _record(int offset) {
    if (endOffset != null && offset >= endOffset!) return;
    final current = firstBoundaryOffset;
    if (current == null || offset < current) firstBoundaryOffset = offset;
  }
}

bool _isSimpleTerminalStateBranch(Statement statement, Expression condition) {
  if (statement is! Block || statement.statements.isEmpty) return false;
  final terminal = statement.statements.last;
  final isTerminalThrow = terminal is ExpressionStatement && terminal.expression is ThrowExpression;
  if (terminal is! ReturnStatement && !isTerminalThrow) return false;
  if (!statement.statements.take(statement.statements.length - 1).every(_isStateWriteStatement)) {
    return false;
  }
  final safety = _TerminalBranchSafetyVisitor();
  condition.accept(safety);
  statement.accept(safety);
  return !safety.hasResourceOperation;
}

bool _isStateWriteStatement(Statement statement) {
  if (statement is! ExpressionStatement || statement.expression is! AssignmentExpression) {
    return false;
  }
  final target = (statement.expression as AssignmentExpression).leftHandSide;
  return target is SimpleIdentifier && target.name == 'state' ||
      target is PropertyAccess &&
          target.target is ThisExpression &&
          target.propertyName.name == 'state';
}

final class _TerminalBranchSafetyVisitor extends RecursiveAstVisitor<void> {
  bool hasResourceOperation = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasResourceOperation = true;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final receiverType = node.target?.staticType;
    final isResourceOperation =
        _isMutationDependencyRead(node) ||
        _isResolvedFutureDependencyAcquisitionFromCall(node) ||
        _isRepositoryOrServiceType(receiverType) ||
        _isRepositoryOrServiceType(node.staticType) && !_isRepositoryOrServiceType(receiverType);
    if (isResourceOperation) hasResourceOperation = true;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isRepositoryOrServiceType(node.target?.staticType) ||
        _isRepositoryOrServiceType(node.staticType)) {
      hasResourceOperation = true;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    hasResourceOperation = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    hasResourceOperation = true;
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    hasResourceOperation = true;
  }
}

bool _isResolvedFutureDependencyAcquisitionFromCall(MethodInvocation call) {
  final futureType = call.staticType;
  if (futureType is! InterfaceType) return false;
  final uri = futureType.element.library.uri;
  return uri.scheme == 'dart' &&
      uri.pathSegments.firstOrNull == 'async' &&
      {'Future', 'FutureOr'}.contains(futureType.element.name) &&
      futureType.typeArguments.length == 1 &&
      _isDependencyCaptureType(futureType.typeArguments.single);
}

bool _isDependencyCaptureType(DartType type) =>
    _isRepositoryOrServiceType(type) ||
    type is RecordType && _hasRepositoryOrServiceRecordField(type);

bool _usesConstructorInjectedDependencies(
  SourceScannerContext context,
  ScannerClassSpan classSpan,
  ScannerMethodSpan method,
) {
  final body = context.source.masked.sublist(method.start, method.end + 1).join('\n');
  if (body.contains('ref.read(') || _hasNullRepositoryReturn(body)) return false;
  final dependencies = RegExp(r'\b(_[A-Za-z0-9_]*(?:repo|repository)[A-Za-z0-9_]*)\b')
      .allMatches(body)
      .map((match) => match.group(1)!)
      .toSet();
  if (dependencies.isEmpty) return false;
  final declaration = context.unit.declarations
      .whereType<ClassDeclaration>()
      .where((candidate) => candidate.namePart.typeName.lexeme == classSpan.name)
      .firstOrNull;
  if (declaration == null) return false;
  final fields = _nonNullableInjectedFields(declaration);
  if (!fields.containsAll(dependencies)) return false;
  return _allConstructorsInject(declaration, dependencies);
}

Set<String> _nonNullableInjectedFields(ClassDeclaration declaration) {
  final fields = <String>{};
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    if (!field.fields.isFinal || field.fields.isLate) continue;
    for (final variable in field.fields.variables) {
      final type = variable.declaredFragment?.element.type;
      if (variable.initializer == null &&
          type != null &&
          type is! DynamicType &&
          type.nullabilitySuffix == NullabilitySuffix.none) {
        fields.add(variable.name.lexeme);
      }
    }
  }
  return fields;
}

bool _allConstructorsInject(ClassDeclaration declaration, Set<String> dependencies) {
  final constructors = declaration.body.members.whereType<ConstructorDeclaration>().toList();
  if (constructors.isEmpty ||
      constructors.any((constructor) => constructor.factoryKeyword != null)) {
    return false;
  }
  return constructors.every((constructor) {
    final injected = constructor.parameters.parameters
        .whereType<FieldFormalParameter>()
        .map((parameter) => parameter.name.lexeme)
        .toSet();
    return injected.containsAll(dependencies);
  });
}

bool _hasMutationDependency(String line) =>
    line.contains('_repository') || line.contains('_repo') || line.contains('Repository');

bool _hasNullRepositoryReturn(String line) =>
    RegExp(r'if\s*\(\s*_\w*(?:repo|repository)\w*\s*==\s*null\s*\)\s*return').hasMatch(line);
