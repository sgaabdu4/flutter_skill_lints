import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_consumer_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> architectureSourceRules = [
  /// Domain code must stay pure Dart.
  ///
  /// Why: Flags Flutter or package imports from domain files. Domain may only
  /// import freezed_annotation and other /domain/ paths (other entities or Value
  /// Objects). For shared primitive logic, create a Value Object (sealed Freezed
  /// class) in /domain/values/. For one-off derivation, add an entity
  /// getter. Never import core/extensions/ — that violates the Clean Architecture
  /// Dependency Rule (inner layer must not depend on outer).
  scannerRule(
    code: const LintCode(
      'arch_domain_import',
      'Domain code must stay pure Dart.',
      correctionMessage:
          'Domain may only import freezed_annotation and other /domain/ paths. '
          'For shared primitive logic, create a Value Object in '
          '/domain/values/ (sealed Freezed class). For one-off derivation, '
          'add an entity getter. See building-flutter-apps SKILL.md Critical Rule 11 + 12.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags Flutter or package imports from domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.isDomainPath) return;
      for (final directive in context.unit.directives.whereType<ImportDirective>()) {
        final uri = _resolvedImportUri(context, directive);
        if (uri == null || _isAllowedDomainImport(uri)) continue;
        reporter.reportOffset(context, directive.offset);
      }
    },
  ),

  /// Storage SDKs live in local datasources only.
  ///
  /// Why: architecture.md forbids `dart:io`, Hive CE, SharedPreferences, secure storage, and
  /// path_provider imports in `presentation/`, `*_notifier.dart`, `*_service.dart`, and
  /// `*_repository.dart` files. Storage lives in `Local<X>Datasource`, exposed via
  /// `<X>Repository`. Reusable presentation widgets report the same imports through
  /// `presentation_widget_infrastructure_dependency`.
  scannerRule(
    code: const LintCode(
      'arch_storage_sdk_import',
      'Storage SDK imports belong in local datasources.',
      correctionMessage:
          'Move the storage SDK or dart:io call into a Local<X>Datasource and expose it '
          'through the <X>Repository interface.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags storage SDK and dart:io imports in presentation, notifier, service, and repository files.',
    scan: (reporter, context) {
      if (context.isTestFile || context.isPresentationWidgetFile) return;
      if (!_isStorageSdkForbiddenFile(context.path)) return;
      for (final directive in context.unit.directives.whereType<ImportDirective>()) {
        final uri = _resolvedImportUri(context, directive);
        if (uri == null || !_isStorageSdkImport(uri)) continue;
        reporter.reportOffset(context, directive.offset);
      }
    },
  ),

  /// Domain code must not own JSON serialization.
  ///
  /// Why: Flags JSON serialization members in domain files. Move fromJson/toJson code to data
  /// models.
  scannerRule(
    code: const LintCode(
      'arch_domain_serialization',
      'Domain code must not own JSON serialization.',
      correctionMessage: 'Move fromJson/toJson code to data models.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags JSON serialization members in domain files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isDomainPath &&
            RegExp(r'\b(?:fromJson|toJson|_\$\w+FromJson)\s*\(')
                .hasMatch(context.source.masked[i])) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),

  /// Repositories and datasources need interface contracts.
  ///
  /// Why: Flags repository or datasource files without I* contracts. Add an abstract
  /// interface class for this layer.
  scannerRule(
    code: const LintCode(
      'arch_interface_contract',
      'Repositories and datasources need interface contracts.',
      correctionMessage: 'Add an abstract interface class for this layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags repository or datasource files without I* contracts so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      if ((context.isDatasourcePath || context.isRepositoryPath) &&
          _hasConcreteLayerWithoutInterface(context)) {
        reporter.report(context, 0, 0);
      }
    },
  ),

  /// Repositories should implement contracts, not generated bases.
  ///
  /// Why: Flags repository classes extending generated _$Repository bases. Keep
  /// generated Riverpod classes on notifiers; concrete repositories implement I* contracts.
  scannerRule(
    code: const LintCode(
      'arch_repository_generated_extends',
      'Repositories must implement interfaces instead of extending generated bases.',
      correctionMessage:
          'Use a concrete repository that implements I*Repository, not extends _\$*Repository.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags repositories extending generated classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final generatedRepository = RegExp(r'\bclass\s+\w+Repository\s+extends\s+_\$\w+Repository\b');
      for (var i = 0; i < context.source.length; i++) {
        final match = generatedRepository.firstMatch(context.source.masked[i]);
        if (match != null && !context.hasNearbyAnnotation(i, const {'riverpod', 'Riverpod'})) {
          reporter.report(context, i, context.source.masked[i].indexOf('extends'));
        }
      }
    },
  ),

  /// Layer constructors and providers should use interfaces.
  ///
  /// Why: Flags concrete repository or datasource constructor dependencies, and repository or
  /// datasource providers whose declared return type is a concrete class implementing an
  /// abstract interface class. Take and return I*Repository/I*Datasource interfaces instead.
  scannerRule(
    code: const LintCode(
      'arch_concrete_dependency',
      'Layer constructors and providers should use interfaces.',
      correctionMessage:
          'Take I*Repository/I*Datasource interfaces in constructors and return the interface '
          'type from providers instead of concrete classes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags concrete repository or datasource constructor dependencies and provider return types so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isRepositoryPath && !context.isDatasourcePath) return;
      for (var i = 0; i < context.source.length; i++) {
        if (context.hasConcreteLayerDependencyLine(context.source.masked[i])) {
          reporter.report(context, i, 0);
        }
      }
      for (final function in context.unit.declarations.whereType<FunctionDeclaration>()) {
        if (!hasAnnotationNamed(function, const {'riverpod', 'Riverpod'})) continue;
        final returnType = function.returnType;
        final element = function.declaredFragment?.element;
        if (returnType == null || element == null) continue;
        if (_isConcreteImplementationOfInterface(_unwrapFuture(element.returnType))) {
          reporter.reportOffset(context, returnType.offset);
        }
      }
    },
  ),

  /// Don't catch in a datasource only to rethrow.
  ///
  /// Why: A trailing catch clause that only rethrows adds nothing. Datasources may
  /// catch to translate, classify, recover or roll back; otherwise let errors
  /// propagate to the notifier boundary.
  scannerRule(
    code: const LintCode(
      'arch_datasource_try_catch',
      "Don't catch in a datasource only to rethrow.",
      correctionMessage: 'Delete the catch and let errors propagate to the notifier boundary, or translate, recover or roll back in it.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags datasource catch clauses that only rethrow, while allowing translation, recovery and rollback catches.',
    scan: (reporter, context) {
      if (!context.isDatasourcePath) return;
      final finder = _RethrowOnlyCatchFinder();
      context.unit.accept(finder);
      for (final clause in finder.clauses) {
        final location = context.unit.lineInfo.getLocation(clause.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
      }
    },
  ),

  /// Feature widgets belong under presentation/widgets.
  ///
  /// Why: Flags feature widgets outside presentation/widgets. Move feature widgets into the
  /// presentation layer.
  scannerRule(
    code: const LintCode(
      'arch_widget_path',
      'Feature widgets belong under presentation/widgets.',
      correctionMessage: 'Move feature widgets into the presentation layer.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags feature widgets outside presentation/widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isFeatureWidgetWrongPath) return;
      for (var i = 0; i < context.source.length; i++) {
        reporter.report(context, i, 0);
      }
    },
  ),

  /// Atomic design widgets should not access providers directly.
  ///
  /// Why: Flags provider access from atomic design widgets. Move provider access to the
  /// presentation boundary.
  scannerRule(
    code: const LintCode(
      'atomic_provider_access',
      'Atomic design widgets should not access providers directly.',
      correctionMessage: 'Move provider access to the presentation boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags provider access from atomic design widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isAtomicNoProviderPath &&
            RegExp(r'\bref\s*\.\s*(?:read|watch)\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ref'));
        }
      }
    },
  ),

  /// Pages must be Riverpod consumer widgets.
  ///
  /// Why: atomic-design pages connect state to layout, so every public screen
  /// widget extends ConsumerWidget or ConsumerStatefulWidget.
  scannerRule(
    code: const LintCode(
      'atomic_page_consumer_widget',
      'Screens must extend ConsumerWidget or ConsumerStatefulWidget.',
      correctionMessage: 'Extend ConsumerWidget or ConsumerStatefulWidget and connect state here.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags public screen widgets that are not Riverpod consumer widgets.',
    scan: (reporter, context) {
      if (context.isTestFile || !context.path.contains('/presentation/screens/')) return;

      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final element = declaration.declaredFragment?.element;
        if (element == null ||
            element.isPrivate ||
            element.isAbstract ||
            !_flutterWidgetChecker.isSuperOf(element) ||
            _consumerPageChecker.isSuperOf(element)) {
          continue;
        }
        final name = declaration.namePart.typeName;
        final location = context.unit.lineInfo.getLocation(name.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
      }
    },
  ),

  /// Use typed IDs for entities with multiple String IDs.
  ///
  /// Why: The skill forbids raw `String`/`int` IDs once a feature has several ID types.
  /// Flags domain files with two or more resolved `String`/`int` `...Id` fields or Freezed
  /// redirect parameters. Use extension types or value objects for IDs.
  scannerRule(
    code: const LintCode(
      'typed_id_raw_id',
      'Use typed IDs for entities with multiple String IDs.',
      correctionMessage: 'Use extension types or value objects for IDs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags domain files with multiple raw String/int ID fields or Freezed redirect parameters so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      final idOffsets = _rawIdOffsets(context.unit);
      if (idOffsets.length > 1) {
        reporter.report(
          context,
          context.unit.lineInfo.getLocation(idOffsets.first).lineNumber - 1,
          0,
        );
      }
    },
  ),

  /// Avoid Map<String, dynamic> for non-data multi-value returns.
  ///
  /// Why: Flags non-data helpers returning Map<String, dynamic> tuples. Use records or typed
  /// objects.
  scannerRule(
    code: const LintCode(
      'records_map_return',
      'Avoid Map<String, dynamic> for non-data multi-value returns.',
      correctionMessage: 'Use records or typed objects.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags non-data helpers returning Map<String, dynamic> tuples so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isMapDynamicReturn(line)) {
          reporter.report(context, i, line.indexOf('Map'));
        }
      }
    },
  ),

  /// Cast untyped map boundaries to Map<String, dynamic>.
  ///
  /// Why: Flags `as Map<String, Object?>` casts. JSON/runtime map casts need
  /// `dynamic` values so downstream JSON access stays explicit and consistent.
  scannerRule(
    code: const LintCode(
      'avoid_object_map_cast',
      'Cast untyped map boundaries to Map<String, dynamic>.',
      correctionMessage: 'Use `as Map<String, dynamic>` at runtime map boundaries.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags Map<String, Object?> casts so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final objectMapCast = RegExp(r'\bas\s+Map\s*<\s*String\s*,\s*Object\?\s*>');
      for (var i = 0; i < context.source.length; i++) {
        final match = objectMapCast.firstMatch(context.source.masked[i]);
        if (match != null) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),
];

bool _hasConcreteLayerWithoutInterface(SourceScannerContext context) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.abstractKeyword != null) continue;
    final concreteName = declaration.namePart.typeName.lexeme;
    if (!concreteName.endsWith('Repository') && !concreteName.endsWith('Datasource')) continue;
    final role = concreteName.endsWith('Repository') ? 'Repository' : 'Datasource';
    if (!_implementsLayerContract(declaration, role)) return true;
  }
  return false;
}

