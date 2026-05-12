@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final shouldRun = Platform.environment['RUN_FLUTTER_PLUGIN_SMOKE'] == '1';

  test(
    'loads with riverpod_lint in a real Flutter analysis server run',
    () async {
      final packageRoot = Directory.current.absolute.path;
      final app = await Directory.systemTemp.createTemp('flutter_skill_lints_smoke_');

      try {
        await _writeFile('${app.path}/pubspec.yaml', r'''
name: flutter_skill_lints_smoke
publish_to: none

environment:
  sdk: ^3.10.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.0
  riverpod_annotation: ^3.0.0
''');
        await _writeFile('${app.path}/analysis_options.yaml', '''
plugins:
  flutter_skill_lints:
    path: $packageRoot
  # Pre-release pin: lift when riverpod_lint 3.2.0 stable lands.
  # Verify pub.dev before ship. Promote to latest stable when possible.
  # Pre-release silently adopts dev behavior - review.
  riverpod_lint: 3.1.4-dev.3

analyzer:
  exclude:
    - "**/*.g.dart"
''');
        await Directory('${app.path}/lib').create(recursive: true);
        await Directory('${app.path}/lib/features/history/presentation/notifiers')
            .create(recursive: true);
        await _writeFile('${app.path}/lib/main.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final counterProvider = Provider<int>((ref) => 0);

void main() {
  runApp(const Demo());
}

class Demo extends ConsumerWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(counterProvider);
    final value = ref.watch(counterProvider);
    final label = value == 0 ? null : value.toString();
    return Column(
      textDirection: TextDirection.ltr,
      children: [
        Text(label!, textDirection: TextDirection.ltr),
        const _DemoContent(),
        const _DemoSheet(),
      ],
    );
  }
}

class _DemoContent extends StatelessWidget {
  const _DemoContent();

  @override
  Widget build(BuildContext context) {
    return const Text('content', textDirection: TextDirection.ltr);
  }
}

class _DemoSheet extends ConsumerStatefulWidget {
  const _DemoSheet();

  @override
  ConsumerState<_DemoSheet> createState() => _DemoSheetState();
}

class _DemoSheetState extends ConsumerState<_DemoSheet> {
  @override
  Widget build(BuildContext context) {
    return const Text('sheet', textDirection: TextDirection.ltr);
  }
}
''');
        await _writeFile(
          '${app.path}/lib/features/history/presentation/notifiers/history_calendar_notifier.dart',
          r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class HistoryCalendarNotifier {
  Object build() => Object();
}
''',
        );

        final pubGet = await _run('flutter', ['pub', 'get'], app);
        expect(
          pubGet.exitCode,
          0,
          reason: 'flutter pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
        );

        final analyze = await _run('dart', ['analyze'], app);
        final output = '${analyze.stdout}\n${analyze.stderr}';

        expect(output, contains('avoid_null_bang'));
        expect(output, contains('avoid_ref_read_inside_build'));
        expect(output, contains('missing_provider_scope'));
        expect(output, contains('prefer_single_widget_per_file'));
        expect(output, contains('riverpod_feature_notifier_keepalive'));
        expect(output, isNot(contains('server.pluginError')));
      } finally {
        await app.delete(recursive: true);
      }
    },
    skip: shouldRun ? false : 'Set RUN_FLUTTER_PLUGIN_SMOKE=1 to run.',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

Future<ProcessResult> _run(String executable, List<String> arguments, Directory workingDirectory) {
  return Process.run(executable, arguments, workingDirectory: workingDirectory.path);
}
