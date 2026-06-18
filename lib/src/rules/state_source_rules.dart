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
      correctionMessage:
          'Use a non-nullable collection with an empty default. If null has distinct semantics, model that as AsyncValue or a sealed state.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags nullable collection types so absence is modeled explicitly instead of with List?/Map?/Set?.',
    scan: (reporter, context) {
      if (context.isTestFile || context.isDataModelPath) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final match = _nullableCollectionType.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
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
      correctionMessage:
          'Use String? for true absence, a validated Value Object for required domain text, or rename transient fields as draft/search/input text.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags empty-string defaults in Freezed state unless the field is explicit transient input/search/draft text.',
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
      correctionMessage:
          'Keep the value as bool. If a wire protocol truly requires "1"/"0", convert at the datasource boundary with a named encoder.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags boolean ternaries that produce "1"/"0" string sentinels so state and selectors keep boolean meaning typed.',
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
    description:
        'Flags raw JSON or response values stored in UI state so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\bstate\s*=\s*state\.copyWith\s*\([^)]*(?:rawJson|response|json)',
        ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('state'));
        }
      }
    },
  ),

  /// Do not surface raw exception strings in state.
  ///
  /// Why: Flags `error: e.toString()` state updates. Convert failures to
  /// structured app exceptions or user-safe messages before they enter UI state.
  scannerRule(
    code: const LintCode(
      'state_raw_error_to_string',
      'Do not surface raw exception strings in state.',
      correctionMessage: 'Use AppException or another structured, user-safe error message.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags raw error toString state updates so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final rawErrorString = RegExp(r'\berror\s*:\s*[A-Za-z_]\w*\.toString\(\)');
      for (var i = 0; i < context.source.length; i++) {
        final match = rawErrorString.firstMatch(context.source.masked[i]);
        if (match != null) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Freezed state should not carry nullable raw error strings.
  ///
  /// Why: Flags String? error fields in Freezed state classes. Model failures as
  /// AsyncError, failure unions, or structured app exceptions.
  scannerRule(
    code: const LintCode(
      'state_freezed_nullable_error',
      'Do not store nullable raw error strings in Freezed state.',
      correctionMessage: 'Use AsyncError, a failure union, or a structured app exception.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags String? error fields in Freezed state classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final nullableError = RegExp(r'\bString\?\s+error\b');
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (!classSpan.name.endsWith('State')) continue;
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final match = nullableError.firstMatch(context.source.masked[i]);
          if (match != null) {
            reporter.report(context, i, match.start);
          }
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
    description:
        'Flags broad invalidation before navigation-critical route changes so the Flutter skill violation is shown during analysis.',
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
    description:
        'Flags widget mounted checks after async gaps instead of context.mounted so the Flutter skill violation is shown during analysis.',
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
      correctionMessage:
          "Replace bare 'mounted' / 'this.mounted' with 'context.mounted'. In State methods, capture 'final context = this.context;' when needed.",
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags bare State.mounted checks so widget lifecycle guards use context.mounted consistently.',
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

final _nullableCollectionType = RegExp(
  r'\b(?:(?:Future|Stream)\s*<\s*)?(?:List|Set|Map|Iterable)\s*<[^;\n=(){}]+>\s*\?',
);

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
