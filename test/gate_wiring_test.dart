import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _decimateCommand = 'npx --yes dart-decimate@latest json .';
const _gitleaksAction = 'gitleaks/gitleaks-action@v3';
const _hardEngRef = 'v0.1.0-alpha.gf2c7a9d8842cd2b485819560d8d23728165573c6';
const _privacyCommand = r'python3 scripts/privacy_scan.py --repo "$GITHUB_WORKSPACE"';

File _repoFile(String path) => File('${Directory.current.path}${Platform.pathSeparator}$path');

Map<String, Object?> _object(Object? value) {
  expect(value, isA<Map<Object?, Object?>>());
  return Map<String, Object?>.from(value! as Map<Object?, Object?>);
}

List<String> _strings(Object? value) {
  expect(value, isA<List<Object?>>());
  return List<String>.from(value! as List<Object?>);
}

void main() {
  group('gate wiring', () {
    test('declares the full package quality phase', () {
      final manifest = _object(jsonDecode(_repoFile('hard-eng.gates.json').readAsStringSync()));
      final enforcement = _object(manifest['enforcement']);
      final families = _object(manifest['families']);
      final phases = _object(manifest['phases']);

      expect(enforcement['schema_version'], 1);
      expect(
        _strings(enforcement['required_paths']),
        containsAll([
          'scripts/run-gate-phase.sh',
          'scripts/setup-git-hooks.sh',
          'scripts/privacy_scan.py',
          '.githooks/pre-commit',
          '.githooks/pre-push',
        ]),
      );
      expect(_strings(families['dart-format']), [
        'dart',
        'format',
        '--output=none',
        '--set-exit-if-changed',
        '.',
      ]);
      expect(_strings(families['dart-analyze']), ['dart', 'analyze', '--fatal-infos']);
      expect(_strings(families['dart-test']), ['dart', 'test', '--reporter', 'expanded']);
      expect(_strings(families['dart-decimate']).join(' '), _decimateCommand);
      expect(_strings(families['secrets']), [
        'gitleaks',
        'dir',
        '--redact',
        '--no-banner',
        '--exit-code',
        '1',
        '.',
      ]);
      expect(_strings(families['privacy']), ['python3', 'scripts/privacy_scan.py', '--repo', '.']);
      expect(_strings(phases['commit']), ['dart-format', 'dart-analyze', 'privacy']);
      expect(_strings(phases['push']), [
        'dart-format',
        'dart-analyze',
        'dart-test',
        'dart-decimate',
        'secrets',
        'privacy',
      ]);
      expect(phases['push'], phases['ci']);
    });

    test('uses tracked hooks to run the selected phase', () {
      final runner = _repoFile('scripts/run-gate-phase.sh').readAsStringSync();
      final setup = _repoFile('scripts/setup-git-hooks.sh').readAsStringSync();
      final pubIgnore = _repoFile('.pubignore').readAsStringSync();
      final preCommit = _repoFile('.githooks/pre-commit').readAsStringSync();
      final prePush = _repoFile('.githooks/pre-push').readAsStringSync();

      expect(runner, contains('git rev-parse --local-env-vars'));
      expect(runner, contains('project_gate.py'));
      expect(setup, contains('git config --local core.hooksPath .githooks'));
      expect(pubIgnore, contains('scripts/'));
      for (final path in ['.agents/', '.githooks/', '.hard-eng-runtime/']) {
        expect(pubIgnore, contains(path));
      }
      expect(preCommit, contains('git rev-parse --local-env-vars'));
      expect(prePush, contains('git rev-parse --local-env-vars'));
      expect(preCommit, contains('run-gate-phase.sh" commit'));
      expect(prePush, contains('run-gate-phase.sh" push'));
    });

    test('keeps CI and release validation on the full quality phase', () {
      final ci = _repoFile('.github/workflows/dart.yml').readAsStringSync();
      final publish = _repoFile('.github/workflows/publish.yml').readAsStringSync();

      expect(ci, contains('dart format --output=none --set-exit-if-changed .'));
      expect(publish, contains('dart format --output=none --set-exit-if-changed .'));
      expect(ci, contains(_decimateCommand));
      expect(publish, contains(_decimateCommand));
      for (final job in ['publish-dry-run', 'pana', 'release-tag']) {
        expect(ci, matches(RegExp('  $job:\\n[\\s\\S]*?needs: \\[[^\\]]*dart-decimate')));
        expect(ci, matches(RegExp('  $job:\\n[\\s\\S]*?needs: \\[[^\\]]*universal-gates')));
      }
      for (final workflow in [ci, publish]) {
        expect(workflow, contains(_gitleaksAction));
        expect(workflow, contains('gitleaks dir --redact --no-banner --exit-code 1 .'));
        expect(workflow, contains('GITLEAKS_VERSION: "8.30.1"'));
        expect(workflow, contains(_hardEngRef));
        expect(workflow, contains(_privacyCommand));
      }
    });
  });
}
