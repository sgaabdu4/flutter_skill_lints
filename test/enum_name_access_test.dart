import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_skill_lints/src/additional_lints/enum_name_access.dart';
import 'package:test/test.dart';

void main() {
  test('recognizes the callback parameter name property', () {
    expect(isEnumNameAccess(_expression('item.name'), 'item'), isTrue);
  });

  test('rejects a different property or parameter', () {
    expect(isEnumNameAccess(_expression('item.value'), 'item'), isFalse);
    expect(isEnumNameAccess(_expression('other.name'), 'item'), isFalse);
  });
}

Expression _expression(String source) {
  final visitor = _InitializerVisitor();
  parseString(content: 'void main() { final value = $source; }').unit.accept(visitor);
  return visitor.expression!;
}

class _InitializerVisitor extends RecursiveAstVisitor<void> {
  Expression? expression;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    expression ??= node.initializer;
    super.visitVariableDeclaration(node);
  }
}
