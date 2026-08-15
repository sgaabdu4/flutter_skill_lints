import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when Flutter skill diagnostics are suppressed with local ignore
/// comments.
///
/// Architectural diagnostics should be fixed at the owning code boundary. If a
/// project intentionally opts out, disable the diagnostic in
/// `analysis_options.yaml` so the decision is visible at project scope instead
/// of being hidden beside the violation.
class AvoidFlutterSkillLintSuppression extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_flutter_skill_lint_suppression',
    'Do not suppress Flutter skill lints with local ignore comments.',
    correctionMessage:
        'Fix the violation, or disable the rule in analysis_options.yaml with '
        'a project-level decision.',
  );

  AvoidFlutterSkillLintSuppression()
    : super(
        name: 'avoid_flutter_skill_lint_suppression',
        description:
            'Warns when local ignore comments suppress Flutter skill '
            'architectural diagnostics.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (_isExcludedContext(context)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidFlutterSkillLintSuppression rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final seenOffsets = <int>{};
    Token? token = node.beginToken;

    while (token != null) {
      _checkComments(token.precedingComments, seenOffsets);
      if (token.isEof) break;
      token = token.next;
    }
  }

  void _checkComments(Token? comment, Set<int> seenOffsets) {
    var current = comment;
    while (current != null) {
      if (_isIgnoreComment(current) &&
          _containsProtectedSuppression(current.lexeme) &&
          seenOffsets.add(current.offset)) {
        rule.reportAtOffset(current.offset, current.length);
      }
      current = current.next;
    }
  }
}

bool _isExcludedContext(RuleContext context) {
  return isExcludedProductionSource(context);
}

bool _isIgnoreComment(Token token) {
  return token.type == TokenType.SINGLE_LINE_COMMENT &&
      (token.lexeme.contains('ignore:') || token.lexeme.contains('ignore_for_file:'));
}

bool _containsProtectedSuppression(String lexeme) {
  final match = RegExp(r'ignore(?:_for_file)?:\s*([^\n]+)').firstMatch(lexeme);
  if (match == null) return false;

  final names = match
      .group(1)!
      .split(',')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty);

  return names.any(_protectedDiagnosticNames.contains);
}

const _protectedDiagnosticNames = {'avoid_magic_literals', 'avoid_local_contract_key_constants'};