bool _implementsLayerContract(ClassDeclaration declaration, String role) {
  final interfaces = declaration.implementsClause?.interfaces ?? <NamedType>[];
  return interfaces.any((interface) => _isLayerContract(interface.element, role));
}

bool _isLayerContract(Element? element, String role) {
  if (element is! ClassElement) return false;
  final name = element.name;
  return name != null &&
      name.startsWith('I') &&
      name.endsWith(role) &&
      element.isAbstract &&
      element.isInterface;
}

/// Domain allows pure Dart SDK libraries, freezed_annotation, and /domain/ libraries only.
bool _isAllowedDomainImport(Uri uri) {
  if (uri.isScheme('dart')) return uri.path != 'io' && uri.path != 'ui';
  if (uri.toString() == 'package:freezed_annotation/freezed_annotation.dart') return true;
  return uri.path.contains('/domain/');
}

DartType _unwrapFuture(DartType type) {
  if (type is InterfaceType &&
      type.element.library.isDartAsync &&
      (type.element.name == 'Future' || type.element.name == 'FutureOr') &&
      type.typeArguments.length == 1) {
    return type.typeArguments.single;
  }
  return type;
}

/// A concrete class that implements an `abstract interface class` contract.
bool _isConcreteImplementationOfInterface(DartType type) {
  if (type is! InterfaceType) return false;
  final element = type.element;
  if (element is! ClassElement || element.isAbstract) return false;
  return element.allSupertypes.any((supertype) {
    final contract = supertype.element;
    return contract is ClassElement && contract.isAbstract && contract.isInterface;
  });
}

