import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> testSourceRules = [
  scannerRule(
    code: const LintCode(
      'test_provider_container',
      'Use ProviderContainer.test in tests.',
      correctionMessage: 'Replace ProviderContainer(...) with ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports direct ProviderContainer construction in tests.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bProviderContainer\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ProviderContainer'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_uncontrolled_scope',
      'Use UncontrolledProviderScope in tests.',
      correctionMessage: 'Wrap test widgets with an explicit test container.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports ProviderScope usage in tests.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bProviderScope\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ProviderScope'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_create_container',
      'Avoid createContainer test helpers.',
      correctionMessage: 'Use ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports createContainer test helpers.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bcreateContainer\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('createContainer'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_mock_concrete',
      'Mocks should implement interfaces, not concrete classes.',
      correctionMessage: 'Mock I* contracts instead of concrete implementations.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports mocks that implement concrete classes.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile &&
            RegExp(
              r'class\s+Mock\w+\s+extends\s+Mock\s+implements\s+(?!I)[A-Z]\w+',
            ).hasMatch(line)) {
          reporter.report(context, i, line.indexOf('class'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_pump_and_settle',
      'Avoid unbounded pumpAndSettle in tests.',
      correctionMessage: 'Use explicit pumps or pass a timeout.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports pumpAndSettle calls without explicit timeout.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile &&
            RegExp(r'\bpumpAndSettle\s*\(').hasMatch(line) &&
            !line.contains('timeout')) {
          reporter.report(context, i, line.indexOf('pumpAndSettle'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_tap_at',
      'Avoid coordinate-based test taps.',
      correctionMessage: 'Use stable ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports coordinate-based test taps.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\btapAt\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('tapAt'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_inline_value_key',
      'Avoid inline ValueKey strings.',
      correctionMessage: 'Centralize widget keys in a key registry.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports inline ValueKey string literals outside key registries.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final code = context.source.code[i];
        if (!context.isKeyRegistryFile &&
            RegExp(r"""\bValueKey(?:<[^>]+>)?\s*\(\s*(?:const\s+)?["']""").hasMatch(code)) {
          reporter.report(context, i, line.indexOf('ValueKey'));
        }
      }
    },
  ),
  scannerRule(
    code: const LintCode(
      'test_first_match_finder',
      'Avoid first-match widget finders in tests.',
      correctionMessage: 'Use deterministic ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Reports first-match widget finder usage in tests.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && (line.contains('find.byIcon') || line.contains('.first'))) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
