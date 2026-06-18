// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
// ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show ExpectedDiagnostic;
import 'package:flutter_skill_lints/src/additional_lints/rules/use_local_notifications_exact_alarm_permission_api.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(
    () => defineReflectiveTests(UseLocalNotificationsExactAlarmPermissionApiTest),
  );
}

@reflectiveTest
class UseLocalNotificationsExactAlarmPermissionApiTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseLocalNotificationsExactAlarmPermissionApi();
    super.setUp();
  }

  ExpectedDiagnostic lintFor(String source, String needle) {
    final offset = source.indexOf(needle);
    if (offset < 0) {
      throw StateError('Needle not found: $needle');
    }
    return lint(offset, needle.length);
  }

  Future<void> test_androidIntentExactAlarmSettingsAction_lint() async {
    const source = r'''
class AndroidIntent {
  const AndroidIntent({required String action});
}

void requestPermission() {
  const intent = AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM');
  intent.toString();
}
''';

    await assertDiagnostics(source, [
      lintFor(source, "'android.settings.REQUEST_SCHEDULE_EXACT_ALARM'"),
    ]);
  }

  Future<void> test_androidIntentOtherSettingsAction_noLint() async {
    await assertNoDiagnostics(r'''
class AndroidIntent {
  const AndroidIntent({required String action});
}

void openSettings() {
  const intent = AndroidIntent(action: 'android.settings.APPLICATION_DETAILS_SETTINGS');
  intent.toString();
}
''');
  }

  Future<void> test_exactAlarmPermissionApi_noLint() async {
    await assertNoDiagnostics(r'''
class AndroidFlutterLocalNotificationsPlugin {
  Future<bool?> canScheduleExactNotifications() async => true;
  Future<bool?> requestExactAlarmsPermission() async => true;
}

Future<bool> requestPermission(AndroidFlutterLocalNotificationsPlugin android) async {
  final canSchedule = await android.canScheduleExactNotifications();
  if (canSchedule == true) return true;

  final granted = await android.requestExactAlarmsPermission();
  return granted == true;
}
''');
  }

  Future<void> test_exactAlarmSettingsStringWithoutAndroidIntent_noLint() async {
    await assertNoDiagnostics(r'''
const exactAlarmSettingsAction = 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM';
''');
  }
}
