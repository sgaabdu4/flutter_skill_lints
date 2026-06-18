import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';

/// Warns when Future callback chaining is used where async/await is clearer.
final class PreferAsyncAwait extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_async_await',
    'Prefer async/await over Future callback chaining.',
    correctionMessage: 'Rewrite the Future chain with async/await.',
  );

  PreferAsyncAwait()
    : super(
        name: 'prefer_async_await',
        description: 'Warns when Future.then/catchError/whenComplete chains are used.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    if (path.contains('/data/datasources/')) return;

    registry.addMethodInvocation(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  static const _callbackMethods = {'then', 'catchError', 'whenComplete'};

  final PreferAsyncAwait rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_callbackMethods.contains(node.methodName.name)) return;
    if (!_isAsyncLike(node.target?.staticType)) return;

    rule.reportAtNode(node.methodName);
  }
}

const _futureChecker = TypeChecker.fromUrl('dart:async#Future');

bool _isAsyncLike(DartType? type) {
  if (type == null) return false;
  if (type is InterfaceType && _futureChecker.isAssignableFromType(type)) {
    return true;
  }
  return type.element?.name == 'FutureOr';
}
