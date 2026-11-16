final class TurnHopRow {
  const TurnHopRow(this.id, this.source, this.hops, {this.realSdkOnly = false});

  final String id;
  final String source;
  final List<String> hops;
  final bool realSdkOnly;

  List<int> get hopLines => [
    for (final hop in hops) source.substring(0, source.indexOf(hop)).split('\n').length,
  ];
}

const providerTurnHopRows = <TurnHopRow>[
  TurnHopRow(
    'microtask_statement',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.microtask(() => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'microtask_dot_shorthand',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  unawaited(.microtask(() => print('x')));
  return 0;
}
''',
    ['.microtask('],
  ),
  TurnHopRow(
    'microtask_then_single_report',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.microtask(() {}).then((_) => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'schedule_microtask',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  scheduleMicrotask(() => print('x'));
  return 0;
}
''',
    ['scheduleMicrotask('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'schedule_microtask_expression_body',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
void kickoff(Ref ref) => scheduleMicrotask(() => print('x'));
''',
    ['scheduleMicrotask('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'timer_run',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer.run(() => print('x'));
  return 0;
}
''',
    ['Timer.run('],
  ),
  TurnHopRow(
    'timer_duration_zero',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer(Duration.zero, () => print('x'));
  return 0;
}
''',
    ['Timer(Duration.zero'],
  ),
  TurnHopRow(
    'timer_default_duration',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer(const Duration(), () => print('x'));
  return 0;
}
''',
    ['Timer(const Duration()'],
  ),
  TurnHopRow(
    'timer_milliseconds_zero',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer(const Duration(milliseconds: 0), () => print('x'));
  return 0;
}
''',
    ['Timer(const Duration(milliseconds: 0)'],
  ),
  TurnHopRow(
    'timer_one_microsecond',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer(const Duration(microseconds: 1), () => print('x'));
  return 0;
}
''',
    ['Timer(const Duration(microseconds: 1)'],
  ),
  TurnHopRow(
    'timer_dot_shorthand_zero',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer(.zero, () => print('x'));
  return 0;
}
''',
    ['Timer(.zero'],
  ),
  TurnHopRow(
    'future_constructor',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future(() => print('x'));
  return 0;
}
''',
    ['Future(() =>'],
  ),
  TurnHopRow(
    'future_delayed_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(Duration.zero, () => print('x'));
  return 0;
}
''',
    ['Future.delayed(Duration.zero'],
  ),
  TurnHopRow(
    'future_delayed_zero_then_single_report',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(Duration.zero).then((_) => print('x'));
  return 0;
}
''',
    ['Future.delayed(Duration.zero'],
  ),
  TurnHopRow(
    'future_delayed_microsecond',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(const Duration(microseconds: 1), () => print('x'));
  return 0;
}
''',
    ['Future.delayed(const Duration(microseconds: 1)'],
  ),
  TurnHopRow(
    'future_delayed_zero_milliseconds',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(const Duration(milliseconds: 0), () => print('x'));
  return 0;
}
''',
    ['Future.delayed(const Duration(milliseconds: 0)'],
  ),
  TurnHopRow(
    'future_sync_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.sync(() {}).then((_) => print('x'));
  return 0;
}
''',
    ['Future.sync('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'value_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value().then((_) => print('x'));
  return 0;
}
''',
    ['Future<void>.value()'],
  ),
  TurnHopRow(
    'value_then_parenthesized',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  (Future<void>.value()).then((_) => print('x'));
  return 0;
}
''',
    ['(Future<void>.value())'],
  ),
  TurnHopRow(
    'value_cascade_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value()..then((_) => print('x'));
  return 0;
}
''',
    ['Future<void>.value()..then'],
  ),
  TurnHopRow(
    'value_chained_then_single_report',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value().then((_) {}).then((_) => print('x'));
  return 0;
}
''',
    ['Future<void>.value()'],
  ),
  TurnHopRow(
    'value_catch_error',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value().catchError((_) => print('x'));
  return 0;
}
''',
    ['Future<void>.value()'],
  ),
  TurnHopRow(
    'value_when_complete',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value().whenComplete(() => print('x'));
  return 0;
}
''',
    ['Future<void>.value()'],
  ),
  TurnHopRow(
    'value_dot_shorthand_variable',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final Future<void> done = .value();
  done.then((_) => print('x'));
  return 0;
}
''',
    ['done.then('],
  ),
  TurnHopRow(
    'awaited_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  await Future.microtask(() => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'expression_body_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) => Future.microtask(() => 0);
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'returned_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) {
  return Future.microtask(() => 0);
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'closure_in_other_call',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

void run(void Function() body) {}

