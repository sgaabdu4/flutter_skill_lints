import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
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
    scan: (reporter, context) {
      _scanPresentationWidgetLines(reporter, context, _navigationImportColumn);
      if (!context.isPresentationWidgetFile || context.isTestFile) return;

      final visitor = _NavigationVisitor();
      context.unit.accept(visitor);
      final reportedLines = <int>{};
      for (final offset in visitor.offsets) {
        final location = context.unit.lineInfo.getLocation(offset);
        if (reportedLines.add(location.lineNumber)) {
          reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
        }
      }
    },
  ),

  /// Keep reusable presentation widget State free of domain and workflow state.
  ///
  /// Why: widgets may retain UI lifecycle objects, while screens and notifiers
  /// own selection, navigation history, mutation status, and derived caches.
  scannerRule(
    code: const LintCode(
      'presentation_widget_controller_state',
      'Reusable presentation widgets must not retain domain or workflow state.',
      correctionMessage: 'Pass immutable view data and typed callbacks; move domain and workflow state to the screen, route, or notifier.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Keeps domain and workflow state out of reusable presentation widgets.',
    scan: (reporter, context) {
      if (!context.isPresentationWidgetFile || context.isTestFile) return;

      for (final declaration in context.unit.declarations.whereType<ClassDeclaration>()) {
        final body = flutterStateBody(declaration);
        if (body == null) continue;

        final workflowFlags = _asyncWorkflowFlags(body);
        for (final field in body.members.whereType<FieldDeclaration>()) {
          if (field.isStatic) continue;
          final holdsForbiddenState = field.fields.variables.any((variable) {
            final element = variable.declaredFragment?.element;
            return element is FieldElement &&
                (_holdsDomainOrProviderState(element.type) || workflowFlags.contains(element));
          });
          if (holdsForbiddenState) {
            final location = context.unit.lineInfo.getLocation(field.fields.offset);
            reporter.report(context, location.lineNumber - 1, location.columnNumber - 1);
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
      correctionMessage: 'Emit a typed callback and let the screen or notifier own repositories, services, providers, and SDKs.',
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

int? _navigationImportColumn(String line) =>
    RegExp(r'''^\s*import\s+['"][^'"]*(?:go_router|/routing/|/routes/|_route\.dart)[^'"]*['"]''')
        .firstMatch(line)
        ?.start;

const _navigatorChecker = TypeChecker.any([
  TypeChecker.fromName('Navigator', packageName: 'flutter'),
  TypeChecker.fromName('NavigatorState', packageName: 'flutter'),
]);
const _goRouterRouteDataChecker = TypeChecker.fromName('RouteData', packageName: 'go_router');

/// Collects resolved Navigator, GoRouter, and typed-route navigation calls.
final class _NavigationVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isNavigation(node)) offsets.add(node.offset);
    super.visitMethodInvocation(node);
  }

  bool _isNavigation(MethodInvocation node) {
    final method = node.methodName.element;
    final owner = method?.enclosingElement;
    if (owner != null && _navigatorChecker.isExactly(owner)) {
      return switch (node.methodName.name) {
        'of' || 'maybeOf' || 'canPop' => false,
        'pop' || 'maybePop' => !_isLocalModalDismissal(node),
        _ => true,
      };
    }
    if (method?.library?.identifier.startsWith('package:go_router/') ?? false) return true;

    final targetType = node.realTarget?.staticType;
    return targetType != null && _goRouterRouteDataChecker.isAssignableFromType(targetType);
  }
}

/// Whether a Navigator pop is the final work of its callback: an arrow body,
/// the last statement of the function, or followed only by a bare `return;`.
bool _isLocalModalDismissal(MethodInvocation pop) {
  AstNode node = pop;
  if (node.parent is ExpressionFunctionBody) return true;
  if (node.parent is! ExpressionStatement) return false;
  node = node.parent!;

  while (true) {
    final parent = node.parent;
    switch (parent) {
      case BlockFunctionBody():
        return true;
      case IfStatement():
        node = parent;
      case Block(:final statements):
        final index = statements.indexOf(node as Statement);
        final rest = statements.skip(index + 1).toList();
        if (rest.isEmpty) {
          node = parent;
        } else {
          return rest.length == 1 &&
              rest.single is ReturnStatement &&
              (rest.single as ReturnStatement).expression == null;
        }
      default:
        return false;
    }
  }
}

const _asyncValueChecker = TypeChecker.fromName('AsyncValue', packageName: 'riverpod');

/// Whether [type] is, or is a collection of, a domain-layer type or a
/// provider-derived AsyncValue snapshot.
bool _holdsDomainOrProviderState(DartType type) {
  if (type is! InterfaceType) return false;
  final library = type.element.library.identifier;
  if (library.startsWith('package:') && library.contains('/domain/')) return true;
  if (_asyncValueChecker.isExactlyType(type)) return true;
  return type.typeArguments.any(_holdsDomainOrProviderState);
}

/// Bool fields assigned before an `await` in the same async function: flags
/// that track an in-flight async workflow.
Set<FieldElement> _asyncWorkflowFlags(BlockClassBody body) {
  final visitor = _WorkflowFlagVisitor();
  body.accept(visitor);
  return visitor.flags;
}

final class _WorkflowFlagVisitor extends RecursiveAstVisitor<void> {
  final flags = <FieldElement>{};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final written = node.writeElement;
    final field = switch (written) {
      FieldElement() => written,
      PropertyAccessorElement(:final FieldElement variable) => variable,
      _ => null,
    };
    if (field != null && !field.isStatic && field.type.isDartCoreBool && _precedesAwait(node)) {
      flags.add(field);
    }
    super.visitAssignmentExpression(node);
  }
}

bool _precedesAwait(AstNode node) {
  final asyncBody = node.thisOrAncestorMatching<FunctionBody>(
    (ancestor) => ancestor is FunctionBody && ancestor.isAsynchronous,
  );
  if (asyncBody == null) return false;

  final awaits = _AwaitOffsetVisitor();
  asyncBody.accept(awaits);
  return awaits.offsets.any((offset) => offset > node.end);
}

final class _AwaitOffsetVisitor extends RecursiveAstVisitor<void> {
  final offsets = <int>[];

  @override
  void visitAwaitExpression(AwaitExpression node) {
    offsets.add(node.offset);
    super.visitAwaitExpression(node);
  }
}

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
