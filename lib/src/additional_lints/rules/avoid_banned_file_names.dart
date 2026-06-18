import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Warns when a Dart file basename is unfriendly to generated part files.
final class AvoidBannedFileNames extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_banned_file_names',
    'Avoid uppercase letters or spaces in Dart file names.',
    correctionMessage: 'Rename the file using lowercase snake_case.',
  );

  AvoidBannedFileNames()
    : super(
        name: 'avoid_banned_file_names',
        description: 'Warns when Dart file names contain uppercase letters or spaces.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = context.definingUnit.file.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart') || _isGenerated(path)) return;

    final fileName = path.substring(path.lastIndexOf('/') + 1);
    if (!_hasBannedBasenameCharacter(fileName)) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

final class _Visitor extends SimpleAstVisitor<void> {
  const _Visitor(this.rule);

  final AvoidBannedFileNames rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtToken(node.beginToken);
  }
}

bool _hasBannedBasenameCharacter(String fileName) {
  for (var i = 0; i < fileName.length; i++) {
    final codeUnit = fileName.codeUnitAt(i);
    if ((codeUnit >= 0x41 && codeUnit <= 0x5a) || codeUnit == 0x20) return true;
  }

  return false;
}

bool _isGenerated(String path) {
  const generatedSuffixes = ['.config.dart', '.freezed.dart', '.g.dart', '.gen.dart', '.gr.dart'];

  return generatedSuffixes.any(path.endsWith);
}
