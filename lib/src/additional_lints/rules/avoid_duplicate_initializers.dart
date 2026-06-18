import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports constructor initializer lists that initialize the same field twice.
final class AvoidDuplicateInitializers extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_duplicate_initializers',
    'Avoid duplicate constructor initializer targets.',
    correctionMessage: 'Remove the repeated initializer.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidDuplicateInitializers()
    : super(
        name: 'avoid_duplicate_initializers',
        description: 'Reports constructor initializer lists that initialize the same field twice.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addConstructorDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidDuplicateInitializers rule;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final seen = <String>{};

    for (final initializer in node.initializers) {
      if (initializer is! ConstructorFieldInitializer) continue;

      final name = initializer.fieldName.name;
      if (!seen.add(name)) {
        rule.reportAtNode(initializer.fieldName);
      }
    }
  }
}
