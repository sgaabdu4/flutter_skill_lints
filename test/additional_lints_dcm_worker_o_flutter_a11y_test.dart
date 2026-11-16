import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_image_alt.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_action_button_tooltip.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_define_hero_tag.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_text_rich.dart';
import 'package:test/test.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<PreferActionButtonTooltipTest>(
    'PreferActionButtonTooltipTest',
    PreferActionButtonTooltipTest.new,
    {
      'test_severityIsError': (t) => t._severityIsError(),
      'test_iconButtonMissingTooltip_lint': (t) => t._iconButtonMissingTooltipLint(),
      'test_floatingActionButtonMissingTooltip_lint': (t) =>
          t._floatingActionButtonMissingTooltipLint(),
      'test_actionButtonWithTooltip_noLint': (t) => t._actionButtonWithTooltipNoLint(),
      'test_methodReturningActionButton_noLint': (t) => t._methodReturningActionButtonNoLint(),
      'test_nonActionButton_noLint': (t) => t._nonActionButtonNoLint(),
    },
  );
  analysisRuleSuite<AvoidMissingImageAltTest>(
    'AvoidMissingImageAltTest',
    AvoidMissingImageAltTest.new,
    {
      'test_severityIsError': (t) => t._severityIsError(),
      'test_imageMissingSemanticLabel_lint': (t) => t._imageMissingSemanticLabelLint(),
      'test_assetImageMissingSemanticLabel_lint': (t) => t._assetImageMissingSemanticLabelLint(),
      'test_memoryAndNetworkImagesMissingSemanticLabel_lint': (t) =>
          t._memoryAndNetworkImagesMissingSemanticLabelLint(),
      'test_dotShorthandImageConstructorMissingSemanticLabel_lint': (t) =>
          t._dotShorthandImageConstructorMissingSemanticLabelLint(),
      'test_methodsReturningImage_noLint': (t) => t._methodsReturningImageNoLint(),
      'test_dotShorthandStaticMethodReturningImage_noLint': (t) =>
          t._dotShorthandStaticMethodReturningImageNoLint(),
      'test_constructorTearOff_noLint': (t) => t._constructorTearOffNoLint(),
      'test_unrelatedImageClass_noLint': (t) => t._unrelatedImageClassNoLint(),
      'test_nullLabelAndFalseSemanticsExclusion_lint': (t) =>
          t._nullLabelAndFalseSemanticsExclusionLint(),
      'test_imageWithSemanticLabel_noLint': (t) => t._imageWithSemanticLabelNoLint(),
      'test_decorativeImageExcludedFromSemantics_noLint': (t) =>
          t._decorativeImageExcludedFromSemanticsNoLint(),
    },
  );
  analysisRuleSuite<PreferDefineHeroTagTest>(
    'PreferDefineHeroTagTest',
    PreferDefineHeroTagTest.new,
    {
      'test_floatingActionButtonMissingHeroTag_lint': (t) =>
          t._floatingActionButtonMissingHeroTagLint(),
      'test_extendedFloatingActionButtonMissingHeroTag_lint': (t) =>
          t._extendedFloatingActionButtonMissingHeroTagLint(),
      'test_floatingActionButtonWithHeroTag_noLint': (t) =>
          t._floatingActionButtonWithHeroTagNoLint(),
      'test_floatingActionButtonWithNullHeroTag_noLint': (t) =>
          t._floatingActionButtonWithNullHeroTagNoLint(),
    },
  );
  analysisRuleSuite<PreferTextRichTest>('PreferTextRichTest', PreferTextRichTest.new, {
    'test_severityIsError': (t) => t._severityIsError(),
    'test_richText_lint': (t) => t._richTextLint(),
    'test_text_noLint': (t) => t._textNoLint(),
  });
}

abstract class _FlutterA11yRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget();
}

class Icon extends Widget {
  const Icon(this.name);

  final String name;
}

class IconButton extends Widget {
  const IconButton({
    required Widget icon,
    required void Function()? onPressed,
    String? tooltip,
  });
}

class FloatingActionButton extends Widget {
  const FloatingActionButton({
    Object? heroTag = const _DefaultHeroTag(),
    String? tooltip,
    Widget? child,
    void Function()? onPressed,
  });

  const FloatingActionButton.extended({
    Object? heroTag = const _DefaultHeroTag(),
    String? tooltip,
    required Widget label,
    Widget? icon,
    void Function()? onPressed,
  });
}

class _DefaultHeroTag {
  const _DefaultHeroTag();
}

class Image extends Widget {
  const Image({
    String? semanticLabel,
    bool excludeFromSemantics = false,
  });

  const Image.asset(
    String name, {
    String? semanticLabel,
    bool excludeFromSemantics = false,
  });

  const Image.memory(
    List<int> bytes, {
    String? semanticLabel,
    bool excludeFromSemantics = false,
  });

  const Image.network(
    String url, {
    String? semanticLabel,
    bool excludeFromSemantics = false,
  });

  static Image cached() => const Image(semanticLabel: 'Cached image');
}

