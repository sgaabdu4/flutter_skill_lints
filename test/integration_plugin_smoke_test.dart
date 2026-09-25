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
  flutter_riverpod: 3.4.3
  riverpod_annotation: 4.0.7
  freezed_annotation: 3.1.0
  sentry_flutter: 9.30.1

dev_dependencies:
  build_runner: ^2.5.0
  freezed: 4.0.2
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
  bool _saving = false;
  Future<void> save(Future<void> Function() action, VoidCallback cleanup) async {
    _saving = true;
    try {
      await action();
    } finally {
      cleanup();
    }
  }

  Future<void> catchAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      rethrow;
    }
  }

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
final asyncProvider = Provider<AsyncValue<int>>((ref) => const AsyncData<int>(1));

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

class AsyncView extends ConsumerWidget {
  const AsyncView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(asyncProvider);
    return switch (result) {
      AsyncData(:final value) => Text('$value', textDirection: TextDirection.ltr),
      AsyncError(:final error) => Text('$error', textDirection: TextDirection.ltr),
      AsyncLoading() => const SizedBox.shrink(),
    };
  }
}
''');

        await _writeFile('${app.path}/lib/atomic_update_boundaries.dart', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'atomic_update_boundaries.freezed.dart';

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(
  ProgressNotifier.new,
);

@freezed
sealed class ProgressState with _$ProgressState {
  const factory ProgressState({required bool loading, int? value}) = _ProgressState;
}

Future<int> requestValue() async => 1;
Future<void> saveValue() async {}

class ProgressNotifier extends Notifier<ProgressState> {
  @override
  ProgressState build() => const ProgressState(loading: false);

  int revision = 0;

  Future<void> refresh() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await requestValue();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }

  Future<void> refreshThenSave() async {
    final ticket = ++revision;
    state = state.copyWith(loading: true);
    final value = await requestValue();
    if (!ref.mounted || ticket != revision) return;
    await saveValue();
    state = state.copyWith(loading: false, value: value);
  }

  Future<void> refreshSameDataField() async {
    final ticket = ++revision;
    state = state.copyWith(value: 0);
    final value = await requestValue();
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }

  Future<void> refreshWithLateTicket() async {
    state = state.copyWith(loading: true);
    final value = await requestValue();
    final ticket = ++revision;
    if (!ref.mounted || ticket != revision) return;
    state = state.copyWith(loading: false, value: value);
  }
}
''');

        await _writeFile('${app.path}/lib/sentry_mutation_boundaries.dart', r'''
import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

void sentryBuilderProbe() {
  SentryFlutter.init((options) {
    options.maxBreadcrumbs = 0;
    options = SentryFlutterOptions();
    scheduleMicrotask(() {
      options.maxBreadcrumbs = 1;
    });
  });
}

void sentryOptionsOutsideBuilder(SentryFlutterOptions options) {
  options.maxBreadcrumbs = 0;
}
''');

        await _writeFile('${app.path}/lib/resolved_contexts.dart', r'''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart' show counterProvider;
Widget makeConsumer() => Consumer(builder: (context, ref, child) {
  final count = ref.watch(counterProvider);
  return GestureDetector(
    onTap: () { ref.watch(counterProvider); },
    child: Text('$count', textDirection: TextDirection.ltr),
  );
});

Map<String, Object> encode(int count, int index, List<int> values) {
  final result = <String, Object>{'count': count};
  result['count'] = count;
  if (count < 0) throw ArgumentError.value(count, 'count', 'Must be positive');
  if (count == 0) throw ArgumentError('Must be positive', 'count');
  if (index < 0) throw RangeError.index(index, values, 'index');
  if (count > 10) throw RangeError.range(count, 1, 10, 'count');
  RangeError.checkValidIndex(index, values, 'index');
  RangeError.checkNotNegative(count, 'count');
  return result;
}

mixin LifecycleMixin<T extends StatefulWidget> on State<T> {
  @override
  void dispose() { super.dispose(); }
}
class LifecycleView extends StatefulWidget {
  const LifecycleView({super.key});
  @override
  State<LifecycleView> createState() => LifecycleViewState();
}
class LifecycleViewState extends State<LifecycleView> with LifecycleMixin<LifecycleView> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''');

        await _writeFile('${app.path}/lib/mutation_boundaries.dart', r'''
import 'package:flutter/widgets.dart';
class MutationView extends StatefulWidget {
  const MutationView({super.key});
  @override
  State<MutationView> createState() => MutationViewState();
}
class MutationViewState extends State<MutationView> {
  int _count = 0;
  void _change() {
    _count = _count + 1;
  }
  @override
  Widget build(BuildContext context) {
    _change();
    return GestureDetector(onTap: () => _change(), child: Text('$_count'));
  }
}
''');

        await _writeFile('${app.path}/lib/initialization_boundaries.dart', r'''
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Demo extends StatefulWidget {
  const Demo({super.key});
  @override
  State<Demo> createState() => SafeState();
}
class SafeState extends State<Demo> {
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Expanded(child: TextFieldPlaceholder());
}
class TextFieldPlaceholder extends StatelessWidget {
  const TextFieldPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
class UnsafeState extends State<Demo> {
  late TextEditingController controller;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => const SizedBox();
}
void ownResource(Ref ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
}
Future<void> timed(Future<void> work) {
  final timer = Timer(const Duration(seconds: 1), () {});
  return work.whenComplete(timer.cancel);
}
void lostResource() {
  final controller = TextEditingController();
  print(controller);
}
int? defaultNull() {
  int? count;
  return count;
}
void unassignedLateLocal() {
  late int? count;
  print(count);
}
Widget invalidLayout() => Padding(
  padding: EdgeInsets.zero,
  child: Expanded(child: const SizedBox()),
);
Axis defaultAxis() => Axis.horizontal;
''');

        await _writeFile('${app.path}/lib/expression_boundaries.dart', r'''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class Point { int value = 1; }
void replace(Point point) {
  final previous = point.value;
  point.value = 2;
  print(previous);
}
void duplicate(Point point) {
  final previous = point.value;
  final repeated = point.value;
  print(previous);
  print(repeated);
}
bool overlap(Point a, Point b, Point c, Point d) => a.value < d.value && b.value > c.value;
bool impossible(Point a, int bound) => a.value < bound && a.value > bound;
final formProvider = NotifierProvider<FormNotifier, String>(FormNotifier.new);
class FormNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) { state = value; }
  Future<void> fetch(String value) async {}
}
class FormView extends ConsumerWidget {
  const FormView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
    TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value)),
    TextField(onChanged: (value) => ref.read(formProvider.notifier).fetch(value)),
  ]);
}
''');

        await _writeFile('${app.path}/lib/audit_notifier.dart', r'''
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final auditProvider = NotifierProvider<AuditNotifier, String>(AuditNotifier.new);
class AuditNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String value) { state = value; }
  Future<void> fetch(String value) async {}
  void forward(String value) { unawaited(fetch(value)); }
}
''');
        await _writeFile('${app.path}/lib/audit_boundaries.dart', r'''
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audit_notifier.dart';
import 'expression_boundaries.dart' show formProvider;
class AuditView extends ConsumerWidget {
  const AuditView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(children: [
    TextField(onChanged: (value) => ref.read(auditProvider.notifier).update(value)),
    TextField(onChanged: (value) => ref.read(auditProvider.notifier).forward(value)),
    TextField(onChanged: (value) => ref.read(auditProvider.notifier).fetch(value)),
    TextField(onChanged: (value) => ref.read(formProvider.notifier).update(value)),
    Container(padding: EdgeInsets.zero, child: Expanded(child: const SizedBox())),
    Container(width: 20, child: Expanded(child: const SizedBox())),
    Container(child: Expanded(child: const SizedBox())),
  ]);
}
void separateAllocations() {
  final first = Completer<int>();
  final second = Completer<int>();
  first.complete(1);
  second.complete(2);
}
class Box { const Box(); }
void duplicateConstant() {
  final first = const Box();
  final second = const Box();
  print(first);
  print(second);
}
class StartupView extends ConsumerStatefulWidget {
  const StartupView({super.key});
  @override
  ConsumerState<StartupView> createState() => StartupState();
}
class StartupState extends ConsumerState<StartupView> {
  @override
  void initState() {
    super.initState();
    ref.read(auditProvider);
    (() { ref.read(auditProvider); })();
    [1].forEach((_) { ref.read(auditProvider); });
    WidgetsBinding.instance.addPostFrameCallback((_) { ref.read(auditProvider); });
    WidgetsBinding.instance.addPostFrameCallback(_afterFrame);
  }
  void _afterFrame(Duration elapsed) { ref.read(auditProvider); }
  @override
  Widget build(BuildContext context) => const SizedBox();
}
''');

        await _writeFile('${app.path}/lib/family_boundaries.dart', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';
class Payload {
  const Payload({required this.value});
  final String value;
}
@Riverpod(keepAlive: true)
String singleValue(Ref ref) => '';
@Riverpod(keepAlive: true)
String familyValue(Ref ref, String id) => id;
@Riverpod(keepAlive: true)
class SingleNotifier {
  String build() => '';
  void update({required bool enabled}) {}
}
''');

        await _writeFile('${app.path}/lib/null_container_boundaries.dart', r'''
import 'package:flutter/widgets.dart';
Widget explicitNull() => Container(padding: null, child: Expanded(child: const SizedBox()));
Widget unknown(dynamic padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
Widget nullableBound<T extends EdgeInsetsGeometry?>(T padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
Widget nonNullableBound<T extends EdgeInsetsGeometry>(T padding) => Container(padding: padding, child: Expanded(child: const SizedBox()));
''');

        final pubGet = await _run('flutter', ['pub', 'get'], app);
        expect(
          pubGet.exitCode,
          0,
          reason: 'flutter pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
        );

        final build = await _run('dart', ['run', 'build_runner', 'build'], app);
        expect(
          build.exitCode,
          0,
          reason: 'Freezed generation failed:\n${build.stdout}\n${build.stderr}',
        );

        final analyze = await _run('dart', ['analyze'], app);
        final output = '${analyze.stdout}\n${analyze.stderr}';

        // core-stack.md:60 names avoid_null_bang; a bang reports once.
        expect(output, isNot(contains('avoid_non_null_assertion')));
        expect(output, contains('avoid_null_bang'));
        expect(output, contains('avoid_ref_read_inside_build'));
        expect(output, contains('missing_provider_scope'));
        expect(output, contains('prefer_single_widget_per_file'));
        expect(output, contains('prefer_type_over_var'));
        expect(output, contains('riverpod_feature_notifier_keepalive'));
        expect(output, contains('presentation_widget_navigation_forbidden'));
        expect(output, contains('presentation_widget_controller_state'));
        final catches = output
            .split('\n')
            .where((line) => line.contains('widget_try_catch_boundary'));
        expect(catches, hasLength(1));
        expect(catches.single, contains('content_view.dart:24:'));

        expect(output, contains('presentation_widget_infrastructure_dependency'));
        expect(output, contains('prefer_dot_shorthands'));
        final broadWatches = output
            .split('\n')
            .where((line) => line.contains('riverpod_watch_no_select'));
        expect(broadWatches, hasLength(1));
        expect(broadWatches.single, contains('watch_boundaries.dart:14:'));
        final atomicUpdates = output
            .split('\n')
            .where(
              (line) =>
                  line.contains('atomic_update_boundaries.dart') &&
                  line.contains('require_atomic_async_updates'),
            );
        expect(atomicUpdates, hasLength(1), reason: output);
        for (final lineNumber in [38]) {
          expect(
            atomicUpdates.any(
              (line) => line.contains('atomic_update_boundaries.dart:$lineNumber:'),
            ),
            isTrue,
            reason: output,
          );
        }
        final sentryMutations = output
            .split('\n')
            .where(
              (line) =>
                  line.contains('sentry_mutation_boundaries.dart') &&
                  line.contains('avoid_mutating_parameters'),
            );
        expect(sentryMutations, hasLength(3), reason: output);
        expect(
          sentryMutations.any((line) => line.contains('sentry_mutation_boundaries.dart:7:')),
          isFalse,
          reason: output,
        );
        for (final lineNumber in [8, 10, 16]) {
          expect(
            sentryMutations.any(
              (line) => line.contains('sentry_mutation_boundaries.dart:$lineNumber:'),
            ),
            isTrue,
            reason: output,
          );
        }
        expect(output, contains('riverpod_select_identity_forbidden'));
        final contexts = output
            .split('\n')
            .where((line) => line.contains('resolved_contexts.dart'));
        expect(contexts.where((line) => line.contains('avoid_missing_interpolation')), isEmpty);
        expect(
          contexts.where((line) => line.contains('avoid_unnecessary_stateful_widgets')),
          isEmpty,
        );
        final callbacks = contexts.where((line) => line.contains('avoid_ref_watch_outside_build'));
        expect(callbacks, hasLength(1));
        expect(callbacks.single, contains('resolved_contexts.dart:8:'));
        expect(contexts.where((line) => line.trimLeft().startsWith('error -')), isEmpty);

        final mutations = output
            .split('\n')
            .where(
              (line) =>
                  line.contains('mutation_boundaries.dart') &&
                  line.contains('build_calls_mutating_instance_method'),
            );
        expect(mutations, hasLength(1));
        expect(mutations.single, contains('mutation_boundaries.dart:14:'));

        final initialization = output
            .split('\n')
            .where((line) => line.contains('initialization_boundaries.dart'));
        for (final code in [
          'avoid_unassigned_late_fields',
          'avoid_disposing_late_fields',
          'avoid_undisposed_instances',
          'avoid_flexible_outside_flex',
          'avoid_unassigned_local_variable',
        ]) {
          expect(initialization.where((line) => line.contains(code)), hasLength(1), reason: code);
        }

        final expressions = output
            .split('\n')
            .where((line) => line.contains('expression_boundaries.dart'));
        for (final code in [
          'use_existing_variable',
          'avoid_contradictory_expressions',
          'text_field_on_changed_no_debounce',
        ]) {
          expect(expressions.where((line) => line.contains(code)), hasLength(1), reason: code);
        }

        final audit = output.split('\n').where((line) => line.contains('audit_boundaries.dart'));
        for (final entry in {
          'text_field_on_changed_no_debounce': [11, 12],
          'avoid_flexible_outside_flex': [14, 15],
          'use_existing_variable': [28],
          'riverpod_read_init_state': [41, 42, 43],
        }.entries) {
          final findings = audit.where((line) => line.contains(entry.key));
          expect(findings, hasLength(entry.value.length), reason: '${entry.key}\n$output');
          for (final lineNumber in entry.value) {
            expect(
              findings.any((line) => line.contains('audit_boundaries.dart:$lineNumber:')),
              isTrue,
            );
          }
        }
        expect(
          audit.where(
            (line) =>
                line.trimLeft().startsWith('error -') &&
                !line.contains('riverpod_read_init_state') &&
                !line.contains('avoid_flexible_outside_flex') &&
                !line.contains('text_field_on_changed_no_debounce'),
          ),
          isEmpty,
        );

        final families = output
            .split('\n')
            .where((line) => line.contains('family_boundaries.dart'));
        final keptFamilies = families.where((line) => line.contains('riverpod_keepalive_family'));
        expect(keptFamilies, hasLength(1));
        expect(keptFamilies.single, contains('family_boundaries.dart:8:'));
        expect(
          families.where(
            (line) =>
                line.trimLeft().startsWith('error -') &&
                !line.contains('riverpod_keepalive_family'),
          ),
          isEmpty,
        );

        final nullableContainers = output
            .split('\n')
            .where((line) => line.contains('null_container_boundaries.dart'));
        final invalidContainers = nullableContainers.where(
          (line) => line.contains('avoid_flexible_outside_flex'),
        );
        expect(invalidContainers, hasLength(1));
        expect(invalidContainers.single, contains('null_container_boundaries.dart:5:'));
        expect(invalidContainers.single.trimLeft(), startsWith('error -'));
        expect(
          nullableContainers.where(
            (line) =>
                line.trimLeft().startsWith('error -') &&
                !line.contains('avoid_flexible_outside_flex'),
          ),
          isEmpty,
        );

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
    - "**/*.freezed.dart"
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