@riverpod
int p(Ref ref) {
  run(() => Future.microtask(() => print('x')));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'on_dispose_closure',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  ref.onDispose(() {
    Future.microtask(() => print('x'));
  });
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'helper_wrapping_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

void later(void Function() body) {
  Future.microtask(body);
}

@riverpod
int p(Ref ref) {
  later(() => print('x'));
  return 0;
}
''',
    ['later(() =>'],
  ),
  TurnHopRow(
    'future_wrapping_foundation_call',
    r'''
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future(() => compute(parse, '1'));
  return 0;
}

int parse(String value) => 0;
''',
    ['Future(() =>'],
  ),
  TurnHopRow(
    'classic_provider',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final p = Provider<int>((ref) {
  Future.microtask(() => print('x'));
  return 0;
});
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'classic_provider_zero_timer',
    r'''
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final p = Provider<int>((ref) {
  Timer(Duration.zero, () => print('x'));
  return 0;
});
''',
    ['Timer(Duration.zero'],
  ),
  TurnHopRow(
    'classic_family_provider',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final p = FutureProvider.family<int, int>((ref, id) async {
  await Future.microtask(() => print('x'));
  return id;
});
''',
    ['Future.microtask('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'repository_from_path_package',
    r'''
import 'package:data/data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.microtask(() => Repo().load());
  return 0;
}
''',
    ['Future.microtask('],
    realSdkOnly: true,
  ),
  TurnHopRow('clean_poll_timer', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return 0;
}
''', []),
  TurnHopRow('clean_debounce_returned', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) {
  return Future.delayed(const Duration(milliseconds: 300), () => 0);
}
''', []),
  TurnHopRow('clean_retry_backoff_in_provider', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  for (var i = 1; i <= 3; i++) {
    await Future.delayed(Duration(seconds: i));
  }
  return 0;
}
''', []),
  TurnHopRow('clean_retry_helper_stored_future', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<int> retry(Future<int> Function() attempt) async {
  for (var i = 1; i <= 3; i++) {
    try {
      return await attempt();
    } catch (_) {
      await Future.delayed(Duration(seconds: i));
    }
  }
  return 0;
}

@riverpod
Future<int> p(Ref ref) {
  final attempt = retry(() async => 1);
  return attempt;
}
''', []),
  TurnHopRow('clean_keep_alive_delay', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), link.close);
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_then', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(const Duration(seconds: 1)).then((_) => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_variable_duration', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final wait = Duration(milliseconds: ref.hashCode);
  Future.delayed(wait, () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_timer_variable_duration', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final wait = Duration(milliseconds: ref.hashCode);
  Timer(wait, () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_one_millisecond', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(const Duration(milliseconds: 1), () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_thousand_microseconds', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(const Duration(microseconds: 1000), () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_inline_variable_duration', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future.delayed(Duration(milliseconds: ref.hashCode), () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_in_closure', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final wait = Duration(milliseconds: ref.hashCode);
  ref.onDispose(() {
    unawaited(Future.delayed(wait, () => print('x')));
  });
  return 0;
}
''', []),
  TurnHopRow('clean_value_without_then', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value();
  return 0;
}
''', []),
  TurnHopRow('clean_then_on_pending_future', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  load().then((_) => print('x'));
  return 0;
}

Future<int> load() async => 0;
''', []),
  TurnHopRow('clean_outside_provider', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

void warm() {
  Future.microtask(() => print('x'));
  Timer.run(() => print('x'));
}

@riverpod
int p(Ref ref) => 0;
''', []),
  TurnHopRow('clean_two_level_helper_limit', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

void later(void Function() body) {
  Future.microtask(body);
}

void outer(void Function() body) {
  later(body);
}

@riverpod
int p(Ref ref) {
  outer(() => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_on_dispose_without_hop', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  ref.onDispose(() => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_own_run_method', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Runner {
  static void run(void Function() body) {}
}

@riverpod
int p(Ref ref) {
  Runner.run(() => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_own_value_with_then', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Future<T> {
  Future.value();
  void then(void Function(Object?) body) {}
}

@riverpod
int p(Ref ref) {
  Future<void>.value().then((_) => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_own_timer_zero', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Timer {
  Timer(Duration delay, void Function() body);
}

@riverpod
int p(Ref ref) {
  Timer(Duration.zero, () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_own_schedule_microtask', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

void scheduleMicrotask(void Function() body) {}

@riverpod
int p(Ref ref) {
  scheduleMicrotask(() => print('x'));
  return 0;
}
''', []),
  TurnHopRow(
    'clean_completed_future_non_completion_method',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.value().ignore();
  return 0;
}
''',
    [],
    realSdkOnly: true,
  ),
];
