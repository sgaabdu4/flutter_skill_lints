import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
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

  /// Override repositories or datasources, not notifiers, in tests.
  ///
  /// Why: testing.md requires overriding at the repo/datasource level and never
  /// mocking notifiers directly. `overrideWith(Fake.new)` on a notifier provider
  /// replaces the notifier under test; `overrideWithBuild` and
  /// `overrideWithValue` stay allowed.
  scannerRule(
    code: const LintCode(
      'test_notifier_override',
      'Do not replace a notifier in tests.',
      correctionMessage: 'Override the repository/datasource provider, or use overrideWithBuild to keep the notifier methods.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags overrideWith on Riverpod notifier providers in tests so the Flutter skill violation is shown during analysis.',
    scan: _scanNotifierOverrides,
  ),

  /// Avoid blind sleeps in E2E tests.
  ///
  /// Why: E2E flows must wait on semantic UI or source-of-truth state. An
  /// awaited `Future.delayed` or `dart:io` `sleep` outside a polling loop is a
  /// blind sleep.
  scannerRule(
    code: const LintCode(
      'test_e2e_blind_sleep',
      'Avoid blind sleeps in E2E tests.',
      correctionMessage:
          'Wait for semantic UI state or source-of-truth state instead of a fixed delay.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags awaited Future.delayed and sleep calls in integration_test/ and test_driver/ so the Flutter skill violation is shown during analysis.',
    scan: _scanE2eBlindSleeps,
  ),

  /// Avoid case-sensitive label text as a widget-test interaction selector.
  ///
  /// Why: testing.md forbids case-sensitive label text selectors for taps and
  /// other interactions. Assertions such as `expect(find.text(...), ...)` stay
  /// allowed.
  scannerRule(
    code: const LintCode(
      'test_text_label_selector',
      'Avoid case-sensitive label text as a test interaction selector.',
      correctionMessage: 'Select the widget with a ValueKey from the central key registry.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags literal find.text/widgetWithText finders passed to WidgetTester interactions so the Flutter skill violation is shown during analysis.',
    scan: _scanTextLabelSelectors,
  ),
];

void _scanNotifierOverrides(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!context.isTestFile) return;
  for (final call in collectNodes<MethodInvocation>(context.unit)) {
    final name = call.methodName.name;
    if (name != 'overrideWith' && name != 'overrideWith2') continue;
    final library = call.methodName.element?.library?.identifier ?? '';
    final create = call.argumentList.arguments.whereType<Expression>().firstOrNull?.staticType;
    if (library.startsWith('package:riverpod/') &&
        create is FunctionType &&
        anyNotifierChecker.isAssignableFromType(create.returnType)) {
      reporter.reportNode(context, call.methodName);
    }
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

final _e2ePath = RegExp(r'(^|/)(?:integration_test|test_driver)/');

void _scanE2eBlindSleeps(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!_e2ePath.hasMatch(context.path)) return;
  for (final node in collectNodes<Expression>(context.unit)) {
    if (_isBlindSleep(node) && !_isInsidePollingLoop(node)) reporter.reportNode(context, node);
  }
}

bool _isBlindSleep(Expression node) => switch (node) {
  InstanceCreationExpression(:final constructorName, :final staticType?)
      when node.parent is AwaitExpression =>
    constructorName.name?.name == 'delayed' && _futureChecker.isExactlyType(staticType),
  MethodInvocation(:final methodName) =>
    methodName.name == 'sleep' && methodName.element?.library?.identifier == 'dart:io',
  _ => false,
};

bool _isInsidePollingLoop(AstNode node) {
  for (
    var current = node.parent;
    current != null && current is! FunctionBody;
    current = current.parent
  ) {
    if (current is WhileStatement || current is DoStatement || current is ForStatement) return true;
  }
  return false;
}

const _widgetControllerChecker = TypeChecker.fromName(
  'WidgetController',
  packageName: 'flutter_test',
);
const _commonFindersChecker = TypeChecker.fromName('CommonFinders', packageName: 'flutter_test');
const _testerInteractions = {
  'tap',
  'longPress',
  'drag',
  'enterText',
  'fling',
  'timedDrag',
  'press',
};
const _labelFinders = {'text', 'textContaining', 'widgetWithText'};

void _scanTextLabelSelectors(ScannerRuleReporter reporter, SourceScannerContext context) {
  if (!context.path.startsWith('test/') || _e2ePath.hasMatch(context.path)) return;
  for (final call in collectNodes<MethodInvocation>(context.unit)) {
    final testerType = call.realTarget?.staticType;
    if (!_testerInteractions.contains(call.methodName.name) ||
        testerType == null ||
        !_widgetControllerChecker.isAssignableFromType(testerType)) {
      continue;
    }
    for (final finder in collectNodes<MethodInvocation>(call.argumentList)) {
      if (_isLiteralLabelFinder(finder)) reporter.reportNode(context, finder);
    }
  }
}

bool _isLiteralLabelFinder(MethodInvocation finder) {
  final findersType = finder.realTarget?.staticType;
  return _labelFinders.contains(finder.methodName.name) &&
      findersType != null &&
      _commonFindersChecker.isExactlyType(findersType) &&
      finder.argumentList.arguments.any((argument) => argument is StringLiteral);
}

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
    return element is ClassElement && element.isConstructable;
  });
}

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
  for (final creation in collectNodes<InstanceCreationExpression>(context.unit)) {
    final keyClass = creation.constructorName.element?.enclosingElement;
    if (keyClass == null || !_widgetKeyChecker.isExactly(keyClass)) continue;
    final value = creation.argumentList.arguments.firstOrNull;
    if (value is! StringLiteral) continue;
    reporter.reportNode(context, creation.constructorName);
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
  for (final identifier in collectNodes<SimpleIdentifier>(context.unit)) {
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
    if (reportedLines.add(line)) reporter.reportNode(context, identifier);
  }
}
