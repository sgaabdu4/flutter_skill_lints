@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final shouldRun = Platform.environment['RUN_FLUTTER_PLUGIN_SMOKE'] == '1';

  test(
    'loads canonical configuration with riverpod_lint in a real Flutter analysis server run',
    () async {
      final packageRoot = Directory.current.absolute.path;
      final app = await Directory.systemTemp.createTemp('flutter_skill_lints_smoke_');

      try {
        await _writeFile('${app.path}/pubspec.yaml', r'''
name: flutter_skill_lints_smoke
publish_to: none

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.4.3
  riverpod_annotation: ^4.0.7
''');
        final analysisOptionsPath = '${app.path}/analysis_options.yaml';
        await _writeFile(analysisOptionsPath, _analysisOptions(packageRoot));
        await Directory('${app.path}/lib').create(recursive: true);
        await Directory('${app.path}/lib/features/history/presentation/notifiers')
            .create(recursive: true);
        await Directory('${app.path}/lib/features/content/presentation/widgets')
            .create(recursive: true);
        await Directory('${app.path}/lib/features/content/repositories').create(recursive: true);
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
    var hasMore = true;
    ref.read(counterProvider);
    final value = ref.watch(counterProvider);
    final label = value == 0 ? null : value.toString();
    return Column(
      textDirection: TextDirection.ltr,
      children: [
        Text(label!, textDirection: TextDirection.ltr),
        Text(hasMore.toString(), textDirection: TextDirection.ltr),
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
        await _writeFile(
          '${app.path}/lib/features/content/repositories/content_repository.dart',
          'abstract interface class ContentRepository {}',
        );
        await _writeFile(
          '${app.path}/lib/features/content/presentation/widgets/content_view.dart',
          r'''
import 'package:flutter/widgets.dart';

import '../../repositories/content_repository.dart';

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  final List<Object> _pageStack = [];

  @override
  Widget build(BuildContext context) {
    Navigator.of(context).pop();
    return const SizedBox.shrink();
  }
}
''',
        );

        await _writeFile('${app.path}/lib/watch_boundaries.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flagProvider = Provider<bool?>((ref) => null);
final structuredProvider = Provider<List<String>>((ref) => []);

class WatchBoundaries extends ConsumerWidget {
  const WatchBoundaries({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flag = ref.watch(flagProvider);
    final entries = ref.watch(structuredProvider);
    final identity = ref.watch(flagProvider.select((value) => value));
    return Text('$flag $entries $identity', textDirection: TextDirection.ltr);
  }
}
''');

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
        expect(output, contains('prefer_type_over_var'));
        expect(output, contains('riverpod_feature_notifier_keepalive'));
        expect(output, contains('presentation_widget_navigation_forbidden'));
        expect(output, contains('presentation_widget_controller_state'));
        expect(output, contains('presentation_widget_infrastructure_dependency'));
        expect(output, contains('prefer_dot_shorthands'));
        final broadWatches = output
            .split('\n')
            .where((line) => line.contains('riverpod_watch_no_select'));
        expect(broadWatches, hasLength(1));
        expect(broadWatches.single, contains('watch_boundaries.dart:13:'));
        expect(output, contains('riverpod_select_identity_forbidden'));

        expect(output, isNot(contains('deprecated_lint')));
        expect(output, isNot(contains('server.pluginError')));

        await _writeFile(analysisOptionsPath, _analysisOptionsWithDeprecatedLint(packageRoot));
        final deprecatedLintAnalyze = await _run('dart', ['analyze'], app);
        final deprecatedLintOutput =
            '${deprecatedLintAnalyze.stdout}\n${deprecatedLintAnalyze.stderr}';

        expect(deprecatedLintOutput, contains('avoid_private_typedef_functions'));
        expect(deprecatedLintOutput, contains('deprecated_lint'));
      } finally {
        await app.delete(recursive: true);
      }
    },
    skip: shouldRun ? false : 'Set RUN_FLUTTER_PLUGIN_SMOKE=1 to run.',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

String _analysisOptions(String packageRoot) =>
    '''
include: package:flutter_skill_lints/analysis_options.yaml

plugins:
  riverpod_lint: ^3.1.9
  flutter_skill_lints:
    path: $packageRoot

analyzer:
  exclude:
    - "**/*.g.dart"
''';

String _analysisOptionsWithDeprecatedLint(String packageRoot) =>
    '''
${_analysisOptions(packageRoot)}
linter:
  rules:
    - avoid_private_typedef_functions
''';

Future<void> _writeFile(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

Future<ProcessResult> _run(String executable, List<String> arguments, Directory workingDirectory) {
  return Process.run(executable, arguments, workingDirectory: workingDirectory.path);
}
