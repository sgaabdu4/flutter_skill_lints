import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> stateSourceRules = [
  /// Avoid nullable collection types outside wire DTOs.
  ///
  /// Why: Empty collections represent "no items" better than nullable collection
  /// types. If "not loaded" or "not applicable" is a distinct state, model that
  /// as AsyncValue or a sealed union instead of `List<T>?` / `Map<K, V>?`.
  scannerRule(
    code: const LintCode(
      'nullable_collection_type',
      'Avoid nullable collection types.',
      correctionMessage: 'Use a non-nullable collection with an empty default. If null has distinct semantics, model that as AsyncValue or a sealed state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags nullable collection types so absence is modeled explicitly instead of with List?/Map?/Set?.',
    scan: (reporter, context) {
      if (context.isTestFile || context.isDataModelPath) return;
      context.unit.accept(_NullableCollectionVisitor(reporter, context));
    },
  ),

  /// Freezed state should not use empty strings as sentinels.
  ///
  /// Why: Empty string is valid transient input text, but it is a bad "missing"
  /// value for state. Use nullable optional strings for absence, Value Objects
  /// for required domain strings, or explicit draft/search/input field names for
  /// editable text.
  scannerRule(
    code: const LintCode(
      'state_empty_string_sentinel',
      'Do not use empty strings as state sentinels.',
      correctionMessage: 'Use String? for true absence, a validated Value Object for required domain text, or rename transient fields as draft/search/input text.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags empty-string defaults in Freezed state unless the field is explicit transient input/search/draft text.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (!classSpan.name.endsWith('State')) continue;
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final line = context.source.code[i];
          final match = _emptyStringDefault.firstMatch(line);
          if (match == null) continue;
          final name =
              match.namedGroup('defaultName') ??
              match.namedGroup('fieldName') ??
              match.namedGroup('thisName');
          if (name != null && _isTransientTextField(name)) continue;
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Do not encode boolean state as "1"/"0" string sentinels.
  ///
  /// Why: Boolean selectors, signatures, and state should carry boolean meaning
  /// directly. String sentinels hide the contract, make accidental wire-format
  /// coupling easy, and bypass type checking.
  scannerRule(
    code: const LintCode(
      'state_bool_string_sentinel',
      'Do not encode booleans as "1"/"0" strings.',
      correctionMessage: 'Keep the value as bool. If a wire protocol truly requires "1"/"0", convert at the datasource boundary with a named encoder.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags boolean ternaries that produce "1"/"0" string sentinels so state and selectors keep boolean meaning typed.',
    scan: (reporter, context) {
      if (context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final match = _boolStringSentinel.firstMatch(context.source.code[i]);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Do not store raw API responses in state.
  ///
  /// Why: Flags raw JSON or response values stored in UI state. Extract the fields needed by
  /// the UI.
  scannerRule(
    code: const LintCode(
      'state_raw_response',
      'Do not store raw API responses in state.',
      correctionMessage: 'Extract the fields needed by the UI.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags raw JSON or response values stored in UI state so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'\bstate\s*=\s*state\.copyWith\s*\([^)]*(?:rawJson|response|json)')
            .hasMatch(line)) {
          reporter.report(context, i, line.indexOf('state'));
        }
      }
    },
  ),

  /// Do not surface raw exception strings in state.
  ///
  /// Why: Flags String `error:` arguments built from the caught exception, such as
  /// `e.toString()`, `'Failed: $e'` or `e.message`. Translate failures to a typed
  /// AppError before they enter UI state.
  scannerRule(
    code: const LintCode(
      'state_raw_error_to_string',
      'Do not surface raw exception strings in state.',
      correctionMessage:
          'Store a typed AppError, for example AppError.from(e), instead of the exception text.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags String error arguments built from a caught exception or its toString so failures stay typed.',
    scan: (reporter, context) {
      final finder = _RawErrorStringFinder();
      context.unit.accept(finder);
      for (final node in finder.nodes) {
        final location = context.unit.lineInfo.getLocation(node.offset);
        reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
      }
    },
  ),

  /// Notifier state should not carry raw error strings.
  ///
  /// Why: AppError is the sole error type in notifier state. Flags String error
  /// fields and Freezed factory parameters in `*State` classes; a Flutter
  /// widget State is not notifier state.
  scannerRule(
    code: const LintCode(
      'state_freezed_nullable_error',
      'Do not store raw error strings in notifier state.',
      correctionMessage: 'Use a typed AppError field and pattern-match it in the UI.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags String error fields and factory parameters in state classes so failures stay typed as AppError.',
    scan: (reporter, context) {
      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final element = declaration.declaredFragment?.element;
        if (element == null || !(element.name ?? '').endsWith('State') || _isWidgetState(element)) {
          continue;
        }
        final body = declaration.body;
        if (body is! BlockClassBody) continue;
        for (final node in _stringErrorDeclarations(body.members)) {
          final location = context.unit.lineInfo.getLocation(node.offset);
          reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
        }
      }
    },
  ),

  /// Avoid broad invalidation before navigation-critical route changes.
  ///
  /// Why: Flags broad invalidation before navigation-critical route changes. Persist,
  /// targeted-sync state, then navigate.
  scannerRule(
    code: const LintCode(
      'state_broad_invalidation',
      'Avoid broad invalidation before navigation-critical route changes.',
      correctionMessage: 'Persist, targeted-sync state, then navigate.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description: 'Flags broad invalidation before navigation-critical route changes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (line.contains('ref.invalidate(') &&
              context.isMutationMethod(method.name) &&
              context.near(i, 'go(', 8)) {
            reporter.report(context, i, line.indexOf('ref'));
          }
        }
      }
    },
  ),

  /// Use context.mounted after async gaps in widgets.
  ///
  /// Why: Flags widget mounted checks after async gaps instead of context.mounted. Replace
  /// mounted checks with context.mounted for BuildContext safety.
  scannerRule(
    code: const LintCode(
      'async_context_mounted_style',
      'Use context.mounted after async gaps in widgets.',
      correctionMessage: 'Replace mounted checks with context.mounted for BuildContext safety.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags widget mounted checks after async gaps instead of context.mounted so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (line.contains('if (!mounted)') && context.near(i, 'await ', 8)) {
            reporter.report(context, i, line.indexOf('mounted'));
          }
        }
      }
    },
  ),

  /// Do not use State.mounted directly.
  ///
  /// Why: The Flutter skill requires BuildContext safety to be expressed as
  /// `context.mounted`, even inside `State`. Capture `final context =
  /// this.context;` before async/post-frame work and guard that context.
  scannerRule(
    code: const LintCode(
      'bare_state_mounted_forbidden',
      'Use context.mounted instead of bare mounted.',
      correctionMessage: "Replace bare 'mounted' / 'this.mounted' with 'context.mounted'. In State methods, capture 'final context = this.context;' when needed.",
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags bare State.mounted checks so widget lifecycle guards use context.mounted consistently.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _bareStateMounted.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, line.indexOf('mounted', match.start));
      }
    },
  ),
];

