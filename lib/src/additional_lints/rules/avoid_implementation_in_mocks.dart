import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a Mocktail/Mockito mock overrides members.
final class AvoidImplementationInMocks extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_implementation_in_mocks',
    'Avoid implementations in mock classes.',
    correctionMessage: 'Keep mock classes empty and move behavior to stubs or fakes.',
  );

  AvoidImplementationInMocks()
    : super(
        name: 'avoid_implementation_in_mocks',
        description: 'Warns when classes extending Mock override members.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidImplementationInMocks rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final declaredType = node.declaredFragment?.element.thisType;
    if (declaredType == null || !_extendsMock(declaredType)) return;

    final body = node.body;
    if (body is! BlockClassBody) return;

    for (final member in body.members) {
      if (!_hasOverrideAnnotation(member.metadata)) continue;

      switch (member) {
        case MethodDeclaration(:final name):
          rule.reportAtToken(name);
        case FieldDeclaration(:final fields):
          rule.reportAtToken(fields.variables.first.name);
        case _:
          rule.reportAtNode(member);
      }
    }
  }
}

bool _extendsMock(InterfaceType type) {
  if (type.superclass == null) return false;
  if (_isMockType(type.superclass!)) return true;
  return type.allSupertypes.any(_isMockType);
}

bool _isMockType(InterfaceType type) => type.element.name == 'Mock';

bool _hasOverrideAnnotation(NodeList<Annotation> metadata) {
  return metadata.any((annotation) => annotation.name.name == 'override');
}
