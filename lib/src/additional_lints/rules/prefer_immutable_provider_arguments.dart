import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/method_invocation_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/riverpod_type_checkers.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

/// Warns when Riverpod provider family arguments use mutable objects.
class PreferImmutableProviderArguments extends FunctionAndMethodDeclarationRule
    with SkipGeneratedSources {
  static const LintCode code = LintCode(
    'prefer_immutable_provider_arguments',
    'Prefer immutable provider arguments.',
    correctionMessage:
        'Use primitives, enums, records, or immutable value objects for provider family arguments.',
  );

  PreferImmutableProviderArguments()
    : super(
        name: 'prefer_immutable_provider_arguments',
        description: 'Warns when Riverpod provider arguments are mutable.',
        code: code,
      );

  @override
  AstVisitor<void> createVisitor() => _Visitor(this);
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferImmutableProviderArguments rule;

  static const _riverpodAnnotations = {'riverpod', 'Riverpod'};
  static const _mutableCoreTypes = {'Iterable', 'List', 'Map', 'Queue', 'Set'};
  static const _immutableCoreTypes = {
    'BigInt',
    'bool',
    'DateTime',
    'double',
    'Duration',
    'int',
    'num',
    'Object',
    'Pattern',
    'RegExp',
    'String',
    'StringBuffer',
    'Symbol',
    'Uri',
  };
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!hasAnnotationNamed(node, _riverpodAnnotations)) return;
    final parameters = node.functionExpression.parameters?.parameters;
    if (parameters == null || parameters.length <= 1) return;

    for (final parameter in parameters.skip(1)) {
      _checkParameter(parameter);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return;
    final parameters = node.parameters?.parameters;
    if (parameters == null || parameters.isEmpty) return;

    final classDecl = enclosingClass(node);
    final element = classDecl?.declaredFragment?.element;
    if (element == null || !notifierChecker.isSuperOf(element)) return;

    for (final parameter in parameters) {
      _checkParameter(parameter);
    }
  }

  void _checkParameter(FormalParameter parameter) {
    final element = parameter.declaredFragment?.element;
    final type = element?.type;
    if (type == null || _isImmutableProviderArgument(type)) return;

    final token = parameter.name;
    if (token == null) return;
    rule.reportAtToken(token);
  }

  bool _isImmutableProviderArgument(DartType type) {
    if (type is DynamicType || type is InvalidType || type is VoidType) return true;
    if (type is TypeParameterType) return true;
    if (type is RecordType) {
      return type.positionalFields.every((field) => _isImmutableProviderArgument(field.type)) &&
          type.namedFields.every((field) => _isImmutableProviderArgument(field.type));
    }
    if (type is! InterfaceType) return true;

    final element = type.element;
    if (element is EnumElement) return true;
    if (_isDartCore(element)) {
      if (_mutableCoreTypes.contains(element.name)) return false;
      return _immutableCoreTypes.contains(element.name);
    }

    return element.metadata.hasImmutable || _hasOnlyFinalInstanceFields(element);
  }

  bool _isDartCore(InterfaceElement element) => element.library.identifier == 'dart:core';

  bool _hasOnlyFinalInstanceFields(InterfaceElement element) {
    var sawField = false;
    for (final field in element.fields) {
      if (field.isStatic ||
          (!field.isOriginDeclaration && !field.isOriginDeclaringFormalParameter)) {
        continue;
      }
      sawField = true;
      if (!field.isFinal) return false;
    }
    return sawField;
  }
}
