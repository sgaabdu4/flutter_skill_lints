import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when a file contains more than one top-level widget class.
///
/// One widget per file keeps imports, ownership, and test targets clear.
/// In non-test code, public widgets marked `@visibleForTesting` are ignored
/// because they intentionally expose internals for tests. Test files may keep
/// private widget helpers without adding visibility annotations.
class PreferSingleWidgetPerFile extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_single_widget_per_file',
    'Only one widget per file. Move additional widgets to separate files.',
    correctionMessage: 'Move this widget to its own file so ownership stays clear.',
  );

  PreferSingleWidgetPerFile()
    : super(
        name: 'prefer_single_widget_per_file',
        description: 'Warns when multiple widget classes share one file and ownership is unclear.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, isTestFile: _isTestFile(context));
    registry.addCompilationUnit(this, visitor);
  }

  bool _isTestFile(RuleContext context) {
    if (context.isInTestDirectory) return true;
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    return path.endsWith('_test.dart');
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSingleWidgetPerFile rule;
  final bool isTestFile;

  _Visitor(this.rule, {required this.isTestFile});

  static const _widgetChecker = TypeChecker.fromName('Widget', packageName: 'flutter');
  static const _knownWidgetBaseNames = {
    'ConsumerStatefulWidget',
    'ConsumerWidget',
    'HookConsumerWidget',
    'HookWidget',
    'StatefulWidget',
    'StatelessWidget',
    'Widget',
  };

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final widgets = <ClassDeclaration>[];

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      if (isTestFile && _isPrivateClass(declaration)) continue;
      if (!isTestFile && _hasPublicVisibleForTestingAnnotation(declaration)) continue;

      if (_isWidgetClass(declaration)) {
        widgets.add(declaration);
      }
    }

    // Report all widget classes after the first one.
    if (widgets.length > 1) {
      for (var i = 1; i < widgets.length; i++) {
        rule.reportAtToken(widgets[i].namePart.typeName);
      }
    }
  }

  bool _hasPublicVisibleForTestingAnnotation(ClassDeclaration declaration) {
    if (_isPrivateClass(declaration)) return false;

    return declaration.metadata.any((annotation) {
      final name = annotation.name;
      if (name.name == 'visibleForTesting') return true;
      if (name is PrefixedIdentifier) {
        return name.identifier.name == 'visibleForTesting';
      }
      return false;
    });
  }

  bool _isPrivateClass(ClassDeclaration declaration) {
    return declaration.namePart.typeName.lexeme.startsWith('_');
  }

  bool _isWidgetClass(ClassDeclaration declaration) {
    final element = declaration.declaredFragment?.element;
    if (element != null && _widgetChecker.isSuperOf(element)) return true;

    final superclassName = declaration.extendsClause?.superclass.name.lexeme;
    return superclassName != null && _knownWidgetBaseNames.contains(superclassName);
  }
}
