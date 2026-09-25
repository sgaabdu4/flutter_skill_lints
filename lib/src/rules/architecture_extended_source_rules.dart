import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> architectureExtendedSourceRules = [
  /// Data models should expose a toEntity() mapper.
  ///
  /// Why: Flags data model files whose model classes do not expose toEntity(). The mapper may be
  /// a model method (`toEntity()`, or hive-persistence.md's `toDomain()`) or a mapper extension
  /// on the model (value-objects.md Option B, e.g. `/data/mappers/`). Add a toEntity() method on
  /// data models and map in repositories.
  scannerRule(
    code: const LintCode(
      'arch_model_missing_to_entity',
      'Data models should expose a toEntity() mapper.',
      correctionMessage: 'Add a toEntity() method on data models and map in repositories.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags data model files whose model classes do not expose toEntity() so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/')) return;
      if (!RegExp(r'\bclass\s+\w+Model\b').hasMatch(context.source.masked.join('\n'))) {
        return;
      }
      if (context.source.masked.any((line) => RegExp(r'\btoEntity\s*\(').hasMatch(line))) {
        return;
      }
      if (_hasModelMapper(context.unit)) return;
      reporter.report(context, 0, 0);
    },
  ),

  /// Repositories map Data -> Domain with the model mapper.
  ///
  /// Why: architecture.md requires `model.toEntity()` in repositories. Flags repository code
  /// that constructs a domain entity (a `/domain/` class outside `/domain/values/`) from data
  /// model (`/data/models/`) members instead of calling the model mapper.
  scannerRule(
    code: const LintCode(
      'arch_repository_inline_entity_mapping',
      'Repositories must map data models with toEntity().',
      correctionMessage:
          'Call model.toEntity() and keep the Data -> Domain mapping on the model or its mapper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags repositories that build domain entities from data model fields instead of calling toEntity().',
    scan: (reporter, context) {
      if (context.isTestFile || !context.isRepositoryPath) return;
      final visitor = _InlineEntityMappingVisitor();
      context.unit.accept(visitor);
      for (final node in visitor.mappings) {
        reporter.reportOffset(context, node.offset);
      }
    },
  ),

  /// Data models must be separate from domain entities.
  ///
  /// Why: Flags data models that inherit from likely domain entities. Keep model and entity
  /// classes separate; map with toEntity().
  scannerRule(
    code: const LintCode(
      'arch_model_extends_entity',
      'Data models must be separate from domain entities.',
      correctionMessage: 'Keep model and entity classes separate; map with toEntity().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags data models that inherit from likely domain entities so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/data/models/')) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bclass\s+\w+Model\s+extends\s+(?!\w+Model\b)\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('extends'));
        }
      }
    },
  ),

  /// Domain entities must not use JSON annotations.
  ///
  /// Why: Flags JSON annotations in domain files. Move JSON keys and serialization
  /// annotations to data models.
  scannerRule(
    code: const LintCode(
      'arch_domain_json_annotation',
      'Domain entities must not use JSON annotations.',
      correctionMessage: 'Move JSON keys and serialization annotations to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags JSON annotations in domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\b(?:JsonKey|JsonSerializable|FreezedUnionValue)\b').hasMatch(line)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];

const _entityMapperNames = {'toEntity', 'toDomain'};

bool _declaresEntityMapper(ClassBody body) =>
    body is BlockClassBody &&
    body.members.whereType<MethodDeclaration>().any(
      (method) => _entityMapperNames.contains(method.name.lexeme),
    );

bool _hasModelMapper(CompilationUnit unit) {
  final models = [
    for (final declaration in unit.declarations.whereType<ClassDeclaration>())
      if (declaration.declaredFragment?.element case final model?
          when model.name?.endsWith('Model') ?? false)
        (declaration: declaration, element: model),
  ];
  for (final model in models) {
    if (_declaresEntityMapper(model.declaration.body)) return true;
    final sameUnitExtension = unit.declarations.whereType<ExtensionDeclaration>().any(
      (extension) =>
          extension.declaredFragment?.element.extendedType.element == model.element &&
          _declaresEntityMapper(extension.body),
    );
    if (sameUnitExtension || _hasMapperExtensionElsewhere(model.element)) return true;
  }
  return false;
}

final _mapperExtensionTargets = Expando<Set<String>>('flutter_skill_lints_mapper_extensions');

/// Whether another analyzed `lib/` file declares a toEntity()/toDomain() extension on [model].
///
/// Other libraries are only available parsed here, so an extension target is keyed by the
/// extended type name plus each library that file imports; the model matches when its own
/// library URI and name are among them.
bool _hasMapperExtensionElsewhere(ClassElement model) {
  final session = model.library.session;
  final targets = _mapperExtensionTargets[session] ??= _indexMapperExtensionTargets(session);
  return targets.contains('${model.library.uri}#${model.name}');
}

Set<String> _indexMapperExtensionTargets(AnalysisSession session) {
  final targets = <String>{};
  for (final path in session.analysisContext.contextRoot.analyzedFiles()) {
    if (_mayDeclareMapperExtension(session, path)) {
      _addMapperExtensionTargets(session, path, targets);
    }
  }
  return targets;
}

bool _mayDeclareMapperExtension(AnalysisSession session, String path) {
  final normalized = path.replaceAll('\\', '/');
  if (!normalized.endsWith('.dart') || !normalized.contains('/lib/')) return false;
  final String content;
  try {
    content = session.resourceProvider.getFile(path).readAsStringSync();
  } on FileSystemException {
    return false;
  }
  return content.contains('extension') && _entityMapperNames.any(content.contains);
}

void _addMapperExtensionTargets(AnalysisSession session, String path, Set<String> targets) {
  final parsed = session.getParsedUnit(path);
  final fileUri = session.uriConverter.pathToUri(path);
  if (parsed is! ParsedUnitResult || fileUri == null) return;
  final libraryUris = [
    fileUri,
    for (final directive in parsed.unit.directives.whereType<ImportDirective>())
      if (directive.uri.stringValue case final uri?) fileUri.resolve(uri),
  ];
  for (final extension in parsed.unit.declarations.whereType<ExtensionDeclaration>()) {
    final extendedType = extension.onClause?.extendedType;
    if (extendedType is! NamedType || !_declaresEntityMapper(extension.body)) continue;
    for (final uri in libraryUris) {
      targets.add('$uri#${extendedType.name.lexeme}');
    }
  }
}

final class _InlineEntityMappingVisitor extends RecursiveAstVisitor<void> {
  final mappings = <InstanceCreationExpression>[];

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructed = node.constructorName.element?.enclosingElement;
    if (_isDomainEntity(constructed) && _readsDataModel(node.argumentList)) {
      mappings.add(node);
      return;
    }
    super.visitInstanceCreationExpression(node);
  }
}

bool _isDomainEntity(Element? element) {
  if (element is! InterfaceElement) return false;
  final path = element.library.uri.path;
  return path.contains('/domain/') && !path.contains('/domain/values/');
}

bool _readsDataModel(ArgumentList arguments) {
  final visitor = _DataModelReadVisitor();
  arguments.accept(visitor);
  return visitor.found;
}

final class _DataModelReadVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    found = found || _isDataModel(node.prefix.staticType?.element);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    found = found || _isDataModel(node.realTarget.staticType?.element);
    super.visitPropertyAccess(node);
  }
}

bool _isDataModel(Element? element) =>
    element is InterfaceElement && element.library.uri.path.contains('/data/models/');
