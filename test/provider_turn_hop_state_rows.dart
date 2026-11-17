import 'provider_turn_hop_more_rows.dart';

const providerTurnHopStateRows = <TurnHopRow>[
  TurnHopRow('clean_null_coalescing_assign_future_value_fallback', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

final _inflight = <int, Future<int>>{};

@riverpod
Future<int> p(Ref ref) async {
  Future<int>? pending = _inflight[1];
  pending ??= Future.value(0);
  return await pending;
}
''', []),
  TurnHopRow(
    'null_coalescing_assign_to_null_local_with_future_value',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  Future<int>? pending;
  pending ??= Future.value(0);
  return await pending;
}
''',
    ['await pending'],
  ),
  TurnHopRow(
    'null_coalescing_assign_keeps_completed_value',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  Future<int>? pending = Future<int>.value(0);
  pending ??= repo.load();
  return await pending;
}
''',
    ['await pending'],
  ),
  TurnHopRow('clean_completer_reset_before_await', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Stream<int> watchRepo() => throw 0;

@riverpod
Future<int> p(Ref ref) async {
  var completer = Completer<int>();
  completer.complete(0);
  completer = Completer<int>();
  watchRepo().listen(completer.complete);
  return await completer.future;
}
''', []),
  TurnHopRow(
    'completer_reset_then_completed_before_await',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  var completer = Completer<int>();
  completer = Completer<int>();
  completer.complete(1);
  return await completer.future;
}
''',
    ['await completer.future'],
  ),
  TurnHopRow(
    'completer_completed_in_finally_before_await',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<void> load() async {}

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  try {
    await load();
  } finally {
    completer.complete(1);
  }
  return await completer.future;
}
''',
    ['await completer.future'],
  ),
  TurnHopRow('clean_completer_completed_in_try_body_before_await', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<void> load() async {}

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  try {
    await load();
    completer.complete(1);
  } catch (_) {}
  return await completer.future;
}
''', []),
  TurnHopRow('clean_completer_completed_in_finally_after_await', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  try {
    return await completer.future;
  } finally {
    completer.complete(1);
  }
}
''', []),
  TurnHopRow(
    'late_completer_assigned_then_completed',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  late final Completer<int> completer;
  completer = Completer<int>();
  completer.complete(1);
  return await completer.future;
}
''',
    ['await completer.future'],
  ),
  TurnHopRow('clean_late_completer_assigned_and_never_completed', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Stream<int> watchRepo() => throw 0;

@riverpod
Future<int> p(Ref ref) async {
  late final Completer<int> completer;
  completer = Completer<int>();
  watchRepo().listen(completer.complete);
  return await completer.future;
}
''', []),
  TurnHopRow(
    'completer_future_through_bang',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  Completer<int>? completer = Completer<int>();
  completer?.complete(1);
  return await completer!.future;
}
''',
    ['await completer!.future'],
  ),
  TurnHopRow(
    'completer_completed_through_bang',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  Completer<int>? completer = Completer<int>();
  completer!.complete(1);
  return await completer.future;
}
''',
    ['await completer.future'],
  ),
  TurnHopRow(
    'notifier_build_reads_getter_that_hops',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    final warm = _warm;
    return 0;
  }

  Future<void> get _warm => Future.microtask(() => print('x'));
}
''',
    ['_warm;'],
  ),
  TurnHopRow(
    'provider_function_awaits_top_level_getter_that_hops',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

Future<int> get _next => Future.delayed(Duration.zero, () => 1);

@riverpod
Future<int> p(Ref ref) async {
  return await _next;
}
''',
    ['_next;'],
  ),
  TurnHopRow('clean_getter_with_real_delay', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    final warm = _warm;
    return 0;
  }

  Future<void> get _warm => Future.delayed(const Duration(seconds: 1));
}
''', []),
  TurnHopRow(
    'notifier_build_calls_mixin_method_that_hops',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin Warmup {
  void warm() {
    Future.microtask(() => print('x'));
  }
}

class N extends Notifier<int> with Warmup {
  @override
  int build() {
    warm();
    return 0;
  }
}
''',
    ['warm();'],
  ),
  TurnHopRow(
    'notifier_build_calls_base_class_method_that_hops',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseNotifier extends Notifier<int> {
  void warm() {
    Future.microtask(() => print('x'));
  }
}

class N extends BaseNotifier {
  @override
  int build() {
    this.warm();
    return 0;
  }
}
''',
    ['this.warm();'],
  ),
  TurnHopRow('clean_mixin_method_with_real_delay', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin Warmup {
  void warm() {
    Future.delayed(const Duration(seconds: 1), () => print('x'));
  }
}

class N extends Notifier<int> with Warmup {
  @override
  int build() {
    warm();
    return 0;
  }
}
''', []),
  TurnHopRow(
    'notifier_build_calls_static_helper_that_hops',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    _warm();
    return 0;
  }

  static void _warm() {
    Future.microtask(() => print('x'));
  }
}
''',
    ['_warm();'],
  ),
  TurnHopRow(
    'tear_off_passed_to_provider_override_with',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

final p = Provider<int>((ref) => 0);
final o = p.overrideWith(_create);

int _create(Ref ref) {
  Future.microtask(() => print('x'));
  return 0;
}
''',
    ['Future.microtask('],
  ),
];
