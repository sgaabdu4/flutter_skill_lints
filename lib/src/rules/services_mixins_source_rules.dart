import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> servicesMixinsSourceRules = [
  /// Keep singleton instance fields plain and boring.
  ///
  /// Why: Allows only the boring fire-and-forget singleton shape (private constructor + one
  /// static final instance + void/Future<void> public methods) while flagging public
  /// constructors, state/data APIs, mutable resources, debug injection seams, service locators,
  /// and fake/backend swapping inside the singleton itself.
  scannerRule(
    code: const LintCode(
      'service_singleton',
      'Singleton is not plain and boring.',
      correctionMessage:
          'Use a private constructor with one static final instance/trivial getter and void/Future<void> public methods only. Move data/stateful services to a provider/repository boundary.',
      severity: DiagnosticSeverity.WARNING,
    ),
    description:
        'Flags singleton shapes that are mutable, injectable, or missing a private constructor so the Flutter skill singleton guidance is shown during analysis.',
    scan: (reporter, context) {
      for (final classSpan in context.classes) {
        final singletonLine = _singletonInstanceLine(context, classSpan);
        if (singletonLine == null) continue;

        final body = context.source.masked.sublist(classSpan.start, classSpan.end + 1).join('\n');
        if (_hasPrivateConstructor(body, classSpan.name) &&
            !_hasMutableInstanceBacking(body) &&
            !_hasOverbuiltSingletonSeam(body) &&
            !_hasMutableSingletonState(body) &&
            !_hasPublicDataApi(body)) {
          continue;
        }

        final line = context.source.masked[singletonLine];
        reporter.report(context, singletonLine, line.indexOf('static'));
      }
    },
  ),

  /// Avoid mixin class for capability mixins.
  ///
  /// Why: Flags mixin class declarations for capability mixins. Use mixin for reusable
  /// behavior.
  scannerRule(
    code: const LintCode(
      'mixin_mixin_class',
      'Avoid mixin class for capability mixins.',
      correctionMessage: 'Use mixin for reusable behavior.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags mixin class declarations for capability mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (RegExp(r'^\s*mixin\s+class\s+\w+').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('mixin'));
        }
      }
    },
  ),

  /// Mixin names should end with Mixin.
  ///
  /// Why: Flags capability mixins without the Mixin suffix. Suffix capability mixins with
  /// Mixin.
  scannerRule(
    code: const LintCode(
      'mixin_name_suffix',
      'Mixin names should end with Mixin.',
      correctionMessage: 'Suffix capability mixins with Mixin.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags capability mixins without the Mixin suffix so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final mixinMatch = RegExp(r'^\s*mixin(?:\s+class)?\s+(\w+)').firstMatch(line);
        if (mixinMatch != null && !(mixinMatch.group(1) ?? '').endsWith('Mixin')) {
          reporter.report(context, i, mixinMatch.start);
        }
      }
    },
  ),

  /// Mixins should not carry mutable state.
  ///
  /// Why: Flags mutable fields inside mixins. Keep mixins stateless.
  scannerRule(
    code: const LintCode(
      'mixin_mutable_state',
      'Mixins should not carry mutable state.',
      correctionMessage: 'Keep mixins stateless.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags mutable fields inside mixins so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        if (context.isMutableMixinField(i)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];

final _singletonInstanceDeclaration = RegExp(
  r'\bstatic\s+(?:final\s+)?(?:[A-Za-z_]\w*(?:<[^>]+>)?\s+)?(?:get\s+)?instance\b',
);

final _mutableInstanceBacking = RegExp(
  r'\bstatic\s+(?!final\b)(?![A-Za-z_]\w*(?:<[^>]+>)?\s+get\s+instance\b)'
  r'[^;\n=]*\b_?instance\b',
);

final _overbuiltSingletonSeam = RegExp(
  r'\b(?:debug(?:Reset|Configure|Use|Set|Override)\w*|resetForTest(?:ing)?|'
  r'set(?:Instance|Backend|Client|Provider)\w*|'
  r'overrideWithValue|Fake[A-Z]\w*|Mock[A-Z]\w*|'
  r'ServiceLocator|serviceLocator|locator|Backend|backend)\b',
);

final _mutableInstanceField = RegExp(
  r'^(?:late\s+)?(?:var|[A-Za-z_]\w*(?:<[^>]+>)?)\s+_[A-Za-z_]\w*\s*(?:=|;)',
);

final _mutableFinalResourceField = RegExp(
  r'^(?:late\s+)?final\s+(?:[A-Za-z_]\w*(?:<[^>]+>)?\s+)?_[A-Za-z_]\w*\s*=\s*'
  r'(?:<[^>]*>[\[{]|\[|\{|StreamController\b|Timer\b|[A-Za-z_]\w*Controller\b|'
  r'[A-Za-z_]\w*Subscription\b|HttpClient\b)',
);

final _publicDataMethod = RegExp(
  r'^(?:static\s+)?(?!(?:void|Future\s*<\s*void\s*>)\s+)'
  r'(?:Future(?:\s*<[^>]+>)?|[A-Za-z_]\w*(?:<[^>]+>)?)\s+'
  r'(?!get\b|set\b|instance\b|_)\w+\s*\(',
);

final _publicGetter = RegExp(
  r'^(?:static\s+)?[A-Za-z_]\w*(?:<[^>]+>)?\s+get\s+(?!instance\b|_)\w+\b',
);

final _publicField = RegExp(
  r'^(?:static\s+)?(?:final|var|late\s+final|late|const)\s+'
  r'(?:[A-Za-z_]\w*(?:<[^>]+>)?\s+)?(?!instance\b|_)\w+\b',
);

final _classDeclarationLine = RegExp(r'^(?:abstract\s+)?(?:base\s+)?(?:final\s+)?class\s+');
final _privateMemberLine = RegExp(r'\b_[A-Za-z_]\w*\b');

int? _singletonInstanceLine(SourceScannerContext context, ScannerClassSpan classSpan) {
  for (var i = classSpan.start; i <= classSpan.end && i < context.source.length; i++) {
    if (_singletonInstanceDeclaration.hasMatch(context.source.masked[i])) return i;
  }
  return null;
}

bool _hasPrivateConstructor(String body, String className) {
  return RegExp(r'\b' + RegExp.escape(className) + r'\._[A-Za-z0-9_]*\s*\(').hasMatch(body);
}

bool _hasMutableInstanceBacking(String body) {
  return _mutableInstanceBacking.hasMatch(body);
}

bool _hasOverbuiltSingletonSeam(String body) {
  return _overbuiltSingletonSeam.hasMatch(body);
}

bool _hasMutableSingletonState(String body) {
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('static ') || trimmed.startsWith('const ')) continue;
    if (_mutableInstanceField.hasMatch(trimmed)) return true;
    if (_mutableFinalResourceField.hasMatch(trimmed)) return true;
  }
  return false;
}

bool _hasPublicDataApi(String body) {
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (_isPublicDataApiLine(trimmed)) return true;
  }
  return false;
}

bool _isPublicDataApiLine(String line) {
  if (line.startsWith('//') || line.startsWith('@')) return false;
  if (_classDeclarationLine.hasMatch(line) || _singletonInstanceDeclaration.hasMatch(line)) {
    return false;
  }
  if (_privateMemberLine.hasMatch(line)) return false;
  return _publicDataMethod.hasMatch(line) ||
      _publicGetter.hasMatch(line) ||
      _publicField.hasMatch(line);
}
