import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

/// Rules enforcing Value Object boundary integrity in /domain/ paths.
///
/// Why: Primitive obsession leaks through three pinholes: public raw Value
/// Object constructors (skipping validation), named primitive factories on
/// entities (boundary conversion done inside /domain/), and hand-written
/// copyWith on domain types (drift from Freezed-generated semantics). These
/// rules close all three.
final List<ScannerRule> valueObjectSourceRules = [
  /// Value Object raw constructors must be private.
  ///
  /// Why: A raw VO constructor (`const factory Distance.meters(double value) =
  /// _Meters;`) skips invariants — callers can pass `-1` and the type system
  /// shrugs. Make the raw redirect private (`._meters`) and expose a validated
  /// factory (`factory Distance.fromMeters(double m) { assert(m >= 0); ... }`)
  /// so every Distance carries proof of its invariant.
  scannerRule(
    code: const LintCode(
      'vo_public_raw_constructor',
      'Value Object public factory must validate, not just forward.',
      correctionMessage:
          'Make the redirect private and put EXPLICIT guards in the public factory body. '
          'Shape: `const factory X._unit(T v) = _Impl;` then '
          '`factory X.unit(T v) { if (v.isNaN || !v.isFinite) throw ArgumentError.value(v, "v", "X.unit must be finite"); return X._unit(v); }`. '
          'Passthrough factories (`factory X.unit(T v) => X._unit(v);`) are ALSO rejected — '
          'they skip validation just like a public raw redirect. If the value genuinely needs '
          'no validation, collapse the public/private split. See building-flutter-apps SKILL.md '
          'Critical Rule 12 + references/value-objects.md Forbidden section.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags public raw redirecting factories on Value Objects so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/domain/value_objects/')) return;
      final full = context.source.masked.join('\n');
      final lineOffsets = <int>[0];
      for (var i = 0; i < context.source.masked.length; i++) {
        lineOffsets.add(lineOffsets[i] + context.source.masked[i].length + 1);
      }
      int lineOf(int offset) {
        for (var i = 0; i < lineOffsets.length - 1; i++) {
          if (offset < lineOffsets[i + 1]) return i;
        }
        return context.source.length - 1;
      }

      final redirectPattern = RegExp(
        r'\bconst\s+factory\s+([A-Z]\w*)(?:\s*\.\s*([A-Za-z_]\w*))?\s*\(([^)]*)\)\s*=\s*_\w+\s*;',
        dotAll: true,
      );
      for (final m in redirectPattern.allMatches(full)) {
        final ctorName = m.group(2);
        if (ctorName != null && ctorName.startsWith('_')) continue;
        if (m.group(3)!.trim().isEmpty) continue;
        final lineIdx = lineOf(m.start);
        reporter.report(context, lineIdx, m.start - lineOffsets[lineIdx]);
      }

      final passthroughPattern = RegExp(
        r'\bfactory\s+([A-Z]\w*)\s*\.\s*([A-Za-z_]\w*)\s*\(\s*\w+\s+(\w+)\s*\)\s*=>\s*\1\s*\.\s*_\w+\s*\(\s*\3\s*\)\s*;',
        dotAll: true,
      );
      for (final m in passthroughPattern.allMatches(full)) {
        final ctorName = m.group(2)!;
        if (ctorName.startsWith('_')) continue;
        if (ctorName == 'fromJson') continue;
        final lineIdx = lineOf(m.start);
        reporter.report(context, lineIdx, m.start - lineOffsets[lineIdx]);
      }
    },
  ),

  /// Domain entities must not own primitive factories.
  ///
  /// Why: A named factory on a domain entity (`factory User.fromPrimitives(String
  /// email, int age)`) is a boundary in the wrong layer. Primitive → Value
  /// Object conversion belongs to data models, notifiers, or import services.
  /// Domain entities accept VO-typed parameters via the anonymous Freezed
  /// constructor so invalid state is unrepresentable.
  scannerRule(
    code: const LintCode(
      'domain_entity_primitive_factory',
      'Domain entities must not own primitive factories.',
      correctionMessage:
          'Remove the named factory and accept VOs through the canonical Freezed redirect '
          '`const factory Entity({required VO field}) = _Entity;`. Convert primitives at '
          'data/notifier/import boundaries. See building-flutter-apps SKILL.md Critical Rule 12 + '
          'references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags named factories on Freezed domain entities so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      if (context.path.contains('/domain/value_objects/')) return;
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (classSpan.name.startsWith('_')) continue;
        final factoryPattern = RegExp(
          r'\bfactory\s+' + RegExp.escape(classSpan.name) + r'\s*\.\s*([A-Za-z_]\w*)\s*\(',
        );
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final line = context.source.masked[i];
          final match = factoryPattern.firstMatch(line);
          if (match == null) continue;
          final factoryName = match.group(1)!;
          if (factoryName.startsWith('_')) continue;
          if (factoryName == 'fromJson') continue;
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Sealed Value Objects must disable Freezed map/when generation.
  ///
  /// Why: `@freezed` (or `@Freezed()` without opt-outs) on a `sealed` class
  /// generates `.map()` / `.maybeMap()` / `.when()` / `.maybeWhen()` alongside
  /// the native sealed hierarchy. Those APIs bypass the analyzer's exhaustiveness
  /// check on `switch`, are harder to refactor when variants change, and tempt
  /// LLMs trained on Freezed 2.x examples back into the wrong pattern.
  /// Annotate with `@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)`
  /// so the only supported pattern-matching is Dart 3 native `switch`.
  scannerRule(
    code: const LintCode(
      'freezed_disable_map_when_required',
      'Sealed Value Objects must disable Freezed map/when generation.',
      correctionMessage:
          'Replace `@freezed` with '
          '`@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)` '
          'on this sealed Value Object. The default `.map()`/`.when()` methods '
          'bypass the sealed exhaustiveness check and are explicitly forbidden '
          'by Critical Rule 7 — use native `switch (instance) { _Case(:final v) => ... }` '
          'instead. Requires `freezed_annotation ^3.1.0` (those options were '
          'temporarily removed in 3.0.x and re-added in 3.1.0). See '
          'building-flutter-apps SKILL.md Critical Rule 7 + '
          'references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags sealed Freezed Value Objects whose annotation does not disable .map()/.when() generation.',
    scan: (reporter, context) {
      if (!context.path.contains('/domain/value_objects/')) return;
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (classSpan.name.startsWith('_')) continue;
        final declLine = context.source.masked[classSpan.start];
        if (!RegExp(r'\bsealed\s+class\b').hasMatch(declLine)) continue;
        final windowStart = classSpan.start - 10 < 0 ? 0 : classSpan.start - 10;
        final window = context.source.masked.sublist(windowStart, classSpan.start).join('\n');
        final hasMapNone = RegExp(r'map\s*:\s*FreezedMapOptions\.none').hasMatch(window);
        final hasWhenNone = RegExp(r'when\s*:\s*FreezedWhenOptions\.none').hasMatch(window);
        if (hasMapNone && hasWhenNone) continue;
        final col = declLine.indexOf('sealed');
        reporter.report(context, classSpan.start, col < 0 ? 0 : col);
      }
    },
  ),

  /// Domain types must not hand-roll copyWith.
  ///
  /// Why: Freezed generates `copyWith` in the `_$X` mixin from the canonical
  /// redirect constructor. A hand-written `copyWith` in source drifts from the
  /// generated semantics — nullability handling, sentinel values, and equality
  /// diverge silently. Let codegen own the contract; if the API is wrong, fix
  /// the constructor.
  scannerRule(
    code: const LintCode(
      'domain_custom_copy_with',
      'Domain types must not hand-roll copyWith.',
      correctionMessage:
          'Delete the hand-written copyWith and let Freezed generate it from the redirect '
          'constructor. If you need a different shape, change the constructor. See '
          'building-flutter-apps SKILL.md Critical Rule 12 + references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags hand-written copyWith declarations in /domain/ files so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      final declRegex = RegExp(
        r'^\s*(?:abstract\s+|@override\s+)*(?:[A-Za-z_]\w*(?:<[^>]+>)?\??\s+)?copyWith\s*[<(]',
      );
      for (final classSpan in context.classes) {
        if (classSpan.name.startsWith(r'_$')) continue;
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final line = context.source.masked[i];
          final match = declRegex.firstMatch(line);
          if (match == null) continue;
          reporter.report(context, i, line.indexOf('copyWith'));
        }
      }
    },
  ),
];
