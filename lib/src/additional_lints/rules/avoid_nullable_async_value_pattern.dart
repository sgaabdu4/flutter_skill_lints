import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../type_checker.dart';

/// Warns when `AsyncValue` is matched with a nullable `value?` object pattern.
///
/// `AsyncValue(:final value?)` hides loading/error branches behind a nullable
/// getter. Match `AsyncData(:final value)` or switch all states explicitly.
class AvoidNullableAsyncValuePattern extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_nullable_async_value_pattern',
    'Avoid nullable AsyncValue value patterns.',
    correctionMessage:
        'Use AsyncData(:final value), or handle AsyncLoading and AsyncError '
        'branches explicitly.',
  );

  AvoidNullableAsyncValuePattern()
    : super(
        name: 'avoid_nullable_async_value_pattern',
        description: 'Warns when AsyncValue object patterns use value?.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends RecursiveAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidNullableAsyncValuePattern rule;

  static const _asyncValueChecker = TypeChecker.any([
    TypeChecker.fromName('AsyncValue', packageName: 'riverpod'),
    TypeChecker.fromName('AsyncValue', packageName: 'flutter_riverpod'),
  ]);

  @override
  void visitObjectPattern(ObjectPattern node) {
    final element = node.type.element;
    if (element != null && _asyncValueChecker.isSuperOf(element)) {
      for (final field in node.fields) {
        if (field.effectiveName == 'value' && _unwrap(field.pattern) is NullCheckPattern) {
          rule.reportAtNode(field.pattern);
        }
      }
    }

    super.visitObjectPattern(node);
  }

  DartPattern _unwrap(DartPattern pattern) {
    var current = pattern;
    while (current is ParenthesizedPattern) {
      current = current.pattern;
    }
    return current;
  }
}
