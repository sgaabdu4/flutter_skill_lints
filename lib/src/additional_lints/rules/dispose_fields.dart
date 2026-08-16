import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import 'package:flutter_skill_lints/src/additional_lints/disposal_utils.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when a widget State field that has a disposal method (`dispose`,
/// `close`, or `cancel`) is not cleaned up in the `dispose()` method.
///
/// Disposable resources such as `AnimationController`, `TextEditingController`,
/// `StreamController`, `StreamSubscription`, `FocusNode`, `Timer`, etc. must
/// be properly disposed/closed/cancelled in `dispose()` to prevent memory
/// leaks.
class DisposeFields extends ClassDeclarationRule {
  static const LintCode code = LintCode(
    'dispose_fields',
    "Field '{0}' is not disposed. Call '{0}.{1}()' in dispose().",
    correctionMessage: "Add '{0}.{1}()' in the dispose() method to prevent memory leaks.",
  );

  DisposeFields()
    : super(
        name: 'dispose_fields',
        description:
            'Warns when a State field with a disposal method is not '
            'cleaned up in dispose().',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  final DisposeFields rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final body = flutterStateBody(node);
    if (body == null) return;
    final cleanedUpTargets = _cleanedUpTargets(body.members);
    _reportUndisposedFields(rule, body.members, cleanedUpTargets);
  }
}

Map<String, Set<String>> _cleanedUpTargets(List<ClassMember> members) {
  final disposeMethod = members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == 'dispose')
      .firstOrNull;
  if (disposeMethod == null) return {};
  final collector = _CleanupCallCollector();
  disposeMethod.body.visitChildren(collector);
  final targets = <String, Set<String>>{};
  for (final call in collector.calls) {
    targets.putIfAbsent(call.targetSource, () => {}).add(call.methodName);
  }
  return targets;
}

void _reportUndisposedFields(
  DisposeFields rule,
  List<ClassMember> members,
  Map<String, Set<String>> cleanedUpTargets,
) {
  for (final fieldDecl in members.whereType<FieldDeclaration>()) {
    if (fieldDecl.isStatic) continue;
    for (final variable in fieldDecl.fields.variables) {
      final expectedCleanup = _expectedCleanup(variable);
      if (expectedCleanup == null) continue;
      final fieldName = variable.name.lexeme;
      if (_isCleanedUp(cleanedUpTargets, fieldName, expectedCleanup)) continue;
      rule.reportAtToken(variable.name, arguments: [fieldName, expectedCleanup]);
    }
  }
}

String? _expectedCleanup(VariableDeclaration variable) {
  final type = variable.declaredFragment?.element.type;
  return type == null ? null : findCleanupMethod(type);
}

bool _isCleanedUp(Map<String, Set<String>> cleanedUpTargets, String fieldName, String methodName) {
  return cleanedUpTargets[fieldName]?.contains(methodName) == true ||
      cleanedUpTargets['this.$fieldName']?.contains(methodName) == true;
}

/// Represents a cleanup call like `fieldName.dispose()`.
class _CleanupCall {
  final String targetSource;
  final String methodName;

  _CleanupCall({required this.targetSource, required this.methodName});
}

/// Collects all dispose/close/cancel calls within a method body.
class _CleanupCallCollector extends RecursiveAstVisitor<void> {
  final List<_CleanupCall> calls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (cleanupMethods.contains(methodName)) {
      final target = node.realTarget;
      if (target != null) {
        calls.add(_CleanupCall(targetSource: target.toSource(), methodName: methodName));
      }
    }
    super.visitMethodInvocation(node);
  }

  // Stop at function boundaries to avoid false positives from nested closures
  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {}
}
