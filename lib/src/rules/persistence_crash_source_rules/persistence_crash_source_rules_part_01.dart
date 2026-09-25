part of '../persistence_crash_source_rules.dart';

bool _isHiveAnnotation(ElementAnnotation? annotation, String className) =>
    isPackageAnnotation(annotation, 'hive_ce', className);

bool _isRiverpodNotifierType(InterfaceType type) {
  final uri = type.element.library.uri;
  final isRiverpod =
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      const {'riverpod', 'flutter_riverpod', 'hooks_riverpod'}.contains(uri.pathSegments.first);
  return isRiverpod && (type.element.name ?? '').contains('Notifier');
}

final class _HiveReferenceVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitNamedType(NamedType node) {
    if (_isHiveLibrary(node.element?.library)) offsets.add(node.offset);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    final isMember =
        (parent is MethodInvocation && parent.methodName == node && parent.target != null) ||
        (parent is PropertyAccess && parent.propertyName == node) ||
        (parent is PrefixedIdentifier && parent.identifier == node);
    if (!isMember && _isHiveLibrary(node.element?.library)) offsets.add(node.offset);
    super.visitSimpleIdentifier(node);
  }
}

bool _isHiveLibrary(LibraryElement? library) {
  final uri = library?.uri;
  return uri != null &&
      uri.scheme == 'package' &&
      uri.pathSegments.isNotEmpty &&
      const {'hive_ce', 'hive_ce_flutter'}.contains(uri.pathSegments.first);
}

Iterable<Annotation> _unitAnnotations(CompilationUnit unit) sync* {
  for (final declaration in unit.declarations) {
    yield* declaration.metadata;
  }
}

void _reportDuplicateHiveFieldIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  for (final declaration in context.unit.declarations) {
    final memberMetadata = switch (declaration) {
      ClassDeclaration(body: BlockClassBody(:final members)) => [
        for (final member in members) member.metadata,
      ],
      EnumDeclaration(:final body) => [
        for (final constant in body.constants) constant.metadata,
        for (final member in body.members) member.metadata,
      ],
      _ => const <NodeList<Annotation>>[],
    };
    final seen = <int>{};
    for (final annotation in memberMetadata.expand((metadata) => metadata)) {
      if (!_isHiveAnnotation(annotation.elementAnnotation, 'HiveField')) continue;
      final index = annotation.elementAnnotation
          ?.computeConstantValue()
          ?.getField('index')
          ?.toIntValue();
      if (index != null && !seen.add(index)) _reportAtOffset(reporter, context, annotation.offset);
    }
  }
}

/// A resolved `@HiveType(typeId: n)` declaration.
final class _HiveTypeFact {
  const _HiveTypeFact(this.element, this.typeId);

  final Element element;
  final int typeId;
}

/// A resolved `@GenerateAdapters(..., reservedTypeIds: {...})` declaration.
final class _HiveAdapterFact {
  const _HiveAdapterFact(this.element, this.reservedTypeIds);

  final Element element;
  final Set<int> reservedTypeIds;
}

final class _HiveFacts {
  final types = <_HiveTypeFact>[];
  final adapters = <_HiveAdapterFact>[];

  void addAll(_HiveFacts other) {
    types.addAll(other.types);
    adapters.addAll(other.adapters);
  }

  bool containsAll(Iterable<Element> elements) {
    final declared = {
      for (final fact in types) fact.element,
      for (final fact in adapters) fact.element,
    };
    return elements.every(declared.contains);
  }
}

/// The Hive facts reachable through one import or export directive of the unit.
final class _HiveImportScope {
  const _HiveImportScope(this.directive, this.facts);

  final NamespaceDirective directive;
  final _HiveFacts facts;
}

final _localHiveFactsCache = Expando<_HiveFacts>('flutter_skill_lints_local_hive_facts');
final _reachableHiveFactsCache = Expando<_HiveFacts>('flutter_skill_lints_reachable_hive_facts');

/// The `typeId` of a resolved hive_ce `@HiveType`, or null for any other annotation.
int? _hiveTypeId(ElementAnnotation? annotation) => _isHiveAnnotation(annotation, 'HiveType')
    ? annotation?.computeConstantValue()?.getField('typeId')?.toIntValue()
    : null;

/// The `reservedTypeIds` of a resolved hive_ce `@GenerateAdapters`, or null for any
/// other annotation.
Set<int>? _reservedTypeIds(ElementAnnotation? annotation) {
  if (!_isHiveAnnotation(annotation, 'GenerateAdapters')) return null;
  final reserved = annotation?.computeConstantValue()?.getField('reservedTypeIds')?.toSetValue();
  return reserved?.map((value) => value.toIntValue()).whereType<int>().toSet();
}

