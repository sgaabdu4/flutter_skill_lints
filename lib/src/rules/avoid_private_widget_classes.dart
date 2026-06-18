import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Do not declare private widget classes.
///
/// Why: Private widget classes hide composition boundaries and make tests depend on file
/// internals. Use public widget classes with @visibleForTesting for file-internal widgets,
/// or move reused widgets to their own files. Private `State<T>` subclasses remain allowed.
final class AvoidPrivateWidgetClasses extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_private_widget_classes',
    'Do not declare private widget classes.',
    correctionMessage:
        'Rename private widget classes to public classes, using @visibleForTesting when needed.',
    severity: DiagnosticSeverity.ERROR,
  );

  AvoidPrivateWidgetClasses()
    : super(
        name: 'avoid_private_widget_classes',
        description: 'Bans private widget classes while allowing private State<T> subclasses.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    if (_isTestFile(context)) return;
    registry.addClassDeclaration(this, _Visitor(this));
  }

  bool _isTestFile(RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    return !path.contains('/lib/') &&
        (path.contains('/test/') || path.contains('/integration_test/'));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  static const _privateWidgetBaseNames = {
    'ConsumerStatefulWidget',
    'ConsumerWidget',
    'HookConsumerWidget',
    'HookWidget',
    'StatefulHookConsumerWidget',
    'StatefulWidget',
    'StatelessHookConsumerWidget',
    'StatelessWidget',
  };

  final AvoidPrivateWidgetClasses rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.namePart.typeName.lexeme;
    if (!name.startsWith('_')) return;

    final superclassName = node.extendsClause?.superclass.name.lexeme;
    if (superclassName == null || !_privateWidgetBaseNames.contains(superclassName)) {
      return;
    }

    rule.reportAtToken(node.namePart.typeName);
  }
}
