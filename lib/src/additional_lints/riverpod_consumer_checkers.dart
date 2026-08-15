import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

const consumerWidgetChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerWidget', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerWidget', packageName: 'hooks_riverpod'),
]);

const consumerStateChecker = TypeChecker.any([
  TypeChecker.fromName('ConsumerState', packageName: 'flutter_riverpod'),
  TypeChecker.fromName('HookConsumerState', packageName: 'hooks_riverpod'),
]);

bool isConsumerBuildMethod(MethodDeclaration node) {
  if (node.name.lexeme != 'build') return false;

  final element = enclosingClass(node)?.declaredFragment?.element;
  return element != null &&
      (consumerWidgetChecker.isSuperOf(element) || consumerStateChecker.isSuperOf(element));
}
