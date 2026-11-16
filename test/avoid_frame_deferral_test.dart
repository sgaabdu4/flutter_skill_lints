import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_skill_lints/src/additional_lints/rules/avoid_frame_deferral.dart';

import 'analysis_rule_suite.dart';

void main() {
  analysisRuleSuite<_AvoidFrameDeferralTest>(
    'AvoidFrameDeferralTest',
    _AvoidFrameDeferralTest.new,
    {
      'reportsAddPostFrameCallbackOnWidgetsBinding': (t) =>
          t._reportsAddPostFrameCallbackOnWidgetsBinding(),
      'reportsAddPostFrameCallbackOnSchedulerBinding': (t) =>
          t._reportsAddPostFrameCallbackOnSchedulerBinding(),
      'reportsAddPostFrameCallbackOnBindingVariable': (t) =>
          t._reportsAddPostFrameCallbackOnBindingVariable(),
      'reportsScheduleFrameCallback': (t) => t._reportsScheduleFrameCallback(),
      'reportsScheduleFrame': (t) => t._reportsScheduleFrame(),
      'reportsAwaitedEndOfFrame': (t) => t._reportsAwaitedEndOfFrame(),
      'reportsEndOfFrameReadFromBindingVariable': (t) =>
          t._reportsEndOfFrameReadFromBindingVariable(),
      'allowsUserMethodsWithTheSameNames': (t) => t._allowsUserMethodsWithTheSameNames(),
      'allowsOtherSchedulerMembers': (t) => t._allowsOtherSchedulerMembers(),
      'ignoresDocCommentReferences': (t) => t._ignoresDocCommentReferences(),
      'skipsTestFiles': (t) => t._skipsTestFiles(),
      'skipsIntegrationTestHelpers': (t) => t._skipsIntegrationTestHelpers(),
      'skipsGeneratedFiles': (t) => t._skipsGeneratedFiles(),
    },
  );
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

final class _AvoidFrameDeferralTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', _flutterSchedulerLibrary);
    rule = AvoidFrameDeferral();
    super.setUp();
  }

  Future<void> _reportsAddPostFrameCallbackOnWidgetsBinding() async {
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

  Future<void> _reportsAddPostFrameCallbackOnSchedulerBinding() async {
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

  Future<void> _reportsAddPostFrameCallbackOnBindingVariable() async {
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

  Future<void> _reportsScheduleFrameCallback() async {
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

  Future<void> _reportsScheduleFrame() async {
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

  Future<void> _reportsAwaitedEndOfFrame() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> run() async {
  await SchedulerBinding.instance.endOfFrame;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('endOfFrame'), 'endOfFrame'.length)]);
  }

  Future<void> _reportsEndOfFrameReadFromBindingVariable() async {
    const source = r'''
import 'package:flutter/widgets.dart';

Future<void> run(WidgetsBinding binding) {
  final frame = binding.endOfFrame;
  return frame;
}
''';

    await assertDiagnostics(source, [lint(source.indexOf('endOfFrame'), 'endOfFrame'.length)]);
  }

  Future<void> _allowsUserMethodsWithTheSameNames() async {
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

  Future<void> _allowsOtherSchedulerMembers() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void run() {
  SchedulerBinding.instance.scheduleForcedFrame();
}
''');
  }

  Future<void> _ignoresDocCommentReferences() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

/// Not [SchedulerBinding.addPostFrameCallback] and not [SchedulerBinding.endOfFrame].
void run() {}
''');
  }

  Future<void> _skipsIntegrationTestHelpers() async {
    final path = '$testPackageRootPath/integration_test/support/pump.dart';
    newFile(path, r'''
import 'package:flutter/widgets.dart';

Future<void> pump() async {
  await SchedulerBinding.instance.endOfFrame;
}
''');

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _skipsTestFiles() async {
    final path = '$testPackageRootPath/test/widget_test.dart';
    newFile(path, r'''
import 'package:flutter/widgets.dart';

void main() {
  WidgetsBinding.instance.addPostFrameCallback((_) {});
}
''');

    await assertDiagnosticsInFile(path, []);
  }

  Future<void> _skipsGeneratedFiles() async {
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
