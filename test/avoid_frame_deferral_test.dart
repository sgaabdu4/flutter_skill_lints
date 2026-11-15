import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_frame_deferral.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<AvoidFrameDeferralTest>('AvoidFrameDeferralTest', AvoidFrameDeferralTest.new, {
    'reportsAddPostFrameCallbackOnWidgetsBinding': (t) =>
        t.reportsAddPostFrameCallbackOnWidgetsBinding(),
    'reportsAddPostFrameCallbackOnSchedulerBinding': (t) =>
        t.reportsAddPostFrameCallbackOnSchedulerBinding(),
    'reportsAddPostFrameCallbackOnBindingVariable': (t) =>
        t.reportsAddPostFrameCallbackOnBindingVariable(),
    'reportsScheduleFrameCallback': (t) => t.reportsScheduleFrameCallback(),
    'reportsScheduleFrame': (t) => t.reportsScheduleFrame(),
    'reportsAwaitedEndOfFrame': (t) => t.reportsAwaitedEndOfFrame(),
    'reportsEndOfFrameReadFromBindingVariable': (t) => t.reportsEndOfFrameReadFromBindingVariable(),
    'allowsUserMethodsWithTheSameNames': (t) => t.allowsUserMethodsWithTheSameNames(),
    'allowsOtherSchedulerMembers': (t) => t.allowsOtherSchedulerMembers(),
    'skipsTestFiles': (t) => t.skipsTestFiles(),
    'skipsGeneratedFiles': (t) => t.skipsGeneratedFiles(),
  });
}

const _flutterSchedulerLibrary = r'''
typedef FrameCallback = void Function(Duration timeStamp);

class SchedulerBinding {
  static SchedulerBinding get instance => throw UnimplementedError();

  int scheduleFrameCallback(FrameCallback callback) => 0;
  void scheduleFrame() {}
  void scheduleForcedFrame() {}
  void addPostFrameCallback(FrameCallback callback) {}
  Future<void> get endOfFrame => Future<void>.value();
}

class WidgetsBinding extends SchedulerBinding {
  static WidgetsBinding get instance => throw UnimplementedError();
}
''';

final class AvoidFrameDeferralTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', _flutterSchedulerLibrary);
    rule = AvoidFrameDeferral();
    super.setUp();
  }

  Future<void> reportsAddPostFrameCallbackOnWidgetsBinding() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void run() {
  WidgetsBinding.instance.addPostFrameCallback((_) {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('addPostFrameCallback'), 'addPostFrameCallback'.length),
    ]);
  }

  Future<void> reportsAddPostFrameCallbackOnSchedulerBinding() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void run() {
  SchedulerBinding.instance.addPostFrameCallback((_) {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('addPostFrameCallback'), 'addPostFrameCallback'.length),
    ]);
  }

  Future<void> reportsAddPostFrameCallbackOnBindingVariable() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void run(WidgetsBinding binding) {
  binding.addPostFrameCallback((_) {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('addPostFrameCallback'), 'addPostFrameCallback'.length),
    ]);
  }

  Future<void> reportsScheduleFrameCallback() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void run() {
  SchedulerBinding.instance.scheduleFrameCallback((_) {});
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('scheduleFrameCallback'), 'scheduleFrameCallback'.length),
    ]);
  }

  Future<void> reportsScheduleFrame() async {
    const source = r'''
import 'package:flutter/widgets.dart';

void run() {
  SchedulerBinding.instance.scheduleFrame();
}
''';

    await assertDiagnostics(source, [
      lint(source.indexOf('scheduleFrame'), 'scheduleFrame'.length),
    ]);
  }

  Future<void> reportsAwaitedEndOfFrame() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> run() async {
  await SchedulerBinding.instance.endOfFrame;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('endOfFrame'), 'endOfFrame'.length)]);
  }

  Future<void> reportsEndOfFrameReadFromBindingVariable() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> run(WidgetsBinding binding) {
  final frame = binding.endOfFrame;
  return frame;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('endOfFrame'), 'endOfFrame'.length)]);
  }

  Future<void> allowsUserMethodsWithTheSameNames() async {
    await assertNoDiagnostics(r'''
class Scheduler {
  void addPostFrameCallback(void Function() callback) {}
  void scheduleFrameCallback(void Function() callback) {}
  void scheduleFrame() {}
  Future<void> get endOfFrame => Future<void>.value();
}

Future<void> run(Scheduler scheduler) async {
  scheduler.addPostFrameCallback(() {});
  scheduler.scheduleFrameCallback(() {});
  scheduler.scheduleFrame();
  await scheduler.endOfFrame;
}
''');
  }

  Future<void> allowsOtherSchedulerMembers() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void run() {
  SchedulerBinding.instance.scheduleForcedFrame();
}
''');
  }

  Future<void> skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/widgets.dart';

void main() {
  WidgetsBinding.instance.addPostFrameCallback((_) {});
}
''');

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> skipsGeneratedFiles() async {
    final path = '$testPackageRootPath/lib/screen.g.dart';
    newFile(path, r'''
import 'package:flutter/widgets.dart';

void run() {
  WidgetsBinding.instance.addPostFrameCallback((_) {});
}
''');

    await assertDiagnosticsInFile(path, []);
  }
}