const _storageSdkPackages = {
  'hive_ce',
  'hive_ce_flutter',
  'shared_preferences',
  'flutter_secure_storage',
  'path_provider',
};

bool _isStorageSdkImport(Uri uri) {
  if (uri.isScheme('dart')) return uri.path == 'io';
  return uri.isScheme('package') &&
      uri.pathSegments.isNotEmpty &&
      _storageSdkPackages.contains(uri.pathSegments.first);
}

bool _isStorageSdkForbiddenFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.contains('/presentation/') ||
      normalized.endsWith('_notifier.dart') ||
      normalized.endsWith('_service.dart') ||
      normalized.endsWith('_repository.dart');
}

/// The imported library URI, with relative imports resolved against this library.
Uri? _resolvedImportUri(SourceScannerContext context, ImportDirective directive) {
  final importedLibrary = directive.libraryImport?.importedLibrary;
  if (importedLibrary != null) return importedLibrary.uri;
  final uri = directive.uri.stringValue;
  if (uri == null) return null;
  final libraryUri = context.unit.declaredFragment?.source.uri;
  return libraryUri == null ? Uri.tryParse(uri) : libraryUri.resolve(uri);
}

const _flutterWidgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
const _consumerPageChecker = TypeChecker.any([
  consumerWidgetChecker,
  consumerStatefulWidgetChecker,
]);

