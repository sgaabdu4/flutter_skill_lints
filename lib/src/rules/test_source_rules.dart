import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
    description: 'Flags direct ProviderContainer construction in tests so the Flutter skill violation is shown during analysis.',
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
    description: 'Flags ProviderScope usage in tests so the Flutter skill violation is shown during analysis.',
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
    description: 'Flags createContainer test helpers so the Flutter skill violation is shown during analysis.',
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
  /// Why: A mock must implement a non-constructable contract rather than a
  /// concrete class. The contract's declared name does not determine this.
  scannerRule(
    code: const LintCode(
      'test_mock_concrete',
      'Mocks should implement interfaces, not concrete classes.',
      correctionMessage: 'Mock an abstract contract instead of a concrete implementation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags mocks that implement concrete classes so the Flutter skill violation is shown during analysis.',
    scan: _scanConcreteMockContracts,
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
    description: 'Flags pumpAndSettle calls without an explicit duration argument so the Flutter skill violation is shown during analysis.',
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
    description: 'Flags inline ValueKey string literals outside key registries so the Flutter skill violation is shown during analysis.',
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
    description: 'Flags first-match widget finder usage in tests so the Flutter skill violation is shown during analysis.',
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

void _scanConcreteMockContracts(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!context.isTestFile) return;
  for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
    if (!_mockImplementsConcreteContract(declaration)) continue;
    final location = context.unit.lineInfo.getLocation(declaration.offset);
    reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
  }
}

bool _mockImplementsConcreteContract(ClassDeclaration declaration) {
  final superclass = declaration.extendsClause?.superclass.element;
  if (superclass is! ClassElement || superclass.name != 'Mock') return false;
  return (declaration.implementsClause?.interfaces ?? <NamedType>[]).any((interface) {
    final type = interface.type;
    final element = type is InterfaceType ? type.element : null;
    return element is ClassElement &&
        element.isConstructable &&
        !_isAllowedExternalMockBoundary(element);
  });
}

bool _isAllowedExternalMockBoundary(ClassElement element) =>
    switch ((element.library.uri.toString(), element.name)) {
      ('package:appwrite/services/account.dart', 'Account') => true,
      ('package:appwrite/services/tables_db.dart', 'TablesDB') => true,
      ('package:appwrite/services/teams.dart', 'Teams') => true,
      (
        'package:youtube_player_iframe/src/controller/youtube_player_controller.dart',
        'YoutubePlayerController',
      ) =>
        true,
      ('package:youtube_player_iframe/src/player_value.dart', 'YoutubePlayerValue') => true,
      _ => false,
    };
