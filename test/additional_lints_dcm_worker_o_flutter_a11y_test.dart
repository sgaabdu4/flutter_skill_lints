// ignore_for_file: non_constant_identifier_names

import 'package:analyzer/error/error.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_image_alt.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_action_button_tooltip.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_define_hero_tag.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_text_rich.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferActionButtonTooltipTest);
    defineReflectiveTests(AvoidMissingImageAltTest);
    defineReflectiveTests(PreferDefineHeroTagTest);
    defineReflectiveTests(PreferTextRichTest);
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

@reflectiveTest
final class PreferActionButtonTooltipTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferActionButtonTooltip();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(PreferActionButtonTooltip.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_iconButtonMissingTooltip_lint() async {
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

  Future<void> test_floatingActionButtonMissingTooltip_lint() async {
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

  Future<void> test_actionButtonWithTooltip_noLint() async {
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

  Future<void> test_methodReturningActionButton_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

IconButton inspect() => findWidget<IconButton>();
''');
  }

  Future<void> test_nonActionButton_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Create');
''');
  }
}

@reflectiveTest
final class AvoidMissingImageAltTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingImageAlt();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(AvoidMissingImageAlt.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_imageMissingSemanticLabel_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image();
''';

    await assertDiagnostics(source, [lint(source.indexOf('Image'), 'Image'.length)]);
  }

  Future<void> test_assetImageMissingSemanticLabel_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image.asset('avatar.png');
''';

    await assertDiagnostics(source, [lint(source.indexOf('Image.asset'), 'Image.asset'.length)]);
  }

  Future<void> test_memoryAndNetworkImagesMissingSemanticLabel_lint() async {
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

  Future<void> test_dotShorthandImageConstructorMissingSemanticLabel_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Image build() => .asset('avatar.png');
''';

    await assertDiagnostics(source, [lint(source.indexOf('.asset'), 20)]);
  }

  Future<void> test_methodsReturningImage_noLint() async {
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

  Future<void> test_dotShorthandStaticMethodReturningImage_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Image build() => .cached();
''');
  }

  Future<void> test_constructorTearOff_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final imageFactory = Image.asset;
''');
  }

  Future<void> test_unrelatedImageClass_noLint() async {
    await assertNoDiagnostics(r'''
class Image {
  const Image();
  const Image.named();
}

Image regular() => const Image();
Image shorthand() => .named();
''');
  }

  Future<void> test_nullLabelAndFalseSemanticsExclusion_lint() async {
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

  Future<void> test_imageWithSemanticLabel_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image(semanticLabel: 'User avatar');
''');
  }

  Future<void> test_decorativeImageExcludedFromSemantics_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Image.asset(
  'divider.png',
  excludeFromSemantics: true,
);
''');
  }
}

@reflectiveTest
final class PreferDefineHeroTagTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferDefineHeroTag();
    super.setUp();
  }

  Future<void> test_floatingActionButtonMissingHeroTag_lint() async {
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

  Future<void> test_extendedFloatingActionButtonMissingHeroTag_lint() async {
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

  Future<void> test_floatingActionButtonWithHeroTag_noLint() async {
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

  Future<void> test_floatingActionButtonWithNullHeroTag_noLint() async {
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

@reflectiveTest
final class PreferTextRichTest extends _FlutterA11yRuleTest {
  @override
  void setUp() {
    rule = PreferTextRich();
    super.setUp();
  }

  Future<void> test_severityIsError() async {
    expect(PreferTextRich.code.severity, DiagnosticSeverity.ERROR);
  }

  Future<void> test_richText_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() => const RichText(text: 'Total');
''';

    await assertDiagnostics(source, [lint(source.indexOf('RichText('), 'RichText'.length)]);
  }

  Future<void> test_text_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() => const Text('Total');
''');
  }
}
