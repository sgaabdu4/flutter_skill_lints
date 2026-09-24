import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
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

  /// Avoid inline string widget keys.
  ///
  /// Why: Flags `Key('...')` / `ValueKey('...')` string literals outside key registries.
  /// Centralize widget keys in a key registry.
  scannerRule(
    code: const LintCode(
      'test_inline_value_key',
      'Avoid inline string widget keys.',
      correctionMessage: 'Centralize widget keys in a key registry.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags inline Key/ValueKey string literals outside key registries so the Flutter skill violation is shown during analysis.',
    scan: _scanInlineStringKeys,
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
    scan: _scanFirstMatchFinders,
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
  if (superclass is! ClassElement || !_testDoubleBaseChecker.isExactly(superclass)) return false;
  return (declaration.implementsClause?.interfaces ?? <NamedType>[]).any((interface) {
    final type = interface.type;
    final element = type is InterfaceType ? type.element : null;
    return element is ClassElement &&
        element.isConstructable &&
        !_isAllowedExternalMockBoundary(element);
  });
}

bool _isAllowedExternalMockBoundary(ClassElement element) =>
    switch ((element.firstFragment.libraryFragment.source.uri.toString(), element.name)) {
      ('package:appwrite/services/account.dart', 'Account') => true,
      ('package:appwrite/services/functions.dart', 'Functions') => true,
      ('package:appwrite/services/storage.dart', 'Storage') => true,
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

const _testDoubleBaseChecker = TypeChecker.any([
  TypeChecker.fromName('Mock', packageName: 'mocktail'),
  TypeChecker.fromName('Mock', packageName: 'mockito'),
  TypeChecker.fromName('Fake', packageName: 'test_api'),
]);

const _widgetKeyChecker = TypeChecker.any([
  TypeChecker.fromName('Key', packageName: 'flutter'),
  TypeChecker.fromName('ValueKey', packageName: 'flutter'),
]);

const _finderChecker = TypeChecker.fromName('FinderBase', packageName: 'flutter_test');

void _scanInlineStringKeys(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (context.isKeyRegistryFile) return;
  final visitor = _NodeCollector<InstanceCreationExpression>();
  context.unit.accept(visitor);
  for (final creation in visitor.nodes) {
    final keyClass = creation.constructorName.element?.enclosingElement;
    if (keyClass == null || !_widgetKeyChecker.isExactly(keyClass)) continue;
    final value = creation.argumentList.arguments.firstOrNull;
    if (value is! StringLiteral) continue;
    _reportNode(reporter, context, creation.constructorName);
  }
}

void _scanFirstMatchFinders(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!context.isTestFile) return;
  final reportedLines = <int>{};
  for (var i = 0; i < context.source.length; i++) {
    if (!context.source.masked[i].contains('find.byIcon')) continue;
    reporter.report(context, i, 0);
    reportedLines.add(i);
  }
  final visitor = _NodeCollector<SimpleIdentifier>();
  context.unit.accept(visitor);
  for (final identifier in visitor.nodes) {
    if (identifier.name != 'first') continue;
    final parent = identifier.parent;
    final target = switch (parent) {
      PropertyAccess() when parent.propertyName == identifier => parent.realTarget,
      PrefixedIdentifier() when parent.identifier == identifier => parent.prefix,
      _ => null,
    };
    final type = target?.staticType;
    if (type == null || !_finderChecker.isAssignableFromType(type)) continue;
    final line = context.unit.lineInfo.getLocation(identifier.offset).lineNumber - 1;
    if (reportedLines.add(line)) _reportNode(reporter, context, identifier);
  }
}

void _reportNode(ScannerRuleReporter reporter, SourceScannerContext context, AstNode node) {
  final location = context.unit.lineInfo.getLocation(node.offset);
  reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
}

final class _NodeCollector<T extends AstNode> extends GeneralizingAstVisitor<void> {
  final nodes = <T>[];

  @override
  void visitNode(AstNode node) {
    if (node is T) nodes.add(node);
    super.visitNode(node);
  }
}