_HiveFacts _localHiveFacts(LibraryElement library) {
  final cached = _localHiveFactsCache[library];
  if (cached != null) return cached;
  final facts = _HiveFacts();
  for (final element in library.children) {
    for (final annotation in element.metadata.annotations) {
      final typeId = _hiveTypeId(annotation);
      if (typeId != null) facts.types.add(_HiveTypeFact(element, typeId));
      final reserved = _reservedTypeIds(annotation);
      if (reserved != null) facts.adapters.add(_HiveAdapterFact(element, reserved));
    }
  }
  _localHiveFactsCache[library] = facts;
  return facts;
}

/// Walks same-package libraries depth-first from [roots], visiting each once.
/// [visit] returns whether to continue into the library's imports and exports.
void _walkPackageLibraries(
  Iterable<LibraryElement> roots,
  String packageRoot,
  bool Function(LibraryElement library) visit,
) {
  final pending = [...roots];
  final seen = <LibraryElement>{};
  while (pending.isNotEmpty) {
    final library = pending.removeLast();
    if (!seen.add(library) || !_isPackageLibrary(library, packageRoot)) continue;
    if (visit(library)) pending.addAll(_libraryDependencies(library));
  }
}

/// Facts declared in [root] and every same-package library its imports reach.
_HiveFacts _reachableHiveFacts(LibraryElement root, String packageRoot) {
  final cached = _reachableHiveFactsCache[root];
  if (cached != null) return cached;
  final facts = _HiveFacts();
  _walkPackageLibraries([root], packageRoot, (library) {
    facts.addAll(_localHiveFacts(library));
    return true;
  });
  _reachableHiveFactsCache[root] = facts;
  return facts;
}

List<LibraryElement> _libraryDependencies(LibraryElement library) => [
  for (final fragment in library.fragments) ...fragment.importedLibraries,
  ...library.exportedLibraries,
];

bool _isPackageLibrary(LibraryElement library, String packageRoot) =>
    library.firstFragment.source.fullName.replaceAll('\\', '/').startsWith(packageRoot);

String _packageRoot(SourceScannerContext context) {
  final path = context.unit.declaredFragment?.source.fullName.replaceAll('\\', '/') ?? '';
  return path.endsWith(context.path) ? path.substring(0, path.length - context.path.length) : path;
}

/// Import scopes of the defining unit. A generated library (for example the Hive
/// registrar) is not analyzed, so its own imports stand in for it.
List<_HiveImportScope> _hiveImportScopes(CompilationUnit unit, String packageRoot) {
  final scopes = <_HiveImportScope>[];
  for (final directive in unit.directives.whereType<NamespaceDirective>()) {
    final imported = switch (directive) {
      ImportDirective() => directive.libraryImport?.importedLibrary,
      ExportDirective() => directive.libraryExport?.exportedLibrary,
    };
    if (imported == null) continue;
    _walkPackageLibraries([imported], packageRoot, (library) {
      if (isGeneratedSourcePath(library.firstFragment.source.fullName)) return true;
      scopes.add(_HiveImportScope(directive, _reachableHiveFacts(library, packageRoot)));
      return false;
    });
  }
  return scopes;
}

/// A Hive fact seen through the import scope at [scope].
typedef _ScopedHiveFact = ({Object fact, Element element, int scope});

Element _hiveFactElement(Object fact) => switch (fact) {
  _HiveTypeFact(:final element) || _HiveAdapterFact(:final element) => element,
  _ => throw ArgumentError.value(fact, 'fact'),
};

/// Facts reachable through [scopes] that are not declared in [localElements].
List<_ScopedHiveFact> _nonLocalHiveFacts(
  List<_HiveImportScope> scopes,
  Set<Element> localElements,
) => [
  for (var index = 0; index < scopes.length; index++)
    for (final fact in [...scopes[index].facts.types, ...scopes[index].facts.adapters])
      if (!localElements.contains(_hiveFactElement(fact)))
        (fact: fact, element: _hiveFactElement(fact), scope: index),
];

/// Whether [first] and [second] conflict and no single scope already contains both.
bool _meetsFirstInUnit(
  List<_HiveImportScope> scopes,
  _ScopedHiveFact first,
  _ScopedHiveFact second,
  bool Function(Object first, Object second) conflicts,
) =>
    first.element != second.element &&
    conflicts(first.fact, second.fact) &&
    !scopes.any((scope) => scope.facts.containsAll([first.element, second.element]));

