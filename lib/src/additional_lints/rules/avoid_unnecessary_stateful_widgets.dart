import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a StatefulWidget can be replaced with a StatelessWidget because
/// its State class has no mutable state, lifecycle methods, or setState calls.
class AvoidUnnecessaryStatefulWidgets extends CompilationUnitRule {
  static const LintCode code = LintCode(
    'avoid_unnecessary_stateful_widgets',
    'This StatefulWidget has no mutable state. Consider using StatelessWidget instead.',
    correctionMessage: 'Convert to StatelessWidget and move the build method.',
  );

  AvoidUnnecessaryStatefulWidgets()
    : super(
        name: 'avoid_unnecessary_stateful_widgets',
        description: 'Warns when a StatefulWidget can be replaced with a StatelessWidget.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidUnnecessaryStatefulWidgets rule;

  _Visitor(this.rule);

  static const _statefulWidgetChecker = TypeChecker.fromName(
    'StatefulWidget',
    packageName: 'flutter',
  );

  static const _stateChecker = TypeChecker.fromName('State', packageName: 'flutter');

  static const _lifecycleMethods = {
    'initState',
    'dispose',
    'didChangeDependencies',
    'didUpdateWidget',
    'deactivate',
    'activate',
    'reassemble',
  };

  @override
  void visitCompilationUnit(CompilationUnit node) {
    // Collect all State classes and their StatefulWidget pairs
    final statefulWidgets = <ClassDeclaration>[];
    final stateClasses = <ClassDeclaration>[];

    for (final declaration in node.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final element = declaration.declaredFragment?.element;
      if (element == null) continue;

      if (_statefulWidgetChecker.isSuperOf(element)) {
        statefulWidgets.add(declaration);
      } else if (_stateChecker.isSuperOf(element)) {
        stateClasses.add(declaration);
      }
    }

    // For each StatefulWidget, find its companion State class and analyze it
    for (final widget in statefulWidgets) {
      final widgetName = widget.namePart.typeName.lexeme;

      // Find the companion State class
      final stateClass = findStateClass(stateClasses, widgetName);
      if (stateClass == null) continue;

      if (_isUnnecessaryState(stateClass)) {
        rule.reportAtToken(widget.namePart.typeName);
      }
    }
  }

  /// Checks if the State class has no mutable state, lifecycle methods, or
  /// setState calls.
  static bool _isUnnecessaryState(ClassDeclaration stateClass) {
    final body = stateClass.body;
    if (body is! BlockClassBody) return false;
    if (body.members.any(_hasMutableStateMember)) return false;
    if (body.members.whereType<MethodDeclaration>().any(_hasLifecycleMethod)) return false;
    return !_containsSetState(stateClass);
  }

  static bool _hasMutableStateMember(ClassMember member) {
    if (member is! FieldDeclaration || member.isStatic) return false;
    final fields = member.fields;
    return !fields.isConst && !fields.isFinal;
  }

  static bool _hasLifecycleMethod(MethodDeclaration method) =>
      _lifecycleMethods.contains(method.name.lexeme);

  static bool _containsSetState(ClassDeclaration stateClass) {
    final finder = _SetStateFinder();
    stateClass.visitChildren(finder);
    return finder.found;
  }
}

class _SetStateFinder extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      found = true;
    }
    if (!found) {
      super.visitMethodInvocation(node);
    }
  }
}
