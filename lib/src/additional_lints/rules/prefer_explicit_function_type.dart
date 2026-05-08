import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a `Function` type does not specify the return type and arguments.
///
/// Not specifying the return type and the list of arguments can lead to
/// hard-to-spot bugs since the `Function` type effectively makes the
/// declaration dynamic and disables type checks.
///
/// ## Example
///
/// ❌ Bad:
/// ```dart
/// class SomeWidget {
///   final Function onTap;
///   const SomeWidget(this.onTap);
/// }
/// ```
///
/// ✅ Good:
/// ```dart
/// class SomeWidget {
///   final void Function() onTap;
///   const SomeWidget(this.onTap);
/// }
/// ```
class PreferExplicitFunctionType extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_explicit_function_type',
    "This 'Function' type does not specify a return type or parameter list.",
    correctionMessage:
        'Add an explicit return type and parameter list to avoid an untyped Function.',
  );

  PreferExplicitFunctionType()
    : super(
        name: 'prefer_explicit_function_type',
        description: 'Warns when a Function type does not specify the return type and arguments.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferExplicitFunctionType rule;

  _Visitor(this.rule);

  @override
  void visitNamedType(NamedType node) {
    // Check if the type name is 'Function'
    final typeName = node.name;
    if (typeName.lexeme != 'Function') return;

    // If it's from dart:core and has no type arguments, it's the non-explicit form
    // GenericFunctionType is used for explicit function types like `void Function()`
    // NamedType with name 'Function' is the non-explicit form

    // Make sure this is actually the Function type from dart:core
    final element = node.element;
    if (element == null) return;

    // Check if it's the built-in Function type
    final library = element.library;
    if (library?.isDartCore != true) return;

    if (_isFrameworkCompatibleOverrideParameter(node)) return;

    // This is the non-explicit Function type, report it
    rule.reportAtNode(node);
  }

  bool _isFrameworkCompatibleOverrideParameter(NamedType node) {
    var isParameterType = false;
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FormalParameter) {
        isParameterType = true;
      }
      if (current is MethodDeclaration) {
        return isParameterType && _hasOverrideAnnotation(current.metadata);
      }
      if (current is FunctionDeclaration || current is ClassDeclaration) {
        return false;
      }
      current = current.parent;
    }
    return false;
  }

  bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
    return metadata.any((annotation) => annotation.name.name == 'override');
  }
}