/// Directives where two non-local facts first meet: no single import scope already
/// contains both, so no deeper analyzed library reports the pair.
Set<NamespaceDirective> _joinDirectives(
  List<_HiveImportScope> scopes,
  Set<Element> localElements,
  bool Function(Object first, Object second) conflicts,
) {
  final facts = _nonLocalHiveFacts(scopes, localElements);
  return {
    for (var i = 0; i < facts.length; i++)
      for (var j = i + 1; j < facts.length; j++)
        if (_meetsFirstInUnit(scopes, facts[i], facts[j], conflicts))
          scopes[math.max(facts[i].scope, facts[j].scope)].directive,
  };
}

bool _isDefiningUnit(SourceScannerContext context, LibraryElement library) =>
    context.unit.declaredFragment == library.firstFragment;

void _reportDuplicateHiveTypeIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  final library = context.unit.declaredFragment?.element;
  if (library == null) return;
  final packageRoot = _packageRoot(context);
  final reachable = _reachableHiveFacts(library, packageRoot);
  final seenInUnit = <int, Element>{};
  for (final declaration in context.unit.declarations) {
    final element = declaration.declaredFragment?.element;
    if (element == null) continue;
    for (final annotation in declaration.metadata) {
      final typeId = _hiveTypeId(annotation.elementAnnotation);
      if (typeId == null) continue;
      final earlier = seenInUnit.putIfAbsent(typeId, () => element);
      if (earlier != element || _collidesOutsideUnit(context, reachable, typeId, element)) {
        _reportAtOffset(reporter, context, annotation.offset);
      }
    }
  }
  if (_isDefiningUnit(context, library)) {
    _reportDuplicateHiveTypeIdJoins(reporter, context, library, packageRoot);
  }
}

/// Whether a @HiveType declared outside this unit but reachable from it reuses [typeId].
bool _collidesOutsideUnit(
  SourceScannerContext context,
  _HiveFacts reachable,
  int typeId,
  Element element,
) => reachable.types.any(
  (fact) =>
      fact.typeId == typeId &&
      fact.element != element &&
      fact.element.firstFragment.libraryFragment != context.unit.declaredFragment,
);

void _reportDuplicateHiveTypeIdJoins(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  LibraryElement library,
  String packageRoot,
) {
  final local = _localHiveFacts(library).types.map((fact) => fact.element).toSet();
  final joins = _joinDirectives(
    _hiveImportScopes(context.unit, packageRoot),
    local,
    (first, second) =>
        first is _HiveTypeFact && second is _HiveTypeFact && first.typeId == second.typeId,
  );
  for (final directive in joins) {
    _reportAtOffset(reporter, context, directive.offset);
  }
}

void _reportUnreservedHiveTypeIds(ScannerRuleReporter reporter, SourceScannerContext context) {
  final library = context.unit.declaredFragment?.element;
  if (library == null) return;
  final packageRoot = _packageRoot(context);
  final reachable = _reachableHiveFacts(library, packageRoot);
  for (final annotation in _unitAnnotations(context.unit)) {
    final ids = _reservedTypeIds(annotation.elementAnnotation);
    if (ids == null) continue;
    if (reachable.types.any((fact) => !ids.contains(fact.typeId))) {
      _reportAtOffset(reporter, context, annotation.offset);
    }
  }
  if (!_isDefiningUnit(context, library)) return;
  final localFacts = _localHiveFacts(library);
  final scopes = _hiveImportScopes(context.unit, packageRoot);
  final directives = {
    ..._joinDirectives(scopes, {
      for (final fact in localFacts.types) fact.element,
      for (final fact in localFacts.adapters) fact.element,
    }, _isUnreservedPair),
    // A local @HiveType meets an imported @GenerateAdapters here.
    for (final scope in scopes)
      if (localFacts.types.any(
        (type) => scope.facts.adapters.any((adapter) => _isUnreservedPair(adapter, type)),
      ))
        scope.directive,
  };
  for (final directive in directives) {
    _reportAtOffset(reporter, context, directive.offset);
  }
}

bool _isUnreservedPair(Object first, Object second) => switch ((first, second)) {
  (final _HiveAdapterFact adapter, final _HiveTypeFact type) ||
  (
    final _HiveTypeFact type,
    final _HiveAdapterFact adapter,
  ) => !adapter.reservedTypeIds.contains(type.typeId),
  _ => false,
};
