import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_skill_lints/src/rules/ui_single_source_rules.dart';
import 'package:test/test.dart';

import '../test/support/ui_not_control_classes.dart';

void main() {
  test('every widget class of Flutter material and cupertino is judged by the rule', () async {
    final app = await Directory.systemTemp.createTemp('flutter_skill_lints_widget_classes_');
    try {
      await File('${app.path}/pubspec.yaml').writeAsString(_pubspec);
      await Directory('${app.path}/lib').create();
      await File('${app.path}/lib/a.dart')
          .writeAsString("import 'package:flutter/material.dart';\n");
      final pubGet = await Process.run('flutter', ['pub', 'get'], workingDirectory: app.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}\n${pubGet.stderr}');

      final context = AnalysisContextCollection(includedPaths: [app.path]).contexts.single;
      final widgets = <String>{};
      final withCallback = <String>{};
      for (final library in ['material', 'cupertino']) {
        final result = await context.currentSession.getLibraryByUri(
          'package:flutter/$library.dart',
        );
        expect(result, isA<LibraryElementResult>());
        for (final element
            in (result as LibraryElementResult).element.exportNamespace.definedNames2.values) {
          if (element is! ClassElement || element.isPrivate || !_isBuildable(element)) continue;
          if (element.allSupertypes.any((type) => type.element.name == 'Widget')) {
            widgets.add(element.name!);
            if (element.constructors.any(_hasCallbackParameter)) withCallback.add(element.name!);
          }
        }
      }

      expect(widgets.length, greaterThan(400));
      final unjudged = widgets
          .difference(uiBaseControlClasses)
          .difference(uiConditionalControlClasses.keys.toSet())
          .difference(uiNotControlClasses);
      expect(
        unjudged,
        isEmpty,
        reason: 'Put each class in uiBaseControlClasses (it is an input control) or in uiNotControlClasses.',
      );
      expect(uiBaseControlClasses.intersection(uiNotControlClasses), isEmpty);
      expect(uiConditionalControlClasses.keys.toSet().intersection(uiNotControlClasses), isEmpty);

      final reasoned = {for (final names in uiCallbackClassReasons.values) ...names};
      final unreasoned = withCallback.intersection(uiNotControlClasses).difference(reasoned);
      expect(
        unreasoned,
        isEmpty,
        reason: 'A class with an on* callback parameter needs a reason in uiCallbackClassReasons.',
      );
    } finally {
      await app.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 6)));
}

bool _hasCallbackParameter(ConstructorElement constructor) =>
    !constructor.isPrivate &&
    constructor.formalParameters.any((parameter) {
      final name = parameter.name ?? '';
      if (name.length < 3 || !name.startsWith('on')) return false;
      final letter = name.codeUnitAt(2);
      if (letter < 65 || letter > 90) return false;
      final type = parameter.type;
      return type is FunctionType || type.alias?.element.aliasedType is FunctionType;
    });

bool _isBuildable(ClassElement element) =>
    !element.isAbstract || element.constructors.any((constructor) => constructor.isFactory);

const _pubspec = '''
name: flutter_skill_lints_widget_classes
publish_to: none

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
''';
