import 'dart:io';

import 'package:test/test.dart';

import '../test/support/ui_quality_fixture_sources.dart';

void main() {
  test('red card fails and fixed card passes', () async {
    final packageRoot = Directory.current.absolute.path;
    final app = await Directory.systemTemp.createTemp('flutter_skill_lints_ui_quality_');

    try {
      await _writeFile('${app.path}/pubspec.yaml', _pubspec);
      await _writeFile('${app.path}/analysis_options.yaml', _analysisOptions(packageRoot));
      await _writeFile('${app.path}/lib/red_item_card.dart', uiQualityRedCardSource);
      await _writeFile('${app.path}/lib/fixed_item_card.dart', uiQualityFixedCardSource);
      await _writeFile(
        '${app.path}/test/item_card_guidelines_test.dart',
        uiQualityGuidelineTestSource,
      );

      final pubGet = await _run('flutter', ['pub', 'get'], app);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}\n${pubGet.stderr}');

      final (guidelines, analyze) = await (
        _run('flutter', ['test', 'test/item_card_guidelines_test.dart'], app),
        _run('dart', ['analyze'], app),
      ).wait;
      expect(
        guidelines.exitCode,
        0,
        reason:
            'The red card must fail and the fixed card must pass each guideline at 390, 768 '
            'and 1280 px:\n${guidelines.stdout}\n${guidelines.stderr}',
      );

      final output = '${analyze.stdout}\n${analyze.stderr}';
      expect(output, isNot(contains('server.pluginError')));

      List<String> findings(String file, String code) => [
        for (final line in output.split('\n'))
          if (line.contains('$file.dart:') && line.trimRight().endsWith(' - $code')) line.trim(),
      ];

      expect(findings('red_item_card', 'avoid_small_font_size'), hasLength(4), reason: output);
      expect(
        findings('red_item_card', 'avoid_conflicting_filled_buttons'),
        hasLength(1),
        reason: output,
      );
      expect(findings('fixed_item_card', 'avoid_small_font_size'), isEmpty, reason: output);
      expect(
        findings('fixed_item_card', 'avoid_conflicting_filled_buttons'),
        isEmpty,
        reason: output,
      );
    } finally {
      await app.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}

const _pubspec = '''
name: flutter_skill_lints_ui_fixture
publish_to: none

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

String _analysisOptions(String packageRoot) =>
    '''
plugins:
  flutter_skill_lints:
    path: $packageRoot
''';

Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

Future<ProcessResult> _run(String executable, List<String> arguments, Directory workingDirectory) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory.path,
  ).timeout(const Duration(minutes: 6));
}
