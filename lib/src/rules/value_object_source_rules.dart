import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

/// Rules enforcing Value Object boundary integrity in /domain/ paths.
///
/// Why: Primitive obsession leaks through three pinholes: public raw Value
/// Object constructors (skipping validation), named primitive factories on
/// entities (boundary conversion done inside /domain/), and hand-written
/// copyWith on domain types (drift from Freezed-generated semantics). These
/// rules close all three.
final List<ScannerRule> valueObjectSourceRules = [
  /// Domain strings must not use empty-string sentinels.
  ///
  /// Why: `''` does not prove a required domain string is valid, and it hides
  /// absence when the value is optional. Required domain strings should be
  /// validated Value Objects; optional domain strings should be nullable and
  /// normalized at the boundary.
  scannerRule(
    code: const LintCode(
      'domain_empty_string_sentinel',
      'Do not use empty strings as domain sentinels.',
      correctionMessage: 'Use a validated Value Object for required text, or String? for optional text after normalizing blank input to null at the boundary.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags empty-string defaults in domain code so blank text is not used as a missing-value sentinel.',
    scan: (reporter, context) {
      if (!context.isDomainPath) return;
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.code[i];
        final match = _domainEmptyStringDefault.firstMatch(line);
        if (match == null) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Value Object raw constructors must be private.
  ///
  /// Why: A raw VO constructor (`const factory Distance.meters(double value) =
  /// _Meters;`) skips invariants — callers can pass `-1` and the type system
  /// shrugs. Make the raw redirect private (`._meters`) and expose a validated
  /// factory (`factory Distance.fromMeters(double m) { assert(m >= 0); ... }`)
  /// so every Distance carries proof of its invariant. Const and non-const
  /// redirects are both checked. The unnamed redirect of a composite Value
  /// Object with two or more named fields (the skill's `Money({required int
  /// cents, required Currency currency})`) is the documented canonical shape.
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
    description: 'Flags public raw redirecting factories on Value Objects so the Flutter skill violation is shown during analysis.',
    scan: _scanPublicRawRedirectFactories,
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
    description: 'Flags named factories on Freezed domain entities so the Flutter skill violation is shown during analysis.',
    scan: _scanDomainEntityPrimitiveFactories,
  ),

  /// Domain entities must not take raw required strings.
  ///
  /// Why: A required `String` accepts blank or malformed text, so an entity
  /// built from it proves nothing about its IDs, names or emails. Required
  /// domain text is a validated Value Object; optional text is `String?`.
  scannerRule(
    code: const LintCode(
      'domain_raw_required_string',
      'Domain entities must not take raw required String fields.',
      correctionMessage:
          'Wrap required text (IDs, names, emails, slugs) in a validated Value Object from '
          '/domain/values/, or use String? for optional text normalized at the boundary. '
          'Keep String in data models and convert in mappers. See building-flutter-apps '
          'SKILL.md Critical Rule 5 + references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags non-nullable String parameters on Freezed domain entity constructors so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) =>
        _scanDomainEntityParameters(reporter, context, _isRawRequiredString),
  ),

  /// Domain entities must not carry units or money as raw numbers.
  ///
  /// Why: `int lengthCm`, `double weightKg` or `int amountCents` put the unit
  /// in the name instead of the type, so callers can mix units or pass
  /// negative values. Unit and currency values become Value Objects.
  scannerRule(
    code: const LintCode(
      'domain_unit_primitive',
      'Domain entities must not carry unit or currency values as raw numbers.',
      correctionMessage:
          'Use a Value Object (Distance, Money, Weight, Percentage) or Duration for this '
          'unit-named number. Keep the primitive in the data model and convert in the mapper. '
          'See building-flutter-apps SKILL.md Critical Rule 12 + references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags unit- or currency-named numeric parameters on Freezed domain entity constructors so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) => _scanDomainEntityParameters(reporter, context, _isUnitNamedNumber),
  ),

  /// Sealed Value Objects must disable Freezed map/when generation.
  ///
  /// Why: `@freezed` (or `@Freezed()` without opt-outs) on a `sealed` class
  /// generates `.map()` / `.maybeMap()` / `.when()` / `.maybeWhen()` alongside
  /// the native sealed hierarchy. Those APIs bypass the analyzer's exhaustiveness
  /// check on `switch`, are harder to refactor when variants change, and tempt
  /// LLMs trained on Freezed 2.x examples back into the wrong pattern.
  /// Annotate with `@Freezed(map: .none, when: .none)`
  /// so the only supported pattern-matching is Dart 3 native `switch`.
  scannerRule(
    code: const LintCode(
      'freezed_disable_map_when_required',
      'Sealed Value Objects must disable Freezed map/when generation.',
      correctionMessage:
          'Replace `@freezed` with '
          '`@Freezed(map: .none, when: .none)` '
          'on this sealed Value Object. The default `.map()`/`.when()` methods '
          'bypass the sealed exhaustiveness check and are explicitly forbidden '
          'by Critical Rule 7 — use native `switch (instance) { _Case(:final v) => ... }` '
          'instead. Requires `freezed_annotation ^3.1.0` (those options were '
          'temporarily removed in 3.0.x and re-added in 3.1.0). See '
          'building-flutter-apps SKILL.md Critical Rule 7 + '
          'references/value-objects.md.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags sealed Freezed Value Objects whose annotation does not disable .map()/.when() generation.',
    scan: (reporter, context) {
      if (!context.path.contains('/domain/values/')) return;
      for (final classSpan in context.classes) {
        if (!context.hasFreezedAnnotation(classSpan)) continue;
        if (classSpan.name.startsWith('_')) continue;
        final declLine = context.source.masked[classSpan.start];
        if (!RegExp(r'\bsealed\s+class\b').hasMatch(declLine)) continue;
        final windowStart = classSpan.start - 10 < 0 ? 0 : classSpan.start - 10;
        final window = context.source.masked.sublist(windowStart, classSpan.start).join('\n');
        final hasMapNone = RegExp(r'map\s*:\s*(?:FreezedMapOptions)?\.none').hasMatch(window);
        final hasWhenNone = RegExp(r'when\s*:\s*(?:FreezedWhenOptions)?\.none').hasMatch(window);
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
    description: 'Flags hand-written copyWith declarations in /domain/ files so the Flutter skill violation is shown during analysis.',
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

final _domainEmptyStringDefault = RegExp(
  r'''@Default\s*\(\s*r?['"]\s*['"]\s*\)\s*(?:final\s+)?String\s+[A-Za-z_]\w*|'''
  r'''\b(?:final\s+)?String\s+[A-Za-z_]\w*\s*=\s*r?['"]\s*['"]|'''
  r'''\bthis\s*\.\s*[A-Za-z_]\w*\s*=\s*r?['"]\s*['"]''',
);

void _scanPublicRawRedirectFactories(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!context.path.contains('/domain/values/')) return;
  final source = context.source.masked.join('\n');
  final lineOffsets = _sourceLineOffsets(context);
  _reportRawRedirectFactories(context, reporter);
  _reportPassthroughFactories(reporter, context, source, lineOffsets);
}

List<int> _sourceLineOffsets(SourceScannerContext context) {
  final offsets = <int>[0];
  for (final line in context.source.masked) {
    offsets.add(offsets.last + line.length + 1);
  }
  return offsets;
}

void _reportRawRedirectFactories(SourceScannerContext context, ScannerRuleReporter reporter) {
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    for (final constructor in declaration.body.members.whereType<ConstructorDeclaration>()) {
      if (!_isPublicRawRedirect(constructor) || _isCompositeCanonicalRedirect(constructor)) {
        continue;
      }
      final offset = constructor.firstTokenAfterCommentAndMetadata.offset;
      final line = _lineIndexForOffset(offset, context.source.lineOffsets, context.source.length);
      reporter.report(context, line, offset - context.source.lineOffsets[line]);
    }
  }
}

bool _isPublicRawRedirect(ConstructorDeclaration constructor) {
  final redirect = constructor.redirectedConstructor;
  return constructor.factoryKeyword != null &&
      redirect != null &&
      redirect.type.name.lexeme.startsWith('_') &&
      !(constructor.name?.lexeme.startsWith('_') ?? false) &&
      constructor.parameters.parameters.isNotEmpty;
}

/// value-objects.md `Money`: the unnamed redirect of a composite Value Object
/// whose invariant is carried by two or more named component fields.
bool _isCompositeCanonicalRedirect(ConstructorDeclaration constructor) {
  final parameters = constructor.parameters.parameters;
  return constructor.name == null &&
      parameters.length >= 2 &&
      parameters.every((parameter) => parameter.isNamed);
}

void _reportPassthroughFactories(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  String source,
  List<int> lineOffsets,
) {
  final pattern = RegExp(
    r'\bfactory\s+([A-Z]\w*)\s*\.\s*([A-Za-z_]\w*)\s*\(\s*\w+\s+(\w+)\s*\)\s*=>\s*\1\s*\.\s*_\w+\s*\(\s*\3\s*\)\s*;',
    dotAll: true,
  );
  for (final match in pattern.allMatches(source)) {
    final constructorName = match.group(2)!;
    if (constructorName.startsWith('_') || constructorName == 'fromJson') continue;
    _reportFactoryMatch(reporter, context, match.start, lineOffsets);
  }
}

void _reportFactoryMatch(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int offset,
  List<int> lineOffsets,
) {
  final lineIndex = _lineIndexForOffset(offset, lineOffsets, context.source.length);
  reporter.report(context, lineIndex, offset - lineOffsets[lineIndex]);
}

int _lineIndexForOffset(int offset, List<int> lineOffsets, int lineCount) {
  for (var index = 0; index < lineOffsets.length - 1; index++) {
    if (offset < lineOffsets[index + 1]) return index;
  }
  return lineCount - 1;
}

void _scanDomainEntityPrimitiveFactories(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
) {
  if (!context.isDomainPath || context.path.contains('/domain/values/')) return;
  for (final classSpan in context.classes) {
    if (!context.hasFreezedAnnotation(classSpan) || classSpan.name.startsWith('_')) continue;
    final declaration = context.unit.declarations
        .whereType<ClassDeclaration>()
        .where((candidate) => candidate.namePart.typeName.lexeme == classSpan.name)
        .firstOrNull;
    if (declaration == null) continue;
    _reportPrimitiveFactoriesInClass(reporter, context, declaration);
  }
}

void _reportPrimitiveFactoriesInClass(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  ClassDeclaration declaration,
) {
  final isExceptionUnion = _isExceptionUnion(declaration);
  for (final constructor in declaration.body.members.whereType<ConstructorDeclaration>()) {
    if (!_isPublicPrimitiveFactory(constructor)) continue;
    if (isExceptionUnion && _isNullableDiagnosticRedirect(constructor)) continue;
    final offset = constructor.factoryKeyword!.offset;
    final line = _lineIndexForOffset(offset, context.source.lineOffsets, context.source.length);
    reporter.report(context, line, offset - context.source.lineOffsets[line]);
  }
}

bool _isExceptionUnion(ClassDeclaration declaration) {
  if (declaration.sealedKeyword == null) return false;
  final supertypes = [
    ...?declaration.implementsClause?.interfaces,
    ?declaration.extendsClause?.superclass,
  ];
  final implementsCoreError = supertypes.any(
    (type) =>
        type.element?.library?.uri.toString() == 'dart:core' &&
        (type.name.lexeme == 'Exception' || type.name.lexeme == 'Error'),
  );
  if (!implementsCoreError) return false;
  return declaration.body.members
          .whereType<ConstructorDeclaration>()
          .where(
            (constructor) => constructor.name != null && constructor.redirectedConstructor != null,
          )
          .length >=
      2;
}

bool _isNullableDiagnosticRedirect(ConstructorDeclaration constructor) {
  if (constructor.redirectedConstructor == null) return false;
  return constructor.parameters.parameters.every((parameter) {
    if (!parameter.isOptionalNamed ||
        parameter.defaultClause != null ||
        parameter.type?.question == null) {
      return false;
    }
    final type = parameter.declaredFragment?.element.type;
    return switch (parameter.name?.lexeme) {
      'message' || 'type' => type?.isDartCoreString == true,
      'code' || 'statusCode' => type?.isDartCoreInt == true,
      'response' => type?.isDartCoreObject == true,
      _ => false,
    };
  });
}

bool _isPublicPrimitiveFactory(ConstructorDeclaration constructor) {
  final name = constructor.name?.lexeme;
  return constructor.factoryKeyword != null &&
      name != null &&
      !name.startsWith('_') &&
      name != 'fromJson' &&
      constructor.parameters.parameters.any(_takesPrimitiveParameter);
}

bool _takesPrimitiveParameter(FormalParameter parameter) {
  final type = parameter.declaredFragment?.element.type;
  return type != null &&
      (type.isDartCoreString ||
          type.isDartCoreBool ||
          type.isDartCoreInt ||
          type.isDartCoreDouble ||
          type.isDartCoreNum);
}

const _unitWords =
    'Meters|Metres|Kilometers|Kilometres|Km|Miles|Cm|Mm|Kg|Kilograms|Grams|Lbs|Pounds|'
    'Percent|Percentage|Cents|Pence|Price|Cost|Bytes|Seconds|Secs|Ms|Millis|Milliseconds|'
    'Minutes|Mins|Hours|Bpm|Kcal|Calories|Celsius|Fahrenheit';

final _unitName = RegExp('^(?:${_unitWords.toLowerCase()})\$|[a-z0-9](?:$_unitWords)\$');

typedef _EntityParameter = ({DartType type, String name, bool hasDefault});

void _scanDomainEntityParameters(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  bool Function(_EntityParameter parameter) matches,
) {
  if (!context.isDomainPath || context.path.contains('/domain/values/')) return;
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.namePart.typeName.lexeme.startsWith('_') ||
        !_isFreezedDeclaration(declaration)) {
      continue;
    }
    final constructor = _canonicalRedirect(declaration);
    if (constructor == null) continue;
    for (final parameter in constructor.parameters.parameters) {
      // Shipped Hive entities keep their locked primitive slots (value-objects.md Option A).
      if (_hasHiveFieldMarker(parameter)) continue;
      final type = parameter.declaredFragment?.element.type;
      final typeNode = parameter.type;
      final name = parameter.name?.lexeme;
      if (type == null || typeNode == null || name == null) continue;
      final hasDefault =
          parameter.defaultClause != null || parameter.metadata.any(_isFreezedDefault);
      if (!matches((type: type, name: name, hasDefault: hasDefault))) continue;
      final line = _lineIndexForOffset(
        typeNode.offset,
        context.source.lineOffsets,
        context.source.length,
      );
      reporter.report(context, line, typeNode.offset - context.source.lineOffsets[line]);
    }
  }
}

bool _isFreezedDeclaration(ClassDeclaration declaration) => declaration.metadata.any((annotation) {
  final element = annotation.elementAnnotation;
  return element != null && isFreezedAnnotation(element);
});

/// The unnamed Freezed redirect (`[const] factory Entity({...}) = _Entity;`).
ConstructorDeclaration? _canonicalRedirect(ClassDeclaration declaration) => declaration.body.members
    .whereType<ConstructorDeclaration>()
    .where(
      (constructor) =>
          constructor.factoryKeyword != null &&
          constructor.name == null &&
          constructor.redirectedConstructor != null,
    )
    .firstOrNull;

bool _hasHiveFieldMarker(FormalParameter parameter) =>
    parameter.documentationComment?.tokens.any((token) => token.lexeme.contains('HiveField(')) ??
    false;

bool _isFreezedDefault(Annotation annotation) {
  final element = annotation.element;
  return element is ConstructorElement &&
      element.enclosingElement.name == 'Default' &&
      element.library.uri.toString() == 'package:freezed_annotation/freezed_annotation.dart';
}

bool _isRawRequiredString(_EntityParameter parameter) =>
    parameter.type.isDartCoreString &&
    parameter.type.nullabilitySuffix == NullabilitySuffix.none &&
    !parameter.hasDefault;

bool _isUnitNamedNumber(_EntityParameter parameter) =>
    (parameter.type.isDartCoreInt ||
        parameter.type.isDartCoreDouble ||
        parameter.type.isDartCoreNum) &&
    _unitName.hasMatch(parameter.name);
