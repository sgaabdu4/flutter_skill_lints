import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> riverpodSourceRules = [
  /// Avoid ref.read in initState.
  ///
  /// Why: Flags ref.read calls made from initState. Defer reads with a post-frame callback.
  scannerRule(
    code: const LintCode(
      'riverpod_read_init_state',
      'Avoid ref.read in initState.',
      correctionMessage: 'Defer reads with a post-frame callback.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ref.read calls made from initState so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isInitStateRead(i)) {
          reporter.report(context, i, line.indexOf('ref.read'));
        }
      }
    },
  ),

  /// Avoid service locator classes in Riverpod apps.
  ///
  /// Why: Flags service locator classes in Riverpod apps. Model dependencies with providers.
  scannerRule(
    code: const LintCode(
      'riverpod_service_locator',
      'Avoid service locator classes in Riverpod apps.',
      correctionMessage: 'Model dependencies with providers.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags service locator classes in Riverpod apps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(
          r'\bclass\s+(?:ServiceFactory|ServiceLocator|BackendProvider)\b',
        ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('class'));
        }
      }
    },
  ),

  /// Prefer select when watching state in leaf widgets.
  ///
  /// Why: Flags broad ref.watch calls that do not use select. Use
  /// ref.watch(provider.select((value) => value.field)).
  scannerRule(
    code: const LintCode(
      'riverpod_watch_no_select',
      'Prefer select when watching state in leaf widgets.',
      correctionMessage: 'Use ref.watch(provider.select((value) => value.field)).',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags broad ref.watch calls that do not use select so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      // Only fire inside widget build() methods. Computed providers and
      // service factories legitimately call ref.watch without .select.
      // Exempt .notifier) — caller wants the whole notifier, no field to select.
      for (final method in context.methods.where((m) => m.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (_hasBroadRefWatch(context, i, method.end)) {
            reporter.report(context, i, line.indexOf('ref'));
          }
        }
      }
    },
  ),

  /// select() callbacks should use expression-body syntax.
  ///
  /// Why: Keeps Riverpod select examples concise and avoids block callbacks in leaf
  /// widget watches. Use ref.watch(provider.select((value) => value.field)).
  scannerRule(
    code: const LintCode(
      'riverpod_select_arrow_syntax',
      'Use arrow syntax for select() callbacks.',
      correctionMessage: 'Change select((value) { ... }) to select((value) => value.field).',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags select() callbacks without arrow syntax so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          for (final invocation in _refWatchInvocations(context, i, method.end)) {
            if (!_hasBlockSelectCallback(invocation)) continue;
            final selectLine = _firstSelectLine(context, i, method.end);
            reporter.report(
              context,
              selectLine,
              context.source.masked[selectLine].indexOf('.select'),
            );
          }
        }
      }
    },
  ),

  /// Mutation<T> usage should carry an experimental warning.
  ///
  /// Why: Riverpod Mutation is still experimental. Keep a nearby note so code reviewers
  /// see the API stability boundary at the call site.
  scannerRule(
    code: const LintCode(
      'riverpod_mutation_experimental_warning',
      'Mutation<T> usage must have nearby experimental context.',
      correctionMessage: 'Add a nearby comment that says Mutation is experimental.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Mutation<T> usage without nearby experimental context so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      if (!context.path.contains('/notifiers/') && !context.path.endsWith('_notifier.dart')) {
        return;
      }
      final mutationUsage = RegExp(r'\bMutation\s*<');
      final experimental = RegExp(r'\bexperimental\b', caseSensitive: false);
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*class\s+Mutation\s*<').hasMatch(line)) continue;
        if (RegExp(r'^\s*typedef\s+Mutation\s*<').hasMatch(line)) continue;
        if (RegExp(r'^\s*Mutation\s*<[^>]+>\s+\w+(?:<[^>]+>)?\s*\(').hasMatch(line)) {
          continue;
        }
        if (RegExp(
          r'^\s*(?:[A-Za-z_]\w*(?:<[^>]+>)?\??|void)\s+Mutation(?:<[^>]+>)?\s*\(',
        ).hasMatch(line)) {
          continue;
        }
        final match = mutationUsage.firstMatch(line);
        if (match != null && match.start > 0 && line[match.start - 1] == '.') continue;
        if (match == null || context.nearOriginal(i, experimental, 5)) continue;
        reporter.report(context, i, match.start);
      }
    },
  ),

  /// Keep derived providers alive when all watched dependencies are keepAlive.
  ///
  /// Why: Follows the building-flutter-apps provider decision tree for computed or
  /// one-time providers. If every watched dependency is keepAlive, make the derived
  /// non-family provider keepAlive too.
  scannerRule(
    code: const LintCode(
      'riverpod_auto_dispose_keepalive_dependencies',
      'Use keepAlive when all watched dependencies are keepAlive.',
      correctionMessage:
          'Change @riverpod to @Riverpod(keepAlive: true), unless this provider has parameters.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags auto-dispose providers whose same-file watched dependencies are all keepAlive.',
    scan: (reporter, context) {
      final definitions = _providerDefinitions(context);
      final definitionsByName = {
        for (final definition in definitions) definition.providerName: definition,
      };

      for (final definition in definitions) {
        if (definition.keepAlive || definition.hasParameters) continue;
        final watchedProviders = _watchedProviderNames(context, definition);
        if (watchedProviders.isEmpty) continue;
        if (!watchedProviders.every((name) => definitionsByName[name]?.keepAlive ?? false)) {
          continue;
        }
        reporter.report(context, definition.annotationLine, 0);
      }
    },
  ),

  /// Feature notifiers should be keepAlive by default.
  ///
  /// Why: Class-based feature notifiers own mutable screen/feature state. In
  /// presentation notifier files, accidental auto-dispose resets that state when
  /// a subtree temporarily unmounts. Family notifiers stay auto-dispose by
  /// default because keepAlive would cache every argument variant.
  scannerRule(
    code: const LintCode(
      'riverpod_feature_notifier_keepalive',
      'Feature notifiers should use keepAlive.',
      correctionMessage:
          'Change @riverpod to @Riverpod(keepAlive: true), or add an autoDispose rationale comment.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags non-family feature presentation notifiers that auto-dispose without rationale.',
    scan: (reporter, context) {
      if (!_isFeaturePresentationNotifierPath(context)) return;

      for (final definition in _providerDefinitions(context)) {
        if (!definition.isClassBased) continue;
        if (!definition.className.endsWith('Notifier')) continue;
        if (definition.keepAlive || definition.hasParameters) continue;
        if (_registersDisposeCleanup(context, definition)) continue;
        if (_hasAutoDisposeRationale(context, definition.annotationLine)) continue;
        reporter.report(context, definition.annotationLine, 0);
      }
    },
  ),

  /// Avoid keepAlive family providers.
  ///
  /// Why: Flags keepAlive Riverpod families with required parameters. Use auto-dispose
  /// families unless the cache is bounded.
  scannerRule(
    code: const LintCode(
      'riverpod_keepalive_family',
      'Avoid keepAlive family providers.',
      correctionMessage: 'Use auto-dispose families unless the cache is bounded.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags keepAlive Riverpod families with required parameters so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (_isKeepAliveRiverpodAnnotation(context, i) &&
            !_hasKeepAliveTickerModeWorkaround(context, i) &&
            (context.near(i, 'required ', 5) || _hasFamilySignatureAfterKeepAlive(context, i))) {
          reporter.report(context, i, line.indexOf('@Riverpod'));
        }
      }
    },
  ),
];

