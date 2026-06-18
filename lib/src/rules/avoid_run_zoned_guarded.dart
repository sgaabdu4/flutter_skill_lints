import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Avoid `runZonedGuarded` for app startup.
///
/// Why: keep startup simple. Call `WidgetsFlutterBinding.ensureInitialized()`,
/// `await Crash.init()`, then `runApp(...)`. Do not wrap the app in a zone.
///
/// Catches direct calls (`runZonedGuarded(...)`) and aliased imports
/// (`import 'dart:async' as a; a.runZonedGuarded(...)`). Skips method calls whose
/// receiver is not a `dart:async` import prefix (e.g. `Zone().runZonedGuarded()`).
final class AvoidRunZonedGuarded extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_run_zoned_guarded',
    'Avoid `runZonedGuarded` for app startup.',
    correctionMessage: 'Call Crash.init() before runApp instead of wrapping runApp in a zone.',
  );

  AvoidRunZonedGuarded()
    : super(
        name: 'avoid_run_zoned_guarded',
        description:
            'Bans runZonedGuarded for app startup. Use Crash.init() before runApp instead.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidRunZonedGuarded rule;
  final Set<String> _dartAsyncPrefixes = <String>{};

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _dartAsyncPrefixes.clear();
    for (final directive in node.directives) {
      if (directive is ImportDirective) {
        final uri = directive.uri.stringValue;
        if (uri == 'dart:async') {
          final prefix = directive.prefix?.name;
          if (prefix != null) _dartAsyncPrefixes.add(prefix);
        }
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'runZonedGuarded') {
      final target = node.target;
      if (target == null) {
        rule.reportAtNode(node.methodName);
      } else if (target is SimpleIdentifier && _dartAsyncPrefixes.contains(target.name)) {
        rule.reportAtNode(node.methodName);
      }
    }
    super.visitMethodInvocation(node);
  }
}
