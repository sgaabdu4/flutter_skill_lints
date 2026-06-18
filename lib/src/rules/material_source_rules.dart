import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> materialSourceRules = [
  /// Random widgets must not create raw Material/Ink surfaces.
  ///
  /// Why: `Material`, `Ink`, and `InkWell` define surface, ink, clipping,
  /// ripple, and tap policy. Keep that policy in app shell/theme/atoms/dedicated
  /// primitives, not in arbitrary molecules, organisms, screens, dialogs, or
  /// sheets.
  scannerRule(
    code: const LintCode(
      'widget_material_boundary',
      'Random widgets must not create raw Material/Ink surfaces.',
      correctionMessage:
          'Move the concrete widget that owns this tap/surface into lib/core/widgets/atoms/, or compose an existing atom such as BentoCard. Do not add a pass-through Material wrapper.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags raw Material/Ink construction in non-atom UI widgets so surface/ink policy stays owned by app primitives.',
    scan: (reporter, context) {
      if (!context.isUiFile || context.isTestFile || _isMaterialOwnerPath(context.path)) {
        return;
      }

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        for (final match in _rawMaterialInkConstructor.allMatches(line)) {
          reporter.report(context, i, match.start);
        }
      }
    },
  ),

  /// Atoms are the lowest widget layer and must not depend upward.
  ///
  /// Why: atoms may own Material/Ink policy, so they must be concrete,
  /// self-contained primitives. Importing molecules, organisms, templates, or
  /// feature presentation widgets turns the atom into a boundary bypass.
  scannerRule(
    code: const LintCode(
      'atom_widget_layer_dependency',
      'Atoms must not import higher-level widget layers.',
      correctionMessage:
          'Move the reusable dependency down into atoms, or keep the widget in the higher layer and compose existing atoms.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags atom imports from higher widget layers so atomic design remains one-way.',
    scan: (reporter, context) {
      if (context.isTestFile || !_isAtomWidgetPath(context.path)) return;

      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.original[i];
        final importMatch = _importUri.firstMatch(line);
        if (importMatch == null) continue;
        final uri = importMatch.group(1) ?? '';
        if (_isHigherWidgetLayerImport(uri)) {
          reporter.report(context, i, importMatch.start);
        }
      }
    },
  ),
];

final _rawMaterialInkConstructor = RegExp(r'\b(?:Material|Ink|InkWell)\s*\(');
final _importUri = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

bool _isMaterialOwnerPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return _isAtomWidgetPath(normalized) ||
      normalized.startsWith('lib/core/theme/') ||
      normalized == 'lib/main.dart' ||
      normalized == 'lib/app.dart' ||
      normalized.endsWith('/app.dart') ||
      normalized.endsWith('/app_root.dart');
}

bool _isAtomWidgetPath(String path) =>
    path.replaceAll('\\', '/').startsWith('lib/core/widgets/atoms/');

bool _isHigherWidgetLayerImport(String uri) {
  final normalized = uri.replaceAll('\\', '/');
  return normalized.contains('/core/widgets/molecules/') ||
      normalized.contains('/core/widgets/organisms/') ||
      normalized.contains('/core/widgets/templates/') ||
      normalized.startsWith('../molecules/') ||
      normalized.startsWith('../organisms/') ||
      normalized.startsWith('../templates/') ||
      (normalized.contains('/features/') && normalized.contains('/presentation/'));
}