final class _ProviderAnnotation {
  const _ProviderAnnotation({
    required this.line,
    required this.endLine,
    required this.text,
    required this.keepAlive,
  });

  final int line;
  final int endLine;
  final String text;
  final bool keepAlive;
}

final class _RiverpodProviderDefinition {
  const _RiverpodProviderDefinition({
    required this.providerName,
    required this.annotationLine,
    required this.bodyStart,
    required this.bodyEnd,
    required this.keepAlive,
    required this.hasParameters,
    required this.isClassBased,
    required this.className,
  });

  final String providerName;
  final int annotationLine;
  final int bodyStart;
  final int bodyEnd;
  final bool keepAlive;
  final bool hasParameters;
  final bool isClassBased;
  final String className;
}

List<_RiverpodProviderDefinition> _providerDefinitions(SourceScannerContext context) {
  final definitions = <_RiverpodProviderDefinition>[];

  for (var i = 0; i < context.source.length; i++) {
    final annotation = _riverpodAnnotationAt(context, i);
    if (annotation == null) continue;

    final declarationLine = _nextNonEmptyLine(context, annotation.endLine + 1);
    if (declarationLine == null) continue;
    final declaration = context.source.masked[declarationLine];

    final classMatch = RegExp(r'\bclass\s+([A-Za-z_]\w*)\b').firstMatch(declaration);
    if (classMatch != null) {
      final className = classMatch.group(1) ?? '';
      final classSpan = context.classes
          .where((classSpan) => classSpan.start == declarationLine)
          .cast<ScannerClassSpan?>()
          .firstOrNull;
      final bodyEnd = classSpan?.end ?? declarationLine;
      definitions.add(
        _RiverpodProviderDefinition(
          providerName: _classProviderName(className),
          annotationLine: annotation.line,
          bodyStart: declarationLine,
          bodyEnd: bodyEnd,
          keepAlive: annotation.keepAlive,
          hasParameters: _classBuildHasParameters(context, declarationLine, bodyEnd),
          isClassBased: true,
          className: className,
        ),
      );
      i = declarationLine;
      continue;
    }

    final functionName = _functionProviderName(context, declarationLine);
    if (functionName == null) continue;
    definitions.add(
      _RiverpodProviderDefinition(
        providerName: _functionProviderGeneratedName(functionName),
        annotationLine: annotation.line,
        bodyStart: declarationLine,
        bodyEnd: _functionProviderEnd(context, declarationLine),
        keepAlive: annotation.keepAlive,
        hasParameters: _functionHasProviderParameters(context, declarationLine),
        isClassBased: false,
        className: '',
      ),
    );
    i = declarationLine;
  }

  return definitions;
}

