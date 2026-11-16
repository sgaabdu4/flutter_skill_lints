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
  TurnHopRow(
    'notifier_codegen_sync_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class N extends _$N {
  @override
  int build() {
    Future.microtask(() => print('x'));
    return 0;
  }
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'notifier_codegen_sync_timer_run',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class N extends _$N {
  @override
  int build() {
    Timer.run(() => print('x'));
    return 0;
  }
}
''',
    ['Timer.run('],
  ),
  TurnHopRow(
    'notifier_codegen_async_await_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class N extends _$N {
  @override
  Future<int> build() async {
    await Future.microtask(() => print('x'));
    return 0;
  }
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'notifier_codegen_async_await_delayed_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class N extends _$N {
  @override
  Future<int> build() async {
    await Future.delayed(Duration.zero);
    return 0;
  }
}
''',
    ['Future.delayed(Duration.zero'],
  ),
  TurnHopRow(
    'notifier_classic_sync_microtask',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    Future.microtask(() => print('x'));
    return 0;
  }
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'notifier_classic_sync_timer_run',
    r'''
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    Timer.run(() => print('x'));
    return 0;
  }
}
''',
    ['Timer.run('],
  ),
  TurnHopRow(
    'notifier_classic_async_await_microtask',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    await Future.microtask(() => print('x'));
    return 0;
  }
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'notifier_classic_async_await_delayed_zero',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    await Future.delayed(Duration.zero);
    return 0;
  }
}
''',
    ['Future.delayed(Duration.zero'],
  ),
  TurnHopRow('clean_notifier_build_real_delay', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    Future.delayed(const Duration(seconds: 1), () => print('x'));
    return 0;
  }
}
''', []),
  TurnHopRow('clean_plain_class_build_named_notifier', r'''
class FooNotifier {
  int build() {
    Future.microtask(() => print('x'));
    return 0;
  }
}
''', []),
  TurnHopRow(
    'delayed_local_const_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  const zero = Duration.zero;
  Future.delayed(zero, () => print('x'));
  return 0;
}
''',
    ['Future.delayed(zero'],
  ),
  TurnHopRow(
    'timer_top_level_const_zero',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

const kNoDelay = Duration(milliseconds: 0);

@riverpod
int p(Ref ref) {
  Timer(kNoDelay, () => print('x'));
  return 0;
}
''',
    ['Timer(kNoDelay'],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'delayed_top_level_const_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

const kNoDelay = Duration(milliseconds: 0);

@riverpod
int p(Ref ref) {
  Future.delayed(kNoDelay, () => print('x'));
  return 0;
}
''',
    ['Future.delayed(kNoDelay'],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'delayed_duration_of_const_int_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

const kMs = 0;

@riverpod
int p(Ref ref) {
  Future.delayed(Duration(milliseconds: kMs), () => print('x'));
  return 0;
}
''',
    ['Future.delayed(Duration(milliseconds: kMs)'],
  ),
  TurnHopRow('clean_delayed_named_zero_is_two_seconds', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Delays {
  static const zero = Duration(seconds: 2);
}

@riverpod
int p(Ref ref) {
  Future.delayed(Delays.zero, () => print('x'));
  return 0;
}
''', []),
  TurnHopRow('clean_delayed_duration_of_const_int_five', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

const kMs = 5;

@riverpod
int p(Ref ref) {
  Future.delayed(Duration(milliseconds: kMs), () => print('x'));
  return 0;
}
''', []),
  TurnHopRow(
    'delayed_dot_const_new_zero',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.delayed(const .new(milliseconds: 0));
  return 0;
}
''',
    ['Future<void>.delayed(const .new(milliseconds: 0)'],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'delayed_dot_new_default',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.delayed(.new());
  return 0;
}
''',
    ['Future<void>.delayed(.new()'],
  ),
  TurnHopRow(
    'await_value_in_async_provider',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  await Future<void>.value();
  return 0;
}
''',
    ['Future<void>.value()'],
  ),
  TurnHopRow(
    'await_null_in_async_provider',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  await null;
  return 0;
}
''',
    ['await null'],
  ),
  TurnHopRow(
    'zone_schedule_microtask',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Zone.current.scheduleMicrotask(() => print('x'));
  return 0;
}
''',
    ['Zone.current.scheduleMicrotask('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'timer_periodic_zero',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Timer.periodic(Duration.zero, (_) => print('x'));
  return 0;
}
''',
    ['Timer.periodic(Duration.zero'],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'error_catch_error',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<void>.error('x').catchError((_) => print('x'));
  return 0;
}
''',
    ['Future<void>.error('],
  ),
  TurnHopRow(
    'stream_value_listen',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Stream<int>.value(1).listen((_) => print('x'));
  return 0;
}
''',
    ['Stream<int>.value(1)'],
  ),
  TurnHopRow(
    'completed_completer_then',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final done = Completer<void>();
  done.complete();
  done.future.then((_) => print('x'));
  return 0;
}
''',
    ['done.future.then('],
  ),
  TurnHopRow(
    'completer_cascade_complete_then',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final done = Completer<void>()..complete();
  done.future.then((_) => print('x'));
  return 0;
}
''',
    ['done.future.then('],
  ),
  TurnHopRow('clean_pending_completer_then', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  final done = Completer<void>();
  done.future.then((_) => print('x'));
  done.complete();
  return 0;
}
''', []),
  TurnHopRow(
    'tear_off_provider',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final p = Provider<int>(_create);

int _create(Ref ref) {
  Future.microtask(() => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'tear_off_shared_by_two_providers',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final a = Provider<int>(_create);
final b = Provider<int>(_create);

int _create(Ref ref) {
  Future.microtask(() => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'clean_sync_returning_future_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
int p(Ref ref) {
  final repo = Repo();
  Future<int>.sync(() => repo.load()).then((_) => print('x'));
  return 0;
}
''',
    [],
    realSdkOnly: true,
  ),
  TurnHopRow('clean_value_of_future_then', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
int p(Ref ref) {
  final repo = Repo();
  Future.value(repo.load()).then((_) => print('x'));
  return 0;
}
''', []),
  TurnHopRow(
    'sync_plain_result_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<int>.sync(() => 1).then((_) => print('x'));
  return 0;
}
''',
    ['Future<int>.sync('],
    realSdkOnly: true,
  ),
  TurnHopRow(
    'value_plain_arg_then',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
int p(Ref ref) {
  Future<int>.value(1).then((_) => print('x'));
  return 0;
}
''',
    ['Future<int>.value(1)'],
  ),
];
