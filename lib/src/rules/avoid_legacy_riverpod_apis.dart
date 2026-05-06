import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final class AvoidLegacyRiverpodApis extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_legacy_riverpod_apis',
    'Avoid legacy Riverpod provider and ref APIs.',
    correctionMessage: 'Use Riverpod codegen providers and the unified Ref type.',
  );

  static const Set<String> legacyProviders = {
    'Provider',
    'StateProvider',
    'StateNotifierProvider',
    'ChangeNotifierProvider',
    'NotifierProvider',
    'AsyncNotifierProvider',
    'FutureProvider',
    'StreamProvider',
  };

  AvoidLegacyRiverpodApis()
    : super(
        name: 'avoid_legacy_riverpod_apis',
        description: 'Bans legacy Riverpod provider constructors and legacy generated Ref types.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (isGeneratedRuleContext(context)) return;
    final visitor = _Visitor(this);
    registry.addNamedType(this, visitor);
    registry.addSimpleIdentifier(this, visitor);
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidLegacyRiverpodApis rule;

  @override
  void visitNamedType(NamedType node) {
    final name = node.name.lexeme;
    if (_isLegacyRef(name) || AvoidLegacyRiverpodApis.legacyProviders.contains(name)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (classMemberNameIsDeclaration(node)) return;
    if (!AvoidLegacyRiverpodApis.legacyProviders.contains(node.name)) return;
    final parent = node.parent;
    if (parent is NamedType) return;
    if (parent is MethodInvocation && parent.methodName == node) {
      rule.reportAtNode(node);
      return;
    }
    if (parent is ConstructorName && parent.type.name.lexeme == node.name) {
      rule.reportAtNode(node);
    }
  }

  bool _isLegacyRef(String name) {
    if (!name.endsWith('Ref')) return false;
    return name != 'Ref' && name != 'WidgetRef';
  }
}
