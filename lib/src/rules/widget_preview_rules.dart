import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_skill_lints/src/additional_lints/type_checker.dart';
import 'package:flutter_skill_lints/src/ast_utils.dart';

final List<AbstractAnalysisRule> widgetPreviewRules = [
  WidgetPreviewImportLeak(),
  WidgetPreviewPlatformDependency(),
  WidgetPreviewScreen(),
];

const _widgetPreviewsLibrary = 'package:flutter/widget_previews.dart';
const _screensSegment = '/presentation/screens/';

/// Keep `package:flutter/widget_previews.dart` out of production widget files.
///
/// Why: widget-previews.md requires the preview import only in preview files or
/// preview-only blocks. A library that declares no resolved `@Preview`, or that
/// also declares a Widget/State class, ships preview code with production UI.
final class WidgetPreviewImportLeak extends AnalysisRule {
  static const LintCode code = LintCode(
    'widget_preview_import_leak',
    'Import widget_previews only in preview files.',
    correctionMessage:
        'Move @Preview functions into a separate *_preview.dart file next to the widget and '
        'import package:flutter/widget_previews.dart only there.',
    severity: DiagnosticSeverity.ERROR,
  );

  WidgetPreviewImportLeak()
    : super(
        name: 'widget_preview_import_leak',
        description:
            'Flags widget_previews imports in libraries without resolved @Preview declarations '
            'or with production Widget/State classes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (productionLibPath(context) == null) return;
    registry.addCompilationUnit(this, _ImportLeakVisitor(this));
  }
}

final class _ImportLeakVisitor extends SimpleAstVisitor<void> {
  _ImportLeakVisitor(this.rule);

  final WidgetPreviewImportLeak rule;

  static const _productionUiChecker = TypeChecker.any([
    TypeChecker.fromName('Widget', packageName: 'flutter'),
    flutterStateChecker,
  ]);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final previewImports = node.directives.whereType<ImportDirective>().where(
      (directive) =>
          directive.libraryImport?.importedLibrary?.uri.toString() == _widgetPreviewsLibrary,
    );
    if (previewImports.isEmpty) return;

    final isPreviewOnly =
        widgetPreviewDeclarations(node).isNotEmpty &&
        !node.declarations.whereType<ClassDeclaration>().any(
          (declaration) => isClassAssignableTo(declaration, _productionUiChecker),
        );
    if (isPreviewOnly) return;

    for (final directive in previewImports) {
      rule.reportAtNode(directive.uri);
    }
  }
}

/// Keep native plugins, IO, persistence, and network clients out of previews.
///
/// Why: widget-previews.md forbids `dart:io`, platform channels, Firebase, Hive
/// boxes, and real HTTP in previews. References are matched by the resolved
/// element's library; arbitrary native plugins cannot be identified soundly.
final class WidgetPreviewPlatformDependency extends AnalysisRule {
  static const LintCode code = LintCode(
    'widget_preview_platform_dependency',
    'Previews must not use dart:io, platform channels, Firebase, Hive, or real HTTP.',
    correctionMessage:
        'Override the dependency with a fake through AppPreviewShell provider overrides.',
    severity: DiagnosticSeverity.ERROR,
  );

  WidgetPreviewPlatformDependency()
    : super(
        name: 'widget_preview_platform_dependency',
        description:
            'Flags dart:io, platform channel, Hive, Firebase, Dio, and http references '
            'inside resolved @Preview declarations.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    if (productionLibPath(context) == null) return;
    registry.addCompilationUnit(
      this,
      _PreviewDeclarationsVisitor(this, _PlatformReferenceVisitor.new),
    );
  }
}

final class _PlatformReferenceVisitor extends RecursiveAstVisitor<void> {
  _PlatformReferenceVisitor(this.rule);

  final AnalysisRule rule;
  final _reportedStatements = <AstNode>{};

  static const _bannedLibraryPrefixes = [
    'dart:io',
    'dart:_http',
    'package:flutter/src/services/platform_channel.dart',
    'package:hive/',
    'package:hive_ce/',
    'package:hive_flutter/',
    'package:hive_ce_flutter/',
    'package:firebase_',
    'package:cloud_firestore/',
    'package:cloud_functions/',
    'package:dio/',
    'package:http/',
  ];

  @override
  void visitNamedType(NamedType node) {
    _check(node, node.element);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _check(node, node.element);
  }

  void _check(AstNode node, Element? element) {
    final uri = element?.library?.uri.toString();
    if (uri == null || !_bannedLibraryPrefixes.any(uri.startsWith)) return;

    final statement = node.thisOrAncestorOfType<Statement>() ?? node;
    if (_reportedStatements.add(statement)) rule.reportAtNode(node);
  }
}

/// Preview small surfaces, not full runtime screens.
///
/// Why: widget-previews.md forbids `@Preview` on app screens that need a full
/// runtime boot. Screens are placement-defined (`presentation/screens/`, see
/// atomic-design.md), so previews declared in, or constructing a widget from,
/// a screens library are reported.
final class WidgetPreviewScreen extends AnalysisRule {
  static const LintCode code = LintCode(
    'widget_preview_screen',
    'Do not preview full app screens.',
    correctionMessage:
        'Preview a small presentation widget with faked providers instead of a '
        'presentation/screens/ page.',
    severity: DiagnosticSeverity.ERROR,
  );

  WidgetPreviewScreen()
    : super(
        name: 'widget_preview_screen',
        description:
            'Flags @Preview declarations in presentation/screens/ libraries or constructing '
            'screen widgets.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final path = productionLibPath(context);
    if (path == null) return;
    if (path.contains(_screensSegment)) {
      registry.addCompilationUnit(this, _ScreenLibraryPreviewVisitor(this));
    } else {
      registry.addCompilationUnit(
        this,
        _PreviewDeclarationsVisitor(this, _ScreenConstructionVisitor.new),
      );
    }
  }
}

final class _ScreenLibraryPreviewVisitor extends SimpleAstVisitor<void> {
  _ScreenLibraryPreviewVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final declaration in widgetPreviewDeclarations(node)) {
      rule.reportAtNode(widgetPreviewAnnotation(declaration));
    }
  }
}

final class _ScreenConstructionVisitor extends RecursiveAstVisitor<void> {
  _ScreenConstructionVisitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final uri = node.constructorName.element?.library.uri.toString();
    if (uri != null && uri.contains(_screensSegment)) {
      rule.reportAtNode(node.constructorName);
    }
    super.visitInstanceCreationExpression(node);
  }
}

/// Runs a body visitor over every resolved `@Preview` declaration in a unit.
final class _PreviewDeclarationsVisitor extends SimpleAstVisitor<void> {
  _PreviewDeclarationsVisitor(this.rule, this.bodyVisitor);

  final AnalysisRule rule;
  final AstVisitor<void> Function(AnalysisRule rule) bodyVisitor;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final declaration in widgetPreviewDeclarations(node)) {
      final body = switch (declaration) {
        FunctionDeclaration(:final functionExpression) => functionExpression.body,
        MethodDeclaration(:final body) => body,
        ConstructorDeclaration(:final body) => body,
        _ => null,
      };
      body?.accept(bodyVisitor(rule));
    }
  }
}
