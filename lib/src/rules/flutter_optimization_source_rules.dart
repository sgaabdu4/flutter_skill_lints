import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> flutterOptimizationSourceRules = [
  /// Do not create keys inside build().
  ///
  /// Why: Flags local key construction inside build methods. Move stable keys to a field,
  /// registry, or source value outside build().
  scannerRule(
    code: const LintCode(
      'flutter_key_created_in_build',
      'Do not create keys inside build().',
      correctionMessage: 'Move stable keys to a field, registry, or source value outside build().',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags local key construction inside build methods so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final method in context.methods.where((method) => method.name == 'build')) {
        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (_declaresLocalKey(line)) {
            reporter.report(context, i, _keyConstructorColumn(line));
          }
        }
      }
    },
  ),

  /// Avoid UniqueKey and GlobalKey unless identity recreation or state access is required.
  ///
  /// Why: Flags UniqueKey and GlobalKey construction. Prefer ValueKey or ObjectKey for normal
  /// state preservation.
  scannerRule(
    code: const LintCode(
      'flutter_unique_or_global_key',
      'Avoid UniqueKey and GlobalKey unless identity recreation or state access is required.',
      correctionMessage: 'Prefer ValueKey or ObjectKey for normal state preservation.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags UniqueKey and GlobalKey construction so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (_containsConstructor(line, 'UniqueKey') || _containsConstructor(line, 'GlobalKey')) {
          reporter.report(
            context,
            i,
            _firstConstructorColumn(line, const ['UniqueKey', 'GlobalKey']),
          );
        }
      }
    },
  ),

  /// Avoid the Opacity widget for static opacity.
  ///
  /// Why: Flags Opacity widget construction. Use a semi-transparent color for static opacity
  /// or FadeTransition for animation.
  scannerRule(
    code: const LintCode(
      'flutter_opacity_widget',
      'Avoid the Opacity widget for static opacity.',
      correctionMessage:
          'Use a semi-transparent color for static opacity or FadeTransition for animation.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Opacity widget construction so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportConstructors(reporter, context, const ['Opacity']);
    },
  ),

  /// Avoid ShaderMask and ColorFilter saveLayer triggers in hot UI.
  ///
  /// Why: Flags ShaderMask, ColorFiltered, and ColorFilter usage. Prefer cheaper painting or
  /// precomputed assets when a saveLayer is not required.
  scannerRule(
    code: const LintCode(
      'flutter_save_layer_filter',
      'Avoid ShaderMask and ColorFilter saveLayer triggers in hot UI.',
      correctionMessage:
          'Prefer cheaper painting or precomputed assets when a saveLayer is not required.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags ShaderMask, ColorFiltered, and ColorFilter usage so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = _firstFilterColumn(line);
        if (column >= 0) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Avoid Clip.antiAliasWithSaveLayer.
  ///
  /// Why: Flags Clip.antiAliasWithSaveLayer usage. Use border radius, Clip.hardEdge, or
  /// Clip.antiAlias when possible.
  scannerRule(
    code: const LintCode(
      'flutter_clip_save_layer',
      'Avoid Clip.antiAliasWithSaveLayer.',
      correctionMessage: 'Use border radius, Clip.hardEdge, or Clip.antiAlias when possible.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags Clip.antiAliasWithSaveLayer usage so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = line.indexOf('Clip.antiAliasWithSaveLayer');
        if (column >= 0) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Avoid IntrinsicWidth and IntrinsicHeight in performance-sensitive UI.
  ///
  /// Why: Flags intrinsic layout widgets. Prefer fixed constraints, ConstrainedBox, or direct
  /// layout.
  scannerRule(
    code: const LintCode(
      'flutter_intrinsic_layout',
      'Avoid IntrinsicWidth and IntrinsicHeight in performance-sensitive UI.',
      correctionMessage: 'Prefer fixed constraints, ConstrainedBox, or direct layout.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags intrinsic layout widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      _reportConstructors(reporter, context, const ['IntrinsicWidth', 'IntrinsicHeight']);
    },
  ),

  /// AnimatedBuilder should pass static subtrees through child.
  ///
  /// Why: Flags AnimatedBuilder calls without a child argument. Move static widgets to
  /// AnimatedBuilder.child and reuse child in builder.
  scannerRule(
    code: const LintCode(
      'flutter_animated_builder_child',
      'AnimatedBuilder should pass static subtrees through child.',
      correctionMessage: 'Move static widgets to AnimatedBuilder.child and reuse child in builder.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags AnimatedBuilder calls without a child argument so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final column = _constructorColumn(line, 'AnimatedBuilder');
        if (column < 0) continue;

        final endLine = _callEndLine(context, i, column);
        if (!_hasTopLevelNamedArgument(context, i, column, endLine, 'child')) {
          reporter.report(context, i, column);
        }
      }
    },
  ),

  /// Do not override operator == on Widget classes.
  ///
  /// Why: Flags operator == overrides on Widget classes. Use const constructors, stable
  /// inputs, and caching instead.
  scannerRule(
    code: const LintCode(
      'flutter_widget_operator_equals',
      'Do not override operator == on Widget classes.',
      correctionMessage: 'Use const constructors, stable inputs, and caching instead.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags operator == overrides on Widget classes so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        if (!_isWidgetClass(context, classSpan)) continue;
        for (var i = classSpan.start; i <= classSpan.end; i++) {
          final line = context.source.masked[i];
          final column = line.indexOf('operator');
          if (column >= 0 && RegExp(r'\boperator\s*==\s*\(').hasMatch(line)) {
            reporter.report(context, i, column);
          }
        }
      }
    },
  ),
];

final RegExp _localKeyDeclarationPattern = RegExp(
  r'^\s*(?:late\s+)?(?:final|var|Key|LocalKey|ValueKey(?:<[^>]+>)?|ObjectKey|UniqueKey|GlobalKey(?:<[^>]+>)?)\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*(?:const\s+)?(?:Key|ValueKey|ObjectKey|UniqueKey|GlobalKey)\s*(?:<[^>]+>)?\s*\(',
);

bool _declaresLocalKey(String line) => _localKeyDeclarationPattern.hasMatch(line);

int _keyConstructorColumn(String line) =>
    _firstConstructorColumn(line, const ['Key', 'ValueKey', 'ObjectKey', 'UniqueKey', 'GlobalKey']);

void _reportConstructors(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  List<String> names,
) {
  for (var i = 0; i < context.source.length; i++) {
    final line = context.source.masked[i];
    final column = _firstConstructorColumn(line, names);
    if (column >= 0) {
      reporter.report(context, i, column);
    }
  }
}

bool _containsConstructor(String line, String name) => _constructorColumn(line, name) >= 0;

int _firstConstructorColumn(String line, List<String> names) {
  var result = -1;
  for (final name in names) {
    final column = _constructorColumn(line, name);
    if (column < 0) continue;
    if (result < 0 || column < result) {
      result = column;
    }
  }
  return result;
}

int _constructorColumn(String line, String name) {
  final pattern = RegExp('\\b$name\\s*(?:<[^>]+>)?\\s*\\(');
  return pattern.firstMatch(line)?.start ?? -1;
}

int _firstFilterColumn(String line) {
  final constructorColumn = _firstConstructorColumn(line, const [
    'ShaderMask',
    'ColorFiltered',
    'ColorFilter',
  ]);
  if (constructorColumn >= 0) return constructorColumn;

  final colorFilterFactory = RegExp(r'\bColorFilter\s*\.').firstMatch(line);
  return colorFilterFactory?.start ?? -1;
}

int _callEndLine(SourceScannerContext context, int startLine, int startColumn) {
  var depth = 0;
  var sawOpenParen = false;
  for (var lineIndex = startLine; lineIndex < context.source.length; lineIndex++) {
    final line = context.source.masked[lineIndex];
    final start = lineIndex == startLine ? startColumn : 0;
    for (var column = start; column < line.length; column++) {
      final char = line[column];
      if (char == '(') {
        sawOpenParen = true;
        depth++;
      } else if (char == ')' && sawOpenParen) {
        depth--;
        if (depth == 0) return lineIndex;
      }
    }
  }
  return startLine;
}

bool _hasTopLevelNamedArgument(
  SourceScannerContext context,
  int startLine,
  int startColumn,
  int endLine,
  String name,
) {
  var parenDepth = 0;
  var braceDepth = 0;
  var bracketDepth = 0;
  for (var lineIndex = startLine; lineIndex <= endLine; lineIndex++) {
    final line = context.source.masked[lineIndex];
    final start = lineIndex == startLine ? startColumn : 0;
    for (var column = start; column < line.length; column++) {
      if (parenDepth == 1 &&
          braceDepth == 0 &&
          bracketDepth == 0 &&
          _hasNamedArgumentAt(line, column, name)) {
        return true;
      }

      final char = line[column];
      if (char == '(') {
        parenDepth++;
      } else if (char == ')') {
        parenDepth--;
      } else if (char == '{') {
        braceDepth++;
      } else if (char == '}') {
        braceDepth--;
      } else if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        bracketDepth--;
      }
    }
  }
  return false;
}

