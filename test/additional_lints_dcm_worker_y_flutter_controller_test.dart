// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/always_pass_global_key.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_disposing_late_fields.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_missing_controller.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidDisposingLateFieldsTest);
    defineReflectiveTests(AvoidMissingControllerTest);
    defineReflectiveTests(AlwaysPassGlobalKeyTest);
  });
}

abstract class _FlutterControllerRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    super.setUp();
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class Widget {
  const Widget({Key? key});
}

class BuildContext {}

class Key {
  const Key();
}

class GlobalKey extends Key {
  GlobalKey();
}

class StatelessWidget extends Widget {
  const StatelessWidget({super.key});
  Widget build(BuildContext context) => const Widget();
}

class StatefulWidget extends Widget {
  const StatefulWidget({super.key});
}

class TextEditingController {
  void dispose() {}
}

class FocusNode {
  void dispose() {}
}

class TextField extends Widget {
  const TextField({TextEditingController? controller});
}

class TextFormField extends Widget {
  const TextFormField({TextEditingController? controller});
}

class EditableText extends Widget {
  const EditableText({
    required FocusNode focusNode,
    TextEditingController? controller,
  });
}

class DropdownButton<T> extends Widget {
  const DropdownButton({T? value});
}
''');
  }
}

@reflectiveTest
final class AvoidDisposingLateFieldsTest extends _FlutterControllerRuleTest {
  @override
  void setUp() {
    rule = AvoidDisposingLateFields();
    super.setUp();
  }

  Future<void> test_lateFieldDisposed_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late final TextEditingController controller;

  void dispose() {
    controller.dispose();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('controller.dispose()'), 'controller.dispose()'.length),
    ]);
  }

  Future<void> test_thisPrefixedLateFieldDisposed_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host {
  late TextEditingController controller;

  void dispose() {
    this.controller.dispose();
  }
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('this.controller.dispose()'), 'this.controller.dispose()'.length),
    ]);
  }

  Future<void> test_eagerFieldDisposed_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host {
  final controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}
''');
  }

  Future<void> test_lateFieldUsedOutsideDispose_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host {
  late final TextEditingController controller;

  void close() {
    controller.dispose();
  }
}
''');
  }
}

@reflectiveTest
final class AvoidMissingControllerTest extends _FlutterControllerRuleTest {
  @override
  void setUp() {
    rule = AvoidMissingController();
    super.setUp();
  }

  Future<void> test_textFieldMissingController_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const TextField();
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('TextField'), 'TextField'.length)]);
  }

  Future<void> test_textFormFieldMissingController_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const TextFormField();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('TextFormField'), 'TextFormField'.length),
    ]);
  }

  Future<void> test_editableTextMissingController_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

final focusNode = FocusNode();

Widget build() {
  return EditableText(focusNode: focusNode);
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('EditableText'), 'EditableText'.length)]);
  }

  Future<void> test_controllerPassed_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final controller = TextEditingController();
final focusNode = FocusNode();

Widget build() {
  return EditableText(
    controller: controller,
    focusNode: focusNode,
  );
}
''');
  }

  Future<void> test_otherControllerAcceptingWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Widget build() {
  return const DropdownButton<int>();
}
''');
  }
}

@reflectiveTest
final class AlwaysPassGlobalKeyTest extends _FlutterControllerRuleTest {
  @override
  void setUp() {
    rule = AlwaysPassGlobalKey();
    super.setUp();
  }

  Future<void> test_globalKeyCreatedInBuild_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host extends StatelessWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context) {
    return Widget(key: GlobalKey());
  }
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('GlobalKey()'), 'GlobalKey()'.length)]);
  }

  Future<void> test_globalKeyCreatedInWidgetConstructor_lint() async {
    const source = r'''
import 'package:flutter/widgets.dart';

class Host extends Widget {
  Host() : super(key: GlobalKey());
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('GlobalKey()'), 'GlobalKey()'.length)]);
  }

  Future<void> test_globalKeyPassedThroughConstructor_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

class Host extends Widget {
  const Host({GlobalKey? key}) : super(key: key);
}
''');
  }

  Future<void> test_globalKeyCreatedOutsideWidget_noLint() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

final key = GlobalKey();

class Host extends Widget {
  Host() : super(key: key);
}
''');
  }
}