_ProviderAnnotation? _riverpodAnnotationAt(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!RegExp(r'^\s*@(?:r|R)iverpod\b').hasMatch(line)) return null;

  final text = StringBuffer();
  var endLine = lineIndex;
  final needsClosingParen = line.contains('@Riverpod') && line.contains('(') && !line.contains(')');
  for (var i = lineIndex; i < context.source.length; i++) {
    text.write(' ${context.source.masked[i]}');
    endLine = i;
    if (!needsClosingParen || context.source.masked[i].contains(')')) break;
  }

  final annotationText = text.toString();
  return _ProviderAnnotation(
    line: lineIndex,
    endLine: endLine,
    text: annotationText,
    keepAlive: RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(annotationText),
  );
}

int? _nextNonEmptyLine(SourceScannerContext context, int startLine) {
  for (var i = startLine; i < context.source.length; i++) {
    if (context.source.masked[i].trim().isNotEmpty) return i;
  }
  return null;
}

String _classProviderName(String className) {
  final base = className.endsWith('Notifier')
      ? className.substring(0, className.length - 'Notifier'.length)
      : className;
  return '${_lowerFirst(base)}Provider';
}

String _functionProviderGeneratedName(String functionName) =>
    '${_lowerFirst(functionName)}Provider';

String _lowerFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toLowerCase() + value.substring(1);
}

