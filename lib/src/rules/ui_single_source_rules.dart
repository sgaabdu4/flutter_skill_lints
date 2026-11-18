import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> uiSingleSourceRules = [
  /// Base controls belong to the shared UI library listed in hard-eng.gates.json.
  scannerRule(
    code: const LintCode(
      'ui_base_control_outside_library',
      'Base controls belong to the shared UI library.',
      correctionMessage: 'Make it a part of the shared library and use that part',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags base buttons, text fields, dropdowns, dialogs and search widgets built outside the ui_library paths of hard-eng.gates.json (lib/core/widgets/ when it lists none).',
    scan: (reporter, context) {
      if (!context.path.startsWith('lib/') || context.isTestFile) return;

      final hits = <(int, int)>[];
      for (var i = 0; i < context.source.length; i++) {
        for (final match in _baseControl.allMatches(context.source.masked[i])) {
          hits.add((i, match.start));
        }
      }
      if (hits.isEmpty || context.isUiLibraryFile) return;
      for (final (line, column) in hits) {
        reporter.report(context, line, column);
      }
    },
  ),
];

final _baseControl = RegExp(
  r'\b(?:ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|CupertinoButton'
  r'|TextField|TextFormField|CupertinoTextField|CupertinoTextFormFieldRow'
  r'|DropdownButton|DropdownButtonFormField|DropdownMenu'
  r'|AlertDialog|SimpleDialog|Dialog|CupertinoAlertDialog'
  r'|SearchBar|SearchAnchor|CupertinoSearchTextField)'
  r'(?:\s*<(?:[^<>]|<(?:[^<>]|<[^<>]*>)*>)*>)?'
  r'(?:\s*\.\s*(?!styleFrom\b|defaultStyleOf\b|allOf\b)\w+)?\s*\(',
);