/// A trailing catch clause whose body is only `rethrow`. An earlier one can
/// still matter: it keeps its error type out of a later catch.
final class _RethrowOnlyCatchFinder extends RecursiveAstVisitor<void> {
  final clauses = <CatchClause>[];

  @override
  void visitTryStatement(TryStatement node) {
    final clause = node.catchClauses.lastOrNull;
    final statement = clause?.body.statements.singleOrNull;
    if (clause != null &&
        statement is ExpressionStatement &&
        statement.expression is RethrowExpression) {
      clauses.add(clause);
    }
    super.visitTryStatement(node);
  }
}

/// Offsets of `final String/int xId` fields and redirecting-factory parameters.
List<int> _rawIdOffsets(CompilationUnit unit) => unit.declarations
    .whereType<ClassDeclaration>()
    .expand((declaration) => declaration.body.members)
    .expand(
      (member) =>
          _idCandidates(member)
              .where((candidate) => _isRawId(candidate.name, candidate.type))
              .map((_) => member.firstTokenAfterCommentAndMetadata.offset),
    )
    .toList();

/// Each `final` field variable or redirecting-factory parameter of [member].
Iterable<({String name, DartType? type})> _idCandidates(ClassMember member) => switch (member) {
  FieldDeclaration(fields: VariableDeclarationList(isFinal: true, :final variables)) =>
    variables.map(
      (variable) => (name: variable.name.lexeme, type: variable.declaredFragment?.element.type),
    ),
  ConstructorDeclaration(redirectedConstructor: _?) => member.parameters.parameters.expand(
    (parameter) => [
      if (parameter.name case final name?)
        (name: name.lexeme, type: parameter.declaredFragment?.element.type),
    ],
  ),
  _ => const [],
};

bool _isRawId(String name, DartType? type) =>
    name.endsWith('Id') && type != null && (type.isDartCoreString || type.isDartCoreInt);