bool _hasNamedArgumentAt(String line, int column, String name) {
  if (!line.startsWith(name, column)) return false;
  final before = column == 0 ? '' : line[column - 1];
  if (_isIdentifierChar(before)) return false;

  final afterName = column + name.length;
  if (afterName < line.length && _isIdentifierChar(line[afterName])) return false;

  var cursor = afterName;
  while (cursor < line.length && line[cursor].trim().isEmpty) {
    cursor++;
  }
  return cursor < line.length && line[cursor] == ':';
}

bool _isIdentifierChar(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return code == 95 ||
      code >= 48 && code <= 57 ||
      code >= 65 && code <= 90 ||
      code >= 97 && code <= 122;
}

bool _isWidgetClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  final signature = _classSignature(context, classSpan);
  return RegExp(
        r'\bextends\s+(?:[A-Za-z_][A-Za-z0-9_]*\.)?(?:StatelessWidget|StatefulWidget|Widget|ConsumerWidget|HookWidget)\b',
      ).hasMatch(signature) ||
      RegExp(
        r'\bextends\s+(?:[A-Za-z_][A-Za-z0-9_]*\.)?[A-Za-z_][A-Za-z0-9_]*Widget\b',
      ).hasMatch(signature);
}

String _classSignature(SourceScannerContext context, ScannerClassSpan classSpan) {
  final buffer = StringBuffer();
  for (var i = classSpan.start; i <= classSpan.end; i++) {
    buffer.write(' ');
    buffer.write(context.source.masked[i]);
    if (context.source.masked[i].contains('{')) break;
  }
  return buffer.toString();
}
