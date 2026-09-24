import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';
import 'package:flutter_skill_lints/src/rules/source_scanner_rule.dart';

final List<ScannerRule> routerExtendedSourceRules = [
  /// Keep GoRouter redirect decisions in a pure resolver.
  ///
  /// Why: Flags inline branching inside GoRouter redirect closures. Move redirect branching
  /// into a resolve...Redirect function and matrix-test it.
  scannerRule(
    code: const LintCode(
      'router_impure_redirect',
      'Keep GoRouter redirect decisions in a pure resolver.',
      correctionMessage:
          'Move redirect branching into a resolve...Redirect function and matrix-test it.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags inline branching inside GoRouter redirect closures so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      for (var i = 0; i < context.source.length; i++) {
        final line = context.source.masked[i];
        if (!line.contains('redirect:')) continue;
        final windowEnd = (i + 16).clamp(0, context.source.length - 1);
        final window = context.source.masked.sublist(i, windowEnd + 1).join('\n');
        if (RegExp(r'\bresolve\w*Redirect\s*\(').hasMatch(window)) continue;
        if (RegExp(r'\b(?:if|switch)\s*\(').hasMatch(window)) {
          reporter.report(context, i, line.indexOf('redirect'));
        }
      }
    },
  ),

  /// Do not push shell tab routes.
  ///
  /// Why: Flags typed route push calls in shell navigation widgets. Route tab
  /// changes use StatefulNavigationShell.goBranch; pushing a tab root creates
  /// the wrong stack shape.
  scannerRule(
    code: const LintCode(
      'router_shell_tab_push',
      'Do not push shell tab routes.',
      correctionMessage: 'Use StatefulNavigationShell.goBranch for tab changes.',
      severity: DiagnosticSeverity.ERROR,
    ),
    description: 'Flags typed route push calls in shell navigation widgets so the Flutter skill violation is shown during analysis.',
    scan: (reporter, context) {
      final shellTabPush = RegExp(
        r'\bconst\s+[A-Z]\w*Route\s*'
        r'\([^)]*\)\s*\.\s*push\s*(?:<[^>]+>)?\s*\(',
      );

      final reportedLines = <int>{};
      for (final method in context.methods) {
        final body = context.source.masked.sublist(method.start, method.end + 1).join('\n');
        if (!body.contains('StatefulNavigationShell') && !body.contains('goBranch')) continue;

        for (var i = method.start; i <= method.end; i++) {
          final line = context.source.masked[i];
          if (shellTabPush.hasMatch(line)) {
            reporter.report(context, i, 0);
            reportedLines.add(i);
          }
        }
      }
      for (final navigation in _shellTabCallbackNavigations(context.unit)) {
        final line = context.unit.lineInfo.getLocation(navigation.offset).lineNumber - 1;
        if (reportedLines.add(line)) reporter.reportNode(context, navigation);
      }
    },
  ),
];

const _statefulNavigationShellChecker = TypeChecker.fromName(
  'StatefulNavigationShell',
  packageName: 'go_router',
);

const _tabBarChecker = TypeChecker.any([
  TypeChecker.fromName('NavigationBar', packageName: 'flutter'),
  TypeChecker.fromName('NavigationRail', packageName: 'flutter'),
  TypeChecker.fromName('BottomNavigationBar', packageName: 'flutter'),
]);

/// Typed route navigation reached from a tab bar's selection callback (or a
/// method of the same class it calls) in a class that holds a
/// `StatefulNavigationShell`, where `goBranch` is the tab-change API.
Iterable<MethodInvocation> _shellTabCallbackNavigations(CompilationUnit unit) sync* {
  for (final shellClass in unit.declarations.whereType<ClassDeclaration>()) {
    final holdsShell = shellClass.body.members.whereType<FieldDeclaration>().any((field) {
      final type = field.fields.type?.type;
      return type != null && _statefulNavigationShellChecker.isExactlyType(type);
    });
    if (!holdsShell) continue;
    final methods = {
      for (final method in shellClass.body.members.whereType<MethodDeclaration>())
        method.name.lexeme: method,
    };
    for (final callback in collectNodes<NamedArgument>(shellClass)) {
      if (!_isTabSelectionCallback(callback)) continue;
      final value = callback.argumentExpression;
      final scopes = <AstNode>[
        value,
        for (final identifier in collectNodes<SimpleIdentifier>(value))
          ?methods[identifier.name]?.body,
      ];
      for (final scope in scopes) {
        yield* collectNodes<MethodInvocation>(scope).where(_isTypedRouteNavigation);
      }
    }
  }
}

bool _isTabSelectionCallback(NamedArgument argument) {
  final name = argument.name.lexeme;
  if (name != 'onDestinationSelected' && name != 'onTap') return false;
  final type = argument.thisOrAncestorOfType<InstanceCreationExpression>()?.staticType;
  return type != null && _tabBarChecker.isExactlyType(type);
}

bool _isTypedRouteNavigation(MethodInvocation call) {
  final targetType = call.realTarget?.staticType;
  return targetType != null &&
      goRouteDataChecker.isAssignableFromType(targetType) &&
      isResolvedForwardNavigation(call);
}
