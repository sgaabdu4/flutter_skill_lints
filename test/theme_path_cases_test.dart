import 'dart:convert';
import 'dart:io';

import 'package:flutter_skill_lints/src/rules/ui_project_paths.dart';
import 'package:test/test.dart';

void main() {
  test('theme path function answers every case of the Flutter skill case file', () {
    final file = File('fixtures/building-flutter-apps/tool/test_fixtures/theme_paths.json');
    expect(file.existsSync(), isTrue, reason: 'init the fixtures/building-flutter-apps submodule');
    final cases =
        (jsonDecode(file.readAsStringSync()) as Map<String, Object?>)['cases']! as List<Object?>;
    expect(cases, isNotEmpty);
    final wrong = <String>[];
    for (final row in cases.cast<Map<String, Object?>>()) {
      final path = row['path']! as String;
      if (isThemePath(path) != row['theme']) wrong.add('${row['group']}: $path');
    }
    expect(wrong, isEmpty);
  });
}