final class _NullableCollectionVisitor extends RecursiveAstVisitor<void> {
  _NullableCollectionVisitor(this.reporter, this.context);

  final ScannerRuleReporter reporter;
  final SourceScannerContext context;

  @override
  void visitNamedType(NamedType node) {
    if (node.question != null &&
        node.typeArguments != null &&
        const {'List', 'Set', 'Map', 'Iterable'}.contains(node.name.lexeme)) {
      final location = context.unit.lineInfo.getLocation(node.offset);
      reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
    }
    super.visitNamedType(node);
  }
}

final _emptyStringDefault = RegExp(
  r'''@Default\s*\(\s*r?['"]\s*['"]\s*\)\s*(?:final\s+)?String\s+(?<defaultName>[A-Za-z_]\w*)|'''
  r'''\b(?:final\s+)?String\s+(?<fieldName>[A-Za-z_]\w*)\s*=\s*r?['"]\s*['"]|'''
  r'''\bthis\s*\.\s*(?<thisName>[A-Za-z_]\w*)\s*=\s*r?['"]\s*['"]''',
);

bool _isTransientTextField(String name) =>
    RegExp(r'(?:query|search|filter|draft|input|text)', caseSensitive: false).hasMatch(name);

final _boolStringSentinel = RegExp(
  r'''\?\s*r?['"]1['"]\s*:\s*r?['"]0['"]|\?\s*r?['"]0['"]\s*:\s*r?['"]1['"]''',
);

final _bareStateMounted = RegExp(r'(^|[^A-Za-z0-9_\.])(?:this\.)?mounted\b');

final _errorName = RegExp('error', caseSensitive: false);

bool _isStringType(DartType? type) => type != null && type.isDartCoreString;

/// A Flutter `State<T>` holds widget-local state, not notifier state.
bool _isWidgetState(ClassElement element) => element.allSupertypes.any(
  (type) =>
      type.element.name == 'State' &&
      type.element.library.uri.toString().startsWith('package:flutter/'),
);

Iterable<AstNode> _stringErrorDeclarations(NodeList<ClassMember> members) sync* {
  for (final member in members) {
    if (member is FieldDeclaration && !member.isStatic) {
      for (final variable in member.fields.variables) {
        final field = variable.declaredFragment?.element;
        if (_errorName.hasMatch(variable.name.lexeme) && _isStringType(field?.type)) {
          yield member.fields.type ?? variable;
        }
      }
    }
    if (member is ConstructorDeclaration && member.redirectedConstructor != null) {
      // Freezed turns redirecting factory parameters into state fields.
      for (final parameter in member.parameters.parameters) {
        final element = parameter.declaredFragment?.element;
        final name = parameter.name?.lexeme ?? '';
        if (_errorName.hasMatch(name) && _isStringType(element?.type)) yield parameter;
      }
    }
  }
}

final class _RawErrorStringFinder extends RecursiveAstVisitor<void> {
  final nodes = <NamedArgument>[];

  @override
  void visitNamedArgument(NamedArgument node) {
    final value = node.argumentExpression;
    if (node.name.lexeme == 'error' &&
        _isStringType(value.staticType) &&
        _containsRawErrorText(value)) {
      nodes.add(node);
    }
    super.visitNamedArgument(node);
  }
}

/// The value reads the caught exception or stack trace, or stringifies an object.
bool _containsRawErrorText(Expression value) {
  final finder = _RawErrorTextFinder();
  value.accept(finder);
  return finder.found;
}

final class _RawErrorTextFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (node.methodName.name == 'toString' && target != null && !_isStringType(target.staticType)) {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (element is! LocalVariableElement) return;
    for (AstNode? ancestor = node.parent; ancestor != null; ancestor = ancestor.parent) {
      if (ancestor is CatchClause &&
          (ancestor.exceptionParameter?.declaredFragment?.element == element ||
              ancestor.stackTraceParameter?.declaredFragment?.element == element)) {
        found = true;
        return;
      }
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
