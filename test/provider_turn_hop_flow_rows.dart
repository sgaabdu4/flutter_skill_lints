import 'provider_turn_hop_more_rows.dart';

export 'provider_turn_hop_more_rows.dart';

final allProviderTurnHopRows = [
  ...providerTurnHopRows,
  ...providerTurnHopMoreRows,
  ...providerTurnHopFlowRows,
];

const providerTurnHopFlowRows = <TurnHopRow>[
  TurnHopRow('clean_completer_completed_in_listen_callback', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

Stream<int> watchRepo() => throw 0;

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  final sub = watchRepo().listen((value) {
    if (!completer.isCompleted) completer.complete(value);
  });
  ref.onDispose(sub.cancel);
  return await completer.future;
  return 0;
}
''', []),
  TurnHopRow('clean_completer_completed_in_timer_callback', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  Timer(const Duration(seconds: 5), () => completer.complete(1));
  return await completer.future;
  return 0;
}
''', []),
  TurnHopRow('clean_completer_completed_in_on_dispose_callback', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  ref.onDispose(() => completer.complete(1));
  return await completer.future;
  return 0;
}
''', []),
  TurnHopRow(
    'clean_completer_completed_in_ref_listen_callback',
    r'''
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

final other = Provider<int>((ref) => 0);

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  ref.listen(other, (_, next) => completer.complete(next));
  return await completer.future;
}
''',
    [],
    realSdkOnly: true,
  ),
  TurnHopRow('clean_async_notifier_completer_completed_in_listen', r'''
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

Stream<int> watchRepo() => throw 0;

