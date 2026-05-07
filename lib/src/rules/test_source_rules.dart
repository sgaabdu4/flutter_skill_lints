import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> testSourceRules = [
  /// Use ProviderContainer.test in tests.
  ///
  /// Why: Flags direct ProviderContainer construction in tests. Replace
  /// ProviderContainer(...) with ProviderContainer.test().
  scannerRule(
    code: const LintCode(
      'test_provider_container',
      'Use ProviderContainer.test in tests.',
      correctionMessage: 'Replace ProviderContainer(...) with ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags direct ProviderContainer construction in tests so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bProviderContainer\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ProviderContainer'));
        }
      }
    },
  ),

  /// Use UncontrolledProviderScope in tests.
  ///
  /// Why: Flags ProviderScope usage in tests. Wrap test widgets with an explicit test
  /// container.
  scannerRule(
    code: const LintCode(
      'test_uncontrolled_scope',
      'Use UncontrolledProviderScope in tests.',
      correctionMessage: 'Wrap test widgets with an explicit test container.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags ProviderScope usage in tests so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bProviderScope\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('ProviderScope'));
        }
      }
    },
  ),

  /// Avoid createContainer test helpers.
  ///
  /// Why: Flags createContainer test helpers. Use ProviderContainer.test().
  scannerRule(
    code: const LintCode(
      'test_create_container',
      'Avoid createContainer test helpers.',
      correctionMessage: 'Use ProviderContainer.test().',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags createContainer test helpers so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\bcreateContainer\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('createContainer'));
        }
      }
    },
  ),

  /// Mocks should implement interfaces, not concrete classes.
  ///
  /// Why: Flags mocks that implement concrete classes. Mock I* contracts instead of concrete
  /// implementations.
  scannerRule(
    code: const LintCode(
      'test_mock_concrete',
      'Mocks should implement interfaces, not concrete classes.',
      correctionMessage: 'Mock I* contracts instead of concrete implementations.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags mocks that implement concrete classes so the Flutter skill violation is shown during analysis.',
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

  /// Avoid unbounded pumpAndSettle in tests.
  ///
  /// Why: Flags pumpAndSettle calls without an explicit duration argument. Use explicit pumps or
  /// pass a bounded Duration.
  scannerRule(
    code: const LintCode(
      'test_pump_and_settle',
      'Avoid unbounded pumpAndSettle in tests.',
      correctionMessage: 'Use explicit pumps or pass a bounded Duration argument.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags pumpAndSettle calls without an explicit duration argument so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile &&
            RegExp(r'\bpumpAndSettle\s*\(').hasMatch(line) &&
            RegExp(r'\bpumpAndSettle\s*\(\s*\)').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('pumpAndSettle'));
        }
      }
    },
  ),

  /// Avoid coordinate-based test taps.
  ///
  /// Why: Flags coordinate-based test taps. Use stable ValueKey finders.
  scannerRule(
    code: const LintCode(
      'test_tap_at',
      'Avoid coordinate-based test taps.',
      correctionMessage: 'Use stable ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags coordinate-based test taps so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (context.isTestFile && RegExp(r'\btapAt\s*\(').hasMatch(line)) {
          reporter.report(context, i, line.indexOf('tapAt'));
        }
      }
    },
  ),

  /// Avoid inline ValueKey strings.
  ///
  /// Why: Flags inline ValueKey string literals outside key registries. Centralize widget
  /// keys in a key registry.
  scannerRule(
    code: const LintCode(
      'test_inline_value_key',
      'Avoid inline ValueKey strings.',
      correctionMessage: 'Centralize widget keys in a key registry.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags inline ValueKey string literals outside key registries so the Flutter skill violation is shown during analysis.',
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

  /// Avoid first-match widget finders in tests.
  ///
  /// Why: Flags first-match widget finder usage in tests. Use deterministic ValueKey finders.
  scannerRule(
    code: const LintCode(
      'test_first_match_finder',
      'Avoid first-match widget finders in tests.',
      correctionMessage: 'Use deterministic ValueKey finders.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description:
        'Flags first-match widget finder usage in tests so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        final hasByIcon = line.contains('find.byIcon');
        final hasFinderFirst =
            line.contains('.first') && (line.contains('find.') || line.contains('Finder'));
        if (context.isTestFile && (hasByIcon || hasFinderFirst)) {
          reporter.report(context, i, 0);
        }
      }
    },
  ),
];