bool _classBuildHasParameters(SourceScannerContext context, int classStart, int classEnd) {
  for (var i = classStart; i <= classEnd && i < context.source.length; i++) {
    final line = context.source.masked[i];
    if (!RegExp(r'\bbuild\s*\(').hasMatch(line)) continue;
    return _parameterListHasProviderArgs(_declarationText(context, i));
  }
  return false;
}

String? _functionProviderName(SourceScannerContext context, int declarationLine) {
  final declaration = _declarationText(context, declarationLine);
  final match = RegExp(
    r'^\s*(?:[A-Za-z_]\w*(?:<[^>]+>)?\??\s+)+([A-Za-z_]\w*)\s*\(',
  ).firstMatch(declaration);
  return match?.group(1);
}

bool _functionHasProviderParameters(SourceScannerContext context, int declarationLine) =>
    _parameterListHasProviderArgs(_declarationText(context, declarationLine));

String _declarationText(SourceScannerContext context, int startLine) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawParen = false;
  for (var i = startLine; i < context.source.length && i < startLine + 8; i++) {
    final line = context.source.masked[i];
    buffer.write(' $line');
    for (var column = 0; column < line.length; column++) {
      final char = line[column];
      if (char == '(') {
        sawParen = true;
        depth++;
      } else if (char == ')' && sawParen) {
        depth--;
        if (depth == 0) return buffer.toString();
      }
    }
  }
  return buffer.toString();
}

bool _parameterListHasProviderArgs(String declaration) {
  final start = declaration.indexOf('(');
  final end = declaration.indexOf(')', start + 1);
  if (start < 0 || end < 0) return false;
  final parameters = declaration.substring(start + 1, end).trim();
  if (parameters.isEmpty) return false;
  final withoutRef = parameters
      .replaceFirst(RegExp(r'^(?:[A-Za-z_]\w*)?Ref\s+ref\s*,?\s*'), '')
      .replaceFirst(RegExp(r'^WidgetRef\s+ref\s*,?\s*'), '')
      .trim();
  return withoutRef.isNotEmpty;
}

int _functionProviderEnd(SourceScannerContext context, int declarationLine) {
  final declaration = context.source.masked[declarationLine];
  if (declaration.contains('=>')) return declarationLine;

  var depth = 0;
  var sawOpenBrace = false;
  for (var i = declarationLine; i < context.source.length; i++) {
    final line = context.source.masked[i];
    depth += _count(line, '{');
    if (line.contains('{')) sawOpenBrace = true;
    depth -= _count(line, '}');
    if (sawOpenBrace && depth <= 0) return i;
  }
  return declarationLine;
}

Set<String> _watchedProviderNames(
  SourceScannerContext context,
  _RiverpodProviderDefinition definition,
) {
  final body = context.source.masked
      .sublist(definition.bodyStart, definition.bodyEnd + 1)
      .join('\n');
  return RegExp(
    r'\bref\s*\.\s*watch\s*\(\s*([A-Za-z_]\w*Provider)\b',
  ).allMatches(body).map((match) => match.group(1) ?? '').where((name) => name.isNotEmpty).toSet();
}

int _count(String text, String char) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (text[i] == char) count++;
  }
  return count;
}

bool _hasBlockSelectCallback(String invocation) =>
    RegExp(r'\.\s*select\s*\(\s*\([^)]*\)\s*\{').hasMatch(invocation);

int _firstSelectLine(SourceScannerContext context, int startLine, int methodEnd) {
  for (var i = startLine; i <= methodEnd && i < context.source.length; i++) {
    if (context.source.masked[i].contains('.select')) return i;
  }
  return startLine;
}

bool _isKeepAliveRiverpodAnnotation(SourceScannerContext context, int lineIndex) {
  final line = context.source.masked[lineIndex];
  if (!line.contains('@Riverpod')) return false;

  final annotation = StringBuffer();
  final end = (lineIndex + 6).clamp(0, context.source.length - 1);
  for (var i = lineIndex; i <= end; i++) {
    annotation.write(' ${context.source.masked[i]}');
    if (context.source.masked[i].contains(')')) break;
  }
  return RegExp(r'@Riverpod\s*\([^)]*keepAlive\s*:\s*true').hasMatch(annotation.toString());
}