class N extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final completer = Completer<int>();
    watchRepo().listen((value) => completer.complete(value));
    return await completer.future;
  }
}
''', []),
  TurnHopRow('clean_completer_completed_conditionally_before_await', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  if (ref.hashCode == 0) completer.complete(1);
  return await completer.future;
  return 0;
}
''', []),
  TurnHopRow(
    'completer_completed_before_await_in_async_provider',
    r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  completer.complete(1);
  return await completer.future;
  return 0;
}
''',
    ['await completer.future'],
  ),
  TurnHopRow(
    'notifier_sync_build_calls_helper_method_with_microtask',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    _refresh();
    return 0;
  }

  void _refresh() {
    Future.microtask(() => state = 1);
  }
}
''',
    ['_refresh();'],
  ),
  TurnHopRow(
    'notifier_codegen_sync_build_calls_helper_method_with_microtask',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
class N extends _$N {
  @override
  int build() {
    _refresh();
    return 0;
  }

  void _refresh() {
    Future.microtask(() => state = 1);
  }
}
''',
    ['_refresh();'],
  ),
  TurnHopRow(
    'notifier_async_build_calls_helper_method_with_microtask',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    warmUp();
    return 0;
  }

  void warmUp() {
    Future.microtask(() => print('x'));
  }
}
''',
    ['warmUp();'],
  ),
  TurnHopRow(
    'notifier_async_build_awaits_helper_method_with_awaited_value',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    await _init();
    return 0;
  }

  Future<void> _init() async {
    await Future<void>.value();
  }
}
''',
    ['_init();'],
  ),
  TurnHopRow(
    'notifier_build_calls_this_helper_method_with_future_constructor',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    this.kick();
    return 0;
  }

  void kick() {
    Future(() => print('x'));
  }
}
''',
    ['this.kick();'],
  ),
  TurnHopRow('clean_notifier_build_calls_helper_method_with_real_delay', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    _refresh();
    return 0;
  }

  void _refresh() {
    Future.delayed(const Duration(seconds: 1), () => print('x'));
  }
}
''', []),
  TurnHopRow('clean_notifier_two_level_helper_method_limit', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    _outer();
    return 0;
  }

  void _outer() {
    _refresh();
  }

  void _refresh() {
    Future.microtask(() => print('x'));
  }
}
''', []),
  TurnHopRow('clean_notifier_build_calls_method_of_other_object', r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Other {
  void refresh() {
    Future.microtask(() => print('x'));
  }
}

class N extends Notifier<int> {
  @override
  int build() {
    Other().refresh();
    return 0;
  }
}
''', []),
  TurnHopRow(
    'notifier_microtask_import_prefix',
    r'''
import 'dart:async' as async;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    async.Future.microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''',
    ['async.Future.microtask('],
  ),
  TurnHopRow(
    'notifier_microtask_typedef_alias',
    r'''
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Hop = Future<void>;

class N extends Notifier<int> {
  @override
  int build() {
    Hop.microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''',
    ['Hop.microtask('],
  ),
  TurnHopRow(
    'notifier_microtask_typed_future',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    Future<void>.microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''',
    ['Future<void>.microtask('],
  ),
  TurnHopRow(
    'notifier_microtask_typed_dot_shorthand',
    r'''
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    final Future<void> hop = .microtask(() => _loadTodos());
    return 0;
  }

  void _loadTodos() {}
}
''',
    ['.microtask('],
  ),
  TurnHopRow(
    'notifier_microtask_tear_off',
    r'''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class N extends Notifier<int> {
  @override
  int build() {
    Future.microtask(_loadTodos);
    return 0;
  }

  void _loadTodos() {}
}
''',
    ['Future.microtask('],
  ),
  TurnHopRow(
    'await_for_stream_value',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  await for (final _ in Stream<int>.value(1)) {}
  return 0;
}
''',
    ['Stream<int>.value(1)'],
  ),
  TurnHopRow('clean_await_for_pending_stream', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

Stream<int> watchRepo() => throw 0;

@riverpod
Future<int> p(Ref ref) async {
  await for (final _ in watchRepo()) {}
  return 0;
}
''', []),
  TurnHopRow('clean_local_value_reassigned_to_load_before_await', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = Future<int>.value(0);
  pending = repo.load();
  await pending;
  return 0;
}
''', []),
  TurnHopRow(
    'local_value_reassigned_to_value_before_await',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  var done = Future<int>.value(0);
  done = Future<int>.value(1);
  await done;
  return 0;
}
''',
    ['await done'],
  ),
  TurnHopRow(
    'local_load_reassigned_to_value_before_await',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var done = repo.load();
  done = Future<int>.value(1);
  await done;
  return 0;
}
''',
    ['await done'],
  ),
  TurnHopRow('clean_local_value_reassigned_in_closure', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = Future<int>.value(0);
  ref.onDispose(() => pending = repo.load());
  await pending;
  return 0;
}
''', []),
  TurnHopRow('clean_local_value_reassigned_conditionally', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = Future<int>.value(0);
  if (ref.hashCode == 0) pending = repo.load();
  await pending;
  return 0;
}
''', []),
  TurnHopRow('clean_local_value_reassigned_later_in_loop', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = Future<int>.value(0);
  for (var i = 0; i < 2; i++) {
    await pending;
    pending = repo.load();
  }
  return 0;
}
''', []),
  TurnHopRow('clean_tear_off_passed_to_non_provider', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

void runWithRef(void Function(Ref ref) body) {}

void _warm(Ref ref) {
  Future.microtask(() => print('x'));
}

void start() {
  runWithRef(_warm);
}
''', []),
  TurnHopRow('clean_completer_completed_in_braced_if_before_await', r'''
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

@riverpod
Future<int> p(Ref ref) async {
  final completer = Completer<int>();
  if (ref.hashCode == 0) {
    completer.complete(1);
  }
  return await completer.future;
  return 0;
}
''', []),
  TurnHopRow('clean_local_load_reassigned_to_value_conditionally', r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = repo.load();
  if (ref.hashCode == 0) pending = Future<int>.value(1);
  await pending;
  return 0;
}
''', []),
  TurnHopRow(
    'local_value_reassigned_in_closure_after_await',
    r'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

class Repo {
  Future<int> load() async => 0;
}

@riverpod
Future<int> p(Ref ref) async {
  final repo = Repo();
  var pending = Future<int>.value(0);
  await pending;
  ref.onDispose(() => pending = repo.load());
  return 0;
}
''',
    ['await pending'],
  ),
];
