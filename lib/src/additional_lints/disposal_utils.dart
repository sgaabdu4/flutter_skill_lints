import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:flutter_skill_lints/src/additional_lints/ast_node_analysis.dart';

/// Ordered list of cleanup method names to look for on disposable types.
const cleanupMethods = ['dispose', 'close', 'cancel'];

({BlockClassBody body, MethodDeclaration? disposeMethod})? findDisposeContext(AstNode node) {
  final classDecl = enclosingClassDeclaration(node);
  if (classDecl == null || classDecl.body is! BlockClassBody) return null;
  final body = classDecl.body as BlockClassBody;
  return (body: body, disposeMethod: findDisposeMethod(body));
}

({String fieldName, String cleanupMethod, VariableDeclaration declaration})? disposableVariable(
  AstNode node,
) {
  final declaration = nearestNode<VariableDeclaration>(node);
  final type = declaration?.declaredFragment?.element.type;
  final cleanupMethod = type == null ? null : findCleanupMethod(type);
  if (declaration == null || cleanupMethod == null) return null;
  return (
    declaration: declaration,
    fieldName: declaration.name.lexeme,
    cleanupMethod: cleanupMethod,
  );
}

MethodDeclaration? findDisposeMethod(BlockClassBody body) {
  for (final member in body.members) {
    if (member is MethodDeclaration && member.name.lexeme == 'dispose') return member;
  }
  return null;
}

/// Returns the expected cleanup method name for a type, or `null` if the
/// type has no cleanup method.
///
/// Checks the type itself and all supertypes for methods named `dispose`,
/// `close`, or `cancel` (in that priority order).
String? findCleanupMethod(DartType type) {
  if (type is! InterfaceType) return null;

  bool hasMethod(String name) {
    if (type.methods.any((m) => m.name == name)) return true;
    return type.element.allSupertypes.any((s) => s.methods.any((m) => m.name == name));
  }

  for (final cleanup in cleanupMethods) {
    if (hasMethod(cleanup)) return cleanup;
  }
  return null;
}

void addCleanupToDispose(
  DartFileEditBuilder builder,
  BlockClassBody classBody,
  MethodDeclaration? disposeMethod,
  String cleanupCall,
) {
  if (disposeMethod != null) {
    final disposeBody = disposeMethod.body;
    if (disposeBody is! BlockFunctionBody) return;

    final block = disposeBody.block;
    final superDisposeStmt = findSuperDispose(block);
    if (superDisposeStmt != null) {
      builder.addSimpleInsertion(superDisposeStmt.offset, '    $cleanupCall;\n');
    } else {
      builder.addSimpleInsertion(block.rightBracket.offset, '    $cleanupCall;\n  ');
    }
    return;
  }

  const indent = '  ';
  final disposeMethodSource =
      '\n'
      '\n'
      '$indent@override\n'
      '${indent}void dispose() {\n'
      '$indent$indent$cleanupCall;\n'
      '$indent${indent}super.dispose();\n'
      '$indent}\n';
  builder.addSimpleInsertion(classBody.rightBracket.offset, disposeMethodSource);
}

Statement? findSuperDispose(Block block) {
  for (final statement in block.statements) {
    if (statement is ExpressionStatement) {
      final expression = statement.expression;
      if (expression is MethodInvocation &&
          expression.methodName.name == 'dispose' &&
          expression.target is SuperExpression) {
        return statement;
      }
    }
  }
  return null;
}
