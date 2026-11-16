import 'provider_turn_hop_rows.dart';

export 'provider_turn_hop_rows.dart';

final allProviderTurnHopRows = [...providerTurnHopRows, ...providerTurnHopMoreRows];

const providerTurnHopMoreRows = <TurnHopRow>[
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
