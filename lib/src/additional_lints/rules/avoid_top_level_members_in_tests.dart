import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when test files expose public top-level helpers outside `main`.
final class AvoidTopLevelMembersInTests extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_top_level_members_in_tests',
    'Avoid public top-level helpers in test files.',
    correctionMessage:
        'Make the helper private, move it inside main(), or move shared helpers into a dedicated test support file.',
  );

  AvoidTopLevelMembersInTests()
    : super(
        name: 'avoid_top_level_members_in_tests',
        description:
            'Warns when test files expose public top-level functions or variables outside main().',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (!_isTestFile(context)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }

  bool _isTestFile(RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    return path.endsWith('_test.dart');
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidTopLevelMembersInTests rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final declaration in node.declarations) {
      switch (declaration) {
        case FunctionDeclaration(:final name)
            when name.lexeme != 'main' && !_isPrivateName(name.lexeme):
          rule.reportAtToken(name);
        case TopLevelVariableDeclaration(:final variables):
          for (final variable in variables.variables) {
            final name = variable.name.lexeme;
            if (!_isPrivateName(name)) {
              rule.reportAtToken(variable.name);
            }
          }
      }
    }
  }
}

bool _isPrivateName(String name) => name.startsWith('_');
