import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when parameters or global collections are mutated through common APIs.
final class AvoidCollectionMutatingMethods extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_collection_mutating_methods',
    'Avoid mutating parameter or global collections.',
    correctionMessage: 'Create a new collection or keep mutation behind an instance boundary.',
  );

  AvoidCollectionMutatingMethods()
    : super(
        name: 'avoid_collection_mutating_methods',
        description: 'Warns when mutating collection methods are called on parameters or globals.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidCollectionMutatingMethods rule;
  final Set<String> _topLevelVariables = {};
  final Map<String, Set<String>> _staticFieldsByClass = {};
  final List<Set<String>> _parameterStack = [];

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _collectGlobals(node);
    super.visitCompilationUnit(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _withParameters(node.functionExpression.parameters, () {
      super.visitFunctionDeclaration(node);
    });
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _withParameters(node.parameters, () {
      super.visitFunctionExpression(node);
    });
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _withParameters(node.parameters, () {
      super.visitMethodDeclaration(node);
    });
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_mutatingMethods.contains(node.methodName.name) &&
        _isCollectionType(_receiverType(node)) &&
        _isParameterOrGlobalReceiver(_receiver(node))) {
      rule.reportAtNode(node.methodName);
    }
    super.visitMethodInvocation(node);
  }

  void _collectGlobals(CompilationUnit unit) {
    for (final declaration in unit.declarations) {
      switch (declaration) {
        case TopLevelVariableDeclaration(:final variables):
          for (final variable in variables.variables) {
            _topLevelVariables.add(variable.name.lexeme);
          }
        case ClassDeclaration(:final namePart, :final body):
          final fields = <String>{};
          for (final member in body.members) {
            if (member is! FieldDeclaration || !member.isStatic) continue;
            fields.addAll(member.fields.variables.map((variable) => variable.name.lexeme));
          }
          if (fields.isNotEmpty) {
            _staticFieldsByClass[namePart.typeName.lexeme] = fields;
          }
        default:
          break;
      }
    }
  }

  void _withParameters(FormalParameterList? parameters, void Function() visit) {
    _parameterStack.add(_parameterNames(parameters));
    visit();
    _parameterStack.removeLast();
  }

  bool _isParameterOrGlobalReceiver(Expression? receiver) {
    return switch (receiver) {
      SimpleIdentifier(:final name) =>
        _currentParameters.contains(name) || _topLevelVariables.contains(name),
      PrefixedIdentifier(:final prefix, :final identifier) =>
        _staticFieldsByClass[prefix.name]?.contains(identifier.name) ?? false,
      PropertyAccess(target: SimpleIdentifier(:final name), :final propertyName) =>
        _staticFieldsByClass[name]?.contains(propertyName.name) ?? false,
      _ => false,
    };
  }

  Set<String> get _currentParameters {
    if (_parameterStack.isEmpty) return const {};
    return _parameterStack.last;
  }
}

const _mutatingMethods = {
  'add',
  'addAll',
  'clear',
  'fillRange',
  'insert',
  'insertAll',
  'putIfAbsent',
  'remove',
  'removeAt',
  'removeLast',
  'removeRange',
  'removeWhere',
  'replaceRange',
  'retainWhere',
  'setAll',
  'setRange',
  'shuffle',
  'sort',
  'update',
  'updateAll',
};

const _collectionChecker = TypeChecker.any([
  TypeChecker.fromUrl('dart:core#Iterable'),
  TypeChecker.fromUrl('dart:core#List'),
  TypeChecker.fromUrl('dart:core#Map'),
  TypeChecker.fromUrl('dart:core#Set'),
]);

Expression? _receiver(MethodInvocation node) {
  final target = node.target;
  if (target != null) return target;

  final parent = node.parent;
  if (parent is CascadeExpression) {
    return parent.target;
  }

  return null;
}

DartType? _receiverType(MethodInvocation node) => _receiver(node)?.staticType;

bool _isCollectionType(DartType? type) {
  return type != null && _collectionChecker.isAssignableFromType(type);
}

Set<String> _parameterNames(FormalParameterList? parameters) {
  if (parameters == null) return const {};

  return {
    for (final parameter in parameters.parameters)
      if (parameter.name case final name?) name.lexeme,
  };
}
