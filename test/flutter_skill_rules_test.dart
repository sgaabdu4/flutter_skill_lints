// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/rules/avoid_dynamic_except_json_maps.dart';
import 'package:flutter_skill_lints/src/rules/avoid_legacy_riverpod_apis.dart';
import 'package:flutter_skill_lints/src/rules/avoid_null_bang.dart';
import 'package:flutter_skill_lints/src/rules/avoid_private_widget_classes.dart';
import 'package:flutter_skill_lints/src/rules/avoid_route_param_throw_in_build.dart';
import 'package:flutter_skill_lints/src/rules/avoid_run_zoned_guarded.dart';
import 'package:flutter_skill_lints/src/rules/avoid_shrink_wrap.dart';
import 'package:flutter_skill_lints/src/rules/avoid_silent_repository_null_return.dart';
import 'package:flutter_skill_lints/src/rules/avoid_sync_notifier_state_read.dart';
import 'package:flutter_skill_lints/src/rules/avoid_widget_build_helpers.dart';
import 'package:flutter_skill_lints/src/rules/guard_context_pop.dart';
import 'package:flutter_skill_lints/src/rules/use_context_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_invalidate.dart';
import 'package:flutter_skill_lints/src/rules/use_ref_mounted_after_await.dart';
import 'package:flutter_skill_lints/src/rules/use_sealed_freezed_classes.dart';
import 'package:flutter_skill_lints/src/rules/use_unawaited_for_fire_and_forget_futures.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
part 'flutter_skill_rules_test/flutter_skill_rules_part_01.dart';
part 'flutter_skill_rules_test/flutter_skill_rules_part_02.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseRefMountedAfterAwaitTest);
    defineReflectiveTests(UseContextMountedAfterAwaitTest);
    defineReflectiveTests(AvoidLegacyRiverpodApisTest);
    defineReflectiveTests(AvoidDynamicExceptJsonMapsTest);
    defineReflectiveTests(AvoidNullBangTest);
    defineReflectiveTests(AvoidPrivateWidgetClassesTest);
    defineReflectiveTests(AvoidWidgetBuildHelpersTest);
    defineReflectiveTests(AvoidShrinkWrapTest);
    defineReflectiveTests(GuardContextPopTest);
    defineReflectiveTests(UseRefInvalidateTest);
    defineReflectiveTests(UseSealedFreezedClassesTest);
    defineReflectiveTests(AvoidRouteParamThrowInBuildTest);
    defineReflectiveTests(AvoidRunZonedGuardedTest);
    defineReflectiveTests(AvoidSilentRepositoryNullReturnTest);
    defineReflectiveTests(AvoidSyncNotifierStateReadTest);
    defineReflectiveTests(UseUnawaitedForFireAndForgetFuturesTest);
  });
}

abstract class _FlutterSkillRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    _addFlutterPackage();
    _addRiverpodPackage();
    _addFreezedPackage();
    super.setUp();
  }

  ExpectedDiagnostic lintFor(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  ExpectedDiagnostic lintForLast(String source, String needle) {
    final offset = source.lastIndexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  void _addFlutterPackage() {
    newPackage('flutter').addFile('lib/widgets.dart', r'''
class BuildContext {
  bool get mounted => true;
  bool canPop() => true;
  void pop() {}
  void go(String location) {}
}

abstract class Widget {
  const Widget();
}

class SizedBox extends Widget {
  const SizedBox();
}

class Text extends Widget {
  const Text(String data);
}

class ListView extends Widget {
  const ListView({bool shrinkWrap = false});
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget();
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => BuildContext();
}
''');
  }

  void _addRiverpodPackage() {
    newPackage('riverpod').addFile('lib/riverpod.dart', r'''
class Ref {
  bool get mounted => true;
  T read<T>(Object provider) => throw UnimplementedError();
  T watch<T>(Object provider) => throw UnimplementedError();
  T refresh<T>(Object provider) => throw UnimplementedError();
  void invalidate(Object provider) {}
}

class WidgetRef extends Ref {}
class AutoDisposeRef extends Ref {}
class FutureProviderRef<T> extends Ref {}

class Notifier<T> {
  Ref get ref => Ref();
  late T state;
  T build() => throw UnimplementedError();
}

class AsyncNotifier<T> extends Notifier<T> {}

class Provider<T> {
  Provider(T Function(Ref ref) create);
}

class StateProvider<T> {
  StateProvider(T Function(Ref ref) create);
}

class StateNotifierProvider<T, S> {
  StateNotifierProvider(T Function(Ref ref) create);
}

class ChangeNotifierProvider<T> {
  ChangeNotifierProvider(T Function(Ref ref) create);
}

class NotifierProvider<T, S> {
  NotifierProvider(T Function() create);
}

class AsyncNotifierProvider<T, S> {
  AsyncNotifierProvider(T Function() create);
}

class FutureProvider<T> {
  FutureProvider(Future<T> Function(Ref ref) create);
}

class StreamProvider<T> {
  StreamProvider(Stream<T> Function(Ref ref) create);
}
''');
    newPackage(
      'flutter_riverpod',
    ).addFile('lib/flutter_riverpod.dart', "export 'package:riverpod/riverpod.dart';\n");
  }

  void _addFreezedPackage() {
    newPackage('freezed_annotation').addFile('lib/freezed_annotation.dart', r'''
class Freezed {
  const Freezed();
}

const freezed = Freezed();
''');
  }
}