bool _hasKeepAliveTickerModeWorkaround(SourceScannerContext context, int annotationLine) {
  return context.nearOriginal(
    annotationLine,
    RegExp(
      r'(?:#4709|riverpod#4709|TickerMode|pausedActiveSubscriptionCount)',
      caseSensitive: false,
    ),
    6,
  );
}

bool _hasFamilySignatureAfterKeepAlive(SourceScannerContext context, int annotationLine) {
  final end = (annotationLine + 8).clamp(0, context.source.length - 1);
  for (var i = annotationLine + 1; i <= end; i++) {
    final line = context.source.masked[i];
    if (RegExp(r'\bRef\b[^)]*,').hasMatch(line)) return true;
    if (RegExp(r'\bbuild\s*\(\s*[^)]*[A-Za-z_]\w*(?:<[^>]+>)?\??\s+\w+').hasMatch(line)) {
      return true;
    }
  }
  return false;
}

bool _isFeaturePresentationNotifierPath(SourceScannerContext context) {
  final normalized = context.path.replaceAll('\\', '/').toLowerCase();
  return normalized.startsWith('lib/features/') &&
      normalized.contains('/presentation/notifiers/') &&
      normalized.endsWith('_notifier.dart');
}

bool _hasAutoDisposeRationale(SourceScannerContext context, int annotationLine) {
  return context.nearOriginal(
    annotationLine,
    RegExp(
      r'\b(?:auto[- ]?dispose|ephemeral|transient|route[- ]?local|screen[- ]?local|reset when|dispose when unused)\b',
      caseSensitive: false,
    ),
    6,
  );
}

bool _registersDisposeCleanup(
  SourceScannerContext context,
  _RiverpodProviderDefinition definition,
) {
  final body = context.source.masked
      .sublist(definition.bodyStart, definition.bodyEnd + 1)
      .join('\n');
  return RegExp(r'\bref\s*\.\s*onDispose\s*\(').hasMatch(body);
}

bool _hasBroadRefWatch(SourceScannerContext context, int lineIndex, int methodEnd) {
  for (final invocation in _refWatchInvocations(context, lineIndex, methodEnd)) {
    if (!RegExp(r'\.\s*select\s*\(').hasMatch(invocation) &&
        !RegExp(r'\.\s*notifier\b').hasMatch(invocation)) {
      return true;
    }
  }
  return false;
}

List<String> _refWatchInvocations(SourceScannerContext context, int lineIndex, int methodEnd) {
  final firstLine = context.source.masked[lineIndex];
  final matches = RegExp(r'\bref\s*\.\s*watch\s*\(').allMatches(firstLine).toList();
  if (matches.isEmpty) return const [];

  return [
    for (final match in matches) _refWatchInvocation(context, lineIndex, methodEnd, match.start),
  ];
}

String _refWatchInvocation(
  SourceScannerContext context,
  int startLine,
  int methodEnd,
  int startColumn,
) {
  final buffer = StringBuffer();
  var depth = 0;
  var sawOpenParen = false;

  for (
    var lineIndex = startLine;
    lineIndex <= methodEnd && lineIndex < context.source.length;
    lineIndex++
  ) {
    final line = context.source.masked[lineIndex];
    final scanStart = lineIndex == startLine ? startColumn : 0;

    for (var column = scanStart; column < line.length; column++) {
      final char = line[column];
      buffer.write(char);

      if (char == '(') {
        sawOpenParen = true;
        depth++;
        continue;
      }

      if (char == ')' && sawOpenParen) {
        depth--;
        if (depth == 0) {
          return buffer.toString();
        }
      }
    }

    buffer.write('\n');
  }

  return buffer.toString();
}