class Text extends Widget {
  const Text(this.data);

  final String data;
}

class RichText extends Widget {
  const RichText({required Object text});
}

T findWidget<T extends Widget>() => throw StateError('test helper');
''');
  }
}

final class PreferActionButtonTooltipTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferActionButtonTooltip();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(PreferActionButtonTooltip.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _iconButtonMissingTooltipLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return IconButton(
    icon: const Icon('add'),
    onPressed: () {},
  );
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('IconButton'), 'IconButton'.length)]);
  }

  Future<void> _floatingActionButtonMissingTooltipLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FloatingActionButton(
    heroTag: 'create',
    child: const Icon('add'),
    onPressed: () {},
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FloatingActionButton'), 'FloatingActionButton'.length),
    ]);
  }

  Future<void> _actionButtonWithTooltipNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return IconButton(
    tooltip: 'Create item',
    icon: const Icon('add'),
    onPressed: () {},
  );
}
''');
  }

  Future<void> _methodReturningActionButtonNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

IconButton inspect() => findWidget<IconButton>();
''');
  }

  Future<void> _nonActionButtonNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Create');
''');
  }
}

final class AvoidMissingImageAltTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingImageAlt();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(AvoidMissingImageAlt.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _imageMissingSemanticLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image();
''';

    await assertDiagnostics(source, [lint(source.indexOf('Image'), 'Image'.length)]);
  }

  Future<void> _assetImageMissingSemanticLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image.asset('avatar.png');
''';

    await assertDiagnostics(source, [lint(source.indexOf('Image.asset'), 'Image.asset'.length)]);
  }

  Future<void> _memoryAndNetworkImagesMissingSemanticLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget memory() => const Image.memory([1]);
Widget network() => const Image.network('https://example.invalid/image.png');
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Image.memory'), 'Image.memory'.length),
      lint(source.indexOf('Image.network'), 'Image.network'.length),
    ]);
  }

  Future<void> _dotShorthandImageConstructorMissingSemanticLabelLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Image build() => .asset('avatar.png');
''';

    await assertDiagnostics(source, [lint(source.indexOf('.asset'), 20)]);
  }

  Future<void> _methodsReturningImageNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Tester {
  T widget<T extends Widget>() => throw 0;
}

class ImageHolder {
  ImageHolder(this.image);
  final Image image;
  Image getImage() => image;
}

Image inspect(Tester tester) => tester.widget<Image>();
Image retrieve(ImageHolder holder) => holder.getImage();
''');
  }

  Future<void> _dotShorthandStaticMethodReturningImageNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Image build() => .cached();
''');
  }

  Future<void> _constructorTearOffNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final imageFactory = Image.asset;
''');
  }

  Future<void> _unrelatedImageClassNoLint() async {
    await assertNoDiagnostics(r'''
class Image {
  const Image();
  const Image.named();
}

Image regular() => const Image();
Image shorthand() => .named();
''');
  }

  Future<void> _nullLabelAndFalseSemanticsExclusionLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget unlabeled() => const Image(semanticLabel: null);
Widget included() => const Image.asset('avatar.png', excludeFromSemantics: false);
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('Image(semanticLabel'), 'Image'.length),
      lint(source.indexOf('Image.asset'), 'Image.asset'.length),
    ]);
  }

  Future<void> _imageWithSemanticLabelNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image(semanticLabel: 'User avatar');
''');
  }

  Future<void> _decorativeImageExcludedFromSemanticsNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image.asset(
  'divider.png',
  excludeFromSemantics: true,
);
''');
  }
}

final class PreferDefineHeroTagTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferDefineHeroTag();
    super.setUp();
  }

  Future<void> _floatingActionButtonMissingHeroTagLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FloatingActionButton(
    tooltip: 'Create item',
    child: const Icon('add'),
    onPressed: () {},
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FloatingActionButton'), 'FloatingActionButton'.length),
    ]);
  }

  Future<void> _extendedFloatingActionButtonMissingHeroTagLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FloatingActionButton.extended(
    tooltip: 'Create item',
    label: const Text('Create'),
    onPressed: () {},
  );
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('FloatingActionButton.extended'), 'FloatingActionButton.extended'.length),
    ]);
  }

  Future<void> _floatingActionButtonWithHeroTagNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FloatingActionButton(
    heroTag: 'create-item',
    tooltip: 'Create item',
    child: const Icon('add'),
    onPressed: () {},
  );
}
''');
  }

  Future<void> _floatingActionButtonWithNullHeroTagNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return FloatingActionButton(
    heroTag: null,
    tooltip: 'Create item',
    child: const Icon('add'),
    onPressed: () {},
  );
}
''');
  }
}

final class PreferTextRichTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferTextRich();
    super.setUp();
  }

  Future<void> _severityIsError() async {
    expect(PreferTextRich.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> _richTextLint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const RichText(text: 'Total');
''';

    await assertDiagnostics(source, [lint(source.indexOf('RichText('), 'RichText'.length)]);
  }

  Future<void> _textNoLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Total');
''');
  }
}
