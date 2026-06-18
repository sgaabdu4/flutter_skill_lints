import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a declaration uses the `late` keyword.
class AvoidLateKeyword extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_late_keyword',
    'Avoid late declarations.',
    correctionMessage: 'Prefer initializing the value directly or making the state explicit.',
  );

  AvoidLateKeyword()
    : super(
        name: 'avoid_late_keyword',
        description: 'Warns when variable or field declarations use late.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addVariableDeclarationList(this, _Visitor(this, _isTestFile(context)));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule, this.isTestFile);

  final AvoidLateKeyword rule;
  final bool isTestFile;

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    final lateKeyword = node.lateKeyword;
    if (lateKeyword == null) return;
    if (isTestFile) return;
    if (_isStateField(node)) return;

    rule.reportAtToken(lateKeyword);
  }
}

bool _isTestFile(RuleContext context) {
  final path = context.definingUnit.file.path.replaceAll('\\', '/');
  return path.contains('/test/') && !path.contains('/lib/');
}

bool _isStateField(VariableDeclarationList node) {
  final parent = node.parent;
  if (parent is! FieldDeclaration) return false;

  final classNode = parent.thisOrAncestorOfType<ClassDeclaration>();
  if (classNode == null) return false;
  return _isStateSubclass(classNode);
}

bool _isStateSubclass(ClassDeclaration node) {
  final superclassSource = node.extendsClause?.superclass.toSource();
  return superclassSource == 'State' ||
      superclassSource?.startsWith('State<') == true ||
      superclassSource == 'ConsumerState' ||
      superclassSource?.startsWith('ConsumerState<') == true;
}
