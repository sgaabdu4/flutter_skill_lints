import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> presentationWidgetSourceRules = [
  /// Keep reusable presentation widgets free of navigation orchestration.
  ///
  /// Why: screens and typed routes own navigation; widgets emit typed callbacks.
  scannerRule(
    code: const LintCode(
      'presentation_widget_navigation_forbidden',
      'Reusable presentation widgets must not navigate.',
      correctionMessage: 'Emit a typed callback and let the screen or typed route own navigation.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Keeps navigation orchestration out of reusable presentation widgets.',
    scan: (reporter, context) => _scanPresentationWidgetLines(reporter, context, _navigationColumn),
  ),

  /// Keep reusable presentation widget State free of domain and workflow state.
  ///
  /// Why: widgets may retain UI lifecycle objects, while screens and notifiers
  /// own selection, navigation history, mutation status, and derived caches.
  scannerRule(
    code: const LintCode(
      'presentation_widget_controller_state',
      'Reusable presentation widgets must not retain domain or workflow state.',
      correctionMessage:
          'Pass immutable view data and typed callbacks; move domain and workflow state to the screen, route, or notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Keeps domain and workflow state out of reusable presentation widgets.',
    scan: (reporter, context) {
      if (!context.isPresentationWidgetFile || context.isTestFile) return;

      for (final classSpan in context.classes) {
        if (!_isWidgetStateClass(context, classSpan)) continue;

        for (var i = classSpan.start + 1; i < classSpan.end; i++) {
          if (!_isDirectClassMember(context, classSpan, i)) continue;
          final line = context.source.masked[i];
          if (_controllerStateColumn(line) case final column?) {
            reporter.report(context, i, column);
          }
        }
      }
    },
  ),

  /// Keep reusable presentation widgets free of infrastructure dependencies.
  ///
  /// Why: screens and notifiers own providers, repositories, services, and SDKs;
  /// widgets receive immutable view data and emit typed callbacks.
  scannerRule(
    code: const LintCode(
      'presentation_widget_infrastructure_dependency',
      'Reusable presentation widgets must not depend on infrastructure.',
      correctionMessage:
          'Emit a typed callback and let the screen or notifier own repositories, services, providers, and SDKs.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Keeps infrastructure access out of reusable presentation widgets.',
    scan: (reporter, context) =>
        _scanPresentationWidgetLines(reporter, context, _infrastructureColumn),
  ),
];

void _scanPresentationWidgetLines(
  ScannerRuleReporter reporter,
  SourceScannerContext context,
  int? Function(String line) findColumn,
) {
  if (!context.isPresentationWidgetFile || context.isTestFile) return;

  for (var i = 0; i < context.source.length; i++) {
    final masked = context.source.masked[i];
    final line = masked.trimLeft().startsWith('import ') ? context.source.code[i] : masked;
    if (findColumn(line) case final column?) {
      reporter.report(context, i, column);
    }
  }
}

int? _navigationColumn(String line) {
  final patterns = [
    RegExp(r'''^\s*import\s+['"][^'"]*(?:go_router|/routing/|/routes/|_route\.dart)[^'"]*['"]'''),
    RegExp(
      r'\bNavigator\s*\.\s*(?:of\s*\([^)]*\)\s*\.)?(?:push|pop|replace|restorablePush)\w*\s*\(',
    ),
    RegExp(r'\bGoRouter\s*\.\s*of\s*\([^)]*\)\s*\.\s*(?:go|push|replace|pop)\w*\s*\('),
    RegExp(
      r'\b(?:context|[A-Za-z_]\w*Context|this)\s*\.\s*(?:go|goNamed|push|pushNamed|pushReplacement|replace|replaceNamed|pop)\s*\(',
    ),
    RegExp(r'\b[A-Z]\w*Route\s*\([^;]*\)\s*\.\s*(?:go|push|replace)\s*\('),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(line);
    if (match != null) return match.start;
  }
  return null;
}

bool _isWidgetStateClass(SourceScannerContext context, ScannerClassSpan classSpan) {
  final end = (classSpan.start + 3).clamp(classSpan.start, classSpan.end);
  final signature = context.source.masked.sublist(classSpan.start, end + 1).join(' ');
  return RegExp(r'\bextends\s+(?:ConsumerState|HookConsumerState|State)\s*<').hasMatch(signature);
}

bool _isDirectClassMember(SourceScannerContext context, ScannerClassSpan classSpan, int lineIndex) {
  var depth = 0;
  for (var i = classSpan.start; i < lineIndex; i++) {
    depth += _braceDelta(context.source.masked[i]);
  }
  return depth == 1;
}

int _braceDelta(String line) => '{'.allMatches(line).length - '}'.allMatches(line).length;

int? _controllerStateColumn(String line) {
  final match = RegExp(
    r'^\s*(?:(?:late|final)\s+)*(?<type>[A-Za-z_]\w*(?:\s*<[^;=]+>)?\??)\s+(?<name>_[A-Za-z_]\w*)\b',
  ).firstMatch(line);
  if (match == null) return null;

  final type = match.namedGroup('type') ?? '';
  final name = match.namedGroup('name') ?? '';
  if (_isUiLifecycleType(type)) return null;

  final normalizedName = name.replaceAll('_', '').toLowerCase();
  final isWorkflowStatus = RegExp(
    r'^(?:is|has)(?:loading|saving|submitting|deleting|mutating|processing|pending|syncing|refreshing|uploading)$',
  ).hasMatch(normalizedName);
  final isNavigationCollection =
      normalizedName.endsWith('stack') &&
      (normalizedName.contains('page') ||
          normalizedName.contains('navigation') ||
          normalizedName.contains('route'));
  final isDerivedCache =
      normalizedName.endsWith('cache') ||
      normalizedName.endsWith('snapshot') ||
      normalizedName.endsWith('byid');
  final isSelectedDomainRecord = normalizedName.startsWith('selected') && !_isPrimitiveType(type);

  if (!isWorkflowStatus && !isNavigationCollection && !isDerivedCache && !isSelectedDomainRecord) {
    return null;
  }
  return line.indexOf(match.group(0)!.trimLeft());
}

bool _isUiLifecycleType(String type) => RegExp(
  r'^(?:TextEditingController|ScrollController|PageController|FocusNode|AnimationController|TabController|Timer|Debouncer)\??$',
).hasMatch(type);

bool _isPrimitiveType(String type) =>
    RegExp(r'^(?:bool|int|double|num|String|Duration|DateTime)\??$').hasMatch(type);

int? _infrastructureColumn(String line) {
  final patterns = [
    RegExp(
      r'''^\s*import\s+['"][^'"]*(?:/data/|/datasources?/|/repositories/|/services?/|/infrastructure/|package:(?:appwrite|cloud_firestore|dio|firebase_|hive|http|shared_preferences|sqflite))[^'"]*['"]''',
    ),
    RegExp(r'\bref\s*\.\s*(?:read|watch|listen|listenManual|invalidate|refresh)\s*\('),
    RegExp(r'\b[A-Za-z_]\w*Provider\s*\.\s*notifier\b'),
    RegExp(r'\b_?[A-Za-z_]\w*(?:Repository|Datasource|Service|Client|Storage)\s*\.'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(line);
    if (match != null) return match.start;
  }
  return null;
}
