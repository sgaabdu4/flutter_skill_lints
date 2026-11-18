import 'dart:convert';
import 'dart:io';

import 'package:flutter_skill_lints/src/rules/ui_project_paths.dart';
import 'package:test/test.dart';

const _revisionFile = 'test/theme_paths_revision.txt';

void main() {
  test('theme path function answers every case of the Flutter skill case file', () async {
    final text = await _caseFileText();
    final cases = (jsonDecode(text) as Map<String, Object?>)['cases']! as List<Object?>;
    expect(cases.length, greaterThanOrEqualTo(94));
    final wrong = <String>[];
    for (final row in cases.cast<Map<String, Object?>>()) {
      final path = row['path']! as String;
      if (isThemePath(path) != row['theme']) wrong.add('${row['group']}: $path');
    }
    expect(wrong, isEmpty);
  });
}

/// The case file of the Flutter skill repository at the revision in [_revisionFile], kept under `.dart_tool`; any fetch failure fails the test.
Future<String> _caseFileText() async {
  final revision = File(_revisionFile).readAsStringSync().trim();
  final cached = File('.dart_tool/theme_paths/$revision.json');
  if (cached.existsSync()) return cached.readAsStringSync();
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final uri = Uri.https(
      'raw.githubusercontent.com',
      '/sgaabdu4/building-flutter-apps/$revision/tool/test_fixtures/theme_paths.json',
    );
    final response = await (await client.getUrl(uri)).close().timeout(const Duration(seconds: 60));
    expect(response.statusCode, 200, reason: 'fetching $uri');
    final body = await utf8.decodeStream(response);
    cached.parent.createSync(recursive: true);
    cached.writeAsStringSync(body);
    return body;
  } finally {
    client.close();
  }
}
