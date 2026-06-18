// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_image_alt.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_action_button_tooltip.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/prefer_define_hero_tag.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferActionButtonTooltipTest);
    defineReflectiveTests(AvoidMissingImageAltTest);
    defineReflectiveTests(PreferDefineHeroTagTest);
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
}

class Text extends Widget {
  const Text(this.data);

  final String data;
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
